#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Weapon Skin"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module weapon skin"
#define PLUGIN_VERSION      "2.2.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

#include <sdktools>
#include <store>
#include <PTaH>

enum WeaponSkin
{
    String:szUnique[32],
    String:szWeapon[32],
    iSlot,
    iSeed,
    iWearT,
    iPaint,
    Float:fWearF
}

any g_eWeaponSkin[STORE_MAX_ITEMS][WeaponSkin];
int g_iWeaponSkin = 0;
int g_iOffsetName = -1;
int g_iOffsetMyWP = -1;
char g_szEquipWeapon[MAXPLAYERS+1][3][32];

#define SLOT_1 0
#define SLOT_2 1
#define SLOT_3 2
#define SLOT_4 3
#define SLOT_5 4

public void OnPluginStart()
{
    char path[128];
    BuildPath(Path_SM, path, 128, "configs/core.cfg");
    KeyValues kv = new KeyValues("Core");
    
    if(kv.ImportFromFile(path))
        SetFailState("'%s' was not found.", path);

    char val[16];
    kv.GetString("FollowCSGOServerGuidelines", val, 16, "yes");
    if(strcmp(val, "no", false) != 0 && strcmp(val, "false", false) != 0)
        SetFailState("'%s' -> You must be set 'FollowCSGOServerGuidelines' to 'no' or 'false'.", path);
    
    g_iOffsetName = FindSendPropInfo("CBaseAttributableItem", "m_szCustomName");
    if(g_iOffsetName == -1)
        SetFailState("Offset 'CBaseAttributableItem' -> 'm_szCustomName' was not found.");
    
    g_iOffsetMyWP = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    if(g_iOffsetMyWP == -1)
        SetFailState("Offset 'CBasePlayer' -> 'm_hMyWeapons' was not found.");

    Store_RegisterHandler("weaponskin", INVALID_FUNCTION, WeaponSkin_Reset, WeaponSkin_Config, WeaponSkin_Equip, WeaponSkin_Remove, true, false);

    PTaH(PTaH_GiveNamedItemPre, Hook, Event_GiveNamedItemPre);
    PTaH(PTaH_GiveNamedItem,    Hook, Event_GiveNamedItemPost);
}

public void WeaponSkin_Reset()
{
    g_iWeaponSkin = 0;
}

public bool WeaponSkin_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iWeaponSkin);

    KvGetString(kv, "uid"   , g_eWeaponSkin[g_iWeaponSkin][szUnique], 32);
    KvGetString(kv, "weapon", g_eWeaponSkin[g_iWeaponSkin][szWeapon], 32);

    g_eWeaponSkin[g_iWeaponSkin][iSlot]  = KvGetNum(kv, "slot", SLOT_1);
    g_eWeaponSkin[g_iWeaponSkin][iSeed]  = KvGetNum(kv, "seed");
    g_eWeaponSkin[g_iWeaponSkin][iPaint] = KvGetNum(kv, "paint");
    g_eWeaponSkin[g_iWeaponSkin][iWearT] = KvGetNum(kv, "weart", -1);
    g_eWeaponSkin[g_iWeaponSkin][fWearF] = KvGetFloat(kv, "wearf", 0.0416);
    
    g_iWeaponSkin++;
    return true;
}

public int WeaponSkin_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    strcopy(g_szEquipWeapon[client][g_eWeaponSkin[m_iData][iSlot]], 32, g_eWeaponSkin[m_iData][szUnique]);
    CheckClientWeapon(client, m_iData);
    return g_eWeaponSkin[m_iData][iSlot];
}

public int WeaponSkin_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    g_szEquipWeapon[client][g_eWeaponSkin[m_iData][iSlot]][0] = 0;
    return g_eWeaponSkin[m_iData][iSlot];
}

public void OnClientConnected(int client)
{
    g_szEquipWeapon[client][SLOT_1][0] = 0;
    g_szEquipWeapon[client][SLOT_2][0] = 0;
    g_szEquipWeapon[client][SLOT_3][0] = 0;
}

public Action Event_GiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView)
{
    if(IsFakeClient(client))
        return Plugin_Continue;

    int itemid = Store_GetEquippedItem(client, "weaponskin", SLOT_3);
    if(itemid < 0)
        return Plugin_Continue;
    
    int m_iData = Store_GetDataIndex(itemid);

    ignoredCEconItemView = true;
    strcopy(classname, 64, g_eWeaponSkin[m_iData][szWeapon]);

    return Plugin_Changed;
}

public void Event_GiveNamedItemPost(int client, const char[] classname, const CEconItemView item, int entity)
{
    if(IsFakeClient(client) || !IsPlayerAlive(client) || !IsValidEdict(entity))
        return;

    for(int slot = 0; slot < STORE_MAX_SLOTS; ++slot)
    {
        int itemid = Store_GetEquippedItem(client, "weaponskin", slot);
        if(itemid >= 0)
        {
            int m_iData = Store_GetDataIndex(itemid);
            SetWeaponEconmoney(client, m_iData, entity);
        }
    }
}

void SetWeaponEconmoney(int client, int data, int weapon)
{
    //https://www.unknowncheats.me/wiki/Counter_Strike_Global_Offensive:Skin_Changer

    static int IDHigh = 16384;
    SetEntProp(weapon, Prop_Send, "m_iItemIDLow", -1);
    SetEntProp(weapon, Prop_Send, "m_iItemIDHigh", IDHigh++);
    
    if(g_eWeaponSkin[data][iSlot] == SLOT_3)
    {
        EquipPlayerWeapon(client, weapon);
    }

    SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
    SetEntProp(weapon, Prop_Send, "m_nFallbackPaintKit", g_eWeaponSkin[data][iPaint]);
    SetEntProp(weapon, Prop_Send, "m_nFallbackSeed", g_eWeaponSkin[data][iSeed]);
    SetEntProp(weapon, Prop_Send, "m_iEntityQuality", (g_eWeaponSkin[data][iSlot] == SLOT_3) ? 3 : 8);

    SetEntDataString(weapon, g_iOffsetName, "!store", 16);

    switch(g_eWeaponSkin[data][iWearT])
    {
        case 0 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.006999  - 0.001234)) + 0.001234);
        case 1 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.149999  - 0.070000)) + 0.070000);
        case 2 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.369999  - 0.150000)) + 0.150000);
        case 3 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.439999  - 0.370000)) + 0.370000);
        case 4 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.999999  - 0.440000)) + 0.440000);
        default: SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", g_eWeaponSkin[data][fWearF]);
    }

    SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
    SetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner", -1);
}

void CheckClientWeapon(int client, int data)
{
    if(IsPlayerAlive(client))
        return;

    int weapon = GetPlayerWeaponEntity(client, g_eWeaponSkin[data][szWeapon]);
    
    int prevOwner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner");
    if(prevOwner != -1)
        return;
    
    int clip, ammo;
    if(GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType") >= 0)
    {
        clip = GetEntProp(weapon, Prop_Send, "m_iClip1", 4, 0);
        ammo= GetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount");
    }

    if(!RemovePlayerItem(client, weapon))
        LogError("RemovePlayerItem -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data][szWeapon]);
    
    if(!AcceptEntityInput(weapon, "KillHierarchy"))
        LogError("AcceptEntityInput -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data][szWeapon]);

    weapon = GivePlayerItem(client, g_eWeaponSkin[data][szWeapon]);

    if(!IsValidEdict(weapon) || g_eWeaponSkin[data][iSlot] == SLOT_3)
        return;

    DataPack pack = new DataPack();
    pack.WriteCell(EntIndexToEntRef(weapon));
    pack.WriteCell(clip);
    pack.WriteCell(ammo);
    pack.Reset();

    CreateTimer(0.1, Timer_RevertAmmo, pack);
}

public Action Timer_RevertAmmo(Handle timer, DataPack pack)
{
    int iref = pack.ReadCell();
    int clip = pack.ReadCell();
    int ammo = pack.ReadCell();
    delete pack;
    
    int weapon = EntRefToEntIndex(iref);

    if(!IsValidEdict(weapon))
        return Plugin_Stop;

    if(clip != 0)
        SetEntProp(weapon, Prop_Send, "m_iClip1", clip, 4, 0);
    
    if(ammo != 0)
        SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", ammo);
    
    return Plugin_Stop;
}

int GetPlayerWeaponEntity(int client, const char[] weapons)
{
    int weapon = -1;
    char classname[32];

    for(int offset = 0; offset < 128; offset += 4)
        if(IsValidEdict((weapon = GetEntDataEnt2(client, g_iOffsetMyWP+offset))))
            if(GetWeaponClassname(weapon, -1, classname, 32))
                if(strcmp(weapons, classname, false) == 0)
                    return weapon;

    return -1;
}

int GetWeaponClassname(int weapon, int index = -1, char[] classname, int maxLen)
{
    GetEdictClassname(weapon, classname, maxLen);

    if(index == -1)
        index = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");

    switch(index)
    {
        case 60: return strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61: return strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63: return strcopy(classname, maxLen, "weapon_cz75a");
        case 64: return strcopy(classname, maxLen, "weapon_revolver");
    }

    return strlen(classname);
}
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

#define SLOT_1 0
#define SLOT_2 1
#define SLOT_3 2
#define SLOT_4 3
#define SLOT_5 4

public void OnPluginStart()
{
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
    
    //LogMessage("Weapon Skin -> %s -> Paint[%d] Seed[%d] Slot[%d] WearT[%d] WearF[%f]", g_eWeaponSkin[g_iWeaponSkin][szUnique], g_eWeaponSkin[g_iWeaponSkin][iPaint], g_eWeaponSkin[g_iWeaponSkin][iSeed], g_eWeaponSkin[g_iWeaponSkin][iSlot], g_eWeaponSkin[g_iWeaponSkin][iWearT], g_eWeaponSkin[g_iWeaponSkin][fWearF]);

    g_iWeaponSkin++;
    return true;
}

public int WeaponSkin_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(m_iData);
    pack.Reset();
    RequestFrame(CheckClientWeapon, pack);

    return g_eWeaponSkin[m_iData][iSlot];
}

public int WeaponSkin_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    return g_eWeaponSkin[m_iData][iSlot];
}

public Action Event_GiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView)
{
    if(IsFakeClient(client))
        return Plugin_Continue;
    
    if(StrContains(classname, "weapon_") != 0)
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
    
    if(StrContains(classname, "weapon_") != 0)
        return;

    //PrintToChat(client, "Event_GiveNamedItemPost -> %s", classname);

    for(int slot = 1; slot < STORE_MAX_SLOTS; ++slot)
    {
        int itemid = Store_GetEquippedItem(client, "weaponskin", slot);
        if(itemid >= 0)
        {
            int m_iData = Store_GetDataIndex(itemid);
            //PrintToChat(client, "Checking Slot[%d]", slot);
            if(strcmp(classname, g_eWeaponSkin[m_iData][szWeapon], false) == 0)
            {
                //PrintToChat(client, "Replace %s To %s",  classname, g_eWeaponSkin[m_iData][szUnique]);
                SetWeaponEconmoney(client, m_iData, entity);
            }
        }
        else
            //PrintToChat(client, "Slot[%d] -> null", slot);
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

    SetEntProp(weapon, Prop_Send, "m_nFallbackPaintKit", g_eWeaponSkin[data][iPaint]);
    SetEntProp(weapon, Prop_Send, "m_nFallbackSeed", g_eWeaponSkin[data][iSeed]);
    SetEntProp(weapon, Prop_Send, "m_iEntityQuality", (g_eWeaponSkin[data][iSlot] == SLOT_3) ? 3 : 8);

    switch(g_eWeaponSkin[data][iWearT])
    {
        case 0 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.006999  - 0.001234)) + 0.001234);
        case 1 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.149999  - 0.070000)) + 0.070000);
        case 2 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.369999  - 0.150000)) + 0.150000);
        case 3 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.439999  - 0.370000)) + 0.370000);
        case 4 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.999999  - 0.440000)) + 0.440000);
        default: SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", g_eWeaponSkin[data][fWearF]);
    }

    SetEntDataString(weapon, g_iOffsetName, "!store", 16);

    SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
    SetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner", -1);
    
    SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
}

void CheckClientWeapon(DataPack dp)
{
    int client = GetClientOfUserId(dp.ReadCell());
    int data   = dp.ReadCell();
    delete dp;

    if(!IsPlayerAlive(client))
    {
        //PrintToChat(client, "Equipped but Dead");
        return;
    }

    int weapon = GetPlayerWeaponEntity(client, g_eWeaponSkin[data][szWeapon]);
    if(weapon == -1)
    {
        //PrintToChat(client, "Equipped but weapon was not found.");
        return;
    }

    int prevOwner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner");
    if(prevOwner != -1)
    {
        //PrintToChat(client, "PrevOwner is %d", prevOwner);
        return;
    }

    int PAmmo = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
    int SAmmo = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
    int Clip1 = GetEntProp(weapon, Prop_Data, "m_iClip1");
    int Clip2 = GetEntProp(weapon, Prop_Data, "m_iClip2");

    if(!RemovePlayerItem(client, weapon))
        LogError("RemovePlayerItem -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data][szWeapon]);
    
    if(!AcceptEntityInput(weapon, "KillHierarchy"))
        LogError("AcceptEntityInput -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data][szWeapon]);

    if(g_eWeaponSkin[data][iSlot] == SLOT_3)
    {
        //PrintToChat(client, "Give new %s", "weapon_knife");
        weapon = GivePlayerItem(client, "weapon_knife");
        return;
    }
    else
    {
        //PrintToChat(client, "Give new %s", g_eWeaponSkin[data][szWeapon]);
        weapon = GivePlayerItem(client, g_eWeaponSkin[data][szWeapon]);
    }

    if(!IsValidEdict(weapon))
        return;

    DataPack pack = new DataPack();
    pack.WriteCell(EntIndexToEntRef(weapon));
    pack.WriteCell(PAmmo);
    pack.WriteCell(SAmmo);
    pack.WriteCell(Clip1);
    pack.WriteCell(Clip2);
    pack.Reset();

    CreateTimer(0.1, Timer_RevertAmmo, pack);
}

public Action Timer_RevertAmmo(Handle timer, DataPack pack)
{
    int iref = pack.ReadCell();
    int PAmmo = pack.ReadCell();
    int SAmmo = pack.ReadCell();
    int Clip1 = pack.ReadCell();
    int Clip2 = pack.ReadCell();
    delete pack;

    int weapon = EntRefToEntIndex(iref);

    if(!IsValidEdict(weapon))
        return Plugin_Stop;

    if(PAmmo > -1) SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount",     PAmmo);
    if(SAmmo > -1) SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount",   SAmmo);
    if(Clip1 > -1) SetEntProp(weapon, Prop_Data, "m_iClip1",                Clip1);
    if(Clip2 > -1) SetEntProp(weapon, Prop_Data, "m_iClip2",                Clip2);

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
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Weapon Skin"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module weapon skin"
#define PLUGIN_VERSION      "2.4.<commit_count>"
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
#include <clientprefs>

enum struct WeaponSkin
{
    char szUnique[32];
    char szWeapon[32];
    int iSlot;
    int iSeed;
    int iWearT;
    int iPaint;
    float fWearF;
}

static WeaponSkin g_eWeaponSkin[STORE_MAX_ITEMS];
static int g_iWeaponSkin = 0;
static int g_iOffsetName = -1;
static int g_iOffsetMyWP = -1;

static Handle g_hCookieNamed;

#define SLOT_0 "!!!!WE START AT 1!!!!"
#define SLOT_1 1
#define SLOT_2 2
#define SLOT_3 3
#define SLOT_4 4
#define SLOT_5 5

public void OnPluginStart()
{
    char ptah[32];
    if(PTaH_Version(ptah, 32) < 110)
        SetFailState("This plugin requires PTaH 1.1.0.");

    g_iOffsetName = FindSendPropInfo("CBaseAttributableItem", "m_szCustomName");
    if(g_iOffsetName == -1)
        SetFailState("Offset 'CBaseAttributableItem' -> 'm_szCustomName' was not found.");
    
    g_iOffsetMyWP = FindSendPropInfo("CBasePlayer", "m_hMyWeapons");
    if(g_iOffsetMyWP == -1)
        SetFailState("Offset 'CBasePlayer' -> 'm_hMyWeapons' was not found.");

    PTaH(PTaH_GiveNamedItemPre,  Hook, Event_GiveNamedItemPre);
    PTaH(PTaH_GiveNamedItemPost, Hook, Event_GiveNamedItemPost);

    g_hCookieNamed = RegClientCookie("store_ws_name", "", CookieAccess_Protected);
    
    RegConsoleCmd("ws_name", Command_Named);
}

public void Store_OnStoreInit(Handle store_plugin)
{
    Store_RegisterHandler("weaponskin", INVALID_FUNCTION, WeaponSkin_Reset, WeaponSkin_Config, WeaponSkin_Equip, WeaponSkin_Remove, true, false);
}

public Action Command_Named(int client, int args)
{
    if(!client)
        return Plugin_Handled;
    
    if(!(GetUserFlagBits(client) & ADMFLAG_CUSTOM1))
    {
        PrintToChat(client, "[\x04Store\x01]   \x05You do not have permission to use this function.");
        return Plugin_Handled;
    }
    
    if(args != 1)
    {
        PrintToChat(client, "[\x04Store\x01]   \x05Usage: ws_name <name>");
        return Plugin_Handled;
    }
    
    char name[32];
    GetCmdArg(1, name, sizeof(name));
    
    if(strlen(name) < 4)
    {
        PrintToChat(client, "[\x04Store\x01]   strlen(name) must be >= 4");
        return Plugin_Handled;
    }

    SetClientCookie(client, g_hCookieNamed, name);
    PrintToChat(client, "[\x04Store\x01]   Set your skin named \x04%s", name);

    return Plugin_Handled;
}

public void WeaponSkin_Reset()
{
    g_iWeaponSkin = 0;
}

public bool WeaponSkin_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iWeaponSkin);

    KvGetString(kv, "uid"   , g_eWeaponSkin[g_iWeaponSkin].szUnique, sizeof(WeaponSkin::szUnique));
    KvGetString(kv, "weapon", g_eWeaponSkin[g_iWeaponSkin].szWeapon, sizeof(WeaponSkin::szWeapon));

    g_eWeaponSkin[g_iWeaponSkin].iSlot  = KvGetNum(kv, "slot", SLOT_1);
    g_eWeaponSkin[g_iWeaponSkin].iSeed  = KvGetNum(kv, "seed");
    g_eWeaponSkin[g_iWeaponSkin].iPaint = KvGetNum(kv, "paint");
    g_eWeaponSkin[g_iWeaponSkin].iWearT = KvGetNum(kv, "weart", -1);
    g_eWeaponSkin[g_iWeaponSkin].fWearF = KvGetFloat(kv, "wearf", 0.0416);
    
    //LogMessage("Weapon Skin -> %s -> Paint[%d] Seed[%d] Slot[%d] WearT[%d] WearF[%f]", g_eWeaponSkin[g_iWeaponSkin].szUnique, g_eWeaponSkin[g_iWeaponSkin].iPaint, g_eWeaponSkin[g_iWeaponSkin].iSeed, g_eWeaponSkin[g_iWeaponSkin].iSlot, g_eWeaponSkin[g_iWeaponSkin].iWearT, g_eWeaponSkin[g_iWeaponSkin].fWearF);

    g_iWeaponSkin++;
    return true;
}

public int WeaponSkin_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(m_iData);
    pack.WriteCell(0);
    pack.Reset();
    RequestFrame(CheckClientWeapon, pack);

    return g_eWeaponSkin[m_iData].iSlot;
}

public int WeaponSkin_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);

    DataPack pack = new DataPack();
    pack.WriteCell(GetClientUserId(client));
    pack.WriteCell(m_iData);
    pack.WriteCell(1);
    pack.Reset();
    RequestFrame(CheckClientWeapon, pack);

    return g_eWeaponSkin[m_iData].iSlot;
}

public Action Event_GiveNamedItemPre(int client, char classname[64], CEconItemView &item, bool &ignoredCEconItemView, bool &OriginIsNULL, float Origin[3])
{
    if(IsFakeClient(client) || !IsPlayerAlive(client))
        return Plugin_Continue;

    if(!IsWeaponKnife(classname))
        return Plugin_Continue;

    int itemid = Store_GetEquippedItem(client, "weaponskin", SLOT_3);
    if(itemid < 0)
        return Plugin_Continue;

    int m_iData = Store_GetDataIndex(itemid);

    ignoredCEconItemView = true;
    strcopy(classname, sizeof(classname), g_eWeaponSkin[m_iData].szWeapon);

    return Plugin_Changed;
}

public void Event_GiveNamedItemPost(int client, const char[] classname, const CEconItemView item, int entity, bool OriginIsNULL, const float Origin[3])
{
    if(IsFakeClient(client) || !IsPlayerAlive(client) || !IsValidEdict(entity))
        return;
    
    if(StrContains(classname, "weapon_") != 0)
        return;

    for(int slot = 0; slot < STORE_MAX_SLOTS; ++slot)
    {
        int itemid = Store_GetEquippedItem(client, "weaponskin", slot);
        if(itemid >= 0)
        {
            int m_iData = Store_GetDataIndex(itemid);
            if(strcmp(classname, g_eWeaponSkin[m_iData].szWeapon, false) == 0)
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
    
    if(g_eWeaponSkin[data].iSlot == SLOT_3)
    {
        EquipPlayerWeapon(client, weapon);
    }

    SetEntProp(weapon, Prop_Send, "m_nFallbackPaintKit", g_eWeaponSkin[data].iPaint);
    SetEntProp(weapon, Prop_Send, "m_nFallbackSeed", (g_eWeaponSkin[data].iSeed == -1) ? GetRandomInt(0, 1024) : g_eWeaponSkin[data].iSeed);
    SetEntProp(weapon, Prop_Send, "m_iEntityQuality", (g_eWeaponSkin[data].iSlot == SLOT_3) ? 3 : 8);

    switch(g_eWeaponSkin[data].iWearT)
    {
        case 0 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.006999  - 0.001234)) + 0.001234);
        case 1 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.149999  - 0.070000)) + 0.070000);
        case 2 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.369999  - 0.150000)) + 0.150000);
        case 3 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.439999  - 0.370000)) + 0.370000);
        case 4 : SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", (GetURandomFloat() * (0.999999  - 0.440000)) + 0.440000);
        default: SetEntPropFloat(weapon, Prop_Send, "m_flFallbackWear", g_eWeaponSkin[data].fWearF);
    }

    if(GetUserFlagBits(client) & ADMFLAG_CUSTOM1)
    {
        char name[32];
        GetClientCookie(client, g_hCookieNamed, name, sizeof(name));
        if(strlen(name) >= 4)
        {
            SetEntDataString(weapon, g_iOffsetName, name, sizeof(name));
            PrintToChat(client, "[\x04Store\x01]   Set your skin named \x04%s", name);
        }
    }

    SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
    SetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner", -1);
    
    SetEntProp(weapon, Prop_Send, "m_iAccountID", GetSteamAccountID(client));
}

void CheckClientWeapon(DataPack dp)
{
    int client = GetClientOfUserId(dp.ReadCell());
    int data   = dp.ReadCell();
    int unique = dp.ReadCell();
    delete dp;

    if(!IsPlayerAlive(client))
        return;

    int weapon = -1;
    if(g_eWeaponSkin[data].iSlot == SLOT_3)
    {
        weapon = GetPlayerWeaponSlot(client, SLOT_2);
        if(weapon == -1) return;
        char classname[32];
        GetEdictClassname(weapon, classname, sizeof(classname));
        if(strcmp(classname, "weapon_taser") == 0)
        {
            int taser = weapon;
            DataPack pack = new DataPack();
            pack.WriteCell(client);
            pack.WriteCell(weapon);
            pack.Reset();
            RemovePlayerItem(client, taser);
            weapon = GetPlayerWeaponSlot(client, SLOT_2);
            CreateTimer(0.1, Timer_GiveTaser, pack, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else weapon = GetPlayerWeaponEntity(client, g_eWeaponSkin[data].szWeapon);

    if(weapon == -1)
        return;

    int prevOwner = GetEntPropEnt(weapon, Prop_Send, "m_hPrevOwner");
    if(prevOwner != -1)
        return;

    int PAmmo = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
    int SAmmo = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
    int Clip1 = GetEntProp(weapon, Prop_Data, "m_iClip1");
    int Clip2 = GetEntProp(weapon, Prop_Data, "m_iClip2");

    if(!RemovePlayerItem(client, weapon))
        LogError("RemovePlayerItem -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data].szWeapon);

    if(!AcceptEntityInput(weapon, "KillHierarchy"))
        LogError("AcceptEntityInput -> %N -> %d.%s", client, weapon, g_eWeaponSkin[data].szWeapon);

    if(unique && g_eWeaponSkin[data].iSlot == SLOT_3)
    {
        GivePlayerItem(client, "weapon_knife");
        return;
    }

    weapon = GivePlayerItem(client, g_eWeaponSkin[data].szWeapon);
    

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

public Action Timer_GiveTaser(Handle timer, DataPack pack)
{
    int client = pack.ReadCell();
    int weapon = pack.ReadCell();
    delete pack;

    if(IsClientInGame(client) && IsPlayerAlive(client))
        EquipPlayerWeapon(client, weapon);
    else
        AcceptEntityInput(weapon, "Kill");
    
    return Plugin_Stop;
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
            if(GetWeaponClassname(weapon, -1, classname, sizeof(classname)))
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
        case 42 : return strcopy(classname, maxLen, "weapon_knife");
        case 59 : return strcopy(classname, maxLen, "weapon_knife_t");
        case 60 : return strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61 : return strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63 : return strcopy(classname, maxLen, "weapon_cz75a");
        case 64 : return strcopy(classname, maxLen, "weapon_revolver");
        case 500: return strcopy(classname, maxLen, "weapon_bayonet");
        case 506: return strcopy(classname, maxLen, "weapon_knife_gut");
        case 505: return strcopy(classname, maxLen, "weapon_knife_flip");
        case 508: return strcopy(classname, maxLen, "weapon_knife_m9_bayonet");
        case 507: return strcopy(classname, maxLen, "weapon_knife_karambit");
        case 509: return strcopy(classname, maxLen, "weapon_knife_tactical");
        case 515: return strcopy(classname, maxLen, "weapon_knife_butterfly");
        case 512: return strcopy(classname, maxLen, "weapon_knife_falchion");
        case 516: return strcopy(classname, maxLen, "weapon_knife_push");
        case 514: return strcopy(classname, maxLen, "weapon_knife_survival_bowie");
        case 519: return strcopy(classname, maxLen, "weapon_knife_ursus");
        case 520: return strcopy(classname, maxLen, "weapon_knife_jackknife");
        case 522: return strcopy(classname, maxLen, "weapon_knife_stiletto");
        case 523: return strcopy(classname, maxLen, "weapon_knife_windowmaker");
    }

    return strlen(classname);
}

bool IsWeaponKnife(const char[] classname)
{
    if(
        strcmp(classname, "weapon_knife") == 0 ||
        strcmp(classname, "weapon_knife_t") == 0 ||
        strcmp(classname, "weapon_bayonet") == 0 ||
        strcmp(classname, "weapon_knife_gut") == 0 ||
        strcmp(classname, "weapon_knife_flip") == 0 ||
        strcmp(classname, "weapon_knife_m9_bayonet") == 0 ||
        strcmp(classname, "weapon_knife_karambit") == 0 ||
        strcmp(classname, "weapon_knife_tactical") == 0 ||
        strcmp(classname, "weapon_knife_butterfly") == 0 ||
        strcmp(classname, "weapon_knife_falchion") == 0 ||
        strcmp(classname, "weapon_knife_push") == 0 ||
        strcmp(classname, "weapon_knife_survival_bowie") == 0 ||
        strcmp(classname, "weapon_knife_ursus") == 0 ||
        strcmp(classname, "weapon_knife_windowmaker") == 0 ||
        strcmp(classname, "weapon_knife_stiletto") == 0 ||
        strcmp(classname, "weapon_knife_jackknife") == 0
      )
    return true;

    return false;
}

stock bool GetWeaponClassname(int weapon, char[] classname, int maxLen)
{
    if(!GetEdictClassname(weapon, classname, maxLen))
        return false;
    
    if(!HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
        return false;
    
    switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
    {
        case 60: strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61: strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63: strcopy(classname, maxLen, "weapon_cz75a");
        case 64: strcopy(classname, maxLen, "weapon_revolver");
    }
    
    return true;
}
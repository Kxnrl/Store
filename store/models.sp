#define Module_Model

static int g_iRefPVM[MAXPLAYERS+1];
static int g_iOldSequence[MAXPLAYERS+1];
static bool g_bHooked[MAXPLAYERS+1];
static char g_szCurWpn[MAXPLAYERS+1][64];
static float g_fOldCycle[MAXPLAYERS+1];
static StringMap g_smClientWeapon[MAXPLAYERS+1];

enum CustomModel
{
    String:szModelV[PLATFORM_MAX_PATH],
    String:szModelW[PLATFORM_MAX_PATH],
    String:szModelD[PLATFORM_MAX_PATH],
    String:szEntity[32],
    iSlot,
    iCacheIdV,
    iCacheIdW
}

static any g_eCustomModel[STORE_MAX_ITEMS][CustomModel];
static int g_iCustomModels = 0;

void Models_OnPluginStart()
{
    Store_RegisterHandler("vwmodel", Models_OnMapStart, Models_Reset, Models_Config, Models_Equip, Models_Remove, true); 
}

public void Models_OnMapStart() 
{
    for(int i = 0; i < g_iCustomModels; ++i)
    {
        g_eCustomModel[i][iCacheIdV] = PrecacheModel(g_eCustomModel[i][szModelV], true);
        Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelV]);

        if(!StrEqual(g_eCustomModel[i][szModelW], "none", false))
        {
            g_eCustomModel[i][iCacheIdW] = PrecacheModel(g_eCustomModel[i][szModelW], true);
            Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelW]);
            
            if(g_eCustomModel[i][iCacheIdW] == 0)
                g_eCustomModel[i][iCacheIdW] = -1;
        }
        
        if(!StrEqual(g_eCustomModel[i][szModelD], "none", false))
        {
            if(!IsModelPrecached(g_eCustomModel[i][szModelD]))
            {
                PrecacheModel(g_eCustomModel[i][szModelD], true);
                Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelD]);
            }
        }
    }
}

public void Models_Reset() 
{ 
    g_iCustomModels = 0; 
}

public bool Models_Config(KeyValues kv, int itemid) 
{
    Store_SetDataIndex(itemid, g_iCustomModels);
    kv.GetString("model", g_eCustomModel[g_iCustomModels][szModelV], PLATFORM_MAX_PATH);
    kv.GetString("worldmodel", g_eCustomModel[g_iCustomModels][szModelW], PLATFORM_MAX_PATH, "none");
    kv.GetString("dropmodel", g_eCustomModel[g_iCustomModels][szModelD], PLATFORM_MAX_PATH, "none");
    kv.GetString("weapon", g_eCustomModel[g_iCustomModels][szEntity], 32);
    g_eCustomModel[g_iCustomModels][iSlot] = kv.GetNum("slot");
    
    if(FileExists(g_eCustomModel[g_iCustomModels][szModelV], true))
    {
        ++g_iCustomModels;    
        return true;
    }
    return false;
}

public int Models_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);

    if(!Models_AddModels(client, g_eCustomModel[m_iData][szEntity], g_eCustomModel[m_iData][iCacheIdV], g_eCustomModel[m_iData][iCacheIdW], g_eCustomModel[m_iData][szModelD]) && IsClientInGame(client))
        tPrintToChat(client, "\x02 unknown error! please contact to admin!");

    return g_eCustomModel[m_iData][iSlot];
}

public int Models_Remove(int client, int id) 
{
    int m_iData = Store_GetDataIndex(id);

    if(!Models_RemoveModels(client, g_eCustomModel[m_iData][szEntity]) && IsClientInGame(client))
        tPrintToChat(client, "\x02 unknown error! please contact to admin!");

    return g_eCustomModel[m_iData][iSlot];
}

void Models_OnClientPutInServer(int client)
{
    g_iRefPVM[client] = INVALID_ENT_REFERENCE;
    g_bHooked[client] = false;

    g_smClientWeapon[client] = new StringMap();
}

void Models_OnClientDisconnect(int client)
{
    if(g_bHooked[client])
    {
        SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost_Models);
        g_bHooked[client] = false;
    }

    if(g_smClientWeapon[client] != null)
    {
        if(g_smClientWeapon[client].Size > 0)
        {
            SDKUnhook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost_Models); 
            SDKUnhook(client, SDKHook_WeaponSwitch,     Hook_WeaponSwitch_Models); 
            SDKUnhook(client, SDKHook_WeaponEquip,      Hook_WeaponEquip_Models);
            SDKUnhook(client, SDKHook_WeaponDropPost,   Hook_WeaponDropPost_Models);
        }

        delete g_smClientWeapon[client];
        g_smClientWeapon[client] = null;
    }
}

void Models_OnPlayerDeath(int client)
{
    if(!g_bHooked[client])
        return;

    SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost_Models);
    g_bHooked[client] = false;
}

public void Hook_WeaponSwitchPost_Models(int client, int weapon) 
{ 
    if(!IsValidEdict(weapon))
        return;
    
    char classname[32];
    if(!GetWeaponClassname(weapon, classname, 32))
        return;

    if(StrContains(classname, "item", false) == 0)
        return;
    
    char m_szGlobalName[256];
    GetEntPropString(weapon, Prop_Data, "m_iGlobalname", m_szGlobalName, 256);
    if(StrContains(m_szGlobalName, "custom", false) != 0)
        return;
    
    ReplaceString(m_szGlobalName, 256, "custom", "");

    char m_szData[2][192];
    ExplodeString(m_szGlobalName, ";", m_szData, 2, 192);

    int model_index = StringToInt(m_szData[0]);
    
    int m_iPVM = EntRefToEntIndex(g_iRefPVM[client]);
    if(m_iPVM == INVALID_ENT_REFERENCE)
    {
        g_iRefPVM[client] = GetViewModelReference(client, -1); 
        m_iPVM = EntRefToEntIndex(g_iRefPVM[client]);
        if(m_iPVM == INVALID_ENT_REFERENCE) 
            return;
    }

    SetEntProp(weapon, Prop_Send, "m_nModelIndex", 0); 
    SetEntProp(m_iPVM, Prop_Send, "m_nModelIndex", model_index);

    strcopy(g_szCurWpn[client], 64, classname);
    g_bHooked[client] = SDKHookEx(client, SDKHook_PostThinkPost, Hook_PostThinkPost_Models);
}

public Action Hook_WeaponSwitch_Models(int client, int weapon) 
{ 
    if(g_bHooked[client])
    {
        SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost_Models);
        g_bHooked[client] = false;
    }
    return Plugin_Continue;
}

public Action Hook_WeaponEquip_Models(int client, int weapon)
{
    if(!IsValidEdict(weapon))
        return Plugin_Continue;

    if(GetEntProp(weapon, Prop_Send, "m_hPrevOwner") > 0)
        return Plugin_Continue;

    char classname[32];
    if(!GetWeaponClassname(weapon, classname, 32))
        return Plugin_Continue;

    char m_szGlobalName[256];
    GetEntPropString(weapon, Prop_Data, "m_iGlobalname", m_szGlobalName, 256);
    if(StrContains(m_szGlobalName, "custom", false) == 0)
        return Plugin_Continue;

    char classname_world[32], classname_drop[32];
    FormatEx(classname_world, 32, "%s_world", classname);
    FormatEx(classname_drop,  32, "%s_drop",  classname);

    int model_world;
    if(g_smClientWeapon[client].GetValue(classname_world, model_world) && model_world != -1)
    {
        int iWorldModel = GetEntPropEnt(weapon, Prop_Send, "m_hWeaponWorldModel"); 
        if(IsValidEdict(iWorldModel))
            SetEntProp(iWorldModel, Prop_Send, "m_nModelIndex", model_world);
    }

    char model_drop[192];
    if(GetTrieString(g_smClientWeapon[client], classname_drop, model_drop, 192) && !StrEqual(model_drop, "none"))
    {
        if(!IsModelPrecached(model_drop))
            LogError("Hook_WeaponEquip_Models -> not precached -> %s", model_drop);
    }

    int model_index;
    if(!g_smClientWeapon[client].GetValue(classname, model_index) || model_index == -1)
        return Plugin_Continue;

    FormatEx(m_szGlobalName, 256, "custom%i;%s", model_index, model_drop);
    DispatchKeyValue(weapon, "globalname", m_szGlobalName);
    
    return Plugin_Continue;
}

public void Hook_WeaponDropPost_Models(int client, int weapon)
{
    if(!IsValidEdict(weapon))
        return;

    RequestFrame(SetWorldModel, EntIndexToEntRef(weapon));
}

public void Hook_PostThinkPost_Models(int client)
{
    int model = EntRefToEntIndex(g_iRefPVM[client]);

    if(model == INVALID_ENT_REFERENCE)
    {
        SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost_Models);
        g_bHooked[client] = false;
        return;
    }

    int m_iSequence = GetEntProp(model, Prop_Send, "m_nSequence");
    float m_fCycle = GetEntPropFloat(model, Prop_Data, "m_flCycle");

    if(m_fCycle < g_fOldCycle[client] && m_iSequence == g_iOldSequence[client])
    {
        if(StrEqual(g_szCurWpn[client], "weapon_knife"))
        {
            switch(m_iSequence)
            {
                case  3: SetEntProp(model, Prop_Send, "m_nSequence", 4);
                case  4: SetEntProp(model, Prop_Send, "m_nSequence", 3);
                case  5: SetEntProp(model, Prop_Send, "m_nSequence", 6);
                case  6: SetEntProp(model, Prop_Send, "m_nSequence", 5);
                case  7: SetEntProp(model, Prop_Send, "m_nSequence", 8);
                case  8: SetEntProp(model, Prop_Send, "m_nSequence", 7);
                case  9: SetEntProp(model, Prop_Send, "m_nSequence", 10);
                case 10: SetEntProp(model, Prop_Send, "m_nSequence", 11); 
                case 11: SetEntProp(model, Prop_Send, "m_nSequence", 10);
            }
        }
        else if(StrEqual(g_szCurWpn[client], "weapon_ak47"))
        {
            switch(m_iSequence)
            {
                case 3: SetEntProp(model, Prop_Send, "m_nSequence", 2);
                case 2: SetEntProp(model, Prop_Send, "m_nSequence", 1);
                case 1: SetEntProp(model, Prop_Send, "m_nSequence", 3);            
            }
        }
        else if(StrEqual(g_szCurWpn[client], "weapon_mp7"))
        {
            if(m_iSequence == 3)
                SetEntProp(model, Prop_Send, "m_nSequence", -1);
        }
        else if(StrEqual(g_szCurWpn[client], "weapon_awp"))
        {
            if(m_iSequence == 1)
                SetEntProp(model, Prop_Send, "m_nSequence", -1);    
        }
        else if(StrEqual(g_szCurWpn[client], "weapon_deagle"))
        {
            switch(m_iSequence)
            {
                case 3: SetEntProp(model, Prop_Send, "m_nSequence", 2);
                case 2: SetEntProp(model, Prop_Send, "m_nSequence", 1);
                case 1: SetEntProp(model, Prop_Send, "m_nSequence", 3);    
            }
        }
    }

    g_iOldSequence[client] = m_iSequence;
    g_fOldCycle[client] = m_fCycle;
}

public Action Hook_WeaponCanUse(int client, int weapon)
{
    return Plugin_Handled;
}

void SetWorldModel(int iRef)
{
    int weapon = EntRefToEntIndex(iRef);
    
    if(!IsValidEdict(weapon))
        return;

    char m_szGlobalName[256];
    GetEntPropString(weapon, Prop_Data, "m_iGlobalname", m_szGlobalName, 256);

    if(StrContains(m_szGlobalName, "custom", false) != 0)
        return;

    ReplaceString(m_szGlobalName, 64, "custom", "");

    char m_szData[2][192];
    ExplodeString(m_szGlobalName, ";", m_szData, 2, 192);

    if(StrEqual(m_szData[1], "none"))
        return;

    SetEntityModel(weapon, m_szData[1]);
}

bool Models_AddModels(int client, const char[] classname, int model_view, int model_world, const char[] model_drop)
{
    if(!IsClientInGame(client) || g_smClientWeapon[client] == INVALID_HANDLE)
        return false;
    
    if(GetTrieSize(g_smClientWeapon[client]) == 0)
    {
        SDKHook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost_Models); 
        SDKHook(client, SDKHook_WeaponSwitch,     Hook_WeaponSwitch_Models); 
        SDKHook(client, SDKHook_WeaponEquip,      Hook_WeaponEquip_Models);
        SDKHook(client, SDKHook_WeaponDropPost,   Hook_WeaponDropPost_Models);
    }

    char world_name[32], drop_name[32];
    FormatEx(world_name, 32, "%s_world", classname);
    FormatEx(drop_name,  32, "%s_drop",  classname);

    SetTrieValue(g_smClientWeapon[client],  classname,  model_view);
    SetTrieValue(g_smClientWeapon[client],  world_name, model_world);
    SetTrieString(g_smClientWeapon[client], drop_name,  model_drop);

    RefreshWeapon(client, classname);
    
    return true;
}

bool Models_RemoveModels(int client, const char[] classname)
{
    if(!IsClientInGame(client) || g_smClientWeapon[client] == null)
        return false;

    char world_name[32], drop_name[32];
    FormatEx(world_name, 32, "%s_world", classname);
    FormatEx(drop_name,  32, "%s_drop",  classname);

    g_smClientWeapon[client].Remove(classname);
    g_smClientWeapon[client].Remove(world_name);
    g_smClientWeapon[client].Remove(drop_name);

    if(GetTrieSize(g_smClientWeapon[client]) == 0)
    {
        SDKUnhook(client, SDKHook_WeaponSwitchPost, Hook_WeaponSwitchPost_Models); 
        SDKUnhook(client, SDKHook_WeaponSwitch,     Hook_WeaponSwitch_Models); 
        SDKUnhook(client, SDKHook_WeaponEquip,      Hook_WeaponEquip_Models);
        SDKUnhook(client, SDKHook_WeaponDropPost,   Hook_WeaponDropPost_Models);
    }

    RefreshWeapon(client, classname);

    return true;
}

void RefreshWeapon(int client, const char[] classname)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    int weapon = GetClientWeaponIndexByClassname(client, classname);
    
    if(weapon == -1)
        return;

    int m_iPrimaryAmmoCount = GetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount");
    int m_iSecondaryAmmoCount = GetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount");
    int m_iClip1 = GetEntProp(weapon, Prop_Data, "m_iClip1");
    int m_iClip2 = GetEntProp(weapon, Prop_Data, "m_iClip2");

    if(GetEntPropEnt(weapon, Prop_Send, "m_hOwner") != client)
        SetEntPropEnt(weapon, Prop_Send, "m_hOwner", client);
    AcceptEntityInput(weapon, "Kill");

    DataPack pack = new DataPack();
    pack.WriteString(classname);
    pack.WriteCell(client);
    pack.WriteCell(m_iPrimaryAmmoCount);
    pack.WriteCell(m_iSecondaryAmmoCount);
    pack.WriteCell(m_iClip1);
    pack.WriteCell(m_iClip2);
    pack.Reset();
    CreateTimer(0.2, Timer_GiveBackWeapon, pack);

    if(GetPlayerWeaponSlot(client, 0) == -1 && GetPlayerWeaponSlot(client, 1) == -1 && GetPlayerWeaponSlot(client, 2) == -1 && GetPlayerWeaponSlot(client, 3) == -1 && GetPlayerWeaponSlot(client, 4) == -1)
        CreateTimer(0.25, Timer_RemoveDummyWeapon, GivePlayerItem(client, "weapon_decoy"));

    SDKHook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
}

public Action Timer_GiveBackWeapon(Handle timer, DataPack pack)
{
    char classname[32];
    pack.ReadString(classname, 32);
    int client = pack.ReadCell();
    int m_iPrimaryAmmoCount = pack.ReadCell();
    int m_iSecondaryAmmoCount = pack.ReadCell();
    int m_iClip1 = pack.ReadCell();
    int m_iClip2 = pack.ReadCell();

    delete pack;

    if(!IsClientInGame(client))
        return Plugin_Stop;
    
    SDKUnhook(client, SDKHook_WeaponCanUse, Hook_WeaponCanUse);
    
    if(!IsPlayerAlive(client))
        return Plugin_Stop;

    int weapon = GivePlayerItem(client, classname);

    if(StrEqual(classname, "weapon_knife"))
        EquipPlayerWeapon(client, weapon);

    if(m_iPrimaryAmmoCount > -1)   SetEntProp(weapon, Prop_Data, "m_iPrimaryAmmoCount",   m_iPrimaryAmmoCount);
    if(m_iSecondaryAmmoCount > -1) SetEntProp(weapon, Prop_Data, "m_iSecondaryAmmoCount", m_iSecondaryAmmoCount);
    if(m_iClip1 > -1) SetEntProp(weapon, Prop_Data, "m_iClip1", m_iClip1);
    if(m_iClip2 > -1) SetEntProp(weapon, Prop_Data, "m_iClip2", m_iClip2);
    
    return Plugin_Stop;
}

public Action Timer_RemoveDummyWeapon(Handle timer, int weapon)
{
    if(IsValidEdict(weapon))
        AcceptEntityInput(weapon, "Kill");  
    return Plugin_Stop;
}

int GetViewModelReference(int client, int entity) 
{ 
    int owner;

    while ((entity = FindEntityByClassname2(entity, "predicted_viewmodel")) != -1) 
    { 
        owner = GetEntPropEnt(entity, Prop_Send, "m_hOwner"); 

        if(owner == client) 
            return EntIndexToEntRef(entity); 
    }

    return INVALID_ENT_REFERENCE; 
}

int FindEntityByClassname2(int start, const char[] classname) 
{ 
    while(start > MaxClients && !IsValidEntity(start))
        start--; 

    return FindEntityByClassname(start, classname); 
}

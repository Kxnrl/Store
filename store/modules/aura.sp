#define Module_Aura

int g_iAuras = 0; 
int g_iClientAura[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
char g_szAuraName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szAuraClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Aura_OnMapStart()
{
    if(PreDownload("particles/FX.pcf"))
    {
        PrecacheGeneric("particles/FX.pcf", true);
        PrecacheEffect("ParticleEffect");

        for(int index = 0; index < g_iAuras; ++index)
            PrecacheParticleEffect(g_szAuraName[index]);
    }
}

bool PreDownload(const char[] path)
{
    return FileExists(path) && AddFileToDownloadsTable(path);
}

public void Aura_OnClientDisconnect(int client)
{
    Store_RemoveClientAura(client);
    g_szAuraClient[client] = "";
}

public int Aura_Config(Handle &kv, int itemid) 
{ 
    Store_SetDataIndex(itemid, g_iAuras); 
    KvGetString(kv, "effect", g_szAuraName[g_iAuras], PLATFORM_MAX_PATH);

    ++g_iAuras;

    return true; 
}

public void Aura_Reset() 
{ 
    g_iAuras = 0; 
}

public int Aura_Equip(int client, int id) 
{
    g_szAuraClient[client] = g_szAuraName[Store_GetDataIndex(id)];

    if(IsPlayerAlive(client))
        Store_SetClientAura(client);

    return 0; 
}

public int Aura_Remove(int client) 
{
    Store_RemoveClientAura(client);
    g_szAuraClient[client] = "";

    return 0; 
}

void Store_RemoveClientAura(int client)
{
    if(g_iClientAura[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientAura[client]);
        if(IsValidEdict(entity))
        {
#if defined AllowHide
            SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Aura);
#endif
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientAura[client] = INVALID_ENT_REFERENCE;
    }
}

void Store_SetClientAura(int client)
{
    Store_RemoveClientAura(client);

    if(!(strcmp(g_szAuraClient[client], "", false) == 0))
    {
        float clientOrigin[3];
        GetClientAbsOrigin(client, clientOrigin);

        int iEnt = CreateEntityByName("info_particle_system");
        
        DispatchKeyValue(iEnt , "start_active", "1");
        DispatchKeyValue(iEnt, "effect_name", g_szAuraClient[client]);
        DispatchSpawn(iEnt);
        
        TeleportEntity(iEnt, clientOrigin, NULL_VECTOR, NULL_VECTOR);

        SetVariantString("!activator");
        AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);
        
        ActivateEntity(iEnt);

        g_iClientAura[client] = EntIndexToEntRef(iEnt);

        SetEdictFlags(iEnt, GetEdictFlags(iEnt)&(~FL_EDICT_ALWAYS)); //to allow settransmit hooks
		SDKHookEx(iEnt, SDKHook_SetTransmit, Hook_SetTransmit_Aura);
    }
}

public Action Hook_SetTransmit_Aura(int ent, int client)
{
    if(GetEdictFlags(ent) & FL_EDICT_ALWAYS)
        SetEdictFlags(ent, (GetEdictFlags(ent) ^ FL_EDICT_ALWAYS));

#if defined AllowHide
    if(g_bHideMode[client])
        return Plugin_Handled;
#endif

    return Plugin_Continue;
}

//https://forums.alliedmods.net/showpost.php?p=2471747&postcount=4
void PrecacheParticleEffect(const char[] effect)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");
	
    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}

void PrecacheEffect(const char[] sEffectName)
{
    static int table = INVALID_STRING_TABLE;

    if(table == INVALID_STRING_TABLE)
        table = FindStringTable("EffectDispatch");

    bool save = LockStringTables(false);
    AddToStringTable(table, sEffectName);
    LockStringTables(save);
}
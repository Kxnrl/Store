#define Module_Aura

int g_iAuras = 0; 
int g_iClientAura[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
char g_szAuraName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szAuraClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Aura_OnMapStart()
{
    PreDownload("particles/FX.pcf");
    PrecacheGeneric("particles/FX.pcf", true);
}

void PreDownload(const char[] path)
{
    if(FileExists(path))
    {
        AddFileToDownloadsTable(path);
    }
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
    
    if(!FileExists("particles/FX.pcf"))
        return false;
    
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
            AcceptEntityInput(entity, "Kill");
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
        
        ActivateEntity(iEnt);

        SetVariantString("!activator");
        AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);
        
        g_iClientAura[client] = EntIndexToEntRef(iEnt);
    }
}
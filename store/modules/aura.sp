#define Module_Aura

#define MAX_AURA 128

static int g_iAuras = 0; 
static int g_iClientAura[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
static char g_szAuraName[MAX_AURA][PLATFORM_MAX_PATH];
static char g_szAuraFPcf[MAX_AURA][PLATFORM_MAX_PATH];
static char g_szAuraClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Aura_OnMapStart()
{
    if(g_iAuras <= 0)
        return;

    PrecacheEffect("ParticleEffect");

    for(int index = 0; index < g_iAuras; ++index)
    {
        PrecacheGeneric(g_szAuraFPcf[index], true);
        PrecacheParticleEffect(g_szAuraName[index]);
        AddFileToDownloadsTable(g_szAuraFPcf[index]);
    }
}

void Aura_OnClientDisconnect(int client)
{
    Store_RemoveClientAura(client);
    g_szAuraClient[client][0] = '\0';
}

public bool Aura_Config(KeyValues kv, int itemid) 
{ 
    if(g_iAuras >= MAX_AURA)
        return false;

    Store_SetDataIndex(itemid, g_iAuras); 
    kv.GetString("effect", g_szAuraName[g_iAuras], PLATFORM_MAX_PATH);
    kv.GetString("model",  g_szAuraFPcf[g_iAuras], PLATFORM_MAX_PATH);

    if(!FileExists(g_szAuraFPcf[g_iAuras], true))
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
    g_szAuraClient[client][0] = '\0';

    return 0; 
}

void Store_RemoveClientAura(int client)
{
    if(g_iClientAura[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientAura[client]);
        if(IsValidEdict(entity))
        {
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientAura[client] = INVALID_ENT_REFERENCE;
    }
}

void Store_SetClientAura(int client)
{
    Store_RemoveClientAura(client);

    if(strlen(g_szAuraClient[client]) > 0)
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

        Call_OnParticlesCreated(client, iEnt);
    }
}
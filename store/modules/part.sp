#define Module_Part

#define MAX_PART 128

static int g_iParts = 0; 
static int g_iClientPart[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
static char g_szPartName[MAX_PART][PLATFORM_MAX_PATH];
static char g_szPartFPcf[MAX_PART][PLATFORM_MAX_PATH];
static char g_szPartClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

void Part_OnClientDisconnect(int client)
{
    Store_RemoveClientPart(client);
    g_szPartClient[client][0] = '\0';
}

void Part_Reset() 
{ 
    g_iParts = 0;
}

bool Part_Config(KeyValues kv, int itemid) 
{ 
    Store_SetDataIndex(itemid, g_iParts); 
    kv.GetString("effect", g_szPartName[g_iParts], PLATFORM_MAX_PATH);
    kv.GetString("model",  g_szPartFPcf[g_iParts], PLATFORM_MAX_PATH);
    
    if(!FileExists(g_szPartFPcf[g_iParts], true))
    {
        #if defined LOG_NOT_FOUND
        // missing model
        char auth[32], name[32];
        kv.GetString("auth", auth, 32);
        kv.GetString("name", name, 32);
        if (strcmp(auth, "STEAM_ID_INVALID") != 0)
        {
            LogError("Missing aura <%s> -> [%s]", name, g_szPartFPcf[g_iParts]);
        }
        else
        {
            LogMessage("Skipped aura <%s> -> [%s]", name, g_szPartFPcf[g_iParts]);
        }
        #endif
        return false;
    }
    
    ++g_iParts;
    return true;
}

int Part_Equip(int client, int id)
{
    g_szPartClient[client] = g_szPartName[Store_GetDataIndex(id)];

    if(IsPlayerAlive(client))
        Store_SetClientPart(client);

    return 0;
}

int Part_Remove(int client, int id) 
{
    Store_RemoveClientPart(client);
    g_szPartClient[client][0] = '\0';

    return 0; 
}

void Part_OnMapStart()
{
    if(g_iParts <= 0)
        return;

    PrecacheEffect("ParticleEffect");

    for(int index = 0; index < g_iParts; ++index)
    {
        PrecacheGeneric(g_szPartFPcf[index], true);
        PrecacheParticleEffect(g_szPartName[index]);
        AddFileToDownloadsTable(g_szPartFPcf[index]);
    }
}

void Store_RemoveClientPart(int client)
{
    if(g_iClientPart[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientPart[client]);
        if(IsValidEdict(entity))
        {
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientPart[client] = INVALID_ENT_REFERENCE;
    }
}

void Store_SetClientPart(int client)
{
    Store_RemoveClientPart(client);

#if defined GM_ZE
    if(g_iClientTeam[client] == 2)
        return;
#endif

    if(!(strcmp(g_szPartClient[client], "", false) == 0))
    {
        float clientOrigin[3], clientAngles[3];
        GetClientAbsOrigin(client, clientOrigin);
        GetClientAbsAngles(client, clientAngles);

        clientOrigin[2] += 0.5;

        int iEnt = CreateEntityByName("info_particle_system");

        if(!IsValidEdict(iEnt))
        {
            LogError("Failed to create info_particle_system -> %N -> %s", client, g_szPartClient[client]);
            return;
        }

        DispatchKeyValue(iEnt, "targetname", "store_item_particle");

        DispatchKeyValue(iEnt, "start_active", "1");
        DispatchKeyValue(iEnt, "effect_name", g_szPartClient[client]);
        DispatchSpawn(iEnt);

        TeleportEntity(iEnt, clientOrigin, clientAngles, NULL_VECTOR);
 
        SetVariantString("!activator");
        AcceptEntityInput(iEnt, "SetParent", client, iEnt);

        ActivateEntity(iEnt);
        
        g_iClientPart[client] = EntIndexToEntRef(iEnt);

        Call_OnParticlesCreated(client, iEnt);
    }
}
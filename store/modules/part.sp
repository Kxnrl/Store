#define Module_Part

#define MAX_PART 128

int g_iParts = 0; 
int g_iClientPart[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
char g_szPartName[MAX_PART][PLATFORM_MAX_PATH];
char g_szPartFPcf[MAX_PART][PLATFORM_MAX_PATH];
char g_szPartClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

void Part_OnClientDisconnect(int client)
{
    Store_RemoveClientPart(client);
    g_szPartClient[client] = "";
}

public void Part_Reset() 
{ 
    g_iParts = 0;
}

public bool Part_Config(Handle kv, int itemid) 
{ 
    Store_SetDataIndex(itemid, g_iParts); 
    KvGetString(kv, "effect", g_szPartName[g_iParts], PLATFORM_MAX_PATH);
    KvGetString(kv, "model",  g_szPartFPcf[g_iParts], PLATFORM_MAX_PATH);
    ++g_iParts;
    return true;
}

public int Part_Equip(int client, int id)
{
    g_szPartClient[client] = g_szPartName[Store_GetDataIndex(id)];

    if(IsPlayerAlive(client))
        Store_SetClientPart(client);

    return 0;
}

public int Part_Remove(int client) 
{
    Store_RemoveClientPart(client);
    g_szPartClient[client] = "";

    return 0; 
}

public void Part_OnMapStart()
{
    ArrayList path = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    ArrayList fail = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
    for(int index = 0; index < g_iAuras; ++index)
    {
        if(fail.FindString(g_szPartFPcf[index]) != -1)
            continue;

        if(path.FindString(g_szPartFPcf[index]) != -1)
        {
            PrecacheParticleEffect(g_szPartName[index]);
            continue;
        }

        if(PreDownload(g_szPartFPcf[index]))
        {
            PrecacheGeneric(g_szPartFPcf[index], true);
            PrecacheEffect("ParticleEffect");
            PrecacheParticleEffect(g_szPartName[index]);
            path.PushString(g_szPartFPcf[index]);
        }
        else
            fail.PushString(g_szPartFPcf[index]);
    }
    delete path;
    delete fail;
}

void Store_RemoveClientPart(int client)
{
    if(g_iClientPart[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientPart[client]);
        if(IsValidEdict(entity))
        {
#if defined AllowHide
            SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Aura);
#endif
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientPart[client] = INVALID_ENT_REFERENCE;
    }
}

void Store_SetClientPart(int client)
{
    Store_RemoveClientPart(client);

    if(!(strcmp(g_szPartClient[client], "", false) == 0))
    {
        float clientOrigin[3];
        GetClientAbsOrigin(client, clientOrigin);

        int iEnt = CreateEntityByName("info_particle_system");
        
        DispatchKeyValue(iEnt, "start_active", "1");
        DispatchKeyValue(iEnt, "effect_name", g_szPartClient[client]);
        DispatchSpawn(iEnt);
        
        TeleportEntity(iEnt, clientOrigin, NULL_VECTOR,NULL_VECTOR);
        
        ActivateEntity(iEnt);
        
        SetVariantString("!activator");
        AcceptEntityInput(iEnt, "SetParent", client, iEnt, 0);
        
        //https://github.com/neko-pm/auramenu/blob/master/scripting/dominoaura-menu.sp
        SetEdictFlags(iEnt, GetEdictFlags(iEnt)&(~FL_EDICT_ALWAYS)); //to allow settransmit hooks
        SDKHookEx(iEnt, SDKHook_SetTransmit, Hook_SetTransmit_Part);

        g_iClientPart[client] = EntIndexToEntRef(iEnt);
    }
}

public Action Hook_SetTransmit_Part(int ent, int client)
{
    //if(GetEdictFlags(ent) & FL_EDICT_ALWAYS)
    //    SetEdictFlags(ent, (GetEdictFlags(ent) ^ FL_EDICT_ALWAYS));

#if defined AllowHide
    if(g_bHideMode[client])
        return Plugin_Handled;
#endif

    return Plugin_Continue;
}
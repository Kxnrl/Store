#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Pets"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module pets"
#define PLUGIN_VERSION      "2.3.<commit_count>"
#define PLUGIN_URL          "https://www.kxnrl.com"

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

#include <sdktools>
#include <sdkhooks>
#include <store>
#include <store_stock>

enum Pet
{
    String:model[192],
    String:idle[32],
    String:run[32],
    String:death[32],
    Float:fPosition[3],
    Float:fAngles[3],
    iSlot
}

static any g_ePets[STORE_MAX_ITEMS][Pet];
static int g_iPets = 0;
static int g_iPetRef[MAXPLAYERS+1][STORE_MAX_SLOTS];
static int g_iLastAnimation[MAXPLAYERS+1][STORE_MAX_SLOTS];

public void OnPluginStart()
{
    HookEvent("player_spawn", Pets_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Pets_PlayerDeath, EventHookMode_Post);
    HookEvent("player_team", Pets_PlayerTeam, EventHookMode_Post);
}

public void Store_OnStoreInit(Handle store_plugin)
{
    Store_RegisterHandler("pet", Pets_OnMapStart, Pets_Reset, Pets_Config, Pets_Equip, Pets_Remove, true);
}

public void Pets_OnMapStart()
{
    for(int i = 0; i < g_iPets; ++i)
    {
        PrecacheModel(g_ePets[i][model], true);
        Downloader_AddFileToDownloadsTable(g_ePets[i][model]);
    }
}

public void Pets_Reset()
{
    g_iPets = 0;
}

public bool Pets_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iPets);
    
    float m_fTemp[3];
    KvGetString(kv, "model", g_ePets[g_iPets][model], 256);
    KvGetString(kv, "idle", g_ePets[g_iPets][idle], 32);
    KvGetString(kv, "run", g_ePets[g_iPets][run], 32);
    KvGetString(kv, "death", g_ePets[g_iPets][death], 32);
    KvGetVector(kv, "position", m_fTemp);
    g_ePets[g_iPets][fPosition] = m_fTemp;
    KvGetVector(kv, "angles", m_fTemp);
    g_ePets[g_iPets][fAngles] = m_fTemp;
    g_ePets[g_iPets][iSlot] = KvGetNum(kv, "slot");
    
    if(FileExists(g_ePets[g_iPets][model], true))
    {
        ++g_iPets;
        return true;
    }

    return false;
}

public int Pets_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    
    ResetPet(client, g_ePets[m_iData][iSlot]);

    if(IsPlayerAlive(client))
        CreatePet(client, id, g_ePets[m_iData][iSlot]);

    return g_ePets[m_iData][iSlot];
}

public int Pets_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    ResetPet(client, g_ePets[m_iData][iSlot]);
    return g_ePets[m_iData][iSlot];
}

void Store_SetClientPet(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        ResetPet(client, i);
        CreatePet(client, -1, i);
    }
}

void Store_ClientDeathPet(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        DeathPet(client, i);
}

void Store_RemovePet(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        ResetPet(client, i);
}

public void OnClientConnected(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        g_iPetRef[client][i] = INVALID_ENT_REFERENCE;
}

public void OnClientDisconnect(int client)
{
    Store_RemovePet(client);
}

public void Pets_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;
    
    Store_SetClientPet(client);
}

public void Pets_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!client || !IsClientInGame(client))
        return;

    Store_ClientDeathPet(client);
}

public void Pets_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!client || !IsClientInGame(client))
        return;

    Store_RemovePet(client);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client) || tickcount % 5 != 0)
        return Plugin_Continue;
    
    float CurVec[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVec);
    float CurDist = GetVectorLength(CurVec);
    
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        AdjustPet(client, i, CurDist);

    return Plugin_Continue;
}

void AdjustPet(int client, int slot, const float fDist)
{
    if(g_iPetRef[client][slot] == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_iPetRef[client][slot]);

    if(!IsValidEdict(entity))
        return;
    
    if(g_iLastAnimation[client][slot] != 1 && fDist > 0.0)
    {
        SetVariantString(g_ePets[Store_GetDataIndex(Store_GetEquippedItem(client, "pet", slot))][run]);
        AcceptEntityInput(EntRefToEntIndex(g_iPetRef[client][slot]), "SetAnimation");
        g_iLastAnimation[client][slot] = 1;
    }
    else if(g_iLastAnimation[client][slot] != 2 && fDist == 0.0)
    {
        SetVariantString(g_ePets[Store_GetDataIndex(Store_GetEquippedItem(client, "pet", slot))][idle]);
        AcceptEntityInput(EntRefToEntIndex(g_iPetRef[client][slot]), "SetAnimation");
        g_iLastAnimation[client][slot] = 2;
    }
}

void CreatePet(int client, int itemid = -1, int slot = 0)
{
    if(g_iPetRef[client][slot] != INVALID_ENT_REFERENCE)
    {
        LogError("Why you create entity with equipped slot?");
        return;
    }

    int m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "pet", slot) : itemid);

    if(m_iEquipped < 0)
        return;
    
    int m_iData = Store_GetDataIndex(m_iEquipped);

    int entity = CreateEntityByName("prop_dynamic_override");
    if(entity == -1)
        return;

    float m_flPosition[3];
    float m_flAngles[3];
    float m_flClientOrigin[3];
    float m_flClientAngles[3];
    GetClientAbsOrigin(client, m_flClientOrigin);
    GetClientAbsAngles(client, m_flClientAngles);

    m_flPosition[0] = g_ePets[m_iData][fPosition][0];
    m_flPosition[1] = g_ePets[m_iData][fPosition][1];
    m_flPosition[2] = g_ePets[m_iData][fPosition][2];
    m_flAngles[0] = g_ePets[m_iData][fAngles][0];
    m_flAngles[1] = g_ePets[m_iData][fAngles][1];
    m_flAngles[2] = g_ePets[m_iData][fAngles][2];

    float m_fForward[3];
    float m_fRight[3];
    float m_fUp[3];
    GetAngleVectors(m_flClientAngles, m_fForward, m_fRight, m_fUp);

    m_flClientOrigin[0] += m_fRight[0]*m_flPosition[0]+m_fForward[0]*m_flPosition[1]+m_fUp[0]*m_flPosition[2];
    m_flClientOrigin[1] += m_fRight[1]*m_flPosition[0]+m_fForward[1]*m_flPosition[1]+m_fUp[1]*m_flPosition[2];
    m_flClientOrigin[2] += m_fRight[2]*m_flPosition[0]+m_fForward[2]*m_flPosition[1]+m_fUp[2]*m_flPosition[2];
    m_flAngles[1] += m_flClientAngles[1];

    DispatchKeyValue(entity, "model", g_ePets[m_iData][model]);
    DispatchKeyValue(entity, "spawnflags", "256");
    DispatchKeyValue(entity, "solid", "0");
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

    DispatchSpawn(entity);    
    AcceptEntityInput(entity, "TurnOn", entity, entity, 0);
    
    TeleportEntity(entity, m_flClientOrigin, m_flAngles, NULL_VECTOR); 
    
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client, entity, 0);

    SetVariantString("letthehungergamesbegin");
    AcceptEntityInput(entity, "SetParentAttachmentMaintainOffset", entity, entity, 0);

    g_iPetRef[client][slot] = EntIndexToEntRef(entity);
    g_iLastAnimation[client][slot] = -1;
    
    SDKHook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Pet);
}

void ResetPet(int client, int slot)
{
    if(g_iPetRef[client][slot] == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_iPetRef[client][slot]);

    g_iPetRef[client][slot] = INVALID_ENT_REFERENCE;

    if(entity == -1 || !IsValidEdict(client))
        return;
    
    SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Pet);

    AcceptEntityInput(entity, "Kill");
}

void DeathPet(int client, int slot)
{
    if(g_iPetRef[client][slot] == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_iPetRef[client][slot]);

    if(!IsValidEdict(entity))
        return;
    
    int m_iData = Store_GetDataIndex(Store_GetEquippedItem(client, "pet", slot));
    
    if(g_ePets[m_iData][death][0] == '\0')
    {
        ResetPet(client, slot);
        return;
    }
    
    SetVariantString(g_ePets[m_iData][death]);
    AcceptEntityInput(EntRefToEntIndex(g_iPetRef[client][slot]), "SetAnimation");
    g_iLastAnimation[client][slot] = 3;
    HookSingleEntityOutput(entity, "OnAnimationDone", Hook_OnAnimationDone, true);
}

public Action Hook_SetTransmit_Pet(int ent, int client)
{
    return Store_IsPlayerHide(client) ? Plugin_Handled : Plugin_Continue;
}

public void Hook_OnAnimationDone(const char[] output, int caller, int activator, float delay)
{
    if(!IsValidEdict(caller))
        return;

    int owner = GetEntPropEnt(caller, Prop_Send, "m_hOwnerEntity");

    if(1 <= owner <= MaxClients && IsClientInGame(owner))
    {
        int iRef = EntIndexToEntRef(caller);
        for(int slot = 0; slot < STORE_MAX_SLOTS; ++slot)
            if(g_iPetRef[owner][slot] == iRef)
                g_iPetRef[owner][slot] = INVALID_ENT_REFERENCE;
    }

    SDKUnhook(caller, SDKHook_SetTransmit, Hook_SetTransmit_Pet);
    AcceptEntityInput(caller, "Kill");
}

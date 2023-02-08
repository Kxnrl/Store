#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <store>
#include <store_stock>

#undef REQUIRE_PLUGIN
#include <fys.pupd>
#define REQUIRE_PLUGIN

public Plugin myinfo = 
{
    name        = "Store - Pets",
    author      = STORE_AUTHOR,
    description = "store module pets",
    version     = STORE_VERSION,
    url         = STORE_URL
};

enum struct Pet
{
    char model[192];
    char idle[32];
    char idle2[32];
    char run[32];
    char spawn[32];
    char death[32];
    float fPosition[3];
    float fAngles[3];
    float fScale;
    int iSlot;
    int iTeam;
}

enum struct PetInfo_t
{
    int m_iEntRef;
    int m_iDataIndex;

    int m_iLastAnimation;
    int m_iNextIdleTimes;
    int m_iLastSpawnTime;

    void Reset()
    {
        this.m_iEntRef = INVALID_ENT_REFERENCE;
        this.m_iDataIndex = -1;
    }
}

static int g_iPets = 0;
static int g_iOwner[2048];

static Handle g_hDelay[MAXPLAYERS+1];

static Pet g_ePets[STORE_MAX_ITEMS];
static PetInfo_t g_sPetRef[MAXPLAYERS+1][STORE_MAX_SLOTS];

public void OnPluginStart()
{
    HookEvent("player_spawn", Pets_PlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", Pets_PlayerDeath, EventHookMode_Post);
    HookEvent("player_team",  Pets_PlayerTeam,  EventHookMode_Post);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    MarkNativeAsOptional("Pupd_CheckPlugin");
    return APLRes_Success;
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/Modules/");
}

public void OnEntityDestroyed(int entity)
{
    if (MaxClients < entity < 2048)
        g_iOwner[entity] = -1;
}

public void Store_OnStoreInit(Handle store_plugin)
{
    Store_RegisterHandler("pet", Pets_OnMapStart, Pets_Reset, Pets_Config, Pets_Equip, Pets_Remove, true);
}

public void Pets_OnMapStart()
{
    for(int i = 0; i < g_iPets; ++i)
    {
        PrecacheModel(g_ePets[i].model, false);
        AddFileToDownloadsTable(g_ePets[i].model);
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
    KvGetString(kv, "model", g_ePets[g_iPets].model, sizeof(Pet::model));
    KvGetString(kv, "idle", g_ePets[g_iPets].idle, sizeof(Pet::idle));
    KvGetString(kv, "idle2", g_ePets[g_iPets].idle2, sizeof(Pet::idle2));
    KvGetString(kv, "run", g_ePets[g_iPets].run, sizeof(Pet::run));
    KvGetString(kv, "spawn", g_ePets[g_iPets].spawn, sizeof(Pet::spawn));
    KvGetString(kv, "death", g_ePets[g_iPets].death, sizeof(Pet::death));
    KvGetVector(kv, "position", m_fTemp);
    g_ePets[g_iPets].fPosition = m_fTemp;
    KvGetVector(kv, "angles", m_fTemp);
    g_ePets[g_iPets].fAngles = m_fTemp;
    g_ePets[g_iPets].iSlot = KvGetNum(kv, "slot");
    g_ePets[g_iPets].iTeam = KvGetNum(kv, "team");
    g_ePets[g_iPets].fScale = KvGetFloat(kv, "scale", 1.0);

    if(FileExists(g_ePets[g_iPets].model, true))
    {
        ++g_iPets;
        return true;
    }

    return false;
}

public int Pets_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    
    ResetPet(client, g_ePets[m_iData].iSlot);

    if(IsPlayerAlive(client))
        CreatePet(client, id, g_ePets[m_iData].iSlot);

    return g_ePets[m_iData].iSlot;
}

public int Pets_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    ResetPet(client, g_ePets[m_iData].iSlot);
    return g_ePets[m_iData].iSlot;
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
        g_sPetRef[client][i].Reset();
}

public void OnClientDisconnect(int client)
{
    delete g_hDelay[client];

    Store_RemovePet(client);
}

public void Pets_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    // fix first join
    if (GetEventInt(event, "teamnum") == 0)
        return;

    //TODO performance problem
    // I don't know why player_spwan called twice...

    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (g_hDelay[client] != null)
        delete g_hDelay[client];

    g_hDelay[client] = CreateTimer(UTIL_GetRandomInt(1, 10) * 0.1, Timer_DelaySpawn, client);
}

Action Timer_DelaySpawn(Handle timer, int client)
{
    g_hDelay[client] = null;

    if (IsPlayerAlive(client))
    {
        Store_SetClientPet(client);
    }
    return Plugin_Stop;
}

public void Pets_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    delete g_hDelay[client];
    Store_ClientDeathPet(client);
}

public void Pets_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!client || !IsClientInGame(client))
        return;

    if (GetEventInt(event, "team") <= 1)
    {
        // spec only
        Store_RemovePet(client);
    }
}

public void OnPlayerRunCmdPost(int client, int buttons, int impulse, const float vel[3], const float angles[3], int weapon, int subtype, int cmdnum, int tickcount, int seed, const int mouse[2])
{
    if(tickcount % 8 != 0 || !IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    float CurVec[3];
    GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", CurVec);
    float CurDist = GetVectorLength(CurVec);

    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        AdjustPet(client, i, CurDist);
}

void AdjustPet(int client, int slot, const float fDist)
{
    if(g_sPetRef[client][slot].m_iEntRef == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_sPetRef[client][slot].m_iEntRef);

    if(!IsValidEdict(entity))
        return;

    int time = GetTime();
    if (time < g_sPetRef[client][slot].m_iLastSpawnTime)
        return;

    int m_iData = g_sPetRef[client][slot].m_iDataIndex;
    if (m_iData < 0)
        return;

    if(g_sPetRef[client][slot].m_iLastAnimation != 1 && fDist > 0.0 && g_ePets[m_iData].run[0])
    {
        SetVariantString(g_ePets[m_iData].run);
        AcceptEntityInput(entity, "SetAnimation");
        g_sPetRef[client][slot].m_iLastAnimation = 1;
    }
    else if(g_sPetRef[client][slot].m_iLastAnimation != 2 && fDist == 0.0 && g_ePets[m_iData].idle[0])
    {
        if (g_sPetRef[client][slot].m_iNextIdleTimes < time && g_ePets[m_iData].idle2[0])
        {
            g_sPetRef[client][slot].m_iLastSpawnTime = time + 2;
            g_sPetRef[client][slot].m_iNextIdleTimes = time + UTIL_GetRandomInt(12, 36);
            SetVariantString(g_ePets[m_iData].idle2);
        }
        else
        {
            SetVariantString(g_ePets[m_iData].idle);
        }
        AcceptEntityInput(entity, "SetAnimation");
        g_sPetRef[client][slot].m_iLastAnimation = 2;
    }
}

void CreatePet(int client, int itemid = -1, int slot = 0)
{
    if(g_sPetRef[client][slot].m_iEntRef != INVALID_ENT_REFERENCE)
    {
        LogError("Why you create entity with equipped slot?");
        return;
    }

    int m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "pet", slot) : itemid);

    if(m_iEquipped < 0)
        return;
    
    int m_iData = Store_GetDataIndex(m_iEquipped);

    if (!Store_IsGlobalTeam() && g_ePets[m_iData].iTeam > 0 && GetClientTeam(client) != g_ePets[m_iData].iTeam)
        return;

    int entity = CreateEntityByName("prop_dynamic_override");
    if(entity == -1)
        return;

    float m_flPosition[3];
    float m_flAngles[3];
    float m_flClientOrigin[3];
    float m_flClientAngles[3];
    GetClientAbsOrigin(client, m_flClientOrigin);
    GetClientAbsAngles(client, m_flClientAngles);

    m_flPosition[0] = g_ePets[m_iData].fPosition[0];
    m_flPosition[1] = g_ePets[m_iData].fPosition[1];
    m_flPosition[2] = g_ePets[m_iData].fPosition[2];
    m_flAngles[0] = g_ePets[m_iData].fAngles[0];
    m_flAngles[1] = g_ePets[m_iData].fAngles[1];
    m_flAngles[2] = g_ePets[m_iData].fAngles[2];

    float m_fForward[3];
    float m_fRight[3];
    float m_fUp[3];
    GetAngleVectors(m_flClientAngles, m_fForward, m_fRight, m_fUp);

    m_flClientOrigin[0] += m_fRight[0]*m_flPosition[0]+m_fForward[0]*m_flPosition[1]+m_fUp[0]*m_flPosition[2];
    m_flClientOrigin[1] += m_fRight[1]*m_flPosition[0]+m_fForward[1]*m_flPosition[1]+m_fUp[1]*m_flPosition[2];
    m_flClientOrigin[2] += m_fRight[2]*m_flPosition[0]+m_fForward[2]*m_flPosition[1]+m_fUp[2]*m_flPosition[2];
    m_flAngles[1] += m_flClientAngles[1];

    DispatchKeyValue(entity, "targetname", "store_item_pet");
    DispatchKeyValue(entity, "model", g_ePets[m_iData].model);
    DispatchKeyValue(entity, "spawnflags", "256");
    DispatchKeyValue(entity, "solid", "0");
    SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);

    // scale
    SetEntPropFloat(entity, Prop_Send, "m_flModelScale", g_ePets[m_iData].fScale); 

    DispatchSpawn(entity);    
    AcceptEntityInput(entity, "TurnOn", entity, entity, 0);
    
    TeleportEntity(entity, m_flClientOrigin, m_flAngles, NULL_VECTOR); 
    
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", client, entity, 0);

    g_sPetRef[client][slot].m_iDataIndex = m_iData;
    g_sPetRef[client][slot].m_iEntRef = EntIndexToEntRef(entity);
    g_sPetRef[client][slot].m_iLastAnimation = -1;
    g_sPetRef[client][slot].m_iLastSpawnTime = GetTime() + 2;

    g_iOwner[entity] = client;

    if (g_ePets[m_iData].spawn[0])
    {
        SetVariantString(g_ePets[m_iData].spawn);
        AcceptEntityInput(entity, "SetAnimation");
    }

    Call_OnPetsCreated(client, entity, slot);
}

void ResetPet(int client, int slot)
{
    if(g_sPetRef[client][slot].m_iEntRef == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_sPetRef[client][slot].m_iEntRef);

    g_sPetRef[client][slot].Reset();

    if(entity == -1 || !IsValidEdict(client))
        return;

    AcceptEntityInput(entity, "Kill");

    g_iOwner[entity] = -1;
}

void DeathPet(int client, int slot)
{
    if(g_sPetRef[client][slot].m_iEntRef == INVALID_ENT_REFERENCE)
        return;

    int entity = EntRefToEntIndex(g_sPetRef[client][slot].m_iEntRef);

    if(!IsValidEdict(entity))
        return;
    
    int m_iData = g_sPetRef[client][slot].m_iDataIndex;
    if (m_iData < 0)
        return;
    
    if(g_ePets[m_iData].death[0] == '\0')
    {
        ResetPet(client, slot);
        return;
    }
    
    SetVariantString(g_ePets[m_iData].death);
    AcceptEntityInput(entity, "SetAnimation");
    g_sPetRef[client][slot].m_iLastAnimation = 3;
    HookSingleEntityOutput(entity, "OnAnimationDone", Hook_OnAnimationDone, true);

    // Fix some pets deadlock
    SetVariantString("OnUser4 !self:Kill::3.0:1");
    if (!AcceptEntityInput(entity, "AddOutput") || !AcceptEntityInput(entity, "FireUser4"))
        ResetPet(client, slot);
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
            if(g_sPetRef[owner][slot].m_iEntRef == iRef)
                g_sPetRef[owner][slot].Reset();
    }

    AcceptEntityInput(caller, "Kill");
}

stock void Call_OnPetsCreated(int client, int entity, int slot)
{
    static Handle gf = null;
    if (gf == null)
    {
        // create
        gf = CreateGlobalForward("Store_OnPetsCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_PushCell(slot);
    Call_Finish();
}
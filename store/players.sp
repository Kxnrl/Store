// MAIN_FILE ../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Player

static bool        bSpawning[MAXPLAYERS + 1];
static DynamicHook pSetModel;

void Players_OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
    HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);

    InitDHooks();

#if defined Module_Skin
    Skin_OnPluginStart();
#endif

#if defined Module_Hats
    Store_RegisterHandler("hat", Hats_OnMapStart, Hats_Reset, Hats_Config, Hats_Equip, Hats_Remove, true);
#endif

#if defined Module_Neon
    //  neon id -> color
    //  modify in dev1.92
    Store_RegisterHandler("neon", Neon_OnMapStart, Neon_Reset, Neon_Config, Neon_Equip, Neon_Remove, true);
#endif

#if defined Module_Aura
    Store_RegisterHandler("aura", Aura_OnMapStart, Aura_Reset, Aura_Config, Aura_Equip, Aura_Remove, true);
#endif

#if defined Module_Part
    Store_RegisterHandler("particle", Part_OnMapStart, Part_Reset, Part_Config, Part_Equip, Part_Remove, true);
#endif

#if defined Module_Trail
    Store_RegisterHandler("trail", Trails_OnMapStart, Trails_Reset, Trails_Config, Trails_Equip, Trails_Remove, true);
#endif
}

void InitDHooks()
{
    // Gamedata.
    GameData config = new GameData("sdktools.games");
    if (config == null)
    {
        LogError("Could not load sdktools.games gamedata");
        return;
    }

    int offset = config.GetOffset("SetEntityModel");
    if (offset == -1)
    {
        LogError("Failed to find SetEntityModel offset");
        return;
    }

    delete config;

    // DHooks.
    pSetModel = new DynamicHook(offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity);
    if (pSetModel == null)
    {
        LogError("Failed to DHook \"SetEntityModel\".");
        return;
    }

    pSetModel.AddParam(HookParamType_CharPtr);
}

void Players_OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_Spawn, OnClientSpawning);
    SDKHook(client, SDKHook_SpawnPost, OnClientSpawned);

#if defined Module_Skin
    Skin_OnClientPutInServer(client, pSetModel);
#endif
}

void Players_OnClientDisconnect(int client)
{
#if defined Module_Aura
    Aura_OnClientDisconnect(client);
#endif

#if defined Module_Neon
    Neon_OnClientDisconnect(client);
#endif

#if defined Module_Part
    Part_OnClientDisconnect(client);
#endif

#if defined Module_Skin
    Skin_OnClientDisconnect(client);
#endif

#if defined Module_Trail
    Trails_OnClientDisconnect(client);
#endif
}

static Action OnClientSpawning(int client)
{
    bSpawning[client] = true;

    return Plugin_Continue;
}

static void OnClientSpawned(int client)
{
    bSpawning[client] = false;

    // preventing client connected spawning
    if (GetClientTeam(client) <= TEAM_OB)
        return;

#if defined Module_Skin
    // now support default skin for FakeClient
    Skin_OnPlayerSpawn(client);
#endif

    if (IsFakeClient(client))
        return;

    // particles should be delay.
    CreateTimer(0.5 + (client / 8) * 0.1, Timer_DelaySpawn, GetClientSerial(client), TIMER_FLAG_NO_MAPCHANGE);
}

static Action Timer_DelaySpawn(Handle timer, int serial)
{
    int client = GetClientFromSerial(serial);

    if (!client || !IsPlayerAlive(client))
        return Plugin_Stop;

#if defined Module_Trail
    Trails_SetClientTrail(client);
#endif

#if defined Module_Hats
    Hats_SetClientHat(client);
#endif

#if defined Module_Aura
    Aura_SetClientAura(client);
#endif

#if defined Module_Neon
    Neon_SetClientNeon(client);
#endif

#if defined Module_Part
    Part_SetClientPart(client);
#endif

    return Plugin_Stop;
}

static Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));

    if (IsFakeClient(client))
        return Plugin_Continue;

#if defined Module_Skin
    RequestFrame(Skin_BroadcastDeathSound, client);
    RequestFrame(Skin_FirstPersonDeathCamera, client);
#endif

    DeathReset(client);

    return Plugin_Continue;
}

public void ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
    DeathReset(client);

#if defined Module_Skin
    Skin_ResetPlayerSkin(client);
#endif
}

public void ZE_OnPlayerInfected(int client, int attacker, bool motherZombie, bool teleportOverride, bool teleport)
{
    DeathReset(client);

#if defined Module_Skin
    Skin_ResetPlayerSkin(client);
#endif
}

void DeathReset(int client)
{
#pragma unused client

#if defined Module_Aura
    Aura_RemoveClientAura(client);
#endif

#if defined Module_Neon
    Neon_RemoveClientNeon(client);
#endif

#if defined Module_Part
    Part_RemoveClientPart(client);
#endif

    for (int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
#if defined Module_Hats
        Hats_RemoveClientHats(client, i);
#endif

#if defined Module_Trail
        Trails_RemoveClientTrail(client, i);
#endif
    }
}

static Action Event_PlayerTeam(Event event, const char[] name, bool dontBroadcast)
{
    int client  = GetClientOfUserId(event.GetInt("userid"));
    int newteam = event.GetInt("team");
    int oldteam = event.GetInt("oldteam");

    if (oldteam > TEAM_OB && newteam <= TEAM_OB)
    {
#if defined Module_Aura
        Aura_RemoveClientAura(client);
#endif

#if defined Module_Neon
        Neon_RemoveClientNeon(client);
#endif

#if defined Module_Part
        Part_RemoveClientPart(client);
#endif

#if defined Module_Trail
        for (int i = 0; i < STORE_MAX_SLOTS; ++i)
            Trails_RemoveClientTrail(client, i);
#endif

#if defined Module_Hats
        for (int i = 0; i < STORE_MAX_SLOTS; ++i)
            Hats_RemoveClientHats(client, i);
#endif
    }

#if defined TeamArms
    RequestFrame(OnClientTeamPost, client);
#endif

    return Plugin_Continue;
}

#if defined TeamArms

void OnClientTeamPost(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client) || GetClientTeam(client) <= TEAM_OB)
        return;

    Skin_SetClientSkin(client);
}

#endif

stock void Call_OnParticlesCreated(int client, int entity)
{
    static GlobalForward gf = null;
    if (gf == null)
    {
        // create
        gf = new GlobalForward("Store_OnParticlesCreated", ET_Ignore, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_Finish();
}

bool IsPlayerSpawing(int client)
{
    return bSpawning[client];
}
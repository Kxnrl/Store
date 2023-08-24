// MAIN_FILE ../../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Skin

abstract_struct PlayerSkin
{
    char szModel[PLATFORM_MAX_PATH];
    char szArms[PLATFORM_MAX_PATH];
    char szSound[PLATFORM_MAX_PATH];
    int  iLevel;
    int  iTeam;
    int  nBody;
}

static PlayerSkin g_ePlayerSkins[STORE_MAX_ITEMS];

static bool   g_bSoundHooked;
static int    g_iPlayerSkins = 0;
static bool   g_bSpawnModelHook;
static int    g_iSkinLevel[MAXPLAYERS + 1];
static int    g_iPreviewTimes[MAXPLAYERS + 1];
static int    g_iPreviewModel[MAXPLAYERS + 1] = { INVALID_ENT_REFERENCE, ... };
static int    g_iCameraRef[MAXPLAYERS + 1]    = { INVALID_ENT_REFERENCE, ... };
static char   g_szDeathVoice[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static char   g_szSkinModel[MAXPLAYERS + 1][PLATFORM_MAX_PATH];
static bool   g_bShouldFireEvent[MAXPLAYERS + 1];
static ConVar spec_freeze_time;
static ConVar mp_round_restart_delay;
static ConVar sv_disablefreezecam;
static ConVar spec_replay_enable;
static ConVar store_firstperson_death_camera;

static Handle g_tKillPreview[MAXPLAYERS + 1];
static Handle g_tResetCamera[MAXPLAYERS + 1];

static GlobalForward g_hOnPlayerSkinDefault  = null;
static GlobalForward g_hOnPlayerSetModel     = null;
static GlobalForward g_hOnPlayerSetModelPost = null;
static GlobalForward g_hOnFPDeathCamera      = null;
static GlobalForward g_hOnPlayerDeathVoice   = null;

#define SKIN_FLAGS_SKIN 1 << 1
#define SKIN_FLAGS_ARMS 1 << 2

void Skin_InitConVar()
{
    store_firstperson_death_camera = CreateConVar("store_firstperson_death_camera", "1", "Camera for firstperson death view.", _, true, 0.0, true, 1.0);
}

void Skin_OnPluginStart()
{
    g_hOnPlayerSkinDefault  = new GlobalForward("Store_OnPlayerSkinDefault", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell, Param_CellByRef);
    g_hOnFPDeathCamera      = new GlobalForward("Store_OnFPDeathCamera", ET_Hook, Param_Cell);
    g_hOnPlayerSetModel     = new GlobalForward("Store_OnSetPlayerSkin", ET_Event, Param_Cell, Param_String, Param_String, Param_CellByRef);
    g_hOnPlayerSetModelPost = new GlobalForward("Store_OnSetPlayerSkinPost", ET_Ignore, Param_Cell, Param_String, Param_String, Param_Cell);
    g_hOnPlayerDeathVoice   = new GlobalForward("Store_OnPlayerDeathVoice", ET_Event, Param_Cell, Param_String);

    Store_RegisterHandler("playerskin", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);

    RegAdminCmd("sm_arms", Command_Arms, ADMFLAG_ROOT, "Fixed Player Arms");

    spec_freeze_time       = FindConVar("spec_freeze_time");
    sv_disablefreezecam    = FindConVar("sv_disablefreezecam");
    mp_round_restart_delay = FindConVar("mp_round_restart_delay");
    spec_replay_enable     = FindConVar("spec_replay_enable");

    spec_freeze_time.SetFloat(-1.0, true, true);
    sv_disablefreezecam.SetBool(true, true, true);
    mp_round_restart_delay.SetFloat(8.0, true, true);
    spec_replay_enable.SetBool(false, true, true);

    spec_freeze_time.AddChangeHook(OnOtherConVarChanged);
    sv_disablefreezecam.AddChangeHook(OnOtherConVarChanged);
    mp_round_restart_delay.AddChangeHook(OnOtherConVarChanged);
    spec_replay_enable.AddChangeHook(OnOtherConVarChanged);

    // DEATH CAMERA CCVAR
    store_firstperson_death_camera.SetBool(true, true, true);
    store_firstperson_death_camera.AddChangeHook(OnCameraConVarChanged);
}

static void OnCameraConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (StringToInt(newValue) == 0)
    {
        spec_freeze_time.RestoreDefault(true, true);
        sv_disablefreezecam.RestoreDefault(true, true);
        mp_round_restart_delay.RestoreDefault(true, true);
        spec_replay_enable.RestoreDefault(true, true);
    }
    else
    {
        spec_freeze_time.SetFloat(-1.0, true, true);
        sv_disablefreezecam.SetBool(true, true, true);
        mp_round_restart_delay.SetFloat(8.0, true, true);
        spec_replay_enable.SetBool(false, true, true);
    }
}

static void OnOtherConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (store_firstperson_death_camera.BoolValue)
    {
        if (convar == spec_freeze_time)
            spec_freeze_time.SetFloat(-1.0, true, true);

        if (convar == sv_disablefreezecam)
            sv_disablefreezecam.SetBool(true, true, true);

        if (convar == mp_round_restart_delay)
            mp_round_restart_delay.SetFloat(8.0, true, true);

        if (convar == spec_replay_enable)
            spec_replay_enable.SetBool(false, true, true);
    }
    else
    {
        if (convar == spec_freeze_time)
            spec_freeze_time.RestoreDefault(true, true);

        if (convar == sv_disablefreezecam)
            sv_disablefreezecam.RestoreDefault(true, true);

        if (convar == mp_round_restart_delay)
            mp_round_restart_delay.RestoreDefault(true, true);

        if (convar == spec_replay_enable)
            spec_replay_enable.RestoreDefault(true, true);
    }
}

void Skin_OnClientPutInServer(int client, DynamicHook pHook)
{
    if (pHook == null)
        return;

    pHook.HookEntity(Hook_Pre, client, Hook_OnSetModel);
    pHook.HookEntity(Hook_Post, client, Hook_OnSetModelPost);
}

void Skin_OnClientDisconnect(int client)
{
    if (g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);

    if (g_tResetCamera[client] != null)
        TriggerTimer(g_tResetCamera[client], false);

    // fallback
    g_bSpawnModelHook = false;
}

static MRESReturn Hook_OnSetModel(int client, DHookParam hParams)
{
    if (g_bSpawnModelHook)
        return MRES_Ignored;

    if (IsPlayerSpawing(client))
    {
        // due to connected spawning should be ignore
        int team = GetClientTeam(client);
        if (team < TEAM_OB)
        {
            // LogStackTrace("Failed to spawning setmodel: %N", client);
            return MRES_Ignored;
        }

#if defined GM_ZE
        // if we are in zombie mode, fallback to default model
        if (team == TEAM_ZM)
        {
            return MRES_Ignored;
        }
#endif

        g_bShouldFireEvent[client] = false;

        g_bSpawnModelHook = true;
        Skin_ResetPlayerSkin(client);
        bool supercede    = Skin_SetClientSkin(client);
        g_bSpawnModelHook = false;

        return supercede ? MRES_Supercede : MRES_Ignored;
    }

    return MRES_Ignored;
}

static MRESReturn Hook_OnSetModelPost(int client, DHookParam hParams)
{
    if (g_bSpawnModelHook)
        return MRES_Ignored;

    char model[PLATFORM_MAX_PATH];
    // supercede!!!
    // hParams.GetString(1, model, sizeof(model));
    GetClientModel(client, model, sizeof(model));
    if (strcmp(model, g_szSkinModel[client]) != 0)
        Skin_ResetPlayerSkin(client);

    return MRES_Ignored;
}

static Action Command_Arms(int client, int args)
{
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
        return Plugin_Handled;
#endif

    Skin_ResetPlayerSkin(client);
    Skin_SetClientSkin(client);

    return Plugin_Handled;
}

static bool PlayerSkins_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iPlayerSkins);

    kv.GetString("model", g_ePlayerSkins[g_iPlayerSkins].szModel, PLATFORM_MAX_PATH);
    kv.GetString("arms", g_ePlayerSkins[g_iPlayerSkins].szArms, PLATFORM_MAX_PATH);
    kv.GetString("sound", g_ePlayerSkins[g_iPlayerSkins].szSound, PLATFORM_MAX_PATH);

    g_ePlayerSkins[g_iPlayerSkins].iLevel = kv.GetNum("lvls", 0);
    g_ePlayerSkins[g_iPlayerSkins].nBody  = kv.GetNum("skin", 0);

#if defined Global_Skin
    g_ePlayerSkins[g_iPlayerSkins].iTeam = 4;
#else
    g_ePlayerSkins[g_iPlayerSkins].iTeam = kv.GetNum("team");
#endif

    if (!FileExists(g_ePlayerSkins[g_iPlayerSkins].szModel, true))
    {
#if defined LOG_NOT_FOUND
        // missing model
        char auth[32], name[32];
        kv.GetString("auth", auth, 32);
        kv.GetString("name", name, 32);
        if (strcmp(auth, "STEAM_ID_INVALID") != 0)
        {
            LogError("Missing skin <%s> -> [%s]", name, g_ePlayerSkins[g_iPlayerSkins].szModel);
        }
        else
        {
            LogMessage("Skipped skin <%s> -> [%s]", name, g_ePlayerSkins[g_iPlayerSkins].szModel);
        }
#endif
        return false;
    }

    if (g_ePlayerSkins[g_iPlayerSkins].szArms[0] && !FileExists(g_ePlayerSkins[g_iPlayerSkins].szArms, true))
    {
        LogError("Missing 'Arms' files for '%s'::'%s'.", g_ePlayerSkins[g_iPlayerSkins].szModel, g_ePlayerSkins[g_iPlayerSkins].szArms);
    }

    g_iPlayerSkins++;
    return true;
}

static void PlayerSkins_OnMapStart()
{
    int  deathsounds = 0;
    char szPath[PLATFORM_MAX_PATH], szPathStar[PLATFORM_MAX_PATH];
    for (int i = 0; i < g_iPlayerSkins; ++i)
    {
        PrecacheModel(g_ePlayerSkins[i].szModel, false);
        AddFileToDownloadsTable(g_ePlayerSkins[i].szModel);

        // prevent double call
        if (g_ePlayerSkins[i].szArms[0] != 0 && strcmp(g_ePlayerSkins[i].szArms, g_ePlayerSkins[i].szModel, false) != 0)
        {
            PrecacheModel(g_ePlayerSkins[i].szArms, false);
            AddFileToDownloadsTable(g_ePlayerSkins[i].szArms);
        }

        if (g_ePlayerSkins[i].szSound[0] != 0)
        {
            FormatEx(STRING(szPath), "sound/%s", g_ePlayerSkins[i].szSound);
            if (FileExists(szPath, true))
            {
                FormatEx(STRING(szPathStar), "*%s", g_ePlayerSkins[i].szSound);
                AddToStringTable(FindStringTable("soundprecache"), szPathStar);
                AddFileToDownloadsTable(szPath);
                deathsounds++;
            }
        }
    }

    PrecacheModel("models/blackout.mdl", false);

    if (deathsounds > 0 && !g_bSoundHooked)
    {
        AddNormalSoundHook(Hook_NormalSound);
        g_bSoundHooked = true;
    }
}

void PlayerSkins_OnMapEnd()
{
    if (g_bSoundHooked)
    {
        g_bSoundHooked = false;
        RemoveNormalSoundHook(Hook_NormalSound);
    }
}

static void PlayerSkins_Reset()
{
    g_iPlayerSkins = 0;
}

static int PlayerSkins_Equip(int client, int id)
{
    if (IsClientInGame(client) && IsPlayerAlive(client))
        tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

#if defined Global_Skin
    return 2;
#else
    return g_ePlayerSkins[Store_GetDataIndex(id)].iTeam - 2;
#endif
}

static int PlayerSkins_Remove(int client, int id)
{
    if (IsClientInGame(client))
        tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

#if defined Global_Skin
    return 2;
#else
    return g_ePlayerSkins[Store_GetDataIndex(id)].iTeam - 2;
#endif
}

bool Skin_SetClientSkin(int client)
{
    int m_iEquipped = GetEquippedSkin(client);

    return m_iEquipped >= 0 ? SetClientInventorySkin(client, Store_GetDataIndex(m_iEquipped)) : SetClientDefaultSkin(client);
}

static bool SetClientInventorySkin(int client, int index)
{
#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
    {
        strcopy(g_szSkinModel[client], sizeof(g_szSkinModel[]), "#zombie");
        return false;
    }
#endif

    char skin_t[128], arms_t[128];
    strcopy(STRING(skin_t), g_ePlayerSkins[index].szModel);
    strcopy(STRING(arms_t), g_ePlayerSkins[index].szArms);
    int body_t = g_ePlayerSkins[index].nBody;

    Action res = CallPreSetModel(client, skin_t, arms_t, body_t);
    if (res >= Plugin_Handled)
        return false;
    else if (res == Plugin_Changed)
    {
        // verify data index;
        index = FindDataIndexByModel(skin_t, body_t);
        if (index == -1)
            return false;
    }

    if (g_ePlayerSkins[index].szSound[0] != 0)
        FormatEx(g_szDeathVoice[client], sizeof(g_szDeathVoice[]), "*%s", g_ePlayerSkins[index].szSound);

    // basic player skin
    SetEntityModel(client, skin_t);

    // check merged model ? skin? body?
    SetEntProp(client, Prop_Send, "m_nBody", body_t > 0 ? body_t : 0);

    strcopy(g_szSkinModel[client], sizeof(g_szSkinModel[]), skin_t);

    if (arms_t[0] && strcmp(arms_t, "null") != 0 && CallAllowSetPlayerSkinArms(client, STRING(arms_t)))
    {
        SetClientArms(client, arms_t);
    }

    g_iSkinLevel[client] = g_ePlayerSkins[index].iLevel;

    Call_StartForward(g_hOnPlayerSetModelPost);
    Call_PushCell(client);
    Call_PushString(skin_t);
    Call_PushString(arms_t);
    Call_PushCell(body_t);
    Call_Finish();

    return true;
}

static Action Hook_NormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    // not death sound
    if (channel != SNDCHAN_VOICE || sample[0] != '~')
        return Plugin_Continue;

    // not from local player
    if (!IsValidClient(client))
        return Plugin_Continue;

#if defined GM_ZE
    // ignore zombie
    if (GetClientTeam(client) == TEAM_ZM)
        return Plugin_Continue;
#endif

    // allow sound
    if (g_szDeathVoice[client][0] != '*')
        return Plugin_Continue;

    // if (strcmp(soundEntry, "Player.Death") == 0 || strcmp(soundEntry, "Player.DeathFem") == 0)
    if (strncmp(soundEntry, "Player.Death", 12, false) == 0)
    {
        // Block
        return Plugin_Handled;
    }

    // others
    return Plugin_Continue;
}

void Skin_BroadcastDeathSound(int client)
{
    if (!IsClientInGame(client))
        return;

    if (g_szDeathVoice[client][0] != '*')
        return;

#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
        return;
#endif

    char sound[PLATFORM_MAX_PATH];
    strcopy(sound, PLATFORM_MAX_PATH, g_szDeathVoice[client]);

    Action res = Plugin_Continue;

    Call_StartForward(g_hOnPlayerDeathVoice);
    Call_PushCell(client);
    Call_PushStringEx(sound, PLATFORM_MAX_PATH, SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish(res);

    if (res >= Plugin_Handled)
        return;

    if (res == Plugin_Continue)
        strcopy(sound, PLATFORM_MAX_PATH, g_szDeathVoice[client]);

    float fPos[3], fAgl[3];
    GetClientEyePosition(client, fPos);
    GetClientEyeAngles(client, fAgl);

    fPos[2] -= 3.0;

    int speaker = SpawnSpeakerEntity(fPos, fAgl, 3.0);

    int m_iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

    if (m_iRagdoll > MaxClients)
    {
        // make sound following ragdoll
        SetVariantString("!activator");
        AcceptEntityInput(speaker, "SetParent", client);
        SetVariantString("facemask");
        AcceptEntityInput(speaker, "SetParentAttachment");
    }
    else
    {
        // fallback to client
        speaker = client;
    }

    EmitSoundToClient(client, sound, SOUND_FROM_PLAYER, SNDCHAN_VOICE, _, _, 1.0);

    int[] clients = new int[MAXPLAYERS + 1];
    int   counts;
    float vPos[3];
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i) && i != client)
        {
            if (IsPlayerAlive(i))
            {
                GetClientEyePosition(i, vPos);
                if (GetVectorDistance(fPos, vPos) >= 1024.0)
                {
                    // skip if so far
                    continue;
                }
            }

            clients[counts++] = i;
        }

    if (counts > 0)
        EmitSound(clients, counts, sound, speaker, SNDCHAN_VOICE, _, _, 1.0, _, speaker);
}

void Skin_PreviewSkin(int client, int itemid)
{
    if (g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);

    if (g_iPreviewTimes[client] > GetTime())
    {
        tPrintToChat(client, "%T", "too many commands", client);
        return;
    }

    int m_iViewModel = CreateEntityByName("prop_dynamic_override"); // prop_physics_multiplayer
    DispatchKeyValue(m_iViewModel, "spawnflags", "64");
    DispatchKeyValue(m_iViewModel, "model", g_ePlayerSkins[g_Items[itemid].iData].szModel);
    DispatchKeyValue(m_iViewModel, "rendermode", "0");
    DispatchKeyValue(m_iViewModel, "renderfx", "0");
    DispatchKeyValue(m_iViewModel, "rendercolor", "255 255 255");
    DispatchKeyValue(m_iViewModel, "renderamt", "255");
    DispatchKeyValue(m_iViewModel, "solid", "0");

    DispatchSpawn(m_iViewModel);

    if (g_ePlayerSkins[g_Items[itemid].iData].nBody > 0)
    {
        // set?
        SetEntProp(m_iViewModel, Prop_Send, "m_nBody", g_ePlayerSkins[g_Items[itemid].iData].nBody);
    }

    SetEntProp(m_iViewModel, Prop_Send, "m_CollisionGroup", 11);

    AcceptEntityInput(m_iViewModel, "Enable");

    int offset = GetEntSendPropOffs(m_iViewModel, "m_clrGlow");
    SetEntProp(m_iViewModel, Prop_Send, "m_bShouldGlow", true, true);
    SetEntProp(m_iViewModel, Prop_Send, "m_nGlowStyle", 2);
    SetEntPropFloat(m_iViewModel, Prop_Send, "m_flGlowMaxDist", 2000.0);

    // Miku Green
    SetEntData(m_iViewModel, offset, 57, _, true);
    SetEntData(m_iViewModel, offset + 1, 197, _, true);
    SetEntData(m_iViewModel, offset + 2, 187, _, true);
    SetEntData(m_iViewModel, offset + 3, 255, _, true);

    float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];

    GetClientAbsOrigin(client, m_fOrigin);
    GetClientAbsAngles(client, m_fAngles);

    m_fRadians[0] = DegToRad(m_fAngles[0]);
    m_fRadians[1] = DegToRad(m_fAngles[1]);

    m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
    m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
    m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);

    m_fAngles[0] *= -1.0;
    m_fAngles[1] *= -1.0;

    TeleportEntity(m_iViewModel, m_fPosition, m_fAngles, NULL_VECTOR);

    g_iPreviewTimes[client] = GetTime() + 18;
    g_iPreviewModel[client] = EntIndexToEntRef(m_iViewModel);

    if (g_pTransmit)
    {
        if (GetFeatureStatus(FeatureType_Native, "TransmitManager_SetEntityBlock") == FeatureStatus_Available)
        {
            TransmitManager_AddEntityHooks(m_iViewModel, false);
            TransmitManager_SetEntityBlock(m_iViewModel, true);
            PrintToServer("[Store]  Spawn preview model<%d> in block mode.", m_iViewModel);
        }
        // TODO switch to old mode
        else
        {
            TransmitManager_AddEntityHooks(m_iViewModel);

            SetEntPropEnt(m_iViewModel, Prop_Send, "m_hOwnerEntity", client);
            CreateTimer(0.1, UpdatePreviewTransmitState, EntIndexToEntRef(m_iViewModel), TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
            PrintToServer("[Store]  Spawn preview model<%d> in normal mode.", m_iViewModel);
        }

        TransmitManager_SetEntityOwner(m_iViewModel, client);
        TransmitManager_SetEntityState(m_iViewModel, client, true);
    }
    else if (!IsParallelMode())
    {
        // SDKHooks crashes in parallel mode
        SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
    }

    g_tKillPreview[client] = CreateTimer(15.0, Timer_KillPreview, client);

    tPrintToChat(client, "%T", "Chat Preview", client);
}

static Action UpdatePreviewTransmitState(Handle timer, int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity < MaxClients)
        return Plugin_Stop;

    int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if (client == INVALID_ENT_REFERENCE)
    {
        RemoveEntity(entity);
        return Plugin_Stop;
    }

    PrintToServer("[Store]  Update preview model<%d> in normal mode.", entity);

    for (int target = 1; target <= MaxClients; ++target)
    {
        if (client != target && IsClientInGame(target))
        {
            TransmitManager_SetEntityState(entity, client, false);
        }
    }

    TransmitManager_SetEntityState(entity, client, true);

    return Plugin_Continue;
}

static Action Hook_SetTransmit_Preview(int entity, int client)
{
    if (g_iPreviewModel[client] == INVALID_ENT_REFERENCE)
        return Plugin_Handled;

    if (entity != EntRefToEntIndex(g_iPreviewModel[client]))
        return Plugin_Handled;

    float vPosEntity[3], vPosClient[3];
    GetClientAbsOrigin(client, vPosClient);
    GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPosEntity);
    if (vPosClient[2] < vPosEntity[2] - 40.0)
    {
        SafeKillPreview(client, entity);
        return Plugin_Handled;
    }
    vPosClient[2] = 0.0;
    vPosEntity[2] = 0.0;
    if (GetVectorDistance(vPosEntity, vPosClient) < 32.0)
    {
        SafeKillPreview(client, entity);
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

static void SafeKillPreview(int client, int entity)
{
    RemoveEntity(entity);
    g_iPreviewModel[client] = INVALID_ENT_REFERENCE;
    delete g_tKillPreview[client];

    tPrintToChat(client, "%T", "anti collision", client);

    g_iPreviewTimes[client] = GetTime() + 3;
}

static Action Timer_KillPreview(Handle timer, int client)
{
    g_tKillPreview[client] = null;

    if (g_iPreviewModel[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iPreviewModel[client]);
        if (entity > MaxClients)
        {
            RemoveEntity(entity);
        }
    }
    g_iPreviewModel[client] = INVALID_ENT_REFERENCE;

    return Plugin_Stop;
}

void Skin_FirstPersonDeathCamera(int client)
{
    if (!IsClientInGame(client) || GetClientTeam(client) <= TEAM_OB || IsPlayerAlive(client))
        return;

    if (!store_firstperson_death_camera.BoolValue)
        return;

    Action ret = Plugin_Continue;

    Call_StartForward(g_hOnFPDeathCamera);
    Call_PushCell(client);
    Call_Finish(ret);

    if (ret >= Plugin_Handled)
    {
        g_iCameraRef[client] = INVALID_ENT_REFERENCE;
        return;
    }

    int m_iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

    if (m_iRagdoll < 0)
        return;

    SpawnCamAndAttach(client, m_iRagdoll);
}

static bool SpawnCamAndAttach(int client, int ragdoll)
{
    int iEntity = CreateEntityByName("prop_dynamic");
    if (iEntity == -1)
        return false;

    DispatchKeyValue(iEntity, "model", "models/blackout.mdl");
    DispatchKeyValue(iEntity, "solid", "0");
    DispatchKeyValue(iEntity, "rendermode", "10");    // dont render
    DispatchKeyValue(iEntity, "disableshadows", "1"); // no shadows

    float m_fAngles[3];
    GetClientEyeAngles(client, m_fAngles);

    DispatchKeyValueVector(iEntity, "angles", m_fAngles);

    SetEntityModel(iEntity, "models/blackout.mdl");
    DispatchSpawn(iEntity);

    SetVariantString("!activator");
    AcceptEntityInput(iEntity, "SetParent", ragdoll, iEntity, 0);

    SetVariantString("facemask");
    AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);

    AcceptEntityInput(iEntity, "TurnOn");

    SetClientViewEntity(client, iEntity);
    g_iCameraRef[client] = EntIndexToEntRef(iEntity);

    FadeScreenBlack(client);

    g_tResetCamera[client] = CreateTimer(6.0, Timer_ClearCamera, client);

    return true;
}

static Action Timer_ClearCamera(Handle timer, int client)
{
    g_tResetCamera[client] = null;

    // Fix screen
    if (IsClientInGame(client))
    {
        SetClientViewEntity(client, client);
        FadeScreenWhite(client);
    }

    // Remove entity
    if (g_iCameraRef[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iCameraRef[client]);
        if (entity > MaxClients)
        {
            RemoveEntity(entity);
        }
        g_iCameraRef[client] = INVALID_ENT_REFERENCE;
    }

    return Plugin_Stop;
}

#define FFADE_IN       0x0001 // Just here so we don't pass 0 into the function
#define FFADE_OUT      0x0002 // Fade out (not in)
#define FFADE_MODULATE 0x0004 // Modulate (don't blend)
#define FFADE_STAYOUT  0x0008 // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE    0x0010 // Purges all other fades, replacing them with this one

static void FadeScreenBlack(int client)
{
    Protobuf pb = view_as<Protobuf>(StartMessageOne("Fade", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
    pb.SetInt("duration", 2560); // 3072
    pb.SetInt("hold_time", 0);
    pb.SetInt("flags", FFADE_OUT | FFADE_PURGE | FFADE_STAYOUT);
    pb.SetColor("clr", { 0, 0, 0, 255 });
    EndMessage();
}

static void FadeScreenWhite(int client)
{
    Protobuf pb = view_as<Protobuf>(StartMessageOne("Fade", client, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS));
    pb.SetInt("duration", 1536);
    pb.SetInt("hold_time", 1536);
    pb.SetInt("flags", FFADE_IN | FFADE_PURGE);
    pb.SetColor("clr", { 0, 0, 0, 0 });
    EndMessage();
}

void Skin_OnRunCmd(int client)
{
    if (g_iCameraRef[client] == INVALID_ENT_REFERENCE)
        return;

    if (IsPlayerAlive(client))
        return;

    int m_iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if (m_iObserverMode < OBS_MODE_ROAMING)
        SetEntProp(client, Prop_Send, "m_iObserverMode", OBS_MODE_ROAMING);
}

static int GetEquippedSkin(int client)
{
    if (IsFakeClient(client))
        return -1;

#if defined Global_Skin
    return Store_GetEquippedItem(client, "playerskin", 2);
#else
    return Store_GetEquippedItem(client, "playerskin", GetClientTeam(client) - 2);
#endif
}

#if defined GM_ZE

public void ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
    // If client has been respawned.
    if (respawn)
        return;

    // Dead Player.
    if (!IsPlayerAlive(client))
        return;

    Skin_SetClientSkin(client);
}
#endif

void Skin_RemoveClientGloves(int client, int flags)
{
    if (flags & SKIN_FLAGS_ARMS == 0)
        return;

    int gloves = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
    if (gloves != INVALID_ENT_REFERENCE)
        AcceptEntityInput(gloves, "KillHierarchy");
}

void Skin_OnPlayerSpawn(int client)
{
    g_bShouldFireEvent[client] = false;

    int entity = EntRefToEntIndex(g_iCameraRef[client]);
    if (entity > MaxClients)
        RemoveEntity(entity);

    SetClientViewEntity(client, client);

    if (g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);

    Skin_RemoveClientGloves(client, CheckDefaultSkinFlags(client));
}

void Skin_ResetPlayerSkin(int client)
{
    strcopy(g_szSkinModel[client], sizeof(g_szSkinModel[]), "#default");

#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
        strcopy(g_szSkinModel[client], sizeof(g_szSkinModel[]), "#zombie");
#endif

    g_iSkinLevel[client]      = 0;
    g_szDeathVoice[client][0] = 0;
}

static bool SetClientDefaultSkin(int client)
{
#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
    {
        strcopy(g_szSkinModel[client], sizeof(g_szSkinModel[]), "#zombie");
        return false;
    }
#endif

    char skin_t[128], arms_t[128];
    int  body = 0;
    bool ret  = false;
    bool set  = false;

    Call_StartForward(g_hOnPlayerSkinDefault);
    Call_PushCell(client);
    Call_PushCell(GetClientTeam(client) - 2);
    Call_PushStringEx(STRING(skin_t), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_PushStringEx(STRING(arms_t), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_PushCellRef(body);
    Call_Finish(ret);

    if (ret)
    {
        if (IsModelPrecached(skin_t))
        {
            SetEntityModel(client, skin_t);
            SetEntProp(client, Prop_Send, "m_nBody", body > 0 ? body : 0);
            set = true;
        }

        if (CallAllowSetPlayerSkinArms(client, STRING(arms_t)))
        {
            if (IsModelPrecached(arms_t))
            {
                SetClientArms(client, arms_t);
            }
        }

        EnforceDeathSound(client, skin_t, body);
    }

    return set;
}

static int CheckDefaultSkinFlags(int client)
{
    char skin_t[128], arms_t[128];
    int  body  = 0;
    int  flags = 0;
    bool ret   = false;

    Call_StartForward(g_hOnPlayerSkinDefault);
    Call_PushCell(client);
    Call_PushCell(GetClientTeam(client) - 2);
    Call_PushStringEx(STRING(skin_t), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_PushStringEx(STRING(arms_t), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_PushCellRef(body);
    Call_Finish(ret);

    if (!ret)
        return flags;

    if (IsModelPrecached(skin_t))
        flags |= SKIN_FLAGS_SKIN;

    if (IsModelPrecached(arms_t))
        flags |= SKIN_FLAGS_ARMS;

    return flags;
}

static void EnforceDeathSound(int client, const char[] skin, const int body)
{
    g_szDeathVoice[client][0] = 0;

    int index = FindDataIndexByModel(skin, body);
    if (index == -1)
    {
        // item not from store DB
        return;
    }

    if (g_ePlayerSkins[index].szSound[0] != 0)
        FormatEx(g_szDeathVoice[client], sizeof(g_szDeathVoice[]), "*%s", g_ePlayerSkins[index].szSound);
}

static Action CallPreSetModel(int client, char skin[128], char arms[128], int &body)
{
    char s[128], a[128];
    int  b = body;
    strcopy(STRING(s), skin);
    strcopy(STRING(a), arms);

    Action res = Plugin_Continue;

    Call_StartForward(g_hOnPlayerSetModel);
    Call_PushCell(client);
    Call_PushStringEx(STRING(s), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(STRING(a), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCellRef(b);
    Call_Finish(res);

    if (res == Plugin_Changed)
    {
        strcopy(skin, 128, s);
        strcopy(arms, 128, a);
        body = b;
    }

    return res;
}

static bool CallAllowSetPlayerSkinArms(int client, char[] arms, int len)
{
    static GlobalForward gf = null;
    if (gf == null)
    {
        gf = new GlobalForward("Store_OnSetPlayerSkinArms", ET_Hook, Param_Cell, Param_String, Param_Cell);
    }

    char buff[128];
    strcopy(STRING(buff), arms);

    Action res = Plugin_Continue;
    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushStringEx(STRING(buff), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(len);
    Call_Finish(res);

    if (res == Plugin_Continue)
    {
        return true;
    }
    else if (res == Plugin_Changed)
    {
        strcopy(arms, len, buff);
        return true;
    }

    return false;
}

static int FindDataIndexByModel(const char[] skin, const int body)
{
    for (int i = 0; i < g_iPlayerSkins; ++i)
    {
        if (strcmp(g_ePlayerSkins[i].szModel, skin) == 0)
        {
            if (g_ePlayerSkins[i].nBody > 0)
            {
                if (body != g_ePlayerSkins[i].nBody)
                {
                    continue;
                }
            }
            return i;
        }
    }
    return -1;
}

static void SetClientArms(int client, const char[] arms_t)
{
    Skin_RemoveClientGloves(client, SKIN_FLAGS_ARMS);
    SetEntPropString(client, Prop_Send, "m_szArmsModel", arms_t);

    if (!g_bShouldFireEvent[client])
    {
        g_bShouldFireEvent[client] = true;
        return;
    }

    if (IsFakeClient(client))
        return;

    Event event = CreateEvent("player_spawn", true);
    if (event == null)
        return;

    event.SetInt("userid", GetClientUserId(client));
    event.FireToClient(client);
    event.Cancel();
}

// Internal Api

/**
 * Checks if a client is in death camera mode.
 *
 * @param client The client index to check.
 * @return True if the client is in death camera mode, false otherwise.
 */
bool Skin_IsInDeathCamera(int client)
{
    return g_iCameraRef[client] != INVALID_ENT_REFERENCE && EntRefToEntIndex(g_iCameraRef[client]) > MaxClients;
}

/**
 * Returns the skin level of the player with the given client index.
 *
 * @param client The client index of the player to get the skin level of.
 * @return The skin level of the player.
 */
int Skin_GetPlayerSkinLevel(int client)
{
    return g_iSkinLevel[client];
}

/**
 * Retrieves the current skin model for a given client.
 *
 * @param client The client index.
 * @param model The buffer to store the skin model.
 * @param maxLen The maximum length of the buffer.
 */
void Skin_GetClientSkinModel(int client, char[] model, int maxLen)
{
    GetEntPropString(client, Prop_Data, "m_ModelName", model, maxLen);
}

/**
 * Retrieves the skin model of a player that set by store.
 *
 * @param client The client index of the player.
 * @param model The buffer to store the skin model.
 * @param maxLen The maximum length of the buffer.
 */
void Skin_GetPlayerSkinModel(int client, char[] model, int maxLen)
{
    strcopy(model, maxLen, g_szSkinModel[client]);
}

/**
 * Retrieves skin data for a given item ID.
 *
 * @param itemid The ID of the item to retrieve skin data for.
 * @param skin The name of the skin model to retrieve.
 * @param arms The name of the arms model to retrieve.
 * @param body The body index to retrieve.
 * @param team The team index to retrieve.
 * @return True if the skin data was successfully retrieved, false otherwise.
 */
bool Skin_GetSkinData(int itemid, char skin[128], char arms[128], int &body, int &team = 0)
{
    int m_iData = Store_GetDataIndex(itemid);
    if (m_iData == -1)
        return false;

    strcopy(skin, 128, g_ePlayerSkins[m_iData].szModel);
    strcopy(arms, 128, g_ePlayerSkins[m_iData].szArms);
    body = g_ePlayerSkins[m_iData].nBody;
    team = g_ePlayerSkins[m_iData].iTeam;
    return true;
}

/**
 * Kills the skin preview for the specified client.
 *
 * @param client The client index to kill the skin preview for.
 */
void Skin_KillPreview(int client)
{
    if (g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);
}
#define Module_Skin

enum PlayerSkin
{
    String:szModel[PLATFORM_MAX_PATH],
    String:szArms[PLATFORM_MAX_PATH],
    String:szSound[PLATFORM_MAX_PATH],
    iLevel,
    iTeam
}

static any g_ePlayerSkins[STORE_MAX_ITEMS][PlayerSkin];

static int    g_iPlayerSkins = 0;
static int    g_iSkinLevel[MAXPLAYERS+1];
static int    g_iPreviewTimes[MAXPLAYERS+1];
static int    g_iPreviewModel[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
static int    g_iCameraRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
static char   g_szDeathVoice[MAXPLAYERS+1][PLATFORM_MAX_PATH];
static char   g_szSkinModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];
static ConVar spec_freeze_time;
static ConVar mp_round_restart_delay;
static ConVar sv_disablefreezecam;
static ConVar spec_replay_enable;

bool   g_bSpecJoinPending[MAXPLAYERS+1];
Handle g_tKillPreview[MAXPLAYERS+1];

Handle g_hOnPlayerSkinDefault = null;
Handle g_hOnPlayerSetModel = null;
Handle g_hOnFPDeathCamera = null;

void Skin_OnPluginStart()
{
    g_hOnPlayerSkinDefault = CreateGlobalForward("Store_OnPlayerSkinDefault", ET_Event, Param_Cell, Param_Cell, Param_String, Param_Cell, Param_String, Param_Cell);
    g_hOnFPDeathCamera = CreateGlobalForward("Store_OnFPDeathCamera", ET_Hook, Param_Cell);
    g_hOnPlayerSetModel = CreateGlobalForward("Store_OnSetPlayerSkin", ET_Event, Param_Cell, Param_String, Param_String);

    AddNormalSoundHook(Hook_NormalSound);

    Store_RegisterHandler("playerskin", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);

    RegAdminCmd("sm_arms", Command_Arms, ADMFLAG_ROOT, "Fixed Player Arms");

    //DEATH CAMERA CCVAR
    spec_freeze_time = FindConVar("spec_freeze_time");
    HookConVarChange(spec_freeze_time, Skin_OnConVarChanged);
    SetConVarString(spec_freeze_time, "-1.0", true);

    sv_disablefreezecam = FindConVar("sv_disablefreezecam");
    HookConVarChange(sv_disablefreezecam, Skin_OnConVarChanged);
    SetConVarString(sv_disablefreezecam, "1", true);

    mp_round_restart_delay = FindConVar("mp_round_restart_delay");
    HookConVarChange(mp_round_restart_delay, Skin_OnConVarChanged);
    SetConVarString(mp_round_restart_delay, "8", true);

    spec_replay_enable = FindConVar("spec_replay_enable");
    HookConVarChange(spec_replay_enable, Skin_OnConVarChanged);
    SetConVarString(spec_replay_enable, "0", true);
}

public void Skin_OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if(convar == spec_freeze_time)
        SetConVarString(spec_freeze_time, "-1.0", true);

    if(convar == sv_disablefreezecam)
        SetConVarString(sv_disablefreezecam, "1", true);    

    if(convar == mp_round_restart_delay)
    {
        if(mp_round_restart_delay.FloatValue < 8.0)
            SetConVarFloat(mp_round_restart_delay, 8.0, true);
    }

    if(convar == spec_replay_enable)
        SetConVarString(spec_replay_enable, "0", true);
}

void Skin_OnClientDisconnect(int client)
{
    if(g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);

    if(g_iCameraRef[client] != INVALID_ENT_REFERENCE)
        CreateTimer(0.0, Timer_ClearCamera, client);

    if(g_bSpecJoinPending[client])
        g_bSpecJoinPending[client] = false;
}

public Action Command_Arms(int client, int args)
{
    if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
        return Plugin_Handled;

#if defined GM_ZE    
    if(g_iClientTeam[client] == 2)
        return Plugin_Handled;
#endif

    Store_PreSetClientModel(client);

    return Plugin_Handled;
}

public bool PlayerSkins_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iPlayerSkins);
    
    kv.GetString("model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
    kv.GetString("arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);
    kv.GetString("sound", g_ePlayerSkins[g_iPlayerSkins][szSound], PLATFORM_MAX_PATH);
    
    g_ePlayerSkins[g_iPlayerSkins][iLevel] = kv.GetNum("lvls", 0)+1;

#if defined Global_Skin
    g_ePlayerSkins[g_iPlayerSkins][iTeam] = 4;
#else
    g_ePlayerSkins[g_iPlayerSkins][iTeam] = kv.GetNum("team");
#endif

    if(FileExists(g_ePlayerSkins[g_iPlayerSkins][szModel], true))
    {
        ++g_iPlayerSkins;
        return true;
    }

    return false;
}

public void PlayerSkins_OnMapStart()
{
    char szPath[PLATFORM_MAX_PATH], szPathStar[PLATFORM_MAX_PATH];
    for(int i = 0; i < g_iPlayerSkins; ++i)
    {
        PrecacheModel(g_ePlayerSkins[i][szModel], true);
        Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szModel]);

        if(g_ePlayerSkins[i][szArms][0] != 0)
        {
            PrecacheModel(g_ePlayerSkins[i][szArms], true);
            Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
        }

        if(g_ePlayerSkins[i][szSound][0] != 0)
        {
            FormatEx(szPath, 256, "sound/%s", g_ePlayerSkins[i][szSound]);
            if(FileExists(szPath, true))
            {
                FormatEx(szPathStar, 256, "*%s", g_ePlayerSkins[i][szSound]);
                AddToStringTable(FindStringTable("soundprecache"), szPathStar);
                Downloader_AddFileToDownloadsTable(szPath);
            }
        }
    }

    PrecacheModel("models/blackout.mdl", true);
}

public void PlayerSkins_Reset()
{
    g_iPlayerSkins = 0;
}

public int PlayerSkins_Equip(int client, int id)
{
    if(IsClientInGame(client) && IsPlayerAlive(client))
        tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

#if defined Global_Skin
    return 2;
#else
    return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
#endif
}

public int PlayerSkins_Remove(int client, int id)
{
    if(IsClientInGame(client))
        tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

#if defined Global_Skin
    return 2;
#else
    return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
#endif
}

void Store_PreSetClientModel(int client)
{
    int m_iEquipped = GetEquippedSkin(client);

    if(m_iEquipped >= 0)
    {
        CreateTimer(0.02, Timer_SetClientModel, client | (Store_GetDataIndex(m_iEquipped) << 7), TIMER_FLAG_NO_MAPCHANGE);
        return;
    }

    Store_CallDefaultSkin(client);

#if defined Module_Hats
    Store_SetClientHat(client);
#endif
}

static void Store_SetClientModel(int client, int m_iData)
{
    if(!IsClientInGame(client) || !IsPlayerAlive(client))
        return;
    
#if defined GM_ZE
    if(g_iClientTeam[client] == 2)
    {
        strcopy(g_szSkinModel[client], 256, "#zombie");
        return;
    }
#endif

    char skin_t[128], arms_t[128];
    strcopy(skin_t, 128, g_ePlayerSkins[m_iData][szModel]);
    strcopy(arms_t, 128, g_ePlayerSkins[m_iData][szArms]);

    Action res = Store_CallPreSetModel(client, skin_t, arms_t);
    if (res >= Plugin_Handled)
        return;
    else if (res == Plugin_Changed)
    {
        // verify data index;
        m_iData = FindDataIndexByModel(skin_t);
        if (m_iData == -1)
            return;
    }

    SetEntityModel(client, skin_t);
    strcopy(g_szSkinModel[client], 256, skin_t);

    if(g_ePlayerSkins[m_iData][szSound][0] != 0)
        FormatEx(g_szDeathVoice[client], 256, "*%s", g_ePlayerSkins[m_iData][szSound]);

    if(!StrEqual(arms_t, "null"))
    {
        if (Store_CallSetPlayerSkinArms(client, arms_t, 128))
        {
            // Has valve gloves?
            Store_RemoveClientGloves(client, 0);
            SetEntPropString(client, Prop_Send, "m_szArmsModel", arms_t);
        }
    }

    g_iSkinLevel[client] = g_ePlayerSkins[m_iData][iLevel];

#if defined Module_Hats
    Store_SetClientHat(client);
#endif
}

public Action Timer_SetClientModel(Handle timer, int val)
{
    Store_SetClientModel(val & 0x7f, val >> 7);
    return Plugin_Stop;
}

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    // not death sound
    if(channel != SNDCHAN_VOICE || sample[0] != '~')
        return Plugin_Continue;

    // not from local player
    if(!IsValidClient(client))
        return Plugin_Continue;

#if defined GM_ZE
    // ignore zombie
    if(g_iClientTeam[client] == 2)
        return Plugin_Continue;
#endif

    // allow sound
    if(g_szDeathVoice[client][0] != '*')
        return Plugin_Continue;

    if (strcmp(soundEntry, "Player.Death") == 0)
    {
        // Block
        return Plugin_Handled;
    }

    // others
    return Plugin_Continue;
}

void Broadcast_DeathSound(int client)
{
    if(!IsClientInGame(client))
        return;

    if(g_szDeathVoice[client][0] != '*')
        return;

#if defined GM_ZE
    if(g_iClientTeam[client] == 2)
        return;
#endif

    float fPos[3], fAgl[3];
    GetClientEyePosition(client, fPos);
    GetClientEyeAngles  (client, fAgl);

    fPos[2] -= 3.0;

    int speaker = SpawnSpeakerEntity(fPos, fAgl, client, 3.0);

#if defined GM_ZE
    EmitSoundToClient(client, g_szDeathVoice[client], speaker, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, speaker, fPos, fAgl, true);
#else
    EmitSoundToAll(g_szDeathVoice[client], speaker, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, speaker, fPos, fAgl, true);
#endif
}

void Store_PreviewSkin(int client, int itemid)
{
    if(g_tKillPreview[client] != null)
        TriggerTimer(g_tKillPreview[client], false);

    int m_iViewModel = CreateEntityByName("prop_dynamic_override"); //prop_physics_multiplayer
    char m_szTargetName[32];
    FormatEx(m_szTargetName, 32, "Store_Preview_%d", m_iViewModel);
    DispatchKeyValue(m_iViewModel, "targetname", m_szTargetName);
    DispatchKeyValue(m_iViewModel, "spawnflags", "64");
    DispatchKeyValue(m_iViewModel, "model", g_ePlayerSkins[g_eItems[itemid][iData]][szModel]);
    DispatchKeyValue(m_iViewModel, "rendermode", "0");
    DispatchKeyValue(m_iViewModel, "renderfx", "0");
    DispatchKeyValue(m_iViewModel, "rendercolor", "255 255 255");
    DispatchKeyValue(m_iViewModel, "renderamt", "255");
    DispatchKeyValue(m_iViewModel, "solid", "0");
    
    DispatchSpawn(m_iViewModel);
    
    SetEntProp(m_iViewModel, Prop_Send, "m_CollisionGroup", 11);

    AcceptEntityInput(m_iViewModel, "Enable");

    int offset = GetEntSendPropOffs(m_iViewModel, "m_clrGlow");
    SetEntProp(m_iViewModel, Prop_Send, "m_bShouldGlow", true, true);
    SetEntProp(m_iViewModel, Prop_Send, "m_nGlowStyle", 0);
    SetEntPropFloat(m_iViewModel, Prop_Send, "m_flGlowMaxDist", 2000.0);

    //Miku Green
    SetEntData(m_iViewModel, offset    ,  57, _, true);
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
    
    g_iPreviewTimes[client] = GetTime()+90;
    g_iPreviewModel[client] = EntIndexToEntRef(m_iViewModel);

    SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_Preview);

    g_tKillPreview[client] = CreateTimer(45.0, Timer_KillPreview, client);

    tPrintToChat(client, "%T", "Chat Preview", client);
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
    if(g_iPreviewModel[client] == INVALID_ENT_REFERENCE)
        return Plugin_Handled;
    
    if(ent == EntRefToEntIndex(g_iPreviewModel[client]))
        return Plugin_Continue;

    return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
    g_tKillPreview[client] = null;

    if(g_iPreviewModel[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iPreviewModel[client]);

        if(IsValidEdict(entity))
        {
            SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
            AcceptEntityInput(entity, "Kill");
        }
    }
    g_iPreviewModel[client] = INVALID_ENT_REFERENCE;

    return Plugin_Stop;
}

public void FirstPersonDeathCamera(int client)
{
    if(!IsClientInGame(client) || g_iClientTeam[client] < 2 || IsPlayerAlive(client))
        return;

    Action ret = Plugin_Continue;
    
    Call_StartForward(g_hOnFPDeathCamera);
    Call_PushCell(client);
    Call_Finish(ret);
    
    if(ret >= Plugin_Handled)
        return;

    int m_iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

    if(m_iRagdoll < 0)
        return;

    SpawnCamAndAttach(client, m_iRagdoll);
}

static bool SpawnCamAndAttach(int client, int ragdoll)
{
    char m_szTargetName[32]; 
    FormatEx(m_szTargetName, 32, "ragdoll%d", client);
    DispatchKeyValue(ragdoll, "targetname", m_szTargetName);

    int iEntity = CreateEntityByName("prop_dynamic");
    if(iEntity == -1)
        return false;

    char m_szCamera[32]; 
    FormatEx(m_szCamera, 32, "ragdollCam%d", iEntity);

    DispatchKeyValue(iEntity, "targetname", m_szCamera);
    DispatchKeyValue(iEntity, "parentname", m_szTargetName);
    DispatchKeyValue(iEntity, "model",      "models/blackout.mdl");
    DispatchKeyValue(iEntity, "solid",      "0");
    DispatchKeyValue(iEntity, "rendermode", "10"); // dont render
    DispatchKeyValue(iEntity, "disableshadows", "1"); // no shadows

    float m_fAngles[3]; 
    GetClientEyeAngles(client, m_fAngles);
    
    char m_szCamAngles[64];
    FormatEx(m_szCamAngles, 64, "%f %f %f", m_fAngles[0], m_fAngles[1], m_fAngles[2]);

    DispatchKeyValue(iEntity, "angles", m_szCamAngles);

    SetEntityModel(iEntity, "models/blackout.mdl");
    DispatchSpawn(iEntity);

    SetVariantString(m_szTargetName);
    AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity, 0);

    SetVariantString("facemask");
    AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);

    AcceptEntityInput(iEntity, "TurnOn");

    SetClientViewEntity(client, iEntity);
    g_iCameraRef[client] = EntIndexToEntRef(iEntity);
    
    FadeScreenBlack(client);

    CreateTimer(7.0, Timer_ClearCamera, client);

    //SetEntPropEnt(client, Prop_Send, "m_hRagdoll", iEntity);

    return true;
}

public Action Timer_ClearCamera(Handle timer, int client)
{
    if(g_iCameraRef[client] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iCameraRef[client]);

        if(IsValidEdict(entity))
        {
            AcceptEntityInput(entity, "Kill");
        }

        g_iCameraRef[client] = INVALID_ENT_REFERENCE;
    }

    if(IsClientInGame(client))
    {
        SetClientViewEntity(client, client);
        FadeScreenWhite(client);
    }

    return Plugin_Stop;
}

void AttemptState(int client, bool spec)
{
    char client_specmode[10];
    GetClientInfo(client, "cl_spec_mode", client_specmode, 9);
    if(StringToInt(client_specmode) <= 4)
    {
        g_bSpecJoinPending[client] = spec;
        ClientCommand(client, "cl_spec_mode 6");
    }
}

#define FFADE_IN        0x0001        // Just here so we don't pass 0 into the function
#define FFADE_OUT       0x0002        // Fade out (not in)
#define FFADE_MODULATE  0x0004        // Modulate (don't blend)
#define FFADE_STAYOUT   0x0008        // ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE     0x0010        // Purges all other fades, replacing them with this one

static void FadeScreenBlack(int client)
{
    Protobuf pb = view_as<Protobuf>(StartMessageOne("Fade", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    pb.SetInt("duration", 3072);
    pb.SetInt("hold_time", 0);
    pb.SetInt("flags", FFADE_OUT|FFADE_PURGE|FFADE_STAYOUT);
    pb.SetColor("clr", {0, 0, 0, 255});
    EndMessage();
}

static void FadeScreenWhite(int client)
{
    Protobuf pb = view_as<Protobuf>(StartMessageOne("Fade", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    pb.SetInt("duration", 1536);
    pb.SetInt("hold_time", 1536);
    pb.SetInt("flags", FFADE_IN|FFADE_PURGE);
    pb.SetColor("clr", {0, 0, 0, 0});
    EndMessage();
}

void Skin_OnRunCmd(int client, int &buttons)
{
    if(IsPlayerAlive(client))
        return;
    
    if(g_iCameraRef[client] == INVALID_ENT_REFERENCE)
        return;

    buttons = 0;

    int m_iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
    if(m_iObserverMode <= 4)
        SetEntProp(client, Prop_Send, "m_iObserverMode", 6);

    //AttemptState(client, false);
}

static int GetEquippedSkin(int client)
{
#if defined Global_Skin
    return Store_GetEquippedItem(client, "playerskin", 2);
#else
    return Store_GetEquippedItem(client, "playerskin", g_iClientTeam[client]-2);
#endif
}

#if defined GM_ZE
public void ZR_OnClientHumanPost(int client, bool respawn, bool protect)
{
    // If client has been respawned.
    if(respawn) 
        return;

    // Dead Player.
    if(!IsPlayerAlive(client))
        return;

    Store_PreSetClientModel(client);
}
#endif

void Store_RemoveClientGloves(int client, int m_iData = -1)
{
    if(m_iData == -1 && GetEquippedSkin(client) <= 0)
        return;

    int gloves = GetEntPropEnt(client, Prop_Send, "m_hMyWearables");
    if(gloves != -1)
        AcceptEntityInput(gloves, "KillHierarchy");
}

void Store_ResetPlayerSkin(int client)
{
    strcopy(g_szSkinModel[client], 256, "#default");
    g_iSkinLevel[client] = 0;
    g_szDeathVoice[client][0] = '\0';
}

int Store_GetPlayerSkinLevel(int client)
{
    return g_iSkinLevel[client];
}

void Store_GetClientSkinModel(int client, char[] model, int maxLen)
{
    GetEntPropString(client, Prop_Data, "m_ModelName", model, maxLen);
}

void Store_GetPlayerSkinModel(int client, char[] model, int maxLen)
{
    strcopy(model, maxLen, g_szSkinModel[client]);
}

void Store_CallDefaultSkin(int client)
{
    char skin_t[128], arms_t[128];

    bool ret = false;

    Call_StartForward(g_hOnPlayerSkinDefault);
    Call_PushCell(client);
    Call_PushCell(g_iClientTeam[client]-2);
    Call_PushStringEx(skin_t, 128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_PushStringEx(arms_t,  128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCell(128);
    Call_Finish(ret);

    if(ret)
    {
        if(IsModelPrecached(skin_t))
            SetEntityModel(client, skin_t);

        if (Store_CallSetPlayerSkinArms(client, arms_t, 128))
        {
            if(IsModelPrecached(arms_t))
            {
                Store_RemoveClientGloves(client, 0);
                SetEntPropString(client, Prop_Send, "m_szArmsModel", arms_t);
            }
        }
    }
}

Action Store_CallPreSetModel(int client, char skin[128], char arms[128])
{
    char s[128], a[128];
    strcopy(s, 128, skin);
    strcopy(a, 128, arms);

    Action res = Plugin_Continue;

    Call_StartForward(g_hOnPlayerSetModel);
    Call_PushCell(client);
    Call_PushStringEx(s, 128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(a,  128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish(res);

    if (res == Plugin_Changed)
    {
        strcopy(skin, 128, s);
        strcopy(arms, 128, a);
    }

    return res;
}

bool Store_CallSetPlayerSkinArms(int client, char[] arms, int len)
{
    static Handle gf = null;
    if (gf == null)
    {
        gf = CreateGlobalForward("Store_OnSetPlayerSkinArms", ET_Hook, Param_Cell, Param_String, Param_Cell);
    }

    char buff[128];
    strcopy(buff, 128, arms);

    Action res = Plugin_Continue;
    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushString(buff);
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

bool GetSkinData(int itemid, char skin[128], char arms[128])
{
    int m_iData = Store_GetDataIndex(itemid);
    if (m_iData == -1)
        return false;

    strcopy(skin, 128, g_ePlayerSkins[m_iData][szModel]);
    strcopy(arms, 128, g_ePlayerSkins[m_iData][szArms]);
    return true;
}

int FindDataIndexByModel(const char[] skin)
{
    for(int i = 0; i < g_iPlayerSkins; ++i)
    {
        if (strcmp(g_ePlayerSkins[i][szModel], skin) == 0)
            return i;
    }
    return -1;
}
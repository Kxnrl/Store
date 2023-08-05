// MAIN_FILE ../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Spray

// options
static char   g_szSprays[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];
static char   g_szSprayName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];
static int    g_iSprayCooldown[STORE_MAX_ITEMS] = { 30, ... };
static int    g_iSprayPrecache[STORE_MAX_ITEMS] = { -1, ... };
static int    g_iSprayCache[MAXPLAYERS + 1]     = { -1, ... };
static int    g_iSprayLimit[MAXPLAYERS + 1]     = { 0, ... };
static int    g_iSprays                         = 0;
static Handle g_fwdOnClientSpray;
static Handle g_hOnSprayCommand;
static Handle g_hOnSprayModel;

static bool g_bFallbackSprayerSound;

#define FALLBACK_SPARYER_SOUND "maoling/sprayer.mp3"

void Sprays_OnPluginStart()
{
    Store_RegisterHandler("spray", Sprays_OnMapStart, Sprays_Reset, Sprays_Config, Sprays_Equip, Sprays_Remove, true);

    g_fwdOnClientSpray = CreateGlobalForward("Store_OnClientSpray", ET_Ignore, Param_Cell);
    g_hOnSprayCommand  = CreateGlobalForward("Store_OnSprayCommand", ET_Hook, Param_Cell, Param_CellByRef);
    g_hOnSprayModel    = CreateGlobalForward("Store_OnSprayModel", ET_Hook, Param_Cell, Param_String, Param_String, Param_CellByRef, Param_CellByRef);

    RegConsoleCmd("spray", Command_Spray);
    RegConsoleCmd("sprays", Command_Spray);
}

static void Sprays_OnMapStart()
{
    g_bFallbackSprayerSound = false;

    char m_szDecal[PLATFORM_MAX_PATH];

    for (int i = 0; i < g_iSprays; ++i)
        if (FileExists(g_szSprays[i], true))
        {
            strcopy(STRING(m_szDecal), g_szSprays[i][10]);
            m_szDecal[strlen(m_szDecal) - 4] = 0;

            g_iSprayPrecache[i] = PrecacheDecal(m_szDecal, true);
            AddFileToDownloadsTable(g_szSprays[i]);
        }

    PrecacheSound("items/spraycan_spray.wav", false);

    if (FileExists("sound/" ... FALLBACK_SPARYER_SOUND, false))
    {
        g_bFallbackSprayerSound = true;
        AddToStringTable(FindStringTable("soundprecache"), ")" ... FALLBACK_SPARYER_SOUND);
        AddFileToDownloadsTable("sound/" ... FALLBACK_SPARYER_SOUND);
    }
}

void Sprays_OnClientConnected(int client)
{
    g_iSprayCache[client] = -1;
}

void Spray_OnClientDeath(int client)
{
    g_iSprayLimit[client] = -1;
}

static Action Command_Spray(int client, int args)
{
    if (g_iSprayLimit[client] > GetTime())
    {
        tPrintToChat(client, "%T", "spray cooldown", client);
        return Plugin_Handled;
    }

    if (g_iSprayCache[client] < 0)
    {
        if (!StartNullSpray(client))
            tPrintToChat(client, "%T", "spray no equip", client);
        return Plugin_Handled;
    }

    CreateSpray(client);

    return Plugin_Handled;
}

static bool StartNullSpray(int client)
{
    bool res      = false;
    int  cooldown = 60;

    Call_StartForward(g_hOnSprayCommand);
    Call_PushCell(client);
    Call_PushCellRef(cooldown);
    Call_Finish(res);

    if (res)
    {
        g_iSprayLimit[client] = GetTime() + cooldown;
    }

    return res;
}

static void Sprays_Reset()
{
    g_iSprays = 0;
}

static bool Sprays_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iSprays);
    kv.GetString("material", g_szSprays[g_iSprays], sizeof(g_szSprays[]));
    kv.GetString("name", g_szSprayName[g_iSprays], sizeof(g_szSprayName[]));
    g_iSprayCooldown[g_iSprays] = kv.GetNum("cooldown", 30);

    if (FileExists(g_szSprays[g_iSprays], true))
    {
        ++g_iSprays;
        return true;
    }

#if defined LOG_NOT_FOUND
    // missing model
    char auth[32], name[32];
    kv.GetString("auth", auth, 32);
    kv.GetString("name", name, 32);
    if (strcmp(auth, "STEAM_ID_INVALID") != 0)
    {
        LogError("Missing spray <%s> -> [%s]", name, g_szSprays[g_iSprays]);
    }
    else
    {
        LogMessage("Skipped spray <%s> -> [%s]", name, g_szSprays[g_iSprays]);
    }
#endif

    return false;
}

static int Sprays_Equip(int client, int id)
{
    int m_iData           = Store_GetDataIndex(id);
    g_iSprayCache[client] = m_iData;
    return 0;
}

static int Sprays_Remove(int client, int id)
{
    g_iSprayCache[client] = -1;
    return 0;
}

static void CreateSpray(int client)
{
    if (!IsPlayerAlive(client))
        return;

    float m_flEye[3];
    GetClientEyePosition(client, m_flEye);

    float m_flView[3];
    GetPlayerEyeViewPoint(client, m_flView);

    float distance = GetVectorDistance(m_flEye, m_flView);

    if (distance > 115.0)
    {
        tPrintToChat(client, "%T", "spray distance", client);
        return;
    }

    StartSprayToAll(client, m_flView);

    Call_StartForward(g_fwdOnClientSpray);
    Call_PushCell(client);
    Call_Finish();
}

static void StartSprayToAll(int client, const float vPos[3])
{
    char model[PLATFORM_MAX_PATH], name[64];
    strcopy(STRING(model), g_szSprays[g_iSprayCache[client]]);
    strcopy(STRING(name), g_szSprayName[g_iSprayCache[client]]);

    int precache = g_iSprayPrecache[g_iSprayCache[client]];
    int cooldown = g_iSprayCooldown[g_iSprayCache[client]];

    Action res = Plugin_Continue;
    Call_StartForward(g_hOnSprayModel);
    Call_PushCell(client);
    Call_PushStringEx(STRING(model), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(STRING(name), SM_PARAM_STRING_UTF8 | SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCellRef(precache);
    Call_PushCellRef(cooldown);
    Call_Finish(res);

    if (res >= Plugin_Handled)
    {
        g_iSprayLimit[client] = GetTime() + cooldown;
        return;
    }

    if (res == Plugin_Continue)
    {
        // copy again
        precache = g_iSprayPrecache[g_iSprayCache[client]];
        cooldown = g_iSprayCooldown[g_iSprayCache[client]];
    }

    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin", vPos);
    TE_WriteNum("m_nIndex", precache);
    TE_SendToAll();

    if (g_bFallbackSprayerSound)
    {
        EmitSoundToAll(")" ... FALLBACK_SPARYER_SOUND, client);
    }
    else
    {
        EmitSoundToAll("items/spraycan_spray.wav", client);
    }

    g_iSprayLimit[client] = GetTime() + cooldown;

    tPrintToChatAll("%t", "spray to all", client, name);
}

static void GetPlayerEyeViewPoint(int client, float m_fPosition[3])
{
    float m_flRotation[3];
    float m_flPosition[3];

    GetClientEyeAngles(client, m_flRotation);
    GetClientEyePosition(client, m_flPosition);

    TR_TraceRayFilter(m_flPosition, m_flRotation, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
    TR_GetEndPosition(m_fPosition);
}

// use for TE hook World decals
bool Spray_IsSpray(int index)
{
    for (int i = 0; i < g_iSprays; ++i)
        if (g_iSprayPrecache[i] == index)
            return true;

    return false;
}

void Spray_OnRunCmd(int client, int &buttons)
{
    if (g_iSprayCache[client] == -1 || !IsPlayerAlive(client))
        return;

    static int lastUse[MAXPLAYERS + 1];
    int        time = GetTime();
    if (time == lastUse[client])
        return;

    lastUse[client] = time;

    if ((buttons & IN_SPEED) && (buttons & IN_USE))
    {
        buttons &= ~IN_SPEED;
        buttons &= ~IN_USE;

        Command_Spray(client, 0);
    }
}

static bool TraceRayDontHitSelf(int entity, int mask, any data)
{
    return (entity != data);
}
#if defined GM_ZE || defined GM_KZ || defined GM_BH || defined GM_SR || defined GM_TT
    #define Module_TPMode
#endif

bool g_bMirror[MAXPLAYERS+1];
bool g_bThirdperson[MAXPLAYERS+1];

static ConVar store_thirdperson_enabled = null;
static ConVar store_thirdperson_enforce = null;
static ConVar mp_forcecamera = null;

void TPMode_InitConVar()
{
    store_thirdperson_enabled = CreateConVar("store_thirdperson_enabled", "1", "Enabled or not third person.", _, true, 0.0, true, 1.0);
    store_thirdperson_enforce = CreateConVar("store_thirdperson_enforce", "1", "Enforce player third person.", _, true, 0.0, true, 1.0);
}

void TPMode_OnPluginStart()
{
#if !defined GM_IS
    ConVar sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
    sv_allow_thirdperson.IntValue = 1;
    sv_allow_thirdperson.AddChangeHook(ConVar_sv_allow_thirdperson);

    mp_forcecamera = FindConVar("mp_forcecamera");
#else
    store_thirdperson_enabled.BoolValue = false;
    store_thirdperson_enforce.BoolValue = false;
#endif

    store_thirdperson_enabled.AddChangeHook(ConVar_store_thirdperson_enabled);

    RegConsoleCmd("sm_tp", Command_TP, "Toggle TP Mode");
    RegConsoleCmd("sm_seeme", Command_Mirror, "Toggle Mirror Mode");

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);

    CreateTimer(0.5, EnforceCamera, _, TIMER_REPEAT);
}

static void ConVar_store_thirdperson_enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!convar.BoolValue || StringToInt(newValue) == 0)
    {
        for (int client = 1; client <= MaxClients; client++)
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            ToggleTp(client, false);
            ToggleMirror(client, false);
        }
    }
}

#if !defined GM_IS
static void ConVar_sv_allow_thirdperson(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.IntValue = 1;
}
#endif

void TPMode_OnClientConnected(int client)
{
    g_bThirdperson[client] = false;
    g_bMirror[client] = false;
}

static Action Command_TP(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

#if !defined Module_TPMode
    if(!IsImmunityClient(client))
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }
#endif

    if (!AllowTP() && !IsImmunityClient(client))
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }

    if(!IsPlayerAlive(client))
    {
        tPrintToChat(client, "%T", "tp dead", client);
        return Plugin_Handled;
    }

    if(g_bMirror[client])
    {
        tPrintToChat(client, "%T", "tp seeme", client);
        return Plugin_Handled;
    }

    ToggleTp(client, !g_bThirdperson[client]);

    return Plugin_Handled;
}

static Action Command_Mirror(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

#if !defined Module_TPMode
    if(!IsImmunityClient(client))
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }
#endif

    if (!AllowTP() && !IsImmunityClient(client))
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }

    if(!IsPlayerAlive(client))
    {
        tPrintToChat(client, "%T", "tp dead", client);
        return Plugin_Handled;
    }

    if(g_bThirdperson[client])
    {
        tPrintToChat(client, "%T", "seeme tp", client);
        return Plugin_Handled;
    }

    if(mp_forcecamera == null)
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }

    ToggleMirror(client, !g_bMirror[client]);

    return Plugin_Handled;
}

static void Event_PlayerSpawn(Event e, const char[] name, bool dontBroadcast)
{
    CreateTimer(0.3, Timer_TPSpawnPost, e.GetInt("userid"));
}

static Action Timer_TPSpawnPost(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);
    if (!client || !IsClientInGame(client) || !IsPlayerAlive(client) || IsFakeClient(client))
        return Plugin_Stop;

    ToggleTp(client, false);
    ToggleMirror(client, false);

    return Plugin_Stop;
}

bool ToggleTp(int client, bool state)
{
    ClientCommand(client, state ? "cam_collision 0; cam_idealpitch 0; cam_idealdist 150; cam_idealdistright 0; cam_idealdistup 0; thirdperson;" : "firstperson");
    g_bThirdperson[client] = state;
    return g_bThirdperson[client];
}

static void ToggleMirror(int client, bool state)
{
    if(state)
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
        mp_forcecamera.ReplicateToClient(client, "1");
    }
    else
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
        char value[6];
        mp_forcecamera.GetString(value, 6);
        mp_forcecamera.ReplicateToClient(client, value);
    }

    g_bMirror[client] = state;
}

void CheckMirror(int client)
{
    if (IsFakeClient(client) || !g_bMirror[client])
        return;

    ToggleMirror(client, false);
}

static bool IsImmunityClient(int client)
{
    AdminId admin = GetUserAdmin(client);
    if (admin == INVALID_ADMIN_ID || admin.ImmunityLevel <= 80)
        return false;

    return true;
}

static bool AllowTP()
{
    if (store_thirdperson_enabled == null)
        return false;

    return store_thirdperson_enabled.BoolValue;
}

static Action EnforceCamera(Handle timer)
{
    if (!store_thirdperson_enforce.BoolValue)
        return Plugin_Continue;

    for(int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || IsFakeClient(i))
            continue;

        // in state -> skipped
        if (g_bThirdperson[i] || g_bMirror[i])
            continue;

        // every think we enforce to firstperson
        ToggleTp(i, false);
    }

    return Plugin_Continue;
}
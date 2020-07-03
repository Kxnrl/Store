#if defined GM_ZE || defined GM_KZ || defined GM_BH || defined GM_SR || defined GM_TT
    #define Module_TPMode
#endif

bool g_bMirror[MAXPLAYERS+1];
bool g_bThirdperson[MAXPLAYERS+1];

static ConVar store_thirdperson_enabled = null;
static ConVar mp_forcecamera = null;

void TPMode_OnPluginStart()
{
    store_thirdperson_enabled = CreateConVar("store_thirdperson_enabled", "1", "Enable or not third person.", _, true, 0.0, true, 1.0);
    store_thirdperson_enabled.AddChangeHook(ConVar_store_thirdperson_enabled);

    mp_forcecamera = FindConVar("mp_forcecamera");

    ConVar sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
    sv_allow_thirdperson.IntValue = 1;
    sv_allow_thirdperson.AddChangeHook(ConVar_sv_allow_thirdperson);

    RegConsoleCmd("sm_tp", Command_TP, "Toggle TP Mode");
    RegConsoleCmd("sm_seeme", Command_Mirror, "Toggle Mirror Mode");

    HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
}

public void ConVar_store_thirdperson_enabled(ConVar convar, const char[] oldValue, const char[] newValue)
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

public void ConVar_sv_allow_thirdperson(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.IntValue = 1;
}

void TPMode_OnClientConnected(int client)
{
    g_bThirdperson[client] = false;
    g_bMirror[client] = false;
}

public Action Command_TP(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;
    
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

public Action Command_Mirror(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

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

public void Event_PlayerSpawn(Event e, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(e.GetInt("userid"));
    ToggleTp(client, false);
    ToggleMirror(client, false);
}

void ToggleTp(int client, bool state)
{
    ClientCommand(client, state ? "thirdperson" : "firstperson");
    g_bThirdperson[client] = state;
}

void ToggleMirror(int client, bool state)
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

bool IsImmunityClient(int client)
{
    AdminId admin = GetUserAdmin(client);
    if (admin == INVALID_ADMIN_ID || admin.ImmunityLevel <= 80)
        return false;

    return true;
}

bool AllowTP()
{
    if (store_thirdperson_enabled == null)
        return false;

    return store_thirdperson_enabled.BoolValue;
}
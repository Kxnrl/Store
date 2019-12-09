#if defined GM_ZE || defined GM_KZ || defined GM_BH || defined GM_SR
    #define Module_TPMode
#endif

bool g_bMirror[MAXPLAYERS+1];
bool g_bThirdperson[MAXPLAYERS+1];

static ConVar store_thirdperson_enabled = null;

void TPMode_OnPluginStart()
{
    store_thirdperson_enabled = CreateConVar("store_thirdperson_enabled", "1", "Enable or not third person.", _, true, 0.0, true, 1.0);
    store_thirdperson_enabled.AddChangeHook(ConVar_store_thirdperson_enabled);


    ConVar sv_allow_thirdperson = FindConVar("sv_allow_thirdperson");
    sv_allow_thirdperson.IntValue = 1;
    sv_allow_thirdperson.AddChangeHook(ConVar_sv_allow_thirdperson);

    RegConsoleCmd("sm_tp", Command_TP, "Toggle TP Mode");
    RegConsoleCmd("sm_seeme", Command_Mirror, "Toggle Mirror Mode");
}

public void ConVar_store_thirdperson_enabled(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!convar.BoolValue)
    {
        for (int client = 1; client <= MaxClients; client++)
        if (IsClientInGame(client) && !IsFakeClient(client))
        CheckClientTP(client);
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
    if(!(GetUserFlagBits(client) & ADMFLAG_ROOT))
    {
        tPrintToChat(client, "%T", "tp not allow", client);
        return Plugin_Handled;
    }
#endif

    if (!store_thirdperson_enabled.BoolValue)
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

    g_bThirdperson[client] = !g_bThirdperson[client];
    ClientCommand(client, g_bThirdperson[client] ? "thirdperson" : "firstperson");

    return Plugin_Handled;
}

public Action Command_Mirror(int client, int args)
{
    if(!client || !IsClientInGame(client))
        return Plugin_Handled;

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
    
    if(!g_bMirror[client])
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
        SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
        SetEntProp(client, Prop_Send, "m_iFOV", 120);
        SendConVarValue(client, FindConVar("mp_forcecamera"), "1");
        g_bMirror[client] = true;
    }
    else
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
        char valor[6];
        GetConVarString(FindConVar("mp_forcecamera"), valor, 6);
        SendConVarValue(client, FindConVar("mp_forcecamera"), valor);
        g_bMirror[client] = false;
    }

    return Plugin_Handled;
}

void CheckClientTP(int client)
{
    if(g_bThirdperson[client])
    {
        ClientCommand(client, "firstperson");
        g_bThirdperson[client] = false;
    }

    if(g_bMirror[client])
    {
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
        SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
        SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
        SetEntProp(client, Prop_Send, "m_iFOV", 90);
        char value[6];
        GetConVarString(FindConVar("mp_forcecamera"), value, 6);
        SendConVarValue(client, FindConVar("mp_forcecamera"), value);
        g_bMirror[client] = false;
    }
}

void TP_OnClientPutInServer(int client)
{
    ClientCommand(client, "firstperson");
    SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
    SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
    SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
    SetEntProp(client, Prop_Send, "m_iFOV", 90);
    char value[6];
    GetConVarString(FindConVar("mp_forcecamera"), value, 6);
    SendConVarValue(client, FindConVar("mp_forcecamera"), value);
}
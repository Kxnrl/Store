#pragma semicolon 1

#define PLUGIN_NAME ""
#define PLUGIN_AUTHOR "yoshino(Maoling)"
#define PLUGIN_DESCRIPTION "Trail Display Settings"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""

#include <sourcemod>
#include <clientprefs>
#include <zephstocks>

new g_HideSettings[MAXPLAYERS+1]={0,...};

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	IdentifyGame();
	RegConsoleCmd("sm_hidetrails", Command_Settings);
	AutoExecConfig();
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("HideTrails_ShouldHide", Native_ShouldHide);

	return APLRes_Success;
}

public Native_ShouldHide(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_HideSettings[client];
}

public OnClientConnected(client)
{
	g_HideSettings[client] = 0;
}

public Action:Command_Settings(client, args)
{
	g_HideSettings[client] = (g_HideSettings[client] == 0 ? 2 : 0);
	return Plugin_Handled;
}

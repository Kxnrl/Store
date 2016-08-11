#pragma semicolon 1

#define PLUGIN_NAME "Thirdperson Mode + SeeMe"
#define PLUGIN_AUTHOR "Zephyrus, maoling ( shAna.xQy )"
#define PLUGIN_DESCRIPTION "Thirdperson mode"
#define PLUGIN_VERSION " 1.1 - [CG] Community Version "
#define PLUGIN_URL ""

#include <sourcemod>
#include <sdktools>
#include <zephstocks>

new bool:g_bThirdperson[MAXPLAYERS+1] = {false,...};
new bool:mirror[MAXPLAYERS + 1] = { false, ... };
Handle mp_forcecamera;

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
	HookEvent("player_death", Event_PlayerSpawn);
	RegConsoleCmd("sm_tp", Command_TP, "Toggle TP Mode");
	mp_forcecamera = FindConVar("mp_forcecamera");
	RegConsoleCmd("sm_seeme", Cmd_Mirror, "Toggle Mirror Mode");
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("IsPlayerInTP", Native_IsPlayerInTP);
	CreateNative("TogglePlayerTP", Native_TogglePlayerTP);

	return APLRes_Success;
}

public Native_IsPlayerInTP(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	bool active;
	if(g_bThirdperson[client] || mirror[client])
		active = true;
	return active;
}

public Native_TogglePlayerTP(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	g_bThirdperson[client] = !g_bThirdperson[client];
	ToggleThirdperson(client);
}

public OnClientConnected(client)
{
	g_bThirdperson[client] = false;
}

public Action:Command_TP(client, args)
{
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		PrintToConsole(client, "Success");
	}
	else
	{
		if(FindPluginByFile("ct.smx") || FindPluginByFile("hg.smx") || FindPluginByFile("ctban.smx"))
		{
			ReplyToCommand(client, "[CG] 当前模式不允许使用TP");
			return Plugin_Handled;
		}
	}
	

	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[CG] 你已经嗝屁了,还想开TP?");
		return Plugin_Handled;
	}
	
	if(mirror[client])
	{
		ReplyToCommand(client, "[CG] 你已经开了SeeMe,还想开TP?");
		return Plugin_Handled;
	}

	g_bThirdperson[client] = !g_bThirdperson[client];
	ToggleThirdperson(client);
	return Plugin_Handled;
}


public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(g_bThirdperson[client])
	{
		SetThirdperson(client, false);
		g_bThirdperson[client] = !g_bThirdperson[client];
	}
	
	if(mirror[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		decl String:valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);
		mirror[client] = false;
	}
}

public Action Cmd_Mirror(int client, int args)
{
	if (!IsPlayerAlive(client))
	{
		ReplyToCommand(client, "[CG] 你已经嗝屁了,还想开SeeMe?");
		return Plugin_Handled;
	}
	
	if (g_bThirdperson[client])
	{
		ReplyToCommand(client, "[CG] 你已经开了TP,还想开SeeMe?");
		return Plugin_Handled;
	}
	
	if (!mirror[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
		SendConVarValue(client, mp_forcecamera, "1");
		mirror[client] = true;
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		decl String:valor[6];
		GetConVarString(mp_forcecamera, valor, 6);
		SendConVarValue(client, mp_forcecamera, valor);
		mirror[client] = false;
	}
	return Plugin_Handled;
}

stock ToggleThirdperson(client)
{
	if(g_bThirdperson[client])
		SetThirdperson(client, true);
	else
		SetThirdperson(client, false);
}

stock SetThirdperson(client, bool:tp)
{
	if(g_bCSGO)
	{
		static Handle:m_hAllowTP = INVALID_HANDLE;
		if(m_hAllowTP == INVALID_HANDLE)
			m_hAllowTP = FindConVar("sv_allow_thirdperson");

		SetConVarInt(m_hAllowTP, 1);

		if(tp)
		{
			ClientCommand(client, "thirdperson");
		}
		else
		{
			ClientCommand(client, "firstperson");
		}
	}
}
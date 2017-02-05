bool g_bHideMode[MAXPLAYERS+1];
bool g_bMirror[MAXPLAYERS+1];
bool g_bThirdperson[MAXPLAYERS+1];

#include "store/modules/skin.sp"
#include "store/modules/neon.sp"
#include "store/modules/aura.sp"
#include "store/modules/hats.sp"
#include "store/modules/part.sp"
#include "store/modules/trail.sp"

void Players_OnPluginStart()
{
	if(g_bGameModePR)
		return;
	
	Store_RegisterHandler("playerskin", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);
	
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

	RegConsoleCmd("sm_tp", Command_TP, "Toggle TP Mode");
	RegConsoleCmd("sm_seeme", Command_Mirror, "Toggle Mirror Mode");
	RegConsoleCmd("sm_arm", Command_Arm, "Draw Player Arms");
	RegAdminCmd("sm_arms", Command_Arms, ADMFLAG_ROOT, "Fixed Player Arms");

	if(!g_bGameModeKZ)
		Store_RegisterHandler("hat", "model", Hats_OnMapStart, Hats_Reset, Hats_Config, Hats_Equip, Hats_Remove, true);

	if(g_bGameModeHZ || g_bGameModeZE || g_bGameModeKZ)
		return;

	Store_RegisterHandler("trail", "material", Trails_OnMapStart, Trails_Reset, Trails_Config, Trails_Equip, Trails_Remove, true);
	Store_RegisterHandler("Aura", "Name", Aura_OnMapStart, Aura_Reset, Aura_Config, Aura_Equip, Aura_Remove, true);
	Store_RegisterHandler("neon", "ID", Neon_OnMapStart, Neon_Reset, Neon_Config, Neon_Equip, Neon_Remove, true); 
	Store_RegisterHandler("Particles", "Name", Part_OnMapStart, Part_Reset, Part_Config, Part_Equip, Part_Remove, true);

	RegConsoleCmd("sm_hide", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hidetrail", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hideneon", Command_Hide, "Hide Trail and Neon");
}

void Players_OnClientConnected(int client)
{
	g_bHideMode[client] = false;
	g_bThirdperson[client] = false;
	g_bMirror[client] = false;
}

public void CG_OnRoundEnd(int winner)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		g_iClientAura[client] = 0;
		g_iClientNeon[client] = 0;
		g_iClientPart[client] = 0;
	}
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	RequestFrame(OnClientSpawn, client);

	if(g_bGameModeZE && GetClientTeam(client) == 2)
		return Plugin_Continue;

	Store_PreSetClientModel(client);
	CreateTimer(1.0, Timer_SetPlayerArms, GetClientUserId(client));
	
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	CheckClientTP(client);
	
	RequestFrame(OnClientDeath, client);
	
	if(g_bGameModeKZ)
		return Plugin_Continue;

	if(!g_bGameModeHZ && !g_bGameModeZE)
	{
		Store_RemoveClientAura(client);
		Store_RemoveClientNeon(client);
		Store_RemoveClientPart(client);
	}

	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
	{
		Store_RemoveClientHats(client, i);

		if(!g_bGameModeHZ && !g_bGameModeZE)
			Store_RemoveClientTrail(client, i);
	}
	
	return Plugin_Continue;
}

public void CG_OnClientTeam(int client)
{
	if(g_bGameModePR)
		return;
	RequestFrame(OnClientTeam, client);
}

public void OnClientSpawn(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || g_bGameModeKZ)
		return;

	if(!g_bGameModeHZ && !g_bGameModeZE)
	{
		Store_SetClientTrail(client);
		Store_SetClientAura(client);
		Store_SetClientNeon(client);
		Store_SetClientPart(client);
	}
	
	Store_SetClientHat(client);
}

public void OnClientDeath(int client)
{
	g_bHasPlayerskin[client] = false;
}

public void OnClientTeam(int client)
{
	if(g_bGameModePR || g_bGameModeKZ || !IsClientInGame(client))
		return;

	if(!IsPlayerAlive(client))
	{
		Store_RemoveClientAura(client);
		Store_RemoveClientNeon(client);
		Store_RemoveClientPart(client);
		
		for(int i = 0; i < STORE_MAX_SLOTS; ++i)
			Store_RemoveClientHats(client, i);
	}

	if(g_bGameModeMG && IsPlayerAlive(client))
	{
		Store_PreSetClientModel(client);
		CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
	}
}

public Action Command_Hide(int client, int args)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	g_bHideMode[client] = !g_bHideMode[client];
	tPrintToChat(client, "'\x04!hidetrail\x01' 你已%s屏蔽足迹和霓虹", g_bHideMode[client] ? "\x04开启\x01" : "\x07关闭\x01");

	return Plugin_Handled;
}

public Action Command_TP(int client, int args)
{
	if((g_bGameModeTT || g_bGameModeHG || g_bGameModeJB || g_bGameModePR || g_bGameModeHZ) && CG_GetClientGId(client) != 9999)
	{
		tPrintToChat(client, "当前模式不允许使用TP");
		return Plugin_Handled;
	}

	if(!IsPlayerAlive(client))
	{
		tPrintToChat(client, "你已经嗝屁了,还想开TP?");
		return Plugin_Handled;
	}
	
	if(g_bMirror[client])
	{
		tPrintToChat(client, "你已经开了SeeMe,还想开TP?");
		return Plugin_Handled;
	}

	g_bThirdperson[client] = !g_bThirdperson[client];
	ToggleThirdperson(client);

	return Plugin_Handled;
}


public Action Command_Mirror(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		tPrintToChat(client, "你已经嗝屁了,还想开SeeMe?");
		return Plugin_Handled;
	}
	
	if(g_bThirdperson[client])
	{
		tPrintToChat(client, "你已经开了TP,还想开SeeMe?");
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

public Action Command_Arm(int client, int args)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", true);
	
	return Plugin_Handled;
}

public Action Command_Arms(int client, int args)
{
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	if(g_bGameModeZE && GetClientTeam(client) == 2)
		return Plugin_Handled;
	
	Store_PreSetClientModel(client);
	
	CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
	
	return Plugin_Handled;
}
#define Module_Player

void Players_OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);

#if defined Module_Skin
	Skin_OnPluginStart();
#endif

#if defined Module_Hats
	Store_RegisterHandler("hat", "model", Hats_OnMapStart, Hats_Reset, Hats_Config, Hats_Equip, Hats_Remove, true);
#endif

#if defined Module_Neon
	Store_RegisterHandler("neon", "ID", Neon_OnMapStart, Neon_Reset, Neon_Config, Neon_Equip, Neon_Remove, true); 
#endif

#if defined Module_Aura
	Store_RegisterHandler("Aura", "Name", Aura_OnMapStart, Aura_Reset, Aura_Config, Aura_Equip, Aura_Remove, true);
#endif

#if defined Module_Part
	Store_RegisterHandler("Particles", "Name", Part_OnMapStart, Part_Reset, Part_Config, Part_Equip, Part_Remove, true);
#endif

#if defined Module_Trail
	Store_RegisterHandler("trail", "material", Trails_OnMapStart, Trails_Reset, Trails_Config, Trails_Equip, Trails_Remove, true);
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
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsFakeClient(client))
		return Plugin_Continue;

	RequestFrame(OnClientSpawnPost, client);

#if defined Module_Skin
	g_szDeathVoice[client][0] = '\0';
	Store_PreSetClientModel(client);
	CreateTimer(0.0, Timer_KillPreview, client);
#endif

	return Plugin_Continue;
}

public void OnClientSpawnPost(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

#if defined Module_Trail
	Store_SetClientTrail(client);
#endif

#if defined Module_Aura
	Store_SetClientAura(client);
#endif

#if defined Module_Neon
	Store_SetClientNeon(client);
#endif

#if defined Module_Part
	Store_SetClientPart(client);
#endif

#if defined Module_Hats	
	Store_SetClientHat(client);
#endif
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(IsFakeClient(client))
		return Plugin_Continue;

#if defined Module_Skin
	FirstPersonDeathCamera(client);
#endif

#if defined Module_Aura
	Store_RemoveClientAura(client);
#endif

#if defined Module_Neon
	Store_RemoveClientNeon(client);
#endif

#if defined Module_Part
	Store_RemoveClientPart(client);
#endif

	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
	{
#if defined Module_Hats
		Store_RemoveClientHats(client, i);
#endif

#if defined Module_Trail
		Store_RemoveClientTrail(client, i);
#endif
	}

	return Plugin_Continue;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	g_iClientTeam[client] = 2;

#if defined Module_Hats
	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
		Store_RemoveClientHats(client, i);
#endif
}

public void CG_OnClientTeam(int client, int oldteam, int newteam)
{
	g_iClientTeam[client] = newteam;
	
#if defined TeamArms
	RequestFrame(OnClientTeamPost, client);
#endif
}

public void OnClientTeamPost(int client)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return;

	Store_PreSetClientModel(client);
	CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
}

public __pl_ZombieEscape_SetNTVOptional()
{
	MarkNativeAsOptional("ZE_GetPlayerOnlines");
	MarkNativeAsOptional("ZE_GetPlayerScores");
	MarkNativeAsOptional("ZE_GetPlayerPoints");
	MarkNativeAsOptional("ZE_GetPlayerRank");
	MarkNativeAsOptional("ZE_GetPlayerPass");
	MarkNativeAsOptional("ZE_GetPlayerDamage");
	MarkNativeAsOptional("ZE_SetPlayerPoints");
	MarkNativeAsOptional("ZE_StatsEnable");
	MarkNativeAsOptional("ZE_IsClientCommander");
	MarkNativeAsOptional("ZE_GetCommander");
	MarkNativeAsOptional("ZE_IsClientTerminator");
	MarkNativeAsOptional("ZE_GetTerminatorType");
}

native ZE_GetPlayerOnlines(int client);
native ZE_GetPlayerScores(int client);
native ZE_GetPlayerPoints(int client);
native ZE_GetPlayerCredits(int client);
native ZE_GetPlayerRank(int client);
native ZE_GetPlayerPass(int client);
native ZE_GetPlayerDamage(int client);
native ZE_SetPlayerPoints(int client, int Point);
native ZE_SetPlayerCredits(int client, int Point);
native bool ZE_StatsEnable();
forward Action ZE_OnClientLoaded(int client);
forward int ZE_GetClientGroupStats(int client);

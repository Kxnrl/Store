#define Module_Skin

#define Model_ZE_Newbee "models/player/custom_player/legacy/tm_leet_variant_classic.mdl"
#define Arms_ZE_NewBee "models/weapons/t_arms_anarchist.mdl"

enum PlayerSkin
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szArms[PLATFORM_MAX_PATH],
	String:szSound[PLATFORM_MAX_PATH],
	iTeam
}

PlayerSkin g_ePlayerSkins[STORE_MAX_ITEMS][PlayerSkin];

int g_iPlayerSkins = 0;
int g_iPreviewTimes[MAXPLAYERS+1];
int g_iPreviewModel[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
int g_iCameraRef[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};
bool g_bSpecJoinPending[MAXPLAYERS+1];
char g_szDeathVoice[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char g_szDeathModel[MAXPLAYERS+1][PLATFORM_MAX_PATH];
ConVar spec_freeze_time;
ConVar mp_round_restart_delay;

void Skin_OnPluginStart()
{
	AddNormalSoundHook(Hook_NormalSound);

	CheckGameItemsTxt();
	
	Store_RegisterHandler("playerskin", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);

	RegConsoleCmd("sm_arm", Command_Arm, "Draw Player Arms");
	RegAdminCmd("sm_arms", Command_Arms, ADMFLAG_ROOT, "Fixed Player Arms");
	
	//DEATH CAMERA CCVAR
	spec_freeze_time = FindConVar("spec_freeze_time");
	HookConVarChange(spec_freeze_time, Skin_OnConVarChanged);
	SetConVarString(spec_freeze_time, "-1.0", true);
	
	mp_round_restart_delay = FindConVar("mp_round_restart_delay");
	HookConVarChange(mp_round_restart_delay, Skin_OnConVarChanged);
	SetConVarString(mp_round_restart_delay, "12", true);
}

public void Skin_OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == spec_freeze_time)
		SetConVarString(spec_freeze_time, "-1.0", true);
	
	if(convar == mp_round_restart_delay)
		SetConVarString(mp_round_restart_delay, "12", true);
}

void Skin_OnClientDisconnect(int client)
{
	if(g_iPreviewModel[client] != INVALID_ENT_REFERENCE)
		CreateTimer(0.0, Timer_KillPreview, client);
	
	if(g_iCameraRef[client] != INVALID_ENT_REFERENCE)
		CreateTimer(0.0, Timer_ClearCamera, client);
	
	if(g_bSpecJoinPending[client])
		g_bSpecJoinPending[client] = false;
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

#if defined GM_ZE	
	if(g_iClientTeam[client] == 2)
		return Plugin_Handled;
#endif

	Store_PreSetClientModel(client);

	CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
	
	return Plugin_Handled;
}

public int PlayerSkins_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);
	KvGetString(kv, "sound", g_ePlayerSkins[g_iPlayerSkins][szSound], PLATFORM_MAX_PATH);

#if defined Global_Skin
	g_ePlayerSkins[g_iPlayerSkins][iTeam] = Global_Skin;
#else
	g_ePlayerSkins[g_iPlayerSkins][iTeam] = KvGetNum(kv, "team");
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
		PrecacheModel2(g_ePlayerSkins[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szModel]);

		if(g_ePlayerSkins[i][szArms][0] != 0)
		{
			PrecacheModel2(g_ePlayerSkins[i][szArms], true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
		}
		
		if(g_ePlayerSkins[i][szArms][0] != 0)
		{
			PrecacheModel2(g_ePlayerSkins[i][szArms], true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
		}

		if(g_ePlayerSkins[i][szSound][0] != 0)
		{
			Format(szPath, 256, "sound/%s", g_ePlayerSkins[i][szSound]);
			if(FileExists(szPath, true))
			{
				Format(szPathStar, 256, "*%s", g_ePlayerSkins[i][szSound]);
				AddToStringTable(FindStringTable("soundprecache"), szPathStar);
				Downloader_AddFileToDownloadsTable(szPath);
			}
		}
	}

#if defined GM_ZE
	if(FileExists(Model_ZE_Newbee))
	{
		PrecacheModel2(Model_ZE_Newbee, true);
		PrecacheModel2(Arms_ZE_NewBee, true);
		Downloader_AddFileToDownloadsTable(Model_ZE_Newbee);
	}
#endif
}

public void PlayerSkins_Reset()
{
	g_iPlayerSkins = 0;
}

public int PlayerSkins_Equip(int client, int id)
{
	if(IsClientInGame(client))
		tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

public int PlayerSkins_Remove(int client, int id)
{
	if(IsClientInGame(client))
		tPrintToChat(client, "%T", "PlayerSkins Settings Changed", client);

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

void Store_PreSetClientModel(int client)
{
#if defined GM_ZE
	if(g_iClientTeam[client] == 2)
		return;
#endif
	
	int m_iEquipped = Store_GetEquippedItem(client, "playerskin", g_iClientTeam[client]-2);

	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
		if(g_ePlayerSkins[m_iData][szSound][0] != 0)
			Format(g_szDeathVoice[client], PLATFORM_MAX_PATH, "*%s", g_ePlayerSkins[m_iData][szSound]);
	}
#if defined GM_ZE
	else
	{
		if(IsModelPrecached(Model_ZE_Newbee) && IsModelPrecached(Arms_ZE_NewBee))
			Store_SetClientModel(client, Model_ZE_Newbee, Arms_ZE_NewBee);
	}
#endif
}

void Store_SetClientModel(int client, const char[] model, const char[] arms = "null")
{
	if(!IsModelPrecached(model))
		PrecacheModel2(model, true);

	SetEntityModel(client, model);

	if(!StrEqual(arms, "null"))
	{
		if(!IsModelPrecached(arms))
			PrecacheModel2(arms, true);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	}
	
	strcopy(g_szDeathModel[client], 256, model);

#if defined Module_Hats
	Store_SetClientHat(client);
#endif
}

public Action Hook_NormalSound(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &client, int &channel, float &volume, int &level, int &pitch, int &flags)
{
	if(channel != SNDCHAN_VOICE || !(1 <= client <= MaxClients) || !IsClientInGame(client))
		return Plugin_Continue;
	
#if defined GM_ZE
	if(g_iClientTeam[client] == 2)
		return Plugin_Continue;
#endif
	
	if(g_szDeathVoice[client][0] == '\0')
		return Plugin_Continue;

	if	( 
			StrEqual(sample, "player/death1.wav", false)||
			StrEqual(sample, "player/death2.wav", false)||
			StrEqual(sample, "player/death3.wav", false)||
			StrEqual(sample, "player/death4.wav", false)||
			StrEqual(sample, "player/death5.wav", false)
		)
		{
			RequestFrame(BroadcastDeathSound, client);
			return Plugin_Stop;
		}

	return Plugin_Continue;
}

void BroadcastDeathSound(int client)
{
	if(!IsClientInGame(client))
		return;

	EmitSoundToAll(g_szDeathVoice[client], client, SNDCHAN_VOICE, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, client);
}

public Action Timer_FixPlayerArms(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsPlayerAlive(client))
		return Plugin_Stop;

	ResetPlayerArms(client);

	return Plugin_Stop;
}

void ResetPlayerArms(int client)
{
	float delay = 2.0;
	if(g_eClients[client][iId] == 1) delay = 0.1;
	
	ResetClientWeaponBySlot(client, 0, delay);
	ResetClientWeaponBySlot(client, 1, delay);
	while(ResetClientWeaponBySlot(client, 2, delay)){}
	while(ResetClientWeaponBySlot(client, 3, delay)){}
	while(ResetClientWeaponBySlot(client, 4, delay)){}
}

public Action Timer_GiveWeapon(Handle timer, Handle pack)
{
	ResetPack(pack);
	int client = ReadPackCell(pack);
	if(!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	char weapon[32];
	ReadPackString(pack, weapon, 32);
	GivePlayerItem(client, weapon);

	return Plugin_Stop;
}

bool ResetClientWeaponBySlot(int client, int slot, float giveDelay)
{
	int weapon = GetPlayerWeaponSlot(client, slot);

	if(weapon == -1 || !IsValidEdict(weapon))
		return false;

	char classname[32];
	GetWeaponClassname(weapon, classname, 32);
	RemovePlayerItem(client, weapon);
	AcceptEntityInput(weapon, "Kill");

	Handle hPack;
	CreateDataTimer(giveDelay, Timer_GiveWeapon, hPack, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(hPack, client);
	WritePackString(hPack, classname);

	return true;
}

void GetWeaponClassname(int weapon, char[] classname, int maxLen)
{
	GetEdictClassname(weapon, classname, maxLen);
	switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
	{
		case 60: strcopy(classname, maxLen, "weapon_m4a1_silencer");
		case 61: strcopy(classname, maxLen, "weapon_usp_silencer");
		case 63: strcopy(classname, maxLen, "weapon_cz75a");
		case 64: strcopy(classname, maxLen, "weapon_revolver");
	}
}

void Store_PreviewSkin(int client, int itemid)
{
	int m_iViewModel = CreateEntityByName("prop_dynamic_override"); //prop_physics_multiplayer
	char m_szTargetName[32];
	Format(m_szTargetName, 32, "Store_Preview_%d", m_iViewModel);
	DispatchKeyValue(m_iViewModel, "targetname", m_szTargetName);
	DispatchKeyValue(m_iViewModel, "spawnflags", "64");
	DispatchKeyValue(m_iViewModel, "model", g_eItems[itemid][szUniqueId]);
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

	CreateTimer(30.0, Timer_KillPreview, client);

	tPrintToChat(client, "%T", "Chat Preview", client);
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
	if(ent == EntRefToEntIndex(g_iPreviewModel[client]))
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
	if(g_iPreviewModel[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(g_iPreviewModel[client]);
	
		if(IsValidEdict(entity))
		{
			char m_szName[32];
			GetEntPropString(entity, Prop_Data, "m_iName", m_szName, 32);
			if(StrContains(m_szName, "Store_Preview_", false) == 0)
			{
				SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Preview);
				AcceptEntityInput(entity, "Kill");
			}
		}
	}
	g_iPreviewModel[client] = INVALID_ENT_REFERENCE;
	
	return Plugin_Stop;
}

void CheckGameItemsTxt()
{
	Handle kv = CreateKeyValues("items_game");
	
	if(!FileToKeyValues(kv, "scripts/items/items_game.txt"))
	{
		LogError("Unable to open/read file at 'scripts/items/items_game.txt'.");
		CloseHandle(kv);
		return;
	}
	
	if(!KvJumpToKey(kv, "items"))
	{
		LogError("Unable to read key 'items'.");
		CloseHandle(kv);
		return;
	}

	bool del = false;

	if(KvJumpToKey(kv, "5028"))
	{
		KvDeleteThis(kv);
		LogMessage("Deleted 'scripts/items/items_game.txt' key '5028'");
		KvRewind(kv);
		KvJumpToKey(kv, "items");
		del = true;
	}
	
	if(KvJumpToKey(kv, "5029"))
	{
		KvDeleteThis(kv);
		LogMessage("Deleted 'scripts/items/items_game.txt' key '5028'");
		del = true;
	}

	KvRewind(kv);
	
	if(!del)
	{
		LogMessage("'scripts/items/items_game.txt' is lastest verison");
		CloseHandle(kv);
		return;
	}

	if(KeyValuesToFile(kv, "scripts/items/items_game.txt"))
	{
		LogMessage("Updated 'scripts/items/items_game.txt' successfully. - Restart Server");
		CreateTimer(10.0, Timer_Shutdown);
	}
	else
		LogError("Unable to save file at 'scripts/items/items_game.txt'.");

	CloseHandle(kv);
}

public Action Timer_Shutdown(Handle timer)
{
	ServerCommand("quit");
}

void FirstPersonDeathCamera(Handle pack)
{
	int client = ReadPackCell(pack);
	int attacker = ReadPackCell(pack);
	CloseHandle(pack);

	if(!IsClientInGame(client) || g_iClientTeam[client] < 2 || IsPlayerAlive(client))
		return;

	if(IsValidClient(attacker))
		CreateTimer(0.2, Timer_UpdateDeathModel, client);

#if !defined GM_TT	
	int m_iRagdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");

	if(m_iRagdoll < 0)
		return;

	SpawnCamAndAttach(client, m_iRagdoll);
#endif
}

#if !defined GM_TT
bool SpawnCamAndAttach(int client, int ragdoll)
{
	char m_szModel[32];
	Format(m_szModel, 32, "models/blackout.mdl"); //
	PrecacheModel(m_szModel, true);

	char m_szTargetName[32]; 
	Format(m_szTargetName, 32, "ragdoll%d", client);
	DispatchKeyValue(ragdoll, "targetname", m_szTargetName);

	int iEntity = CreateEntityByName("prop_dynamic");
	if(iEntity == -1)
		return false;

	char m_szCamera[32]; 
	Format(m_szCamera, 32, "ragdollCam%d", iEntity);

	DispatchKeyValue(iEntity, "targetname", m_szCamera);
	DispatchKeyValue(iEntity, "parentname", m_szTargetName);
	DispatchKeyValue(iEntity, "model",	  m_szModel);
	DispatchKeyValue(iEntity, "solid",	  "0");
	DispatchKeyValue(iEntity, "rendermode", "10"); // dont render
	DispatchKeyValue(iEntity, "disableshadows", "1"); // no shadows

	float m_fAngles[3]; 
	GetClientEyeAngles(client, m_fAngles);
	
	char m_szCamAngles[64];
	Format(m_szCamAngles, 64, "%f %f %f", m_fAngles[0], m_fAngles[1], m_fAngles[2]);

	DispatchKeyValue(iEntity, "angles", m_szCamAngles);

	SetEntityModel(iEntity, m_szModel);
	DispatchSpawn(iEntity);

	SetVariantString(m_szTargetName);
	AcceptEntityInput(iEntity, "SetParent", iEntity, iEntity, 0);

	SetVariantString("facemask");
	AcceptEntityInput(iEntity, "SetParentAttachment", iEntity, iEntity, 0);

	AcceptEntityInput(iEntity, "TurnOn");

	SetClientViewEntity(client, iEntity);
	g_iCameraRef[client] = EntIndexToEntRef(iEntity);
	
	FadeScreenBlack(client);

	CreateTimer(10.0, Timer_ClearCamera, client);

	return true;
}
#endif

public Action Timer_ClearCamera(Handle timer, int client)
{
	if(g_iCameraRef[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(g_iCameraRef[client]);

		if(IsValidEdict(entity))
		{
			char m_szName[32];
			GetEntPropString(entity, Prop_Data, "m_iName", m_szName, 32);
			if(!StrContains(m_szName, "ragdollCam", false))
				AcceptEntityInput(entity, "Kill");
		}

		if(IsClientInGame(client))
		{
			SetClientViewEntity(client, client);
#if !defined GM_TT
			FadeScreenWhite(client);
#endif
		}
	}

	g_iCameraRef[client] = INVALID_ENT_REFERENCE;

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

#if !defined GM_TT

#define FFADE_IN		0x0001		// Just here so we don't pass 0 into the function
#define FFADE_OUT		0x0002		// Fade out (not in)
#define FFADE_MODULATE	0x0004		// Modulate (don't blend)
#define FFADE_STAYOUT	0x0008		// ignores the duration, stays faded out until new ScreenFade message received
#define FFADE_PURGE		0x0010		// Purges all other fades, replacing them with this one

void FadeScreenBlack(int client)
{
	Handle pb = StartMessageOne("Fade", client);
	PbSetInt(pb, "duration", 3072);
	PbSetInt(pb, "hold_time", 3072);
	PbSetInt(pb, "flags", FFADE_OUT|FFADE_PURGE|FFADE_STAYOUT);
	PbSetColor(pb, "clr", {0, 0, 0, 255});
	EndMessage();
}

void FadeScreenWhite(int client)
{
	Handle pb = StartMessageOne("Fade", client);
	PbSetInt(pb, "duration", 1536);
	PbSetInt(pb, "hold_time", 1536);
	PbSetInt(pb, "flags", FFADE_IN|FFADE_PURGE);
	PbSetColor(pb, "clr", {0, 0, 0, 0});
	EndMessage();
}
#endif

public Action Timer_UpdateDeathModel(Handle timer, int client)
{
	if(!IsValidClient(client) || IsPlayerAlive(client))
		return;

	if(g_szDeathModel[client][0] == '\0')
		return;

	char emodel[256], m_szQuery[512];
	SQL_EscapeString(g_hDatabase, g_szDeathModel[client], emodel, 256);
	Format(m_szQuery, 512, "INSERT INTO `playertrack_deathmodel` VALUES ('%d', '%d', '%s', unix_timestamp())", CG_GetServerId(), CG_GetClientId(client), emodel);
	SQL_TVoid(g_hDatabase, m_szQuery);
	g_szDeathModel[client][0] = '\0';
}
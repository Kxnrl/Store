#define Model_ZE_Newbee "models/player/custom_player/legacy/tm_leet_variant_classic.mdl"
#define Arms_ZE_NewBee "models/weapons/t_arms_anarchist.mdl"

enum PlayerSkin
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szArms[PLATFORM_MAX_PATH],
	iTeam,
}

PlayerSkin g_ePlayerSkins[STORE_MAX_ITEMS][PlayerSkin];

int g_iPlayerSkins = 0;
int g_iPreviewTimes[MAXPLAYERS+1];
int g_iPreviewModel[MAXPLAYERS+1];
bool g_bHasPlayerskin[MAXPLAYERS+1];

public int PlayerSkins_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);

	g_ePlayerSkins[g_iPlayerSkins][iTeam] = KvGetNum(kv, "team");
	
	if(g_eGameMode == GameMode_TTT)
		g_ePlayerSkins[g_iPlayerSkins][iTeam] = 2;
	
	if(g_eGameMode == GameMode_Zombie || g_eGameMode == GameMode_DeathRun)
		g_ePlayerSkins[g_iPlayerSkins][iTeam] = 3;
	
	if(FileExists(g_ePlayerSkins[g_iPlayerSkins][szModel], true))
	{
		++g_iPlayerSkins;
		return true;
	}

	return false;
}

public void PlayerSkins_OnMapStart()
{
	for(int i = 0; i < g_iPlayerSkins; ++i)
	{
		PrecacheModel2(g_ePlayerSkins[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szModel]);

		if(g_ePlayerSkins[i][szArms][0] != 0)
		{
			PrecacheModel2(g_ePlayerSkins[i][szArms], true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
		}
	}

	if(g_eGameMode == GameMode_Zombie)
	{
		if(FileExists(Model_ZE_Newbee))
		{
			PrecacheModel2(Model_ZE_Newbee, true);
			PrecacheModel2(Arms_ZE_NewBee, true);
			Downloader_AddFileToDownloadsTable(Model_ZE_Newbee);
		}
	}
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
	int m_iEquipped = Store_GetEquippedItem(client, "playerskin", GetClientTeam(client)-2);

	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);
		if(StrContains(g_ePlayerSkins[m_iData][szModel], "cybertech") != -1 && CG_GetClientId(client) != 1)
			CreateTimer(5.0, Timer_KickClient, GetClientOfUserId(client), TIMER_FLAG_NO_MAPCHANGE);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
	}
	else if(g_eGameMode == GameMode_Zombie)
	{
		if(IsModelPrecached(Model_ZE_Newbee) && IsModelPrecached(Arms_ZE_NewBee))
			Store_SetClientModel(client, Model_ZE_Newbee, Arms_ZE_NewBee);
	}
}

void Store_SetClientModel(int client, const char[] model, const char[] arms = "null")
{
	if(!StrEqual(arms, "null"))
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	
	if(!IsModelPrecached(model))
		PrecacheModel2(model, true);

	SetEntityModel(client, model);

	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, 128);
	
	if(g_eGameMode != GameMode_Zombie)
		g_bHasPlayerskin[client] = true;
	else if(!StrEqual(model, Model_ZE_Newbee))
		g_bHasPlayerskin[client] = true;

	if(!StrEqual(arms, "null") && !StrEqual(currentmodel, arms))
	{
		if(!IsModelPrecached(arms))
			PrecacheModel2(arms, true);
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	}
	
	Store_SetClientHat(client);
}

public Action Timer_SetPlayerArms(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;

	if(g_eGameMode == GameMode_Zombie && GetClientTeam(client) != 3)
		return Plugin_Stop;

	Store_PreSetClientModel(client);

	return Plugin_Stop;
}

public Action Timer_FixPlayerArms(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;
	
	if(g_eGameMode == GameMode_Zombie)
		if(GetClientTeam(client) != 3)
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

stock void GetWeaponClassname(int weapon, char[] classname, int maxLen)
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

	SetVariantString("run_upper_knife");

	AcceptEntityInput(m_iViewModel, "SetAnimation");
	AcceptEntityInput(m_iViewModel, "Enable");

	int offset = GetEntSendPropOffs(m_iViewModel, "m_clrGlow");
	SetEntProp(m_iViewModel, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(m_iViewModel, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(m_iViewModel, Prop_Send, "m_flGlowMaxDist", 1000.0);

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
	
	g_iPreviewTimes[client] = GetTime()+60;
	g_iPreviewModel[client] = m_iViewModel;

	SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_Preview);

	CreateTimer(30.0, Timer_KillPreview, client);

	tPrintToChat(client, "%T", "Chat Preview", client);
}

public Action Hook_SetTransmit_Preview(int ent, int client)
{
	if(ent == g_iPreviewModel[client])
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action Timer_KillPreview(Handle timer, int client)
{
	if(g_iPreviewModel[client] > MaxClients && IsValidEdict(g_iPreviewModel[client]))
	{
		char m_szName[32];
		GetEntPropString(g_iPreviewModel[client], Prop_Data, "m_iName", m_szName, 32);
		if(StrContains(m_szName, "Store_Preview_", false) == 0)
		{
			SetEntProp(g_iPreviewModel[client], Prop_Send, "m_bShouldGlow", false, true);
			SDKUnhook(g_iPreviewModel[client], SDKHook_SetTransmit, Hook_SetTransmit_Preview);
			AcceptEntityInput(g_iPreviewModel[client], "Kill");
		}
	}
	g_iPreviewModel[client] = -1;
}
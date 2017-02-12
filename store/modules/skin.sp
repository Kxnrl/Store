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
bool g_bHasPlayerskin[MAXPLAYERS+1];

public int PlayerSkins_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);

	g_ePlayerSkins[g_iPlayerSkins][iTeam] = KvGetNum(kv, "team");
	
	if(g_bGameModeTT || g_bGameModeJB)
		g_ePlayerSkins[g_iPlayerSkins][iTeam] = 2;
	
	if(g_bGameModeZE || g_bGameModeDR)
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

	if(g_bGameModeZE)
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
		tPrintToChat(client, "%t", "PlayerSkins Settings Changed");

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

public int PlayerSkins_Remove(int client, int id)
{
	if(IsClientInGame(client))
		tPrintToChat(client, "%t", "PlayerSkins Settings Changed");

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
	else if(!g_bGameModeHZ)
	{
		if(g_bGameModeZE || g_bGameModeTT)
		{
			int m_iData;
			switch(GetRandomInt(2, 3))
			{
				case 2:
				{
					m_iData = Store_GetDataIndex(Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl"));
					Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
					tPrintToChat(client, "\x04新年大头派对,现已为你自动装备滑稽");
				}
				case 3:
				{
					m_iData = Store_GetDataIndex(Store_GetItemId("playerskin", "models/player/custom_player/maoling/misc/peter/peter_v2.mdl"));
					Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
					tPrintToChat(client, "\x04新年大头派对,现已为你自动装备皮特");
				}
			}
		}
		else if(GetClientTeam(client) == 2)
		{
			int m_iData = Store_GetDataIndex(Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl"));
			Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
			tPrintToChat(client, "\x04新年大头派对,现已为你自动装备滑稽");
		}
		else if(GetClientTeam(client) == 3)
		{
			int m_iData = Store_GetDataIndex(Store_GetItemId("playerskin", "models/player/custom_player/maoling/misc/peter/peter_v2.mdl"));
			Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
			tPrintToChat(client, "\x04新年大头派对,现已为你自动装备皮特");
		}
		//else if(g_bGameModeZE)
		//{
		//	if(IsModelPrecached(Model_ZE_Newbee) && IsModelPrecached(Arms_ZE_NewBee))
		//		Store_SetClientModel(client, Model_ZE_Newbee, Arms_ZE_NewBee);
		//}
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
	
	if(!g_bGameModeZE)
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

	if(g_bGameModeZE && GetClientTeam(client) != 3)
		return Plugin_Stop;

	Store_PreSetClientModel(client);

	return Plugin_Stop;
}

public Action Timer_FixPlayerArms(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;
	
	if(g_bGameModeZE)
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

/*
void ResetPlayerArms(int client)
{
	Handle pack;
	CreateDataTimer(0.5, Timer_ResetPlayerArms, pack);
	WritePackCell(pack, GetClientUserId(client));

	int iAmmo[5];
	char szWeapon[5][6][32];
	
	for(int x; x < 5; ++x)
		for(int y; y < 6; ++y)
			ResetPlayerWeapon(client, x, y, szWeapon, iAmmo[0], iAmmo[1], iAmmo[2], iAmmo[3], iAmmo[4]);

	for(int i; i < 5; ++i)
		for(int j; j < 6; ++j)
			WritePackString(pack, szWeapon[i][j]);

	for(int k; k < 5; ++k)
		WritePackCell(pack, iAmmo[k]);

	ResetPack(pack);
}

void ResetPlayerWeapon(int client, int x, int y, char[][][] szWeapon, int &a, int &b, int &c, int &d, int &e)
{
	int iWeapon = GetPlayerWeaponSlot(client, x);

	if(IsValidEdict(iWeapon))
	{
		GetEdictClassname(iWeapon, szWeapon[x][y], 32);
		
		switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex"))
		{
			//HE[44][0] Flash[43][1] Smoke[45][2] Fire[46/48][3] Decoy[47][4]
			case 44: a = GetEntProp(client, Prop_Send, "m_iAmmo", _, 14);
			case 43: b = GetEntProp(client, Prop_Send, "m_iAmmo", _, 15);
			case 45: c = GetEntProp(client, Prop_Send, "m_iAmmo", _, 16);
			case 46: d = GetEntProp(client, Prop_Send, "m_iAmmo", _, 17);
			case 48: d = GetEntProp(client, Prop_Send, "m_iAmmo", _, 17);
			case 47: e = GetEntProp(client, Prop_Send, "m_iAmmo", _, 18);
			case 60: strcopy(szWeapon[x][y], 32, "weapon_m4a1_silencer");
			case 61: strcopy(szWeapon[x][y], 32, "weapon_usp_silencer");
			case 63: strcopy(szWeapon[x][y], 32, "weapon_cz75a");
			case 64: strcopy(szWeapon[x][y], 32, "weapon_revolver");
		}

		RemovePlayerItem(client, iWeapon);
		AcceptEntityInput(iWeapon, "Kill");
	}
}

public Action Timer_ResetPlayerArms(Handle timer, Handle pack)
{
	int client = GetClientOfUserId(ReadPackCell(pack));

	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Stop;
	
	int iAmmo[5];
	char szWeapon[5][6][32];
	
	for(int i; i < 5; ++i)
		for(int j; j < 6; ++j)
			ReadPackString(pack, szWeapon[i][j], 32);

	for(int k; k < 5; ++k)
		iAmmo[k] = ReadPackCell(pack);
	
	for(int slot; slot <= 4; ++slot)
	{
		for(int type; type <= 5; ++type)
		{
			int index = -1;
			if(strlen(szWeapon[slot][type]) > 7)
				index = GivePlayerItem(client, szWeapon[slot][type]);
			
			if(slot == 3 && index > MaxClients && IsValidEdict(index))
			{
				switch(GetEntProp(index, Prop_Send, "m_iItemDefinitionIndex"))
				{
					//HE[44][0] Flash[43][1] Smoke[45][2] Fire[46/48][3] Decoy[47][4]
					case 44: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[0], _, 14);
					case 43: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[1], _, 15);
					case 45: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[2], _, 16);
					case 46: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[3], _, 17);
					case 48: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[3], _, 17);
					case 47: SetEntProp(client, Prop_Send, "m_iAmmo", iAmmo[4], _, 18);
				}
			}
		}
	}

	return Plugin_Stop;
}
*/
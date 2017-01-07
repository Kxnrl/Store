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
	tPrintToChat(client, "%t", "PlayerSkins Settings Changed");

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

public int PlayerSkins_Remove(int client, int id)
{
	tPrintToChat(client, "%t", "PlayerSkins Settings Changed");

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

void Store_PreSetClientModel(int client)
{
	int m_iEquipped = Store_GetEquippedItem(client, "playerskin", GetClientTeam(client)-2);

	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
	}
	else
	{
		int itemid = Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl");
		if(Store_HasClientItem(client, itemid) && (g_bGameModeTT || g_bGameModeJB || ((g_bGameModeHZ || g_bGameModeMG) && GetClientTeam(client) == 2)))
		{
			int m_iData = Store_GetDataIndex(itemid);
			Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][szArms]);
			tPrintToChat(client, "\x04新年大头派对,现已为你自动装备滑稽");
		}
		else if(g_bGameModeZE)
		{
			if(IsModelPrecached(Model_ZE_Newbee) && IsModelPrecached(Arms_ZE_NewBee))
				Store_SetClientModel(client, Model_ZE_Newbee, Arms_ZE_NewBee);
		}
	}
}

void Store_SetClientModel(int client, const char[] model, const char[] arms = "null")
{
	if(!StrEqual(arms, "null"))
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);

	SetEntityModel(client, model);

	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, 128);
	
	if(!g_bGameModeZE)
		g_bHasPlayerskin[client] = true;
	else if(!StrEqual(model, Model_ZE_Newbee))
		g_bHasPlayerskin[client] = true;
	
	if(!StrEqual(arms, "null") && !StrEqual(currentmodel, arms))
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	
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
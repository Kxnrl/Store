#define NEXT_PURPLE "models/player/custom_player/maoling/neptunia/neptune/nextform/faith.mdl"
#define NEXT_PURPLE_ARMS "models/player/custom_player/maoling/neptunia/neptune/nextform/nextpurple_arms.mdl"
#define PURPLE_HEART "models/player/custom_player/maoling/neptunia/neptune/hdd/faith.mdl"
#define PURPLE_HEART_ARMS "models/player/custom_player/maoling/neptunia/neptune/hdd/purpleheart_arms.mdl"

enum PlayerSkin
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szArms[PLATFORM_MAX_PATH],
	iSkin,
	iTeam,
	nModelIndex
}

enum Trail
{
	String:szMaterial[PLATFORM_MAX_PATH],
	String:szWidth[16],
	String:szColor[16],
	Float:fWidth,
	iColor[4],
	iSlot,
	iCacheID
}

enum Hat
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szAttachment[64],
	Float:fPosition[3],
	Float:fAngles[3],
	bool:bBonemerge,
	iTeam,
	iSlot
}

enum Neon
{
	iColor[4],
	iBright,
	iDistance,
	iFade
}

PlayerSkin g_ePlayerSkins[STORE_MAX_ITEMS][PlayerSkin];
Trail g_eTrails[STORE_MAX_ITEMS][Trail];
Hat g_eHats[STORE_MAX_ITEMS][Hat];
Neon g_eNeons[STORE_MAX_ITEMS][Neon];
int g_iClientHats[MAXPLAYERS+1][STORE_MAX_SLOTS];
int g_iHats = 0;
int g_iPlayerSkins = 0;
int g_cvarSkinChangeInstant = -1;
int g_cvarSkinForceChange = -1;
int g_cvarSkinForceChangeCT = -1;
int g_cvarSkinForceChangeTE = -1;
int g_cvarPadding = -1;
int g_cvarMaxColumns = -1;
int g_cvarTrailLife = -1;
int g_iTrailOwners[2048] = {-1};
int g_iTrails = 0;
int g_iClientTrails[MAXPLAYERS+1][STORE_MAX_SLOTS];
int g_iAuras = 0; 
int g_iClientAura[MAXPLAYERS+1];
int g_iNeons = 0;
int g_iClientNeon[MAXPLAYERS+1];
int g_iParts = 0; 
int g_iClientPart[MAXPLAYERS+1];
bool g_bTEForcedSkin = false;
bool g_bCTForcedSkin = false;
bool g_bSpawnTrails[MAXPLAYERS+1];
bool g_bHasPlayerskin[MAXPLAYERS+1];
bool g_bHideMode[MAXPLAYERS+1];
float g_fClientCounters[MAXPLAYERS+1];
float g_fLastPosition[MAXPLAYERS+1][3];
char g_szAuraName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szAuraClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];
char g_szPartName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szPartClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Players_OnPluginStart()
{
	if(g_bGameModePR)
		return;
	
	Store_RegisterHandler("playerskin", "model", PlayerSkins_OnMapStart, PlayerSkins_Reset, PlayerSkins_Config, PlayerSkins_Equip, PlayerSkins_Remove, true);
	Store_RegisterHandler("trail", "material", Trails_OnMapStart, Trails_Reset, Trails_Config, Trails_Equip, Trails_Remove, true);
	Store_RegisterHandler("hat", "model", Hats_OnMapStart, Hats_Reset, Hats_Config, Hats_Equip, Hats_Remove, true);
	Store_RegisterHandler("Aura", "Name", Aura_OnMapStart, Aura_Reset, Aura_Config, Aura_Equip, Aura_Remove, true);
	Store_RegisterHandler("neon", "ID", Neon_OnMapStart, Neon_Reset, Neon_Config, Neon_Equip, Neon_Remove, true); 
	Store_RegisterHandler("Particles", "Name", Part_OnMapStart, Part_Reset, Part_Config, Part_Equip, Part_Remove, true); 

	g_cvarSkinChangeInstant = RegisterConVar("sm_store_playerskin_instant", "0", "Defines whether the skin should be changed instantly or on next spawn.", TYPE_INT);
	g_cvarSkinForceChange = RegisterConVar("sm_store_playerskin_force_default", "0", "If it's set to 1, default skins will be enforced.", TYPE_INT);
	g_cvarSkinForceChangeCT = RegisterConVar("sm_store_playerskin_default_ct", "", "Path of the default CT skin.", TYPE_STRING);
	g_cvarSkinForceChangeTE = RegisterConVar("sm_store_playerskin_default_t", "", "Path of the default T skin.", TYPE_STRING);
	g_cvarPadding = RegisterConVar("sm_store_trails_padding", "30.0", "Space between two trails", TYPE_FLOAT);
	g_cvarMaxColumns = RegisterConVar("sm_store_trails_columns", "3", "Number of columns before starting to increase altitude", TYPE_INT);
	g_cvarTrailLife = RegisterConVar("sm_store_trails_life", "1.0", "Life of a trail in seconds", TYPE_FLOAT);

	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);

	RegConsoleCmd("sm_hide", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hidetrail", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hideneon", Command_Hide, "Hide Trail and Neon");
	RegConsoleCmd("sm_hdd", Command_HDD, "Change to HDD mode");
	RegConsoleCmd("sm_nextform", Command_NextForm, "Change to NEXT FORM");
}

public void PlayerSkins_OnMapStart()
{
	for(int i = 0; i < g_iPlayerSkins; ++i)
	{
		g_ePlayerSkins[i][nModelIndex] = PrecacheModel2(g_ePlayerSkins[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szModel]);

		if(g_ePlayerSkins[i][szArms][0] != 0)
		{
			PrecacheModel2(g_ePlayerSkins[i][szArms], true);
			Downloader_AddFileToDownloadsTable(g_ePlayerSkins[i][szArms]);
		}
	}

	if(g_eCvars[g_cvarSkinForceChangeTE][sCache][0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeTE][sCache]) || FileExists(g_eCvars[g_cvarSkinForceChangeTE][sCache], true)))
	{
		g_bTEForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeTE][sCache], true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeTE][sCache]);
	}
	else
		g_bTEForcedSkin = false;
		
	if(g_eCvars[g_cvarSkinForceChangeCT][sCache][0] != 0 && (FileExists(g_eCvars[g_cvarSkinForceChangeCT][sCache]) || FileExists(g_eCvars[g_cvarSkinForceChangeCT][sCache], true)))
	{
		g_bCTForcedSkin = true;
		PrecacheModel2(g_eCvars[g_cvarSkinForceChangeCT][sCache], true);
		Downloader_AddFileToDownloadsTable(g_eCvars[g_cvarSkinForceChangeCT][sCache]);
	}
	else
		g_bCTForcedSkin = false;
}

public void Trails_OnMapStart()
{
	for(int a = 0; a <= MaxClients; ++a)
		for(int b = 0; b < STORE_MAX_SLOTS; ++b)
			g_iClientTrails[a][b] = 0;

	for(int i = 0; i < g_iTrails; ++i)
	{
		g_eTrails[i][iCacheID] = PrecacheModel2(g_eTrails[i][szMaterial], true);
		Downloader_AddFileToDownloadsTable(g_eTrails[i][szMaterial]);
	}
}

public void Hats_OnMapStart()
{
	for(int a = 0; a <= MaxClients; ++a)
		for(int b = 0; b < STORE_MAX_SLOTS; ++b)
			g_iClientHats[a][b] = 0;

	for(int i = 0; i < g_iHats; ++i)
	{
		PrecacheModel2(g_eHats[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_eHats[i][szModel]);
	}
}

public void Aura_OnMapStart()
{
	AddFileToDownloadsTable("materials/ex/gl.vmt");
	AddFileToDownloadsTable("materials/ex/gl.vtf");
	AddFileToDownloadsTable("materials/ex/ballX.vmt");
	AddFileToDownloadsTable("materials/ex/ES.vmt");
	AddFileToDownloadsTable("materials/ex/ballX.vtf");
	AddFileToDownloadsTable("materials/ex/ES.vtf");
	AddFileToDownloadsTable("particles/FX.pcf");
	PrecacheGeneric("particles/FX.pcf",true);
	PrecacheModel("materials/ex/ballX.vmt");
	PrecacheModel("materials/ex/ES.vmt");
	PrecacheModel("materials/ex/ballX.vtf");
	PrecacheModel("materials/ex/gl.vmt");
	PrecacheModel("materials/ex/gl.vtf");
	PrecacheModel("materials/ex/ES.vtf");
}

public void Neon_OnMapStart()
{
	
}

public void Part_OnMapStart()
{
	
}

public void Players_OnClientConnected(int client)
{
	g_bHideMode[client] = false;
}

public void Aura_OnClientDisconnect(int client)
{
	Store_RemoveClientAura(client);
	g_iClientAura[client] = 0;
	g_szAuraClient[client] = "";
}

public void Neon_OnClientDisconnect(int client)
{
	Store_RemoveClientNeon(client);
	g_iClientNeon[client] = 0;
}

public void Part_OnClientDisconnect(int client)
{
	Store_RemoveClientPart(client);
	g_iClientPart[client] = 0;
	g_szPartClient[client] = "";
}

public void PlayerSkins_Reset()
{
	g_iPlayerSkins = 0;
}

public void Trails_Reset()
{
	g_iTrails = 0;
}

public void Hats_Reset()
{
	g_iHats = 0;
}

public void Aura_Reset() 
{ 
	g_iAuras = 0; 
}

public void Neon_Reset()
{
	g_iNeons = 0;
}

public void Part_Reset() 
{ 
	g_iParts = 0;
}

public int PlayerSkins_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iPlayerSkins);
	
	KvGetString(kv, "model", g_ePlayerSkins[g_iPlayerSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "arms", g_ePlayerSkins[g_iPlayerSkins][szArms], PLATFORM_MAX_PATH);

	g_ePlayerSkins[g_iPlayerSkins][iSkin] = KvGetNum(kv, "skin");
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

public int Trails_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iTrails);
	
	KvGetString(kv, "material", g_eTrails[g_iTrails][szMaterial], PLATFORM_MAX_PATH);
	KvGetString(kv, "width", g_eTrails[g_iTrails][szWidth], 16, "10.0");
	KvGetString(kv, "color", g_eTrails[g_iTrails][szColor], 16, "255 255 255");
	KvGetColor(kv, "color", g_eTrails[g_iTrails][iColor][0], g_eTrails[g_iTrails][iColor][1], g_eTrails[g_iTrails][iColor][2], g_eTrails[g_iTrails][iColor][3]);
	g_eTrails[g_iTrails][fWidth] = KvGetFloat(kv, "width", 10.0);
	g_eTrails[g_iTrails][iSlot] = KvGetNum(kv, "slot");

	if(FileExists(g_eTrails[g_iTrails][szMaterial], true))
	{
		++g_iTrails;
		return true;
	}

	return false;
}

public int Hats_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iHats);
	float m_fTemp[3];
	KvGetString(kv, "model", g_eHats[g_iHats][szModel], PLATFORM_MAX_PATH);
	KvGetVector(kv, "position", m_fTemp);
	g_eHats[g_iHats][fPosition] = m_fTemp;
	KvGetVector(kv, "angles", m_fTemp);
	g_eHats[g_iHats][fAngles] = m_fTemp;
	g_eHats[g_iHats][bBonemerge] = (KvGetNum(kv, "bonemerge", 0)?true:false);
	g_eHats[g_iHats][iTeam] = KvGetNum(kv, "team", 0);
	g_eHats[g_iHats][iSlot] = KvGetNum(kv, "slot");
	KvGetString(kv, "attachment", g_eHats[g_iHats][szAttachment], 64, "forward");
	
	if(!(FileExists(g_eHats[g_iHats][szModel], true)))
		return false;

	++g_iHats;
	return true;
}

public int Aura_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iAuras); 
	KvGetString(kv, "Name", g_szAuraName[g_iAuras], PLATFORM_MAX_PATH);
	++g_iAuras;

	return true; 
}

public int Neon_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iNeons); 
	KvGetColor(kv, "neoncolor", g_eNeons[g_iNeons][iColor][0], g_eNeons[g_iNeons][iColor][1], g_eNeons[g_iNeons][iColor][2], g_eNeons[g_iNeons][iColor][3]); 
	g_eNeons[g_iNeons][iBright] = KvGetNum(kv, "brightness");
	g_eNeons[g_iNeons][iDistance] = KvGetNum(kv, "distance");
	g_eNeons[g_iNeons][iFade] = KvGetNum(kv, "distancefade");
	++g_iNeons;
	return true; 
}

public int Part_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iParts); 
	KvGetString(kv, "Name", g_szPartName[g_iParts], PLATFORM_MAX_PATH);
	++g_iParts;
	return true;
}

public int PlayerSkins_Equip(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	
	if(g_eCvars[g_cvarSkinChangeInstant][aCache] && IsPlayerAlive(client) && (GetClientTeam(client) == g_ePlayerSkins[m_iData][iTeam]))
	{
		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][iSkin]);
	}
	else
	{
		if(Store_IsClientLoaded(client))
			Chat(client, "%t", "PlayerSkins Settings Changed");
	}

	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

public int Trails_Equip(int client, int id)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return -1;

	CreateTimer(0.0, Timer_CreateTrails, GetClientUserId(client));

	return g_eTrails[Store_GetDataIndex(id)][iSlot];
}

public int Hats_Equip(int client, int id)
{
	if(!IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return -1;
	
	int m_iData = Store_GetDataIndex(id);
	RemoveHat(client, g_eHats[m_iData][iSlot]);
	CreateHat(client, id);
	return g_eHats[m_iData][iSlot];
}

public int Aura_Equip(int client, int id) 
{
	int m_iData = Store_GetDataIndex(id);
	g_szAuraClient[client] = g_szAuraName[m_iData];
	if(g_iClientAura[client] != 0)
		Store_RemoveClientAura(client);

	CreateTimer(1.0, Timer_SetClientAura, GetClientUserId(client));
	return 0; 
}

public int Neon_Equip(int client, int id)
{
	if(g_iClientNeon[client] != 0)
		Store_RemoveClientNeon(client);

	Store_SetClientNeon(client);
	return 0;
}

public int Part_Equip(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	g_szPartClient[client] = g_szPartName[m_iData];
	
	if(g_iClientPart[client] != 0)
		Store_RemoveClientPart(client);

	Store_SetClientPart(client);
	return 0;
}

public int PlayerSkins_Remove(int client, int id)
{
	if(Store_IsClientLoaded(client) && !g_eCvars[g_cvarSkinChangeInstant][aCache])
		Chat(client, "%t", "PlayerSkins Settings Changed");
	return g_ePlayerSkins[Store_GetDataIndex(id)][iTeam]-2;
}

public int Trails_Remove(int client, int id)
{
	CreateTimer(0.0, Timer_CreateTrails, GetClientUserId(client));
	return  g_eTrails[Store_GetDataIndex(id)][iSlot];
}

public int Hats_Remove(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	RemoveHat(client, g_eHats[m_iData][iSlot]);
	return g_eHats[m_iData][iSlot];
}

public int RemoveTrail(int client, int slot)
{
	if(g_iClientTrails[client][slot] != 0 && IsValidEdict(g_iClientTrails[client][slot]))
	{
		g_iTrailOwners[g_iClientTrails[client][slot]]=-1;

		char m_szClassname[64];
		GetEdictClassname(g_iClientTrails[client][slot], STRING(m_szClassname));
		if(strcmp("env_spritetrail", m_szClassname)==0)
		{
			SDKUnhook(g_iClientTrails[client][slot], SDKHook_SetTransmit, Hook_SetTransmit_Trail);
			AcceptEntityInput(g_iClientTrails[client][slot], "Kill");
		}
	}

	g_iClientTrails[client][slot]=0;
}

public int Aura_Remove(int client) 
{
	Store_RemoveClientAura(client);
	g_iClientAura[client] = 0;
	g_szAuraClient[client] = "";
	return 0; 
}

public int Neon_Remove(int client) 
{
	Store_RemoveClientNeon(client);
	g_iClientNeon[client] = 0;
	return 0; 
}

public int Part_Remove(int client) 
{
	Store_RemoveClientPart(client);
	g_iClientPart[client] = 0;
	g_szPartClient[client] = "";
	return 0; 
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;

	CreateTimer(0.0, Timer_CreateTrails, GetClientUserId(client));
	CreateTimer(0.1, Timer_SetClientHat, GetClientUserId(client));	
	CreateTimer(1.0, Timer_SetClientAura, GetClientUserId(client));
	CreateTimer(1.0, Timer_SetClientNeon, GetClientUserId(client));
	CreateTimer(1.0, Timer_SetClientPart, GetClientUserId(client));

	//PrintToChatAll("Spawn1 %N", client);

	if(g_bGameModeZE)
		if(GetClientTeam(client) != 3)
			return Plugin_Stop;

	Store_PreSetClientModel(client);
	//PrintToChatAll("Spawn2 %N", client);

	return Plugin_Stop;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	Store_RemoveClientAura(client);
	Store_RemoveClientNeon(client);
	Store_RemoveClientPart(client);
	
	g_bHasPlayerskin[client] = false;
	
	if(!IsPlayerAlive(client))
	{
		for(int i = 0; i < STORE_MAX_SLOTS; ++i)
		{
			RemoveTrail(client, i);
			RemoveHat(client, i);
		}
	}
	
	//PrintToChatAll("Death %N", client);

	return Plugin_Continue;
}

public Action Event_PlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!client || !IsClientInGame(client))
		return Plugin_Continue;
	
	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
		RemoveHat(client, i);
	
	int team = GetEventInt(event, "team");
	if(team <= 2)
	{
		Store_RemoveClientAura(client);
		Store_RemoveClientNeon(client);
		Store_RemoveClientPart(client);
	}
	
	if(!IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Continue;

	if(g_bGameModeMG)
		Store_PreSetClientModel(client);

	//PrintToChatAll("Team %N", client);
	
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(0.1, Timer_RoundStartDelay);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
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

public Action Timer_CreateTrails(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	
	if(!client || !IsClientInGame(client))
		return Plugin_Stop;

	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
	{
		RemoveTrail(client, i);
		CreateTrail(client, -1, i);
	}

	return Plugin_Stop;
}

void Store_PreSetClientModel(int client)
{
	int m_iEquipped = Store_GetEquippedItem(client, "playerskin", 2);

	if(m_iEquipped < 0)
		m_iEquipped = Store_GetEquippedItem(client, "playerskin", GetClientTeam(client)-2);

	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);

		Store_SetClientModel(client, g_ePlayerSkins[m_iData][szModel], g_ePlayerSkins[m_iData][iSkin], g_ePlayerSkins[m_iData][szArms]);
	}
	else if(g_eCvars[g_cvarSkinForceChange][aCache])
	{
		int m_iTeam = GetClientTeam(client);

		if(m_iTeam == 2 && g_bTEForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeTE][sCache]);
		else if(m_iTeam == 3 && g_bCTForcedSkin)
			Store_SetClientModel(client, g_eCvars[g_cvarSkinForceChangeCT][sCache]);
	}
}

void Store_SetClientModel(int client, const char[] model, const int skin = 0, const char[] arms = "null")
{
	if(!StrEqual(arms, "null"))
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);

	SetEntityModel(client, model);
	SetEntProp(client, Prop_Send, "m_nSkin", skin);
	SetEntProp(client, Prop_Data, "m_nSkin", skin);
	
	char currentmodel[128];
	GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, 128);
	
	g_bHasPlayerskin[client] = true;
	
	//PrintToConsole(client, "szModel: %s", model);
	//PrintToConsole(client, "strArms: %s", arms);
	//PrintToConsole(client, "Current: %s", currentmodel);
	
	if(!StrEqual(arms, "null") && !StrEqual(currentmodel, arms))
		SetEntPropString(client, Prop_Send, "m_szArmsModel", arms);
	
	//GetEntPropString(client, Prop_Send, "m_szArmsModel", currentmodel, 128);
	//PrintToConsole(client, "Final:: %s", currentmodel);
}

int CreateTrail(int client, int itemid = -1, int slot = 0)
{
	int m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "trail", slot) : itemid);
	
	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);
		
		int m_aEquipped[STORE_MAX_SLOTS] = {-1,...};
		int m_iNumEquipped = 0;
		
		int m_iCurrent;

		for(int i=0;i<STORE_MAX_SLOTS;++i)
		{
			if((m_aEquipped[m_iNumEquipped] = Store_GetEquippedItem(client, "trail", i)) >= 0)
			{
				if(i == g_eTrails[m_iData][iSlot])
					m_iCurrent = m_iNumEquipped;
				++m_iNumEquipped;
			}
		}
		
		if(g_iClientTrails[client][slot] == 0 || !IsValidEdict(g_iClientTrails[client][slot]))
		{
			g_iClientTrails[client][slot] = CreateEntityByName("env_sprite");
			DispatchKeyValue(g_iClientTrails[client][slot], "classname", "env_sprite");
			DispatchKeyValue(g_iClientTrails[client][slot], "spawnflags", "1");
			DispatchKeyValue(g_iClientTrails[client][slot], "scale", "0.0");
			DispatchKeyValue(g_iClientTrails[client][slot], "rendermode", "10");
			DispatchKeyValue(g_iClientTrails[client][slot], "rendercolor", "255 255 255 0");
			DispatchKeyValue(g_iClientTrails[client][slot], "model", g_eTrails[m_iData][szMaterial]);
			DispatchSpawn(g_iClientTrails[client][slot]);
			AttachTrail(g_iClientTrails[client][slot], client, m_iCurrent, m_iNumEquipped);	
			SDKHook(g_iClientTrails[client][slot], SDKHook_SetTransmit, Hook_SetTransmit_Trail);
		}
			
		//Ugh...
		int m_iColor[4];
		m_iColor[0] = g_eTrails[m_iData][iColor][0];
		m_iColor[1] = g_eTrails[m_iData][iColor][1];
		m_iColor[2] = g_eTrails[m_iData][iColor][2];
		m_iColor[3] = g_eTrails[m_iData][iColor][3];
		TE_SetupBeamFollow(g_iClientTrails[client][slot], g_eTrails[m_iData][iCacheID], 0, view_as<float>(g_eCvars[g_cvarTrailLife][aCache]), g_eTrails[m_iData][fWidth], g_eTrails[m_iData][fWidth], 10, m_iColor);
		TE_SendToAll();
	}
}

public int AttachTrail(int ent, int client, int current, int num)
{
	float m_fOrigin[3];
	float m_fAngle[3];
	float m_fTemp[3] = {0.0, 90.0, 0.0};
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
	float m_fX = (view_as<float>(g_eCvars[g_cvarPadding][aCache])*((num-1)%g_eCvars[g_cvarMaxColumns][aCache]))/2-(view_as<float>(g_eCvars[g_cvarPadding][aCache])*(current%g_eCvars[g_cvarMaxColumns][aCache]));
	float m_fPosition[3];
	m_fPosition[0] = m_fX;
	m_fPosition[1] = 0.0;
	m_fPosition[2]= 5.0+(current/g_eCvars[g_cvarMaxColumns][aCache])*view_as<float>(g_eCvars[g_cvarPadding][aCache]);
	GetClientAbsOrigin(client, m_fOrigin);
	AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
	TeleportEntity(ent, m_fOrigin, m_fTemp, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
}

public void Trails_OnGameFrame()
{
	if(g_bGameModePR)
		return;
	
	if(GetGameTickCount()%6 != 0)
		return;	

	float m_fTime = GetEngineTime();
	float m_fPosition[3];

	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;
		
		if(!IsPlayerAlive(i))
			continue;
		
		GetClientAbsOrigin(i, m_fPosition);
		if(GetVectorDistance(g_fLastPosition[i], m_fPosition) <= 5.0)
		{
			if(!g_bSpawnTrails[i])
				if(m_fTime-g_fClientCounters[i] >= view_as<float>(g_eCvars[g_cvarTrailLife][aCache])/2)
					g_bSpawnTrails[i] = true;
		}
		else
		{
			if(g_bSpawnTrails[i])
			{
				g_bSpawnTrails[i] = false;
				TE_Start("KillPlayerAttachments");
				TE_WriteNum("m_nPlayer",i);
				TE_SendToAll();
				for(int a = 0; a < STORE_MAX_SLOTS; ++a)
					CreateTrail(i, -1, a);
			}
			else
				g_fClientCounters[i] = m_fTime;

			g_fLastPosition[i] = m_fPosition;
		}
	}
}

public Action Timer_SetClientHat(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;

	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
	{
		RemoveHat(client, i);
		CreateHat(client, -1, i);
	}

	return Plugin_Stop;
}

int CreateHat(int client, int itemid = -1, int slot = 0)
{
	int  m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "hat", slot) : itemid);
	
	if(m_iEquipped >= 0)
	{
		int m_iData = Store_GetDataIndex(m_iEquipped);
		int m_iTeam = GetClientTeam(client);
		
		if(g_eHats[m_iData][iTeam] != 0 && m_iTeam!=g_eHats[m_iData][iTeam])
			return;
		
		// Calculate the final position and angles for the hat
		float m_fHatOrigin[3];
		float m_fHatAngles[3];
		float m_fForward[3];
		float m_fRight[3];
		float m_fUp[3];
		GetClientAbsOrigin(client,m_fHatOrigin);
		GetClientAbsAngles(client,m_fHatAngles);
		
		m_fHatAngles[0] += g_eHats[m_iData][fAngles][0];
		m_fHatAngles[1] += g_eHats[m_iData][fAngles][1];
		m_fHatAngles[2] += g_eHats[m_iData][fAngles][2];

		float m_fOffset[3];
		m_fOffset[0] = g_eHats[m_iData][fPosition][0];
		m_fOffset[1] = g_eHats[m_iData][fPosition][1];
		m_fOffset[2] = g_eHats[m_iData][fPosition][2];

		GetAngleVectors(m_fHatAngles, m_fForward, m_fRight, m_fUp);

		m_fHatOrigin[0] += m_fRight[0]*m_fOffset[0]+m_fForward[0]*m_fOffset[1]+m_fUp[0]*m_fOffset[2];
		m_fHatOrigin[1] += m_fRight[1]*m_fOffset[0]+m_fForward[1]*m_fOffset[1]+m_fUp[1]*m_fOffset[2];
		m_fHatOrigin[2] += m_fRight[2]*m_fOffset[0]+m_fForward[2]*m_fOffset[1]+m_fUp[2]*m_fOffset[2];
		
		// Create the hat entity
		int m_iEnt = CreateEntityByName("prop_dynamic_override");
		DispatchKeyValue(m_iEnt, "model", g_eHats[m_iData][szModel]);
		DispatchKeyValue(m_iEnt, "spawnflags", "256");
		DispatchKeyValue(m_iEnt, "solid", "0");
		SetEntPropEnt(m_iEnt, Prop_Send, "m_hOwnerEntity", client);
		
		if(g_eHats[m_iData][bBonemerge])
			Bonemerge(m_iEnt);
		
		DispatchSpawn(m_iEnt);	
		AcceptEntityInput(m_iEnt, "TurnOn", m_iEnt, m_iEnt, 0);
		
		// Save the entity index
		g_iClientHats[client][g_eHats[m_iData][iSlot]]=m_iEnt;
		
		// We don't want the client to see his own hat
		SDKHook(m_iEnt, SDKHook_SetTransmit, Hook_SetTransmit_Hat);
		
		// Teleport the hat to the right position and attach it
		TeleportEntity(m_iEnt, m_fHatOrigin, m_fHatAngles, NULL_VECTOR); 
		
		SetVariantString("!activator");
		AcceptEntityInput(m_iEnt, "SetParent", client, m_iEnt, 0);
		
		SetVariantString(g_eHats[m_iData][szAttachment]);
		AcceptEntityInput(m_iEnt, "SetParentAttachmentMaintainOffset", m_iEnt, m_iEnt, 0);
	}
}

public int RemoveHat(int client, int slot)
{
	if(g_iClientHats[client][slot] != 0 && IsValidEdict(g_iClientHats[client][slot]))
	{
		SDKUnhook(g_iClientHats[client][slot], SDKHook_SetTransmit, Hook_SetTransmit_Hat);
		char m_szClassname[64];
		GetEdictClassname(g_iClientHats[client][slot], STRING(m_szClassname));
		if(strcmp("prop_dynamic", m_szClassname)==0)
			AcceptEntityInput(g_iClientHats[client][slot], "Kill");
	}
	g_iClientHats[client][slot] = 0;
}

public Action Hook_SetTransmit_Hat(int ent, int client)
{
	if(GetFeatureStatus(FeatureType_Native, "IsPlayerInTP") == FeatureStatus_Available)
		if(IsPlayerInTP(client))
			return Plugin_Continue;

	for(int i = 0; i< STORE_MAX_SLOTS; ++i)
		if(ent == g_iClientHats[client][i])
			return Plugin_Handled;

	if(client && IsClientInGame(client))
	{
		int m_iObserverMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
		int m_hObserverTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
		if(m_iObserverMode == 4 && m_hObserverTarget>=0)
		{
			for(int i = 0; i < STORE_MAX_SLOTS; ++i)
				if(ent == g_iClientHats[m_hObserverTarget][i])
					return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action Hook_SetTransmit_Neon(int ent, int client)
{
	if(GetEdictFlags(ent) & FL_EDICT_ALWAYS)
		SetEdictFlags(ent, GetEdictFlags(ent) ^ FL_EDICT_ALWAYS & FL_EDICT_DONTSEND);

	return !(g_bHideMode[client]) ? Plugin_Continue : Plugin_Handled;
}

public Action Hook_SetTransmit_Trail(int ent, int client)
{
	if(g_bHideMode[client])
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

public int Bonemerge(int ent)
{
	int m_iEntEffects = GetEntProp(ent, Prop_Send, "m_fEffects"); 
	m_iEntEffects &= ~32;
	m_iEntEffects |= 1;
	m_iEntEffects |= 128;
	SetEntProp(ent, Prop_Send, "m_fEffects", m_iEntEffects); 
}

void Store_RemoveClientAura(int client)
{
	if(g_iClientAura[client] != 0)
	{
		if(IsValidEdict(g_iClientAura[client]))
		{
			AcceptEntityInput(g_iClientAura[client], "Kill");
		}
		g_iClientAura[client] = 0;
	}
}

public Action Timer_RoundStartDelay(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!(2 <= GetClientTeam(client) <= 3))
			continue;
		
		if(!IsPlayerAlive(client))
			continue;
		
		Store_PreSetClientModel(client);
		
		CreateTimer(1.0, Timer_SetClientAura, GetClientUserId(client));
		CreateTimer(1.0, Timer_SetClientNeon, GetClientUserId(client));
		CreateTimer(1.0, Timer_SetClientPart, GetClientUserId(client));
	}
}

public Action Timer_SetClientAura(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;
	
	Store_SetClientAura(client);
	
	return Plugin_Stop;
}

void Store_SetClientAura(int client)
{
	if(g_iClientAura[client] != 0)
	{
		Store_RemoveClientAura(client);
	}

	if(!(strcmp(g_szAuraClient[client], "", false) == 0))
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		g_iClientAura[client] = CreateEntityByName("info_particle_system");
		
		DispatchKeyValue(g_iClientAura[client] , "start_active", "1");
		DispatchKeyValue(g_iClientAura[client] , "effect_name", g_szAuraClient[client]);
		DispatchSpawn(g_iClientAura[client]);
		
		TeleportEntity(g_iClientAura[client], clientOrigin, NULL_VECTOR, NULL_VECTOR);
		
		ActivateEntity(g_iClientAura[client]);

		SetVariantString("!activator");
		
		AcceptEntityInput(g_iClientAura[client], "SetParent", client, g_iClientAura[client], 0);
	}
}

public Action Timer_SetClientNeon(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;
	
	Store_SetClientNeon(client);

	return Plugin_Stop;
}

public Action Timer_SetClientPart(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client) || !IsPlayerAlive(client) || !(2<=GetClientTeam(client)<=3))
		return Plugin_Stop;
	
	Store_SetClientPart(client);
	
	return Plugin_Stop;
}

void Store_RemoveClientNeon(int client)
{
	if(g_iClientNeon[client] != 0)
	{
		if(IsValidEntity(g_iClientNeon[client]))
			SDKUnhook(g_iClientNeon[client], SDKHook_SetTransmit, Hook_SetTransmit_Neon);

		if(IsValidEdict(g_iClientNeon[client]))
			AcceptEntityInput(g_iClientNeon[client], "Kill");

		g_iClientNeon[client] = 0;
	}
}

void Store_SetClientNeon(int client)
{
	if(g_iClientNeon[client] != 0)
		Store_RemoveClientNeon(client);
	
	int m_iEquipped = Store_GetEquippedItem(client, "neon", 0); 
	if(m_iEquipped < 0) 
		return;
	
	int m_iData = Store_GetDataIndex(m_iEquipped);

	if(g_eNeons[m_iData][iColor][3] != 0)
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		int iNeon = CreateEntityByName("light_dynamic");
		
		char m_szString[100];
		IntToString(g_eNeons[m_iData][iBright], m_szString, 100);
		DispatchKeyValue(iNeon, "brightness", m_szString);

		Format(m_szString, 100, "%d %d %d %d", g_eNeons[m_iData][iColor][0], g_eNeons[m_iData][iColor][1], g_eNeons[m_iData][iColor][2], g_eNeons[m_iData][iColor][3]);
		DispatchKeyValue(iNeon, "_light", m_szString);
		
		IntToString(g_eNeons[m_iData][iFade], m_szString, 100);
		DispatchKeyValue(iNeon, "spotlight_radius", m_szString);

		IntToString(g_eNeons[m_iData][iDistance], m_szString, 100);
		DispatchKeyValue(iNeon, "distance", m_szString);

		DispatchKeyValue(iNeon, "style", "0");

		SetEntPropEnt(iNeon, Prop_Send, "m_hOwnerEntity", client);

		DispatchSpawn(iNeon);
		AcceptEntityInput(iNeon, "TurnOn");

		TeleportEntity(iNeon, clientOrigin, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iNeon, "SetParent", client, iNeon, 0);
		
		g_iClientNeon[client] = iNeon;
		
		SDKHook(iNeon, SDKHook_SetTransmit, Hook_SetTransmit_Neon);
	}
}

void Store_RemoveClientPart(int client)
{
	if(g_iClientPart[client] != 0)
	{
		if(IsValidEdict(g_iClientPart[client]))
			AcceptEntityInput(g_iClientPart[client], "Kill");

		g_iClientPart[client] = 0;
	}
}

void Store_SetClientPart(int client)
{
	if(g_iClientPart[client] != 0)
		Store_RemoveClientPart(client);

	if(!(strcmp(g_szPartClient[client], "", false) == 0))
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		g_iClientPart[client] = CreateEntityByName("info_particle_system");
		
		DispatchKeyValue(g_iClientPart[client], "start_active", "1");
		DispatchKeyValue(g_iClientPart[client], "effect_name", g_szPartClient[client]);
		DispatchSpawn(g_iClientPart[client]);
		
		TeleportEntity(g_iClientPart[client], clientOrigin, NULL_VECTOR,NULL_VECTOR);
		
		ActivateEntity(g_iClientPart[client]);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_iClientPart[client], "SetParent", client, g_iClientPart[client], 0);
	}
}

public Action Command_Hide(int client, int args)
{
	if(!IsClientInGame(client))
		return Plugin_Handled;
	
	if(!g_bHideMode[client])
	{
		g_bHideMode[client] = true;
		PrintToChat(client, "[\x0EPlaneptune\x01]   '\x04!hide\x01' 你已\x04开启\x01屏蔽足迹和霓虹");
	}
	else
	{
		g_bHideMode[client] = false;
		PrintToChat(client, "[\x0EPlaneptune\x01]   '\x04!hide\x01' 你已\x07关闭\x01屏蔽足迹和霓虹");
	}

	return Plugin_Handled;
}


public Action Command_HDD(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]   你只有活着才能变身");
		return Plugin_Handled;
	}
	
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	if(!StrEqual(auth, "STEAM_1:1:44083262"))
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]   你不是女神,怎么变身?");
		ForcePlayerSuicide(client);
		return Plugin_Handled;
	}
	
	if(IsModelPrecached(PURPLE_HEART) && IsModelPrecached(PURPLE_HEART_ARMS))
		Store_SetClientModel(client, PURPLE_HEART, 0, PURPLE_HEART_ARMS);
	
	PrintToChatAll("[\x0EPlaneptune\x01]   \x0E%N\x04已变身为HDD形态(Purple Heart)", client);
	
	return Plugin_Handled;
}

public Action Command_NextForm(int client, int args)
{
	if(!IsPlayerAlive(client))
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]   你只有活着才能变身");
		return Plugin_Handled;
	}
	
	char auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32, true);
	if(!StrEqual(auth, "STEAM_1:1:44083262"))
	{
		PrintToChat(client, "[\x0EPlaneptune\x01]   你不是女神,怎么变身?");
		ForcePlayerSuicide(client);
		return Plugin_Handled;
	}
	
	if(IsModelPrecached(NEXT_PURPLE) && IsModelPrecached(NEXT_PURPLE_ARMS))
		Store_SetClientModel(client, NEXT_PURPLE, 0, NEXT_PURPLE_ARMS);
	
	PrintToChatAll("[\x0EPlaneptune\x01]   \x0E%N\x04已进化为Next Form形态(Next Purple)", client);

	return Plugin_Handled;
}
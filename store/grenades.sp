enum GrenadeSkin
{
	String:szModel[PLATFORM_MAX_PATH],
	String:szWeapon[64],
	iLength,
	iSlot
}

enum GrenadeTrail
{
	String:szMaterial[PLATFORM_MAX_PATH],
	String:szWidth[16],
	String:szColor[16],
	Float:fWidth,
	iColor[4],
	iSlot,
	iCacheID
}

int g_eGrenadeSkins[STORE_MAX_ITEMS][GrenadeSkin];
int g_eGrenadeTrails[STORE_MAX_ITEMS][GrenadeTrail];
int g_iGrenadeSkins = 0;
int g_iSlots = 0;
int g_iGrenadeTrails = 0;
char g_szSlots[16][64];


public void Grenades_OnPluginStart()
{
	if(g_bGameModePR || g_bGameModeKZ)
		return;

	Store_RegisterHandler("grenadetrail", "material", GrenadeTrails_OnMapStart, GrenadeTrails_Reset, GrenadeTrails_Config, GrenadeTrails_Equip, GrenadeTrails_Remove, true);
	Store_RegisterHandler("grenadeskin", "model", GrenadeSkins_OnMapStart, GrenadeSkins_Reset, GrenadeSkins_Config, GrenadeSkins_Equip, GrenadeSkins_Remove, true);
}

public void GrenadeSkins_OnMapStart()
{
	for(int i = 0; i< g_iGrenadeSkins; ++i)
	{
		PrecacheModel2(g_eGrenadeSkins[i][szModel], true);
		Downloader_AddFileToDownloadsTable(g_eGrenadeSkins[i][szModel]);
	}
}

public void GrenadeTrails_OnMapStart()
{
	for(int i = 0; i < g_iGrenadeTrails; ++i)
	{
		g_eGrenadeTrails[i][iCacheID] = PrecacheModel2(g_eGrenadeTrails[i][szMaterial], true);
		Downloader_AddFileToDownloadsTable(g_eGrenadeTrails[i][szMaterial]);
	}
}

public void GrenadeSkins_Reset()
{
	g_iGrenadeSkins = 0;
}

public void GrenadeTrails_Reset()
{
	g_iGrenadeTrails = 0;
}

public int GrenadeSkins_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iGrenadeSkins);
	KvGetString(kv, "model", g_eGrenadeSkins[g_iGrenadeSkins][szModel], PLATFORM_MAX_PATH);
	KvGetString(kv, "grenade", g_eGrenadeSkins[g_iGrenadeSkins][szWeapon], PLATFORM_MAX_PATH);
	
	g_eGrenadeSkins[g_iGrenadeSkins][iSlot] = GrenadeSkins_GetSlot(g_eGrenadeSkins[g_iGrenadeSkins][szWeapon]);
	g_eGrenadeSkins[g_iGrenadeSkins][iLength] = strlen(g_eGrenadeSkins[g_iGrenadeSkins][szWeapon]);
	
	if(!(FileExists(g_eGrenadeSkins[g_iGrenadeSkins][szModel], true)))
		return false;
		
	++g_iGrenadeSkins;
	return true;
}

public int GrenadeTrails_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iGrenadeTrails);
	KvGetString(kv, "material", g_eGrenadeTrails[g_iGrenadeTrails][szMaterial], PLATFORM_MAX_PATH);
	KvGetString(kv, "width", g_eGrenadeTrails[g_iGrenadeTrails][szWidth], 16, "10.0");
	g_eGrenadeTrails[g_iGrenadeTrails][fWidth] = KvGetFloat(kv, "width", 10.0);
	KvGetString(kv, "color", g_eGrenadeTrails[g_iGrenadeTrails][szColor], 16, "255 255 255 255");
	KvGetColor(kv, "color", g_eGrenadeTrails[g_iGrenadeTrails][iColor][0], g_eGrenadeTrails[g_iGrenadeTrails][iColor][1], g_eGrenadeTrails[g_iGrenadeTrails][iColor][2], g_eGrenadeTrails[g_iGrenadeTrails][iColor][3]);
	g_eGrenadeTrails[g_iGrenadeTrails][iSlot] = KvGetNum(kv, "slot");
	
	if(FileExists(g_eGrenadeTrails[g_iGrenadeTrails][szMaterial], true))
	{
		++g_iGrenadeTrails;
		return true;
	}
	
	return false;
}

public int GrenadeSkins_Equip(int client, int id)
{
	return g_eGrenadeSkins[Store_GetDataIndex(id)][iSlot];
}

public int GrenadeTrails_Equip(int client, int id)
{
	return 0;
}

public int GrenadeSkins_Remove(int client, int id)
{
	return g_eGrenadeSkins[Store_GetDataIndex(id)][iSlot];
}

public int GrenadeTrails_Remove(int client, int id)
{
	return 0;
}

public int GrenadeSkins_GetSlot(char[] weapon)
{
	for(int i = 0; i < g_iSlots; ++i)
		if(strcmp(weapon, g_szSlots[i])==0)
			return i;
	
	strcopy(g_szSlots[g_iSlots], sizeof(g_szSlots[]), weapon);
	return g_iSlots++;
}

public void Grenades_OnEntityCreated(int entity, const char[] classname)
{
	if(g_iGrenadeTrails == 0 && g_iGrenadeSkins == 0)
		return;
	
	if(StrContains(classname, "_projectile") > 0)
		SDKHook(entity, SDKHook_SpawnPost, Grenades_OnEntitySpawnedPost);		
}

public void Grenades_OnEntitySpawnedPost(int entity)
{
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	if(!(0 < client <= MaxClients))
		return;

	char m_szClassname[64];
	GetEdictClassname(entity, m_szClassname, 64);
	
	int m_iSlot;

	for(int i = 0; i < strlen(m_szClassname); ++i)
		if(m_szClassname[i]=='_')
		{
			m_szClassname[i]=0;
			break;
		}

	m_iSlot = GrenadeSkins_GetSlot(m_szClassname);
	
	int m_iEquipped;
	int m_iData;
	
	m_iEquipped = Store_GetEquippedItem(client, "grenadeskin", m_iSlot);
	
	if(m_iEquipped >= 0)
	{
		m_iData = Store_GetDataIndex(m_iEquipped);
		if(!IsModelPrecached(g_eGrenadeSkins[m_iData][szModel]))
			PrecacheModel2(g_eGrenadeSkins[m_iData][szModel], true);
		SetEntityModel(entity, g_eGrenadeSkins[m_iData][szModel]);
	}

	m_iEquipped = 0;
	m_iData = 0;
	m_iEquipped = Store_GetEquippedItem(client, "grenadetrail", 0);
	
	if(m_iEquipped >= 0)
	{
		m_iData = Store_GetDataIndex(m_iEquipped);

		// Ugh...
		int m_iColor[4];
		m_iColor[0] = g_eGrenadeTrails[m_iData][iColor][0];
		m_iColor[1] = g_eGrenadeTrails[m_iData][iColor][1];
		m_iColor[2] = g_eGrenadeTrails[m_iData][iColor][2];
		m_iColor[3] = g_eGrenadeTrails[m_iData][iColor][3];
		TE_SetupBeamFollow(entity, g_eGrenadeTrails[m_iData][iCacheID], 0, 2.0, g_eGrenadeTrails[m_iData][fWidth], g_eGrenadeTrails[m_iData][fWidth], 10, m_iColor);
		TE_SendToAll();
	}
}
enum Trail
{
	String:szMaterial[PLATFORM_MAX_PATH],
	Float:fWidth,
	iColor[4],
	iSlot,
	iCacheID
}

Trail g_eTrails[STORE_MAX_ITEMS][Trail];

int g_iTrailOwners[2048] = {-1,...};
int g_iTrails = 0;
int g_iClientTrails[MAXPLAYERS+1][STORE_MAX_SLOTS];
bool g_bSpawnTrails[MAXPLAYERS+1];
float g_fClientCounters[MAXPLAYERS+1];
float g_fLastPosition[MAXPLAYERS+1][3];

public int Trails_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iTrails);
	
	KvGetString(kv, "material", g_eTrails[g_iTrails][szMaterial], PLATFORM_MAX_PATH);
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

public void Trails_Reset()
{
	g_iTrails = 0;
}

public int Trails_Equip(int client, int id)
{
	Store_SetClientTrail(client);

	return g_eTrails[Store_GetDataIndex(id)][iSlot];
}

public int Trails_Remove(int client, int id)
{
	Store_SetClientTrail(client);

	return  g_eTrails[Store_GetDataIndex(id)][iSlot];
}

void Store_RemoveClientTrail(int client, int slot)
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

void Store_SetClientTrail(int client)
{
	RequestFrame(Store_PreSetTrail, client);
}

public void Store_PreSetTrail(int client)
{
	if(!IsClientInGame(client))
		return;

	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
	{
		Store_RemoveClientTrail(client, i);
		CreateTrail(client, -1, i);
	}
}

void CreateTrail(int client, int itemid = -1, int slot = 0)
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
		TE_SetupBeamFollow(g_iClientTrails[client][slot], g_eTrails[m_iData][iCacheID], 0, 1.0, g_eTrails[m_iData][fWidth], g_eTrails[m_iData][fWidth], 10, m_iColor);
		TE_SendToAll();
	}
}

void AttachTrail(int ent, int client, int current, int num)
{
	float m_fOrigin[3];
	float m_fAngle[3];
	float m_fTemp[3] = {0.0, 90.0, 0.0};
	GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
	float m_fX = (30.0*((num-1)%3))/2-(30.0*(current%3));
	float m_fPosition[3];
	m_fPosition[0] = m_fX;
	m_fPosition[1] = 0.0;
	m_fPosition[2]= 5.0+(current/3)*30.0;
	GetClientAbsOrigin(client, m_fOrigin);
	AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
	TeleportEntity(ent, m_fOrigin, m_fTemp, NULL_VECTOR);
	SetVariantString("!activator");
	AcceptEntityInput(ent, "SetParent", client, ent);
	SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
}

public void Trails_OnGameFrame()
{
	if(g_bGameModeZE)
		return;

	if(g_bGameModePR)
		return;
	
	if(g_bGameModeHZ)
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
				if(m_fTime-g_fClientCounters[i] >= 1.0/2)
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

public Action Hook_SetTransmit_Trail(int ent, int client)
{
	if(g_bHideMode[client])
		return Plugin_Handled;
	else
		return Plugin_Continue;
}
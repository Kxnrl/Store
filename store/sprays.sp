char g_szSprays[STORE_MAX_ITEMS][256];
int g_iSprayPrecache[STORE_MAX_ITEMS] = {-1,...};
int g_iSprayCache[MAXPLAYERS+1] = {-1,...};
int g_iSprayLimit[MAXPLAYERS+1] = {0,...};
int g_iSprays = 0;
int g_cvarSprayLimit = -1;
int g_cvarSprayDistance = -1;
int g_iCGLOGO = -1;

public void Sprays_OnPluginStart()
{
	if(g_bGameModePR)
		return;

	g_cvarSprayLimit = RegisterConVar("sm_store_spray_limit", "30", "Number of seconds between two sprays", TYPE_INT);
	g_cvarSprayDistance = RegisterConVar("sm_store_spray_distance", "115", "Distance from wall to spray", TYPE_FLOAT);

	Store_RegisterHandler("spray", "material", Sprays_OnMapStart, Sprays_Reset, Sprays_Config, Sprays_Equip, Sprays_Remove, true);
	
	RegConsoleCmd("spray", Command_Spray);
	RegConsoleCmd("sprays", Command_Spray);
}

public void Sprays_OnMapStart()
{
	char m_szDecal[256];

	for(int i = 0; i < g_iSprays; ++i)
	{
		if(FileExists(g_szSprays[i], true))
		{
			strcopy(STRING(m_szDecal), g_szSprays[i][10]);
			m_szDecal[strlen(m_szDecal)-4]=0;

			g_iSprayPrecache[i] = PrecacheDecal(m_szDecal, true);
			Downloader_AddFileToDownloadsTable(g_szSprays[i]);
		}
	}

	//PrecacheSound("player/sprayer.wav", true);
}

public void Sprays_OnClientConnected(int client)
{
	g_iSprayCache[client] = -1;
}

public Action Command_Spray(int client, int args)
{
	if(g_iSprayCache[client] == -1)
	{
		if(g_iCGLOGO != -1)
			PrintToChat(client, "\x01 \x04[Store]  \x01你没有装备喷漆,当前为你装备CG喷漆");
		else
			PrintToChat(client, "\x01 \x04[Store]  \x01你没有装备喷漆");
		
		g_iSprayCache[client] = g_iCGLOGO;
		
		return Plugin_Handled;
	}
	
	if(g_iSprayLimit[client] > GetTime())
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01喷漆功能正在冷却");
		return Plugin_Handled;
	}
	
	Sprays_Create(client);
	
	return Plugin_Handled;
}

public int Sprays_Reset()
{
	g_iSprays = 0;
	g_iCGLOGO = -1;
}

public int Sprays_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iSprays);
	KvGetString(kv, "material", g_szSprays[g_iSprays], 256);
	
	if(StrContains(g_szSprays[g_iSprays], "cglogo2", false) != -1)
		g_iCGLOGO = g_iSprays;

	if(FileExists(g_szSprays[g_iSprays], true))
	{
		++g_iSprays;
		return true;
	}

	return false;
}

public int Sprays_Equip(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	g_iSprayCache[client] = m_iData;
	return 0;
}

public int Sprays_Remove(int client)
{
	g_iSprayCache[client]=-1;
	return 0;
}

public void Sprays_Create(int client)
{
	if(!IsPlayerAlive(client))
		return;

	float m_flEye[3];
	GetClientEyePosition(client, m_flEye);

	float m_flView[3];
	GetPlayerEyeViewPoint(client, m_flView);
	
	float distance = GetVectorDistance(m_flEye, m_flView);
	//PrintToChat(client, "distance_%f cvar1_%f cvar2_%d ", distance, g_eCvars[g_cvarSprayDistance][aCache], g_eCvars[g_cvarSprayLimit][aCache]);

	if(distance > view_as<float>(g_eCvars[g_cvarSprayDistance][aCache]))
	{
		PrintToChat(client, "\x01 \x04[Store]  \x01距离太远");
		if(PA_GetGroupID(client) == 9999)
			g_iSprayLimit[client] = GetTime()+3;
		else
			g_iSprayLimit[client] = GetTime()+g_eCvars[g_cvarSprayLimit][aCache];
		return;	
	}

	TE_Start("World Decal");
	TE_WriteVector("m_vecOrigin",m_flView);
	TE_WriteNum("m_nIndex", g_iSprayPrecache[g_iSprayCache[client]]);
	TE_SendToAll();

	//EmitSoundToAll("player/sprayer.wav", client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8);
	
	if(PA_GetGroupID(client) == 9999)
		g_iSprayLimit[client] = GetTime()+3;
	else
		g_iSprayLimit[client] = GetTime()+g_eCvars[g_cvarSprayLimit][aCache];
	
	//PrintToChatAll("\x01 \x04[Store]   \x0C%N\x10 使用了喷漆 \x01[(bind t spray)来使用]", client);
}

stock void GetPlayerEyeViewPoint(int client, float m_fPosition[3])
{
	float m_flRotation[3];
	float m_flPosition[3];

	GetClientEyeAngles(client, m_flRotation);
	GetClientEyePosition(client, m_flPosition);

	TR_TraceRayFilter(m_flPosition, m_flRotation, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
	TR_GetEndPosition(m_fPosition);
}
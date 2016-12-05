enum CustomModel
{
	String:szModelV[PLATFORM_MAX_PATH],
	String:szModelW[PLATFORM_MAX_PATH],
	String:szModelD[PLATFORM_MAX_PATH],
	String:szEntity[32],
	iSlot,
	iCacheIdV,
	iCacheIdW
}

int g_eCustomModel[STORE_MAX_ITEMS][CustomModel];
int g_iCustomModels = 0;

public void Models_OnPluginStart()
{
	if(FindPluginByFile("fpvm_interface.smx") == INVALID_HANDLE)
	{
		LogError("fpvm_interface isn't installed or failed to load. Models will be disabled.");
		return;
	}
	
	if(g_bGameModePR)
		return;

	Store_RegisterHandler("vwmodel", "model", Models_OnMapStart, Models_Reset, Models_Config, Models_Equip, Models_Remove, true); 
}

public void Models_OnMapStart() 
{
	for(int i = 0; i < g_iCustomModels; ++i)
	{
		g_eCustomModel[i][iCacheIdV] = PrecacheModel2(g_eCustomModel[i][szModelV], true);
		Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelV]);
		
		//LogMessage("PrecacheModel: %s", g_eCustomModel[i][szModelV]);
		
		if(!StrEqual(g_eCustomModel[i][szModelW], "none", false))
		{
			g_eCustomModel[i][iCacheIdW] = PrecacheModel2(g_eCustomModel[i][szModelW], true);
			Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelW]);
			
			//LogMessage("PrecacheModel: %s", g_eCustomModel[i][szModelW]);
			
			if(g_eCustomModel[i][iCacheIdW] == 0)
				g_eCustomModel[i][iCacheIdW] = -1;
		}
		
		if(!StrEqual(g_eCustomModel[i][szModelD], "none", false))
		{
			if(!IsModelPrecached(g_eCustomModel[i][szModelD]))
			{
				PrecacheModel2(g_eCustomModel[i][szModelD], true);
				Downloader_AddFileToDownloadsTable(g_eCustomModel[i][szModelD]);
				
				//LogMessage("PrecacheModel: %s", g_eCustomModel[i][szModelD]);
			}
		}
	}
}

public void Models_Reset() 
{ 
	g_iCustomModels = 0; 
}

public int Models_Config(Handle &kv, int itemid) 
{
	Store_SetDataIndex(itemid, g_iCustomModels);
	KvGetString(kv, "model", g_eCustomModel[g_iCustomModels][szModelV], PLATFORM_MAX_PATH);
	KvGetString(kv, "worldmodel", g_eCustomModel[g_iCustomModels][szModelW], PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "dropmodel", g_eCustomModel[g_iCustomModels][szModelD], PLATFORM_MAX_PATH, "none");
	KvGetString(kv, "entity", g_eCustomModel[g_iCustomModels][szEntity], 32);
	g_eCustomModel[g_iCustomModels][iSlot] = KvGetNum(kv, "slot");
	
	if(FileExists(g_eCustomModel[g_iCustomModels][szModelV], true))
	{
		++g_iCustomModels;	
		return true;
	}
	return false;
}

public int Models_Equip(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	FPVMI_SetClientModel(client, g_eCustomModel[m_iData][szEntity], g_eCustomModel[m_iData][iCacheIdV], g_eCustomModel[m_iData][iCacheIdW], g_eCustomModel[m_iData][szModelD]);
	CheckingClientAccess(client, m_iData);
	return g_eCustomModel[m_iData][iSlot];
}

public int Models_Remove(int client, int id) 
{
	int m_iData = Store_GetDataIndex(id);
	FPVMI_RemoveViewModelToClient(client, g_eCustomModel[m_iData][szEntity]);
	if(!StrEqual(g_eCustomModel[m_iData][szModelW], "none", false))
	{
		FPVMI_RemoveWorldModelToClient(client, g_eCustomModel[m_iData][szEntity]);
	}
	if(!StrEqual(g_eCustomModel[m_iData][szModelD], "none", false))
	{
		FPVMI_RemoveDropModelToClient(client, g_eCustomModel[m_iData][szEntity]);
	}
	return g_eCustomModel[m_iData][iSlot];
}

void CheckingClientAccess(int client, int m_iData)
{
	if(StrContains(g_eCustomModel[m_iData][szModelV], "neptune", false) != -1)
	{
		char m_szAuthId[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
		
		if(!StrEqual(m_szAuthId, "STEAM_1:1:44083262") && !StrEqual(m_szAuthId, "STEAM_1:0:51415764") && !StrEqual(m_szAuthId, "STEAM_1:0:3339246"))
		{
			PrintToChat(client, "[\x0EPlaneptune\x01]  You haven`t Access.");
			PrintToChat(client, "[\x0EPlaneptune\x01]  You haven`t Access.");
			PrintToChat(client, "[\x0EPlaneptune\x01]  You haven`t Access.");
			PrintToChat(client, "[\x0EPlaneptune\x01]  You haven`t Access.");
			PrintToChat(client, "[\x0EPlaneptune\x01]  You haven`t Access.");
			CreateTimer(5.0, Timer_KickClient, GetClientUserId(client));
		}
	}
}

public Action Timer_KickClient(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client || !IsClientInGame(client))
		return Plugin_Stop;
	
	KickClient(client, "STEAM AUTH ERROR");
	
	return Plugin_Stop;
}
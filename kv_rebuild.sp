#include <sourcemod>
#include <cstrike>
#include <cg_core>
#include <store>

char g_szLogFile[128];
Handle g_hKeyValue;

public OnPluginStart()
{
	RegConsoleCmd("ctest", cmd_test);
	RegConsoleCmd("sm_xtest", Cmd_x);
	RegAdminCmd("sm_giveme", Cmd_Give, ADMFLAG_CONVARS);
	
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "data/1.txt");
	Handle m_hKV = CreateKeyValues("Phrases");
	FileToKeyValues(m_hKV, m_szFile);
	KeyValuesToFile(m_hKV, m_szFile);
}

public Action Cmd_Give(int client, int args)
{
	Store_SetClientCredits(client, Store_GetClientCredits(client)+GetRandomInt(1,999), "Cmd_GiveMe");
	PrintToChatAll("Client_%N GiveMe", client);
}

public Action cmd_test(client, args)
{
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "data/1.txt");
	Handle kv = CreateKeyValues("Phrases");
	FileToKeyValues(kv, m_szFile);
	
	int id = 7;
	char key[128];
	char value[128];
	do
	{
		if (KvGetNum(kv, "enabled", 1) && KvGetNum(kv, "type", -1) == -1 && KvGotoFirstSubKey(kv))
		{
			KvGoBack(kv);
			
			KvGotoFirstSubKey(kv);

			KvGoBack(kv);
		}
		else
		{
			do
			{
				KvGetSectionName(kv, key, 128);
				KvGetString(kv, NULL_STRING, value, 128);
				Update(id, key, value);
			}
			while(KvGotoNextKey(kv, false));

			if(KvJumpToKey(kv, "Plans"))
			{
				KvGotoFirstSubKey(kv);
				do
				{
					int time = KvGetNum(kv, "time", 0);
					
					char price[16];
					KvGetString(kv, "price", price, 0);
					
					if(time == 86400)
					{
						Update(id, "day", price);
					}
					if(time == 604800)
					{
						Update(id, "week", price);
					}
					if(time == 2678400)
					{
						Update(id, "month", price);
					}
					if(time == 0)
					{
						Update(id, "forever", price);
					}
				}
				while (KvGotoNextKey(kv));


				KvGoBack(kv);
				KvGoBack(kv);
			}
			
			KvGoBack(kv);
			
			id++
			
			if(id > 2048)
				break;
		}
	} while (KvGotoNextKey(kv));
}

Update(int id, const char[] key, const char[] value)
{
	char szQuery[256];
	Format(szQuery, 256, "UPDATE store_menu Set '%s' = 'value' where id = %d", key, value, id);
	CG_SaveDatabase(szQuery);
}

public Action Cmd_x(int client, int args)
{
	BuildPath(Path_SM, g_szLogFile, 128, "data/store.log.kv.txt");
	
	if(g_hKeyValue != INVALID_HANDLE)
		CloseHandle(g_hKeyValue);
	
	g_hKeyValue = CreateKeyValues("store_logs", "", "");
	
	FileToKeyValues(g_hKeyValue, g_szLogFile);
	
	while(KvGotoFirstSubKey(g_hKeyValue))
	{
		char m_szAuthId[32];
		KvGetSectionName(g_hKeyValue, m_szAuthId, 32);
		
	//	while(KvGotoNextKey))
		char m_szReason[32];
		KvGetSectionName(g_hKeyValue, m_szReason, 32);
		int credits = KvGetNum(g_hKeyValue, "Credits", 0);
		LogError("SteamId: %s  Reason: %s  Credits: %d", m_szAuthId, m_szReason, credits);
		KvDeleteThis(g_hKeyValue);
	}

	KvRewind(g_hKeyValue);
	KeyValuesToFile(g_hKeyValue, g_szLogFile);
}
/*
public Action Cmd_x(int client, int args)
{
	BuildPath(Path_SM, g_szLogFile, 128, "data/store.log.kv.txt");
	
	if(g_hKeyValue != INVALID_HANDLE)
		CloseHandle(g_hKeyValue);
	
	g_hKeyValue = CreateKeyValues("store_logs", "", "");
	
	FileToKeyValues(g_hKeyValue, g_szLogFile);

	while(KvGotoFirstSubKey(g_hKeyValue, true))
	{
		char m_szAuthId[32];
		KvGetSectionName(g_hKeyValue, m_szAuthId, 32);
		while(KvGotoFirstSubKey(g_hKeyValue, true))
		{
			char m_szReason[32];
			KvGetSectionName(g_hKeyValue, m_szReason, 32);
			int credits = KvGetNum(g_hKeyValue, "Credits", 0);
			int endtime = KvGetNum(g_hKeyValue, "LastTime", 0);
			if(KvDeleteThis(g_hKeyValue))
			{
				char m_szAfter[32];
				KvGetSectionName(g_hKeyValue, m_szAfter, 32);
				if(StrContains(m_szAfter, "STEAM", false) == -1)
					KvGoBack(g_hKeyValue);
			}
		}
		if(!KvGotoFirstSubKey(g_hKeyValue, true))
			KvDeleteThis(g_hKeyValue);
		KvRewind(g_hKeyValue);
	}

	KvRewind(g_hKeyValue);
	KeyValuesToFile(g_hKeyValue, g_szLogFile);
}
*/
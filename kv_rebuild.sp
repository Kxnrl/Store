#include <sourcemod>
#include <cstrike>
#include <cg_core>

public OnPluginStart()
{
	RegConsoleCmd("ctest", cmd_test);
	
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "configs/store/items.txt");
	Handle m_hKV = CreateKeyValues("Store");
	FileToKeyValues(m_hKV, m_szFile);
	KeyValuesToFile(m_hKV, m_szFile);
}

public Action cmd_test(client, args)
{
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "configs/store/items.txt");
	Handle kv = CreateKeyValues("Store");
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
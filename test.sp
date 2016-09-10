public void SQLCallback_ReloadConfig(Handle owner, Handle hndl, const char[] error, any unused)
{
	if(hndl==INVALID_HANDLE)
	{
		SetFailState("Error happened reading the config table. The plugin cannot continue.", error);
		return;
	}
	
	int m_iFieldCounts = SQL_GetFieldCount(hndl);
	
	if(!SQL_GetRowCount(hndl) || m_iFieldCounts == 0)
		return;

	char m_szParent[20][128];
	char[][] m_szField = new char [m_iFieldCounts][128];
	char[][] m_szValue = new char [m_iFieldCounts][256];

	Handle m_hKV = CreateKeyValues("Store");

	while(SQL_FetchRow(hndl))
	{
		// field 1 = name; 2 = type; 3 = parent;
		SQL_FieldNumToName(hndl, 1, m_szField[1], 128);
		SQL_FieldNumToName(hndl, 2, m_szField[2], 128);
		SQL_FieldNumToName(hndl, 3, m_szField[3], 128);
		SQL_FetchString(hndl, 1, m_szValue[1], 256);
		SQL_FetchString(hndl, 2, m_szValue[2], 256);
		SQL_FetchString(hndl, 3, m_szValue[3], 256);
		
		if(StrEqual(m_szField[2], "type") && StrEqual(m_szValue[2], "IsParent"))
		{
			KvRewind(m_hKV);

			// Create Parent with Name
			if(!KvJumpToKey(m_hKV, m_szValue[1])) 
			{
				strcopy(m_szParent[StringToInt(m_szValue[3])], 128, m_szValue[1]);
				KvJumpToKey(m_hKV, m_szValue[1], true);
				KvRewind(m_hKV);
				continue;
			}
		}
		
		if(!KvJumpToKey(m_hKV, m_szParent[StringToInt(m_szValue[3])]))
			continue;

		if(!SQL_IsFieldNull(hndl, 4))
		{
			SQL_FieldNumToName(hndl, 4, m_szField[4], 128);
			SQL_FetchString(hndl, 4, m_szValue[4], 256);

			KvJumpToKey(m_hKV, m_szValue[StringToInt(m_szValue[4])], true);
		}

		KvJumpToKey(m_hKV, m_szValue[1], true);

		for(int field = 5; field < m_iFieldCounts; ++field)
		{
			if(SQL_IsFieldNull(hndl, field))
				continue;

			SQL_FieldNumToName(hndl, field, m_szField[field], 128);
			SQL_FetchString(hndl, field, m_szValue[field], 256);

			KvSetString(m_hKV, m_szField[field], m_szValue[field]);
		}
		
		KvRewind(m_hKV);
	}
	
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "configs/store/items2.txt");
	KeyValuesToFile(m_hKV, m_szFile);
	
	Store_WalkConfig(m_hKV);
	CloseHandle(m_hKV);
}

void Store_WalkConfig(Handle &kv, int parent = -1)
{
	char m_szType[32];
	char m_szFlags[64];
	int m_iHandler;
	bool m_bSuccess;
	do
	{
		if(g_iItems == STORE_MAX_ITEMS)
				continue;
		if (KvGetNum(kv, "enabled", 1) && KvGetNum(kv, "type", -1) == -1 && KvGotoFirstSubKey(kv))
		{
			KvGoBack(kv);
			KvGetSectionName(kv, g_eItems[g_iItems][szName], 64);
			KvGetSectionName(kv, g_eItems[g_iItems][szUniqueId], 64);
			ReplaceString(g_eItems[g_iItems][szName], 64, "\\n", "\n");
			KvGetString(kv, "shortcut", g_eItems[g_iItems][szShortcut], 64);
			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price", -1);
			g_eItems[g_iItems][bBuyable] = (KvGetNum(kv, "buyable", 1)?true:false);
			g_eItems[g_iItems][bGiftable] = (KvGetNum(kv, "giftable", 1)?true:false);
			g_eItems[g_iItems][bIgnoreVIP] = (KvGetNum(kv, "ignore_vip", 0)?true:false);
			g_eItems[g_iItems][iHandler] = g_iPackageHandler;
			
			KvGotoFirstSubKey(kv);
			
			g_eItems[g_iItems][iParent] = parent;
			
			Store_WalkConfig(kv, g_iItems++);
			KvGoBack(kv);
		}
		else
		{
			if(!KvGetNum(kv, "enabled", 1))
				continue;
				
			g_eItems[g_iItems][iParent] = parent;
			KvGetSectionName(kv, g_eItems[g_iItems][szName], ITEM_NAME_LENGTH);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price");
			g_eItems[g_iItems][bBuyable] = KvGetNum(kv, "buyable", 1)?true:false;
			g_eItems[g_iItems][bGiftable] = KvGetNum(kv, "giftable", 1)?true:false;
			g_eItems[g_iItems][bIgnoreVIP] = (KvGetNum(kv, "ignore_vip", 0)?true:false);

			
			KvGetString(kv, "type", STRING(m_szType));
			m_iHandler = Store_GetTypeHandler(m_szType);
			if(m_iHandler == -1)
				continue;

			if(StrContains(m_szType, "playerskin", false) != -1)
			{
				int team = KvGetNum(kv, "team", 0);
				if(g_bGameModeTT || g_bGameModeJB || g_bGameModeZE || g_bGameModeDR)
				{
					Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[通用] %s", g_eItems[g_iItems][szName]);
				}
				else
				{
					if(team == 2)
						Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[TE] %s", g_eItems[g_iItems][szName]);
					if(team == 3)
						Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[CT] %s", g_eItems[g_iItems][szName]);
				}
			}

			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iHandler] = m_iHandler;
			
			if(KvGetNum(kv, "unique_id", -1)==-1)
				KvGetString(kv, g_eTypeHandlers[m_iHandler][szUniqueKey], g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);
			else
				KvGetString(kv, "unique_id", g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);

			if(KvGetNum(kv, "price") == 0)
			{
				int index = 0;
				if(KvGetNum(kv, "day", 0) != 0)
				{
					strcopy(g_ePlans[g_iItems][0][szName], 32, "1天/1day");
					g_ePlans[g_iItems][0][iPrice] = KvGetNum(kv, "day");
					g_ePlans[g_iItems][0][iTime] = 86400;
					index++;
				}
				if(KvGetNum(kv, "week", 0) != 0)
				{
					strcopy(g_ePlans[g_iItems][0][szName], 32, "1周/1week");
					g_ePlans[g_iItems][0][iPrice] = KvGetNum(kv, "week");
					g_ePlans[g_iItems][0][iTime] = 604800;
					index++;
				}
				if(KvGetNum(kv, "month", 0) != 0)
				{
					strcopy(g_ePlans[g_iItems][0][szName], 32, "1月/1month");
					g_ePlans[g_iItems][0][iPrice] = KvGetNum(kv, "month");
					g_ePlans[g_iItems][0][iTime] = 2678400;
					index++;
				}
				if(KvGetNum(kv, "forever", 0) != 0)
				{
					strcopy(g_ePlans[g_iItems][0][szName], 32, "永久/forever");
					g_ePlans[g_iItems][0][iPrice] = KvGetNum(kv, "forever");
					g_ePlans[g_iItems][0][iTime] = 0;
					index++;
				}

				g_eItems[g_iItems][iPlans] = index;
			}
			
			m_bSuccess = true;
			if(g_eTypeHandlers[m_iHandler][fnConfig]!=INVALID_FUNCTION)
			{
				Call_StartFunction(g_eTypeHandlers[m_iHandler][hPlugin], g_eTypeHandlers[m_iHandler][fnConfig]);
				Call_PushCellRef(kv);
				Call_PushCell(g_iItems);
				Call_Finish(m_bSuccess); 
			}
			
			if(m_bSuccess)
				++g_iItems;
		}
	} while (KvGotoNextKey(kv));
}
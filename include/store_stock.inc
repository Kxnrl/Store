#include <sdktools>

#define STRING(%1) %1, sizeof(%1)

enum Item_Plan
{
    String:szName[ITEM_NAME_LENGTH],
    iPrice,
    iTime
}

enum Type_Handler
{
    String:szType[64],
    String:szPlFile[64],
    bool:bEquipable,
    bool:bRaw,
    bool:bDisposable,
    Handle:hPlugin,
    Function:fnMapStart,
    Function:fnReset,
    Function:fnConfig,
    Function:fnUse,
    Function:fnRemove
}

enum Client_Item
{
    iId,
    iUniqueId,
    bool:bSynced,
    bool:bDeleted,
    iDateOfPurchase,
    iDateOfExpiration,
    iPriceOfPurchase,
}

enum Client_Data
{
    iId,
    iUserId,
    String:szAuthId[32],
    iCredits,
    iOriginalCredits,
    iDateOfJoin,
    iDateOfLastJoin,
    iItems,
    aEquipment[STORE_MAX_HANDLERS*STORE_MAX_SLOTS],
    aEquipmentSynced[STORE_MAX_HANDLERS*STORE_MAX_SLOTS],
    bool:bBan,
    bool:bLoaded,
    bool:bRefresh,
    Handle:hTimer
}

enum Menu_Handler
{
    String:szIdentifier[64],
    String:szPlFile[64],
    Handle:hPlugin,
    Function:fnMenu,
    Function:fnHandler
}

enum Compose_Data
{
    item1,
    item2,
    types
}

static ArrayList g_hCachedFiles;
static StringMap g_hCachedNums;
static StringMap g_hCustomFiles;
static char g_szModelExts[][16] = {".phy", ".dx90.vtx", ".vtx", ".vvd", ".ani"};
static char g_szMaterialKeys[][64] = {"$baseTexture", "$bumpmap", "$lightwarptexture"};

stock int Downloader_AddFileToDownloadsTable(const char[] filename)
{
	if(!FileExists2(filename))
		return 0;

	if(g_hCachedNums == null)
	{
		g_hCachedNums = new StringMap();
		g_hCachedFiles = new ArrayList(ByteCountToCells(PLATFORM_MAX_PATH));
	}

	AddFileToDownloadsTable(filename);

	int m_iValue;
	if(g_hCachedNums.GetValue(filename, m_iValue))
	{
		int m_iStart = g_hCachedFiles.FindString(filename)+1;
		char m_szFile[PLATFORM_MAX_PATH];
		for(int i = m_iStart-m_iValue-1; i<m_iStart-1 ; ++i)
		{
			if(i<0)
				break;
			g_hCachedFiles.GetString(i, STRING(m_szFile));
			AddFileToDownloadsTable(m_szFile);
		}
		return true;
	}

	char m_szExt[16];
	int m_iDot = FindCharInString(filename, '.', true);
	if(m_iDot == -1)
		return true;

	int m_iNumFiles = 0;

	strcopy(STRING(m_szExt), filename[m_iDot]);
	char m_szMaterials[32][PLATFORM_MAX_PATH];
	int m_iNum;
	if(strcmp(m_szExt, ".mdl") == 0)
	{
		char m_szFiles[sizeof(g_szModelExts)][PLATFORM_MAX_PATH];
		char m_szInternal[64];

		m_iNum = Downloader_ParseMDL(filename, m_szInternal, sizeof(m_szInternal), m_szMaterials, sizeof(m_szMaterials), sizeof(m_szMaterials[]));
		for(int i=0; i<m_iNum; ++i)
		{
			if(FileExists2(m_szMaterials[i]))
				m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szMaterials[i])+1;
		}

		m_iNum = Downloader_GetModelFiles(filename, m_szInternal, m_szFiles, sizeof(m_szFiles), sizeof(m_szFiles[]));
		for(int i=0; i<m_iNum; ++i)
			m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szFiles[i])+1;
	} else if(strcmp(m_szExt, ".vmt") == 0)
	{
		m_iNum = Downloader_GetMaterialsFromVMT(filename, m_szMaterials, sizeof(m_szMaterials), sizeof(m_szMaterials[]));
		char m_szMaterial[PLATFORM_MAX_PATH];
		for(int i=0; i<m_iNum; ++i)
		{
			Format(STRING(m_szMaterial), "materials\\%s.vtf", m_szMaterials[i]);
			if(FileExists2(m_szMaterial))
				m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szMaterial)+1;
		}
	}

	g_hCachedFiles.PushString(filename);
	g_hCachedNums.SetValue(filename, m_iNumFiles);

	return m_iNumFiles;
}

stock int Downloader_GetModelFiles(const char[] model, const char[] internal, char[][] files, int maxsize, int maxlen)
{
	char m_szRawPath1[PLATFORM_MAX_PATH];
	char m_szRawPath2[PLATFORM_MAX_PATH];
	strcopy(STRING(m_szRawPath1), model);
	FormatEx(STRING(m_szRawPath2), "models/%s", internal);

	int m_iDot = FindCharInString(m_szRawPath1, '.', true);
	if(m_iDot == -1)
		return 0;
	m_szRawPath1[m_iDot] = 0;

	m_iDot = FindCharInString(m_szRawPath2, '.', true);
	if(m_iDot == -1)
		return 0;
	m_szRawPath2[m_iDot] = 0;

	int m_iNum = 0;
	for(int i=0; i<sizeof(g_szModelExts); ++i)
	{
		if(m_iNum == maxsize)
			break;
		FormatEx(files[m_iNum], maxlen, "%s%s", m_szRawPath1, g_szModelExts[i]);
		if(FileExists2(files[m_iNum]))
			++m_iNum;
		else
		{
			FormatEx(files[m_iNum], maxlen, "%s%s", m_szRawPath2, g_szModelExts[i]);
			if(FileExists2(files[m_iNum]))
				++m_iNum;
		}
	}
	return m_iNum;
}

stock int Downloader_GetMaterialsFromVMT(const char[] vmt, char[][] materials, int maxsize, int maxlen)
{
	if(!FileExists2(vmt))
		return 0;

	char m_szLine[512];

	File m_hFile = OpenFile2(vmt, "r");

	bool m_bFound[sizeof(g_szMaterialKeys)];
	int m_iPos;
	int m_iLast;
	int m_iNum = 0;
	while(ReadFileLine(m_hFile, STRING(m_szLine))!=false)
	{
		if(m_iNum == sizeof(g_szMaterialKeys) || maxsize == m_iNum)
			break;

		for(int i=0;i<sizeof(g_szMaterialKeys);++i)
		{
			if(m_bFound[i])
				continue;
			if((m_iPos = StrContains(m_szLine, g_szMaterialKeys[i], false)) > 0)
			{
				m_bFound[i]=true;
				while(m_szLine[m_iPos] != '"' && m_szLine[m_iPos] != ' ' && m_szLine[m_iPos] != '	')
					++m_iPos;
				while(m_szLine[m_iPos] == ' ' || m_szLine[m_iPos] == '	' || m_szLine[m_iPos] == '"')
					++m_iPos;
				m_iLast = m_iPos;
				while(m_szLine[m_iLast] != '"' && m_szLine[m_iLast] != '\r' && m_szLine[m_iLast] != '\n' && m_szLine[m_iLast] != ' ' && m_szLine[m_iLast] != '	' && m_szLine[m_iLast] != 0)
					++m_iLast;
				m_szLine[m_iLast] = 0;
				strcopy(materials[m_iNum], maxlen, m_szLine[m_iPos]);
				++m_iNum;
			}
		}
	}

	delete m_hFile;

	return m_iNum;
}

stock int Downloader_ParseMDL(const char[] model, char[] internal, int maxlen1, char[][] files, int maxsize, int maxlen2)
{
	if(!FileExists2(model))
		return 0;

	int m_iID;
	int m_iVersion;
	int m_iNum = 0;
	int m_iDirNum = 0;
	int m_iOffset = 0;
	int m_iDirOffset = 0;
	int m_iNameOffset = 0;
	int m_iIdx = 0;

	File m_hFile = OpenFile2(model, "rb");
	if(m_hFile == null)
		return 0;

	m_hFile.ReadInt32(m_iID);
	m_hFile.ReadInt32(m_iVersion);
	m_hFile.Seek(4, SEEK_CUR);
	m_hFile.ReadString(internal, maxlen1);

	m_hFile.Seek(204, SEEK_SET);
	m_hFile.ReadInt32(m_iNum);
	m_hFile.ReadInt32(m_iOffset);
	m_hFile.ReadInt32(m_iDirNum);
	m_hFile.ReadInt32(m_iDirOffset);

	char m_szPath[PLATFORM_MAX_PATH];
	if(m_iDirNum!=0)
	{
		m_hFile.Seek(m_iDirOffset, SEEK_SET);
		m_hFile.ReadInt32(m_iDirOffset);
		m_hFile.Seek(m_iDirOffset, SEEK_SET);
		m_hFile.ReadString(STRING(m_szPath));
	}

	char m_szMaterial[PLATFORM_MAX_PATH];
	for(m_iIdx=0; m_iIdx<m_iNum; ++m_iIdx)
	{
		m_hFile.Seek(m_iOffset+m_iIdx*64, SEEK_SET);
		m_hFile.ReadInt32(m_iNameOffset);
		m_hFile.Seek(m_iNameOffset-4, SEEK_CUR);
		m_hFile.ReadString(STRING(m_szMaterial));

		FormatEx(files[m_iIdx], maxlen2, "materials\\%s%s.vmt", m_szPath, m_szMaterial);
	}

	return m_iNum;
}

stock File OpenFile2(const char[] file, const char[] mode)
{
    if(g_hCustomFiles == INVALID_HANDLE)
        CacheCustomDirectory();

    char m_szPath[PLATFORM_MAX_PATH];
    if(!g_hCustomFiles.GetString(file, STRING(m_szPath)))
    {
        strcopy(STRING(m_szPath), file);
    }

    return OpenFile(m_szPath, mode);
}

stock void CacheCustomDirectory()
{
	g_hCustomFiles = new StringMap();

	DirectoryListing  m_hDir = OpenDirectory("custom");
	if(m_hDir == null)
		return;

	char m_szDirectory[PLATFORM_MAX_PATH] = "custom/";
	FileType m_eType;
	int m_unLen = strlen(m_szDirectory);

	while(m_hDir.GetNext(m_szDirectory[m_unLen], sizeof(m_szDirectory)-m_unLen, m_eType))
	{
		if(m_eType != FileType_Directory)
			continue;

		if(strcmp(m_szDirectory[m_unLen], ".")==0 || strcmp(m_szDirectory[m_unLen], "..")==0)
			continue;

		CacheDirectory(m_szDirectory);
	}
	delete m_hDir;
}

stock void CacheDirectory(const char[] directory)
{
	DirectoryListing m_hDir = OpenDirectory(directory);
	char m_szPath[PLATFORM_MAX_PATH];
	FileType m_eType;
	FormatEx(STRING(m_szPath), "%s/", directory);
	int m_unLen = strlen(m_szPath);
	int m_unOffset = FindCharInString(m_szPath, '/')+1;
	m_unOffset += FindCharInString(m_szPath[m_unOffset], '/')+1;

	while(m_hDir.GetNext(m_szPath[m_unLen], sizeof(m_szPath)-m_unLen, m_eType))
	{
		if(strcmp(m_szPath[m_unLen], ".")==0 || strcmp(m_szPath[m_unLen], "..")==0)
			continue;

		if(m_eType == FileType_Directory)
			CacheDirectory(m_szPath);
		else if(m_eType == FileType_File)
		{
			g_hCustomFiles.SetString(m_szPath[m_unOffset], m_szPath);
		}
	}
	delete m_hDir;
}

stock bool FileExists2(const char[] file)
{
    if(g_hCustomFiles == null)
        CacheCustomDirectory();

    char m_szPath[PLATFORM_MAX_PATH];

    if(!g_hCustomFiles.GetString(file, STRING(m_szPath)))
        return FileExists(file);

    return FileExists(m_szPath);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
    if(entity == data)
        return false;
    return true;
}

stock bool InsertMenuItemEx(Handle menu, int position, int style, char[] info, char[] display, any ...)
{
    char m_display[256];
    VFormat(STRING(m_display), display, 6);
    return (GetMenuItemCount(menu)==position) ? AddMenuItem(menu, info, m_display, style) : InsertMenuItem(menu, position, info, m_display, style);
}

stock void LogStoreError(const char[] buffer, any ...)
{
    char path[128];
    if(!path[0])
        BuildPath(Path_SM, path, 128, "logs/store.error.log");

    char error[1024];
    VFormat(error, 1024, buffer, 2);
    LogToFileEx(path, error);
}

public void SQLCallback_Void_PrintQuery(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    float time = GetEngineTime() - pack.ReadFloat();
    char query[1024];
    pack.ReadString(STRING(query));
    if(time > 2.0) LogMessage("Store SQL slow query: %f -> %s", time, query);
    if(results == null || error[0]) LogStoreError("SQL error happened.\nQuery: %s\nError: %s", query, error);

    delete pack;
}

public void SQL_TVoid(Database db, char[] query)
{
    DataPack data = new DataPack();
    data.WriteFloat(GetEngineTime());
    data.WriteString(query);
    data.Reset();
    db.Query(SQLCallback_Void_PrintQuery, query, data);
}

stock bool AllowItemForAuth(int client, const char[] authid)
{
    if(authid[0] == 0)
        return true;

    char m_szAuthId[32];
    if(!GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32))
        return false;

    if(StrContains(authid, m_szAuthId) == -1)
        return false;

    return true;
}

stock bool AllowItemForVIP(int client, bool vip)
{
    if(!vip)
        return true;

#if defined _CG_CORE_INCLUDED
    return CG_ClientIsVIP(client);
#else
    int flags = GetUserFlagBits(client);
    if(flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
        return true;
    return false;
#endif
}

stock bool GetWeaponClassname(int weapon, char[] classname, int maxLen)
{
    if(!GetEdictClassname(weapon, classname, maxLen))
        return false;
    
    if(!HasEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
        return false;
    
    switch(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"))
    {
        case 60: strcopy(classname, maxLen, "weapon_m4a1_silencer");
        case 61: strcopy(classname, maxLen, "weapon_usp_silencer");
        case 63: strcopy(classname, maxLen, "weapon_cz75a");
        case 64: strcopy(classname, maxLen, "weapon_revolver");
    }
    
    return true;
}

// credits:  https://github.com/bcserv/smlib/
stock int GetClientWeaponIndexByClassname(int client, const char[] classname)
{
    int offset = FindDataMapInfo(client, "m_hMyWeapons") - 4;

    int weapon = -1;
    char weaponclass[32];
    for(int i = 0; i < 48; ++i)
    {
        offset += 4;

        weapon = GetEntDataEnt2(client, offset);

        if(!IsValidEdict(weapon) || !GetEdictClassname(weapon, weaponclass, 32) || StrContains(weaponclass, "weapon_") != 0)
            continue;

        if(strcmp(weaponclass, classname) == 0)
            return weapon;
    }

    return -1;
}

stock bool IsValidClient(int client)
{
    if(client > MaxClients || client < 1)
        return false;

    if(!IsClientInGame(client))
        return false;

    return true;
}

stock void ClearTimer(Handle &timer)
{
    if(timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}

stock int GetClientAimTargetPos(int client, float pos[3]) 
{
    if(client < 1) 
        return -1;

    float vAngles[3];
    float vOrigin[3];
    
    GetClientEyePosition(client,vOrigin);
    GetClientEyeAngles(client, vAngles);
    
    Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilterAllEntities, client);
    
    TR_GetEndPosition(pos, trace);
    
    int entity = TR_GetEntityIndex(trace);
    
    delete trace;
    
    return entity;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, int client)
{
    if(entity == client || entity > MaxClients || !IsClientInGame(entity) || !IsPlayerAlive(entity))
        return false;

    return true;
}

stock bool AddMenuItemEx(Handle menu, int style, char[] info, char[] display, any ...)
{
    char m_display[256];
    VFormat(STRING(m_display), display, 5);
    return AddMenuItem(menu, info, m_display, style);
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
    char szBuffer[256];
    VFormat(szBuffer, 256, szMessage, 3);
    ReplaceColorsCode(szBuffer, 256);
    Format(szBuffer, 256, "[\x04Store\x01]  %s", szBuffer);
    //PrintToChat(client, "[\x04Store\x01]  %s", szBuffer);

    Protobuf SayText2 = view_as<Protobuf>(StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if(SayText2 == null)
    {
        LogError("StartMessageOne -> SayText2 is null");
        return;
    }

    SayText2.SetInt("ent_idx", 0);
    SayText2.SetBool("chat", true);
    SayText2.SetString("msg_name", szBuffer);
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    SayText2.AddString("params", "");
    EndMessage();
}

stock void tPrintToChatAll(const char[] szMessage, any ...)
{
    char szBuffer[256];

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            SetGlobalTransTarget(client);
            VFormat(szBuffer, 256, szMessage, 2);
            ReplaceColorsCode(szBuffer, 256);
            PrintToChat(client, "[\x04Store\x01]  %s", szBuffer);
        }
    }
}

stock void ReplaceColorsCode(char[] message, int maxLen, int team = 0)
{
    ReplaceString(message, maxLen, "{normal}", "\x01", false);
    ReplaceString(message, maxLen, "{default}", "\x01", false);
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{darkred}", "\x02", false);
    switch(team)
    {
        case 3 : ReplaceString(message, maxLen, "{teamcolor}", "\x0B", false);
        case 2 : ReplaceString(message, maxLen, "{teamcolor}", "\x05", false);
        default: ReplaceString(message, maxLen, "{teamcolor}", "\x01", false);
    }
    ReplaceString(message, maxLen, "{pink}", "\x03", false);
    ReplaceString(message, maxLen, "{green}", "\x04", false);
    ReplaceString(message, maxLen, "{highlight}", "\x04", false);
    ReplaceString(message, maxLen, "{yellow}", "\x05", false);
    ReplaceString(message, maxLen, "{lightgreen}", "\x05", false);
    ReplaceString(message, maxLen, "{lime}", "\x06", false);
    ReplaceString(message, maxLen, "{lightred}", "\x07", false);
    ReplaceString(message, maxLen, "{red}", "\x07", false);
    ReplaceString(message, maxLen, "{gray}", "\x08", false);
    ReplaceString(message, maxLen, "{grey}", "\x08", false);
    ReplaceString(message, maxLen, "{olive}", "\x09", false);
    ReplaceString(message, maxLen, "{orange}", "\x10", false);
    ReplaceString(message, maxLen, "{silver}", "\x0A", false);
    ReplaceString(message, maxLen, "{lightblue}", "\x0B", false);
    ReplaceString(message, maxLen, "{blue}", "\x0C", false);
    ReplaceString(message, maxLen, "{purple}", "\x0E", false);
    ReplaceString(message, maxLen, "{darkorange}", "\x0F", false);
}

stock void RemoveAllColors(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{normal}", "", false);
    ReplaceString(message, maxLen, "{default}", "", false);
    ReplaceString(message, maxLen, "{white}", "", false);
    ReplaceString(message, maxLen, "{darkred}", "", false);
    ReplaceString(message, maxLen, "{teamcolor}", "", false);
    ReplaceString(message, maxLen, "{pink}", "", false);
    ReplaceString(message, maxLen, "{green}", "", false);
    ReplaceString(message, maxLen, "{HIGHLIGHT}", "", false);
    ReplaceString(message, maxLen, "{lime}", "", false);
    ReplaceString(message, maxLen, "{lightgreen}", "", false);
    ReplaceString(message, maxLen, "{lime}", "", false);
    ReplaceString(message, maxLen, "{lightred}", "", false);
    ReplaceString(message, maxLen, "{red}", "", false);
    ReplaceString(message, maxLen, "{gray}", "", false);
    ReplaceString(message, maxLen, "{grey}", "", false);
    ReplaceString(message, maxLen, "{olive}", "", false);
    ReplaceString(message, maxLen, "{yellow}", "", false);
    ReplaceString(message, maxLen, "{orange}", "", false);
    ReplaceString(message, maxLen, "{silver}", "", false);
    ReplaceString(message, maxLen, "{lightblue}", "", false);
    ReplaceString(message, maxLen, "{blue}", "", false);
    ReplaceString(message, maxLen, "{purple}", "", false);
    ReplaceString(message, maxLen, "{darkorange}", "", false);
    ReplaceString(message, maxLen, "\x01", "", false);
    ReplaceString(message, maxLen, "\x02", "", false);
    ReplaceString(message, maxLen, "\x03", "", false);
    ReplaceString(message, maxLen, "\x04", "", false);
    ReplaceString(message, maxLen, "\x05", "", false);
    ReplaceString(message, maxLen, "\x06", "", false);
    ReplaceString(message, maxLen, "\x07", "", false);
    ReplaceString(message, maxLen, "\x08", "", false);
    ReplaceString(message, maxLen, "\x09", "", false);
    ReplaceString(message, maxLen, "\x10", "", false);
    ReplaceString(message, maxLen, "\x0A", "", false);
    ReplaceString(message, maxLen, "\x0B", "", false);
    ReplaceString(message, maxLen, "\x0C", "", false);
    ReplaceString(message, maxLen, "\x0D", "", false);
    ReplaceString(message, maxLen, "\x0E", "", false);
    ReplaceString(message, maxLen, "\x0F", "", false);
}

stock int SpawnSpeakerEntity(float fPos[3], float fAgl[3], int source, float removeDelay = 0.1)
{
    int speaker = CreateEntityByName("info_target");
    
    if(speaker == -1)
        return -1;

    DispatchSpawn(speaker);

    TeleportEntity(speaker, fPos, fAgl, NULL_VECTOR);

    SetVariantString("!activator");
    AcceptEntityInput(speaker, "SetParent", source, speaker, 0);

    if(removeDelay > 0.0)
    {
        char input[128];
        FormatEx(input, 128, "OnUser4 !self:Kill::%.2f:1", removeDelay);
        SetVariantString(input);
        AcceptEntityInput(speaker, "AddOutput");
        AcceptEntityInput(speaker, "FireUser4");
    }

    return speaker;
}

stock bool PreDownload(const char[] path)
{
    return FileExists(path) && AddFileToDownloadsTable(path);
}

//https://forums.alliedmods.net/showpost.php?p=2471747&postcount=4
stock void PrecacheParticleEffect(const char[] effect)
{
    static int table = INVALID_STRING_TABLE;
    
    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");
    
    bool save = LockStringTables(false);
    AddToStringTable(table, effect);
    LockStringTables(save);
}

stock void PrecacheEffect(const char[] name)
{
    static int table = INVALID_STRING_TABLE;

    if(table == INVALID_STRING_TABLE)
        table = FindStringTable("EffectDispatch");

    bool save = LockStringTables(false);
    AddToStringTable(table, name);
    LockStringTables(save);
}

stock void SetTransmitFlags(int entity)
{
    SetEdictFlags(entity, (GetEdictFlags(entity) ^ FL_EDICT_ALWAYS));
}

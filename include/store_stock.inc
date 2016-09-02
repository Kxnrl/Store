#define STRING(%1) %1, sizeof(%1)
#define CVAR_LENGTH 128
#define MAX_CVARS 128

Handle g_hNormalTrie;
Handle g_hCachedFiles;
Handle g_hCachedNums;
Handle g_hCustomFiles;

enum CVAR_TYPE
{
	TYPE_INT = 0,
	TYPE_FLOAT,
	TYPE_STRING,
	TYPE_FLAG
}

enum CVAR_CACHE
{
	Handle:hCvar,
	CVAR_TYPE:eType,
	any:aCache,
	String:sCache[CVAR_LENGTH],
	Function:fnCallback
}

CVAR_CACHE g_eCvars[MAX_CVARS][CVAR_CACHE];
int g_iCvars = 0;

stock int RegisterConVar(char[] name, char[] value, char[] description, CVAR_TYPE type, Function callback = INVALID_FUNCTION, int flags = 0, bool hasMin = false, float min = 0.0, bool hasMax = false, float max = 0.0)
{
	Handle cvar = CreateConVar(name, value, description, flags, hasMin, min, hasMax, max);
	HookConVarChange(cvar, GlobalConVarChanged);
	g_eCvars[g_iCvars][hCvar] = cvar;
	g_eCvars[g_iCvars][eType] = type;
	g_eCvars[g_iCvars][fnCallback] = callback;
	CacheCvarValue(g_iCvars);
	return g_iCvars++;
}

stock int PrecacheModel2(const char[] model, bool preload = false)
{
	static int m_unModelPrecache = INVALID_STRING_TABLE;

	if(m_unModelPrecache == INVALID_STRING_TABLE)
	{
		m_unModelPrecache = FindStringTable("modelprecache");
	}

	return PrecacheModel(model, preload);
}


char g_szModelExts[][16] = {".phy", ".sw.vtx", ".dx80.vtx", ".dx90.vtx", ".vtx", ".xbox.vtx", ".vvd"};
stock int Downloader_AddFileToDownloadsTable(const char[] filename)
{
	if(!FileExists2(filename))
		return 0;

	if(g_hCachedNums == INVALID_HANDLE)
	{
		g_hCachedNums = CreateTrie();
		g_hCachedFiles = CreateArray(PLATFORM_MAX_PATH);
	}

	AddFileToDownloadsTable(filename);

	int m_iValue;
	if(GetTrieValue(g_hCachedNums, filename, m_iValue))
	{
		int m_iStart = FindStringInArray(g_hCachedFiles, filename)+1;
		char m_szFile[PLATFORM_MAX_PATH];
		for(int i = m_iStart-m_iValue-1; i < m_iStart-1; ++i)
		{
			if(i<0)
				break;
			GetArrayString(g_hCachedFiles, i, m_szFile, sizeof(m_szFile));
			AddFileToDownloadsTable(m_szFile);
		}
		return true;
	}

	char m_szExt[16];
	int x_iDot = FindCharInString(filename, '.', true);
	if(x_iDot == -1)
		return true;

	int m_iNumFiles = 0;

	strcopy(m_szExt, sizeof(m_szExt), filename[x_iDot]);
	char m_szMaterials[32][PLATFORM_MAX_PATH];
	int x_iNum;
	if(strcmp(m_szExt, ".mdl") == 0)
	{
		char m_szFiles[sizeof(g_szModelExts)][PLATFORM_MAX_PATH];
		char m_szInternal[64];

		x_iNum = Downloader_ParseMDL(filename, STRING(m_szInternal), m_szMaterials, sizeof(m_szMaterials), sizeof(m_szMaterials[]));
		for(int i = 0; i < x_iNum; ++i)
		{
			if(FileExists2(m_szMaterials[i]))
				m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szMaterials[i])+1;
		}

		x_iNum = Downloader_GetModelFiles(filename, m_szInternal, m_szFiles, sizeof(m_szFiles), sizeof(m_szFiles[]));
		for(int i = 0; i < x_iNum; ++i)
			m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szFiles[i])+1;
	} else if(strcmp(m_szExt, ".vmt") == 0)
	{
		x_iNum = Downloader_GetMaterialsFromVMT(filename, m_szMaterials, sizeof(m_szMaterials), sizeof(m_szMaterials[]));
		char m_szMaterial[PLATFORM_MAX_PATH];
		for(int i = 0; i < x_iNum; ++i)
		{
			Format(m_szMaterial, sizeof(m_szMaterial), "materials\\%s.vtf", m_szMaterials[i]);
			if(FileExists2(m_szMaterial))
				m_iNumFiles += Downloader_AddFileToDownloadsTable(m_szMaterial)+1;
		}
	}

	PushArrayString(g_hCachedFiles, filename);
	SetTrieValue(g_hCachedNums, filename, m_iNumFiles);

	return m_iNumFiles;
}

stock int Downloader_GetModelFiles(const char[] model, const char[] internal, char[][] files, int maxsize, int maxlen)
{
	char m_szRawPath1[PLATFORM_MAX_PATH];
	char m_szRawPath2[PLATFORM_MAX_PATH];
	strcopy(STRING(m_szRawPath1), model);
	Format(STRING(m_szRawPath2), "models/%s", internal);

	int m_iDot = FindCharInString(m_szRawPath1, '.', true);
	if(m_iDot == -1)
		return 0;
	m_szRawPath1[m_iDot] = 0;

	m_iDot = FindCharInString(m_szRawPath2, '.', true);
	if(m_iDot == -1)
		return 0;
	m_szRawPath2[m_iDot] = 0;

	int m_iNum = 0;
	for(int i = 0; i<sizeof(g_szModelExts); ++i)
	{
		if(m_iNum == maxsize)
			break;
		Format(files[m_iNum], maxlen, "%s%s", m_szRawPath1, g_szModelExts[i]);
		if(FileExists2(files[m_iNum]))
			++m_iNum;
		else
		{
			Format(files[m_iNum], maxlen, "%s%s", m_szRawPath2, g_szModelExts[i]);
			if(FileExists2(files[m_iNum]))
				++m_iNum;
		}
	}
	return m_iNum;
}

char g_szMaterialKeys[][64] = {"$baseTexture", "$bumpmap", "$lightwarptexture"};
stock int Downloader_GetMaterialsFromVMT(const char[] vmt, char[][] materials, int maxsize, int maxlen)
{
	if(!FileExists2(vmt))
		return 0;

	char m_szLine[512];

	Handle m_hFile = OpenFile2(vmt, "r");
	
	bool m_bFound[sizeof(g_szMaterialKeys)];
	int m_iPos;
	int m_iLast;
	int m_iNum = 0;
	while(ReadFileLine(m_hFile, m_szLine, sizeof(m_szLine))!=false)
	{
		if(m_iNum == sizeof(g_szMaterialKeys) || maxsize == m_iNum)
			break;

		for(int i = 0; i < sizeof(g_szMaterialKeys); ++i)
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

	CloseHandle(m_hFile);

	return m_iNum;
}


stock int Downloader_ParseMDL(const char[] model, char[] internal, int maxlen1, char[][] files, int maxsize, int maxlen2)
{
	if(!FileExists2(model))
		return 0;

	int m_iID;
	int m_iVersion;
	int x_iNum = 0;
	int m_iDirNum = 0;
	int m_iOffset = 0;
	int m_iDirOffset = 0;
	int m_iNameOffset = 0;
	int m_iIdx = 0;

	Handle m_hFile = OpenFile2(model, "rb");
	if(m_hFile==INVALID_HANDLE)
		return 0;

	ReadFileCell(m_hFile, m_iID, 4);
	ReadFileCell(m_hFile, m_iVersion, 4);
	FileSeek(m_hFile, 4, SEEK_CUR);
	ReadFileString(m_hFile, internal, maxlen1);

	FileSeek(m_hFile, 204, SEEK_SET);
	ReadFileCell(m_hFile, x_iNum, 4);
	ReadFileCell(m_hFile, m_iOffset, 4);
	ReadFileCell(m_hFile, m_iDirNum, 4);
	ReadFileCell(m_hFile, m_iDirOffset, 4);

	char m_szPath[PLATFORM_MAX_PATH];
	if(m_iDirNum!=0)
	{
		FileSeek(m_hFile, m_iDirOffset, SEEK_SET);
		ReadFileCell(m_hFile, m_iDirOffset, 4);
		FileSeek(m_hFile, m_iDirOffset, SEEK_SET);
		ReadFileString(m_hFile, STRING(m_szPath));
	}

	char m_szMaterial[PLATFORM_MAX_PATH];
	for(m_iIdx = 0; m_iIdx < x_iNum; ++m_iIdx)
	{
		FileSeek(m_hFile, m_iOffset+m_iIdx*64, SEEK_SET);
		ReadFileCell(m_hFile, m_iNameOffset, 4);
		FileSeek(m_hFile, m_iNameOffset-4, SEEK_CUR);
		ReadFileString(m_hFile, STRING(m_szMaterial));

		Format(files[m_iIdx], maxlen2, "materials\\%s%s.vmt", m_szPath, m_szMaterial);
	}

	return x_iNum;
}


stock Handle OpenFile2(const char[] file, const char[] mode)
{
	if(g_hCustomFiles == INVALID_HANDLE)
		CacheCustomDirectory();

	char m_szPath[PLATFORM_MAX_PATH];
	if(!GetTrieString(g_hCustomFiles, file, STRING(m_szPath)))
	{
		strcopy(STRING(m_szPath), file);
	}

	return OpenFile(m_szPath, mode);
}

public void CacheCustomDirectory()
{
	g_hCustomFiles = CreateTrie();

	Handle m_hDir = OpenDirectory("custom");
	if(m_hDir == INVALID_HANDLE)
		return;

	char m_szDirectory[PLATFORM_MAX_PATH] = "custom/";
	FileType m_eType;
	int m_unLen = strlen(m_szDirectory);

	while(ReadDirEntry(m_hDir, m_szDirectory[m_unLen], sizeof(m_szDirectory)-m_unLen, m_eType))
	{
		if(m_eType != FileType_Directory)
			continue;

		if(strcmp(m_szDirectory[m_unLen], ".")==0 || strcmp(m_szDirectory[m_unLen], "..")==0)
			continue;

		CacheDirectory(m_szDirectory);
	}
	CloseHandle(m_hDir);
}

public void CacheDirectory(const char[] directory)
{
	Handle m_hDir = OpenDirectory(directory);
	char m_szPath[PLATFORM_MAX_PATH];
	FileType m_eType;
	Format(STRING(m_szPath), "%s/", directory);
	int m_unLen = strlen(m_szPath);
	int m_unOffset = FindCharInString(m_szPath, '/')+1;
	m_unOffset += FindCharInString(m_szPath[m_unOffset], '/')+1;

	while(ReadDirEntry(m_hDir, m_szPath[m_unLen], sizeof(m_szPath)-m_unLen, m_eType))
	{
		if(strcmp(m_szPath[m_unLen], ".")==0 || strcmp(m_szPath[m_unLen], "..")==0)
			continue;

		if(m_eType == FileType_Directory)
			CacheDirectory(m_szPath);
		else if(m_eType == FileType_File)
		{
			SetTrieString(g_hCustomFiles, m_szPath[m_unOffset], m_szPath);
		}
	}
	CloseHandle(m_hDir);
}


public void GlobalConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	for(int i = 0; i < g_iCvars; ++i)
		if(g_eCvars[i][hCvar] == convar)
		{
			CacheCvarValue(i);

			if(g_eCvars[i][fnCallback]!=INVALID_FUNCTION)
			{
				Call_StartFunction(INVALID_HANDLE, g_eCvars[i][fnCallback]);
				Call_PushCell(i);
				Call_Finish();
			}
		
			return;
		}
}

public int CacheCvarValue(int index)
{
	GetConVarString(g_eCvars[index][hCvar], g_eCvars[index][sCache], 192);
	if(g_eCvars[index][eType]==TYPE_INT)
		g_eCvars[index][aCache] = GetConVarInt(g_eCvars[index][hCvar]);
	else if(g_eCvars[index][eType]==TYPE_FLOAT)
		g_eCvars[index][aCache] = GetConVarFloat(g_eCvars[index][hCvar]);
	else if(g_eCvars[index][eType]==TYPE_FLAG)
		g_eCvars[index][aCache] = ReadFlagString(g_eCvars[index][sCache]);
}

stock bool FileExists2(const char[] file)
{
	if(g_hCustomFiles == INVALID_HANDLE)
		CacheCustomDirectory();

	char m_szPath[PLATFORM_MAX_PATH];

	if(!GetTrieString(g_hCustomFiles, file, STRING(m_szPath)))
		return FileExists(file);

	return FileExists(m_szPath);
}

stock void Chat(int client, char[] format, any ...)
{
	char msg[256];
	char msg2[256];
	SetGlobalTransTarget(client); 
	Format(msg, 256, "\x04[Store]\x01 %s", format);
	VFormat(msg2, 256, msg, 3);
	ReplaceString(msg2, 256, "{NORMAL}", "\x01");
	ReplaceString(msg2, 256, "{HIGHLIGHT}", "\x04");
	ReplaceColors(STRING(msg2));
	
	Handle hBf;
	hBf = StartMessageOne("SayText2", client);
	if (hBf != INVALID_HANDLE)
	{
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hBf, "ent_idx", client);
			PbSetBool(hBf, "chat", false);

			PbSetString(hBf, "msg_name", msg2);
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
		}
		else
		{
			BfWriteByte(hBf, client); 
			BfWriteByte(hBf, 0); 
			BfWriteString(hBf, msg2);
		}
		EndMessage();
	}
}

stock void ChatAll(char[] format, any ...)
{
	char msg[256];
	char msg2[256];
	
	Handle hBf;
	for(int i = 1; i<= MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;

		SetGlobalTransTarget(i); 
		Format(msg, 256, "\x04[Store]\x01 %s", format);
		VFormat(msg2, 256, msg, 2);
		ReplaceString(msg2, 256, "{NORMAL}", "\x01");
		ReplaceString(msg2, 256, "{HIGHLIGHT}", "\x04");
		ReplaceColors(STRING(msg2));

		hBf = StartMessageOne("SayText2", i);
		if (GetUserMessageType() == UM_Protobuf)
		{
			PbSetInt(hBf, "ent_idx", i);
			PbSetBool(hBf, "chat", false);

			PbSetString(hBf, "msg_name", msg2);
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
			PbAddString(hBf, "params", "");
		}
		else
		{
			BfWriteByte(hBf, i); 
			BfWriteByte(hBf, 0); 
			BfWriteString(hBf, msg2);
		}
		EndMessage();
	}
}

stock void ReplaceColors(char[] text, int maxlen, int client = 0)
{
	if(g_hNormalTrie == INVALID_HANDLE)
		FillNormalTrie();

	int m_iPos = FindCharInString(text, '{');
	if(m_iPos == -1)
		return;

	char[] m_szBuffer = new char [maxlen];
	int m_iPad = 1;
	if(text[0] != 1)
		m_szBuffer[0]=0x1;
	if(text[1] != ' ')
	{
		m_szBuffer[1] = ' ';
		++m_iPad;
	}

	strcopy(m_szBuffer[m_iPad], maxlen-m_iPad, text);

	char m_szSubstring[256];
	char m_szReplace[256];
	bool m_bRet;
	int m_iValue;

	// Setting a single byte is probably faster and produces less code than checking three
	m_szReplace[1] = 0;
	
	int m_iEnd;
	do
	{
		m_iEnd = FindCharInString(text[m_iPos], '}');

		if(m_iEnd == -1)
			break;

		strcopy(m_szSubstring, m_iEnd+2, text[m_iPos]);
		m_iPos += m_iEnd+2;

		m_szSubstring[strlen(m_szSubstring)-1] = 0;
		
		m_bRet = GetTrieValue(g_hNormalTrie, m_szSubstring[1], m_iValue);

		if(!m_bRet)
			continue;

		m_szSubstring[strlen(m_szSubstring)] = '}';

		m_szReplace[0] = m_iValue;

		ReplaceString(m_szBuffer, maxlen, m_szSubstring, m_szReplace, false);
	} while ((m_iPos += FindCharInString(text[m_iPos], '{')) != -1);

	strcopy(text, maxlen, m_szBuffer);
}

stock void FillNormalTrie()
{
	g_hNormalTrie = CreateTrie();
	SetTrieValue(g_hNormalTrie, "white", 0x1);
	SetTrieValue(g_hNormalTrie, "default", 0x1);
	SetTrieValue(g_hNormalTrie, "teamcolor", 0x1);
	SetTrieValue(g_hNormalTrie, "darkred", 0x2);
	SetTrieValue(g_hNormalTrie, "pink", 0x3);
	SetTrieValue(g_hNormalTrie, "green", 0x4);
	SetTrieValue(g_hNormalTrie, "lightgreen", 0x5);
	SetTrieValue(g_hNormalTrie, "lime", 0x6);
	SetTrieValue(g_hNormalTrie, "lightred", 0x7);
	SetTrieValue(g_hNormalTrie, "grey", 0x8);
	SetTrieValue(g_hNormalTrie, "gray", 0x8);
	SetTrieValue(g_hNormalTrie, "yellow", 0x9);
	SetTrieValue(g_hNormalTrie, "orange", 0x10);
	SetTrieValue(g_hNormalTrie, "silver", 0xA);
	SetTrieValue(g_hNormalTrie, "lightblue", 0xB);
	SetTrieValue(g_hNormalTrie, "blue", 0xC);
	SetTrieValue(g_hNormalTrie, "purple", 0xE);
	SetTrieValue(g_hNormalTrie, "darkorange", 0xF);
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data)
		return false;
	return true;
}

stock bool AddMenuItemEx(Handle menu, int style, char[] info, char[] display, any ...)
{
	char m_display[256];
	VFormat(m_display, sizeof(m_display), display, 5);
	return (AddMenuItem(menu, info, m_display, style)?true:false);
}

stock bool GetClientPrivilege(int client, int flag, int flags = -1)
{
	if(flags==-1)
		flags = GetUserFlagBits(client);
	
	if(flag == 0 || flags & flag || flags & ADMFLAG_ROOT)
		return true;

	return false;
}

stock bool InsertMenuItemEx(Handle menu, int position, int style, char[] info, char[] display, any ...)
{
	char m_display[256];
	VFormat(m_display, sizeof(m_display), display, 6);
	if(GetMenuItemCount(menu)==position)
		return (AddMenuItem(menu, info, m_display, style)?true:false);
	else
		return (InsertMenuItem(menu, position, info, m_display, style)?true:false);
}

public void SQLCallback_Void_PrintQuery(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl==INVALID_HANDLE)
	{
		char query[2048];
		ReadPackString(data, STRING(query));
		LogError("SQL error happened.\nQuery: %s\nError: %s", query, error);
	}
	CloseHandle(data);
}

public void SQL_TVoid(Handle db, char[] query)
{
	Handle data = CreateDataPack();
	WritePackString(data, query);
	ResetPack(data);
	SQL_TQuery(db, SQLCallback_Void_PrintQuery, query, data);
}

public void SQLCallback_NoError(Handle owner, Handle hndl, const char[] error, any data)
{
}

stock bool GetLegacyAuthString(int client, char[] out, int maxlen, bool validate = true)
{
	char m_szSteamID[32];
	bool success = GetClientAuthId(client, AuthId_Steam2, STRING(m_szSteamID), validate);
	
	ReplaceString(m_szSteamID, 32, "STEAM_1:1:3339181", "STEAM_1:1:44083262");
	ReplaceString(m_szSteamID, 32, "STEAM_1:0:3339246", "STEAM_1:1:44083262");

	if(m_szSteamID[0]=='[')
	{
		int m_unAccountID = StringToInt(m_szSteamID[5]);
		int m_unMod = m_unAccountID % 2;
		Format(out, maxlen, "STEAM_0:%d:%d", m_unMod, (m_unAccountID-m_unMod)/2);
	}
	else
	{
		strcopy(out, maxlen, m_szSteamID);
	}

	return success;
}
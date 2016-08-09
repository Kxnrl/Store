
enum Sound
{
	String:szName[128],
	String:szSound[128],
	Float:fVolume,
	iCooldown
}

int g_iSounds = 0;
int g_iSoundClient[MAXPLAYERS+1];
int g_iSoundSpam[MAXPLAYERS+1];
bool g_bClientDisable[MAXPLAYERS+1];

Sound g_eSounds[STORE_MAX_ITEMS][Sound];

Handle g_hCookieSounds;

public void Sounds_OnPluginStart()
{
	if(g_bGameModePR)
		return;

	Store_RegisterHandler("sound", "sound", Sound_OnMapStart, Sound_Reset, Sound_Config, Sound_Equip, Sound_Remove, true);

	RegConsoleCmd("cheer", Command_Cheer);
	RegConsoleCmd("sm_cheer", Command_Cheer);
	RegConsoleCmd("sm_crpb", Command_Silence);
	
	g_hCookieSounds = RegClientCookie("store_sounds", "", CookieAccess_Protected);
}

public void Sound_OnMapStart()
{
	char szPath[256];
	char szPathStar[256];
	for(int i = 0; i < g_iSounds; ++i)
	{
		Format(szPath, 256, "sound/%s", g_eSounds[i][szSound]);
		if(FileExists(szPath, true))
		{
			Format(szPathStar, 256, "*%s", g_eSounds[i][szSound]);
			AddToStringTable(FindStringTable("soundprecache"), szPathStar);
			Downloader_AddFileToDownloadsTable(szPath);
			//LogMessage("Precache %s", g_eSounds[i][szSound]);
		}
	}
}

public void Sound_Reset()
{
	g_iSounds = 0;
}

public int Sound_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iSounds);
	KvGetString(kv, "sound", g_eSounds[g_iSounds][szSound], 128);
	KvGetString(kv, "name", g_eSounds[g_iSounds][szName], 128);
	g_eSounds[g_iSounds][fVolume] = KvGetFloat(kv, "volume", 0.3);
	g_eSounds[g_iSounds][iCooldown] = KvGetNum(kv, "cooldown", 30);
	
	if(g_eSounds[g_iSounds][iCooldown] < 30)
		g_eSounds[g_iSounds][iCooldown] = 30;
	
	if(g_eSounds[g_iSounds][fVolume] > 1.0)
		g_eSounds[g_iSounds][fVolume] = 1.0;
	
	if(g_eSounds[g_iSounds][fVolume] <= 0.0)
		g_eSounds[g_iSounds][fVolume] = 0.05;
	
	char szPath[256];
	Format(szPath, 256, "sound/%s", g_eSounds[g_iSounds][szSound]);
	if(FileExists(szPath, true))
	{
		++g_iSounds;
		//LogMessage("Load %s", g_eSounds[g_iSounds][szSound]);
		return true;
	}

	return false;
}

public int Sound_Equip(int client, int id)
{
	int m_iData = Store_GetDataIndex(id);
	g_iSoundClient[client] = m_iData;
	return 0;
}

public int Sound_Remove(int client)
{
	g_iSoundClient[client] = -1;
	return 0;
}

public void Sound_OnClientConnected(int client)
{
	g_iSoundClient[client] = -1;
	g_bClientDisable[client] = false;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	if(client <= 0)
		return Plugin_Continue;
	
	if(g_iSoundClient[client] < 0)
		return Plugin_Continue;
	
	if(sArgs[0] == '!' || sArgs[0] == '/')
		return Plugin_Continue;
	
	if(g_iSoundSpam[client] > GetTime())
			return Plugin_Continue;
	
	if  ( 
			StrContains(sArgs, "cheer", false) != -1 ||
			StrContains(sArgs, "lol", false) != -1 ||
			StrContains(sArgs, "233", false) != -1 ||
			StrContains(sArgs, "hah", false) != -1 ||
			StrContains(sArgs, "hhh", false) != -1
		)
		{
			g_iSoundSpam[client] = GetTime() + g_eSounds[g_iSoundClient[client]][iCooldown];
			StartSoundToAll(client);
			
			return Plugin_Stop;
		}

	return Plugin_Continue;
}

public Action Command_Cheer(int client, int args)
{
	if(client <= 0)
		return Plugin_Handled;
	
	if(g_iSoundSpam[client] > GetTime())
	{
		PrintToChat(client, "\x01 \x04[Store]  音效功能正在冷却");
		return Plugin_Handled;
	}
	
	if(g_iSoundClient[client] < 0)
	{
		PrintToChat(client, "\x01 \x04[Store]  你还没有打开音效功能,请在Store装备");
		return Plugin_Handled;
	}
	
	if(PA_GetGroupID(client) == 9999)
		g_iSoundSpam[client] = GetTime() + 5;
	else
		g_iSoundSpam[client] = GetTime() + g_eSounds[g_iSoundClient[client]][iCooldown];

	StartSoundToAll(client);

	return Plugin_Handled;
}

void StartSoundToAll(int client)
{
	int[] targets = new int[MaxClients];
	int total = 0;
	
	for(int i=1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			if(!g_bClientDisable[client] || i == client)
				targets[total++] = i;

	char szPath[128];
	Format(szPath, 128, "*%s", g_eSounds[g_iSoundClient[client]][szSound]);
	EmitSound(targets, total, szPath, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_eSounds[g_iSoundClient[client]][fVolume]);

	PrintToChatAll("\x01 \x04%N\x01使用音效[\x0C%s\x01] (!crpb开关屏蔽)", client, g_eSounds[g_iSoundClient[client]][szName]);
}

public void OnClientCookiesCached(int client)
{
	if(g_bGameModePR)
		return;
	
	char buff[4];
	GetClientCookie(client, g_hCookieSounds, buff, 4);
	
	if(buff[0] != 0)
		g_bClientDisable[client] = (StringToInt(buff) == 1 ? true : false);
}

public Action Command_Silence(int client, int args)
{
	if(g_bClientDisable[client])
	{
		g_bClientDisable[client] = false;
		SetClientCookie(client, g_hCookieSounds, "0");
		PrintToChat(client, "\x01 \x04[Store]  \x01你已经\x07关闭屏蔽音效功能");
	}
	else
	{
		g_bClientDisable[client] = true;
		SetClientCookie(client, g_hCookieSounds, "1");
		PrintToChat(client, "\x01 \x04[Store]  \x01你已经\x04开启屏蔽音效功能");
	}
}
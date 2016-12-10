#include <sdktools>

stock bool IsClientKyle(int client)
{
	char SteamID[32];
	GetClientAuthId(client, AuthId_Steam2, SteamID, 32);
	if(StrEqual(SteamID, "STEAM_1:1:44083262"))
		return true;
	return false;
}

stock bool IsValidClient(int client)
{
	if(client > MaxClients || client < 1)
		return false;

	if(!IsClientInGame(client))
		return false;

	return true;
}

stock void ReplaceColorsCode(char[] buffer, int maxLen)
{
	ReplaceString(buffer, maxLen, "{normal}", "\x01", false);
	ReplaceString(buffer, maxLen, "{default}", "\x01", false);
	ReplaceString(buffer, maxLen, "{white}", "\x01", false);
	ReplaceString(buffer, maxLen, "{darkred}", "\x02", false);
	ReplaceString(buffer, maxLen, "{pink}", "\x03", false);
	ReplaceString(buffer, maxLen, "{green}", "\x04", false);
	ReplaceString(buffer, maxLen, "{lime}", "\x05", false);
	ReplaceString(buffer, maxLen, "{yellow}", "\x05", false);
	ReplaceString(buffer, maxLen, "{lightgreen}", "\x06", false);
	ReplaceString(buffer, maxLen, "{lightred}", "\x07", false);
	ReplaceString(buffer, maxLen, "{red}", "\x07", false);
	ReplaceString(buffer, maxLen, "{gray}", "\x08", false);
	ReplaceString(buffer, maxLen, "{grey}", "\x08", false);
	ReplaceString(buffer, maxLen, "{olive}", "\x09", false);
	ReplaceString(buffer, maxLen, "{orange}", "\x10", false);
	ReplaceString(buffer, maxLen, "{purple}", "\x0E", false);
	ReplaceString(buffer, maxLen, "{lightblue}", "\x0B", false);
	ReplaceString(buffer, maxLen, "{blue}", "\x0C", false);
}

stock void ClearTimer(Handle &timer)
{
	if(timer != INVALID_HANDLE)
	{
		KillTimer(timer);
		timer = INVALID_HANDLE;
	}
}

stock int GetClientBySteamID(char[] steamid)
{
	char authid[32];
	for(int client=1;client<=MaxClients;++client)
	{
		if(!IsClientInGame(client))
			continue;
		
		if(!IsClientAuthorized(client))
			continue;
		
		GetClientAuthId(client, AuthId_Steam2, authid, 32);
		
		if(StrEqual(steamid, authid))
			return client;
	}
	return 0;
}

stock void MissionHint(char[] caption, int color1, int color2, int color3, char[] icon)
{
	int instrHintEnt;  
	char color[32];
	instrHintEnt = CreateEntityByName("env_instructor_hint");
	Format(color, 32, "%d %d %d", color1, color2, color3);
	
	DispatchKeyValue(instrHintEnt, "hint_range", "999999");
	DispatchKeyValue(instrHintEnt, "hint_color", color);
	DispatchKeyValue(instrHintEnt, "hint_caption", caption);
	DispatchKeyValue(instrHintEnt, "hint_icon_onscreen", icon);
	DispatchKeyValue(instrHintEnt, "hint_timeout", "5.0");

	DispatchSpawn(instrHintEnt);
	AcceptEntityInput(instrHintEnt, "ShowHint");
	AcceptEntityInput(instrHintEnt, "kill");
}

stock void SetClientHealth(int client, int counts)
{
	SetEntityHealth(int client, int counts);
}

stock void SetClientFrags(int client, int counts)
{
	SetEntProp(client, Prop_Data, "m_iFrags", counts);
}

stock void SetClientMVP(int client, int counts)
{
	CS_SetMVPCount(client, counts);
}

stock void SetClientAssists(int client, int counts)
{
	CS_SetClientAssists(client, counts);
}

stock void SetClientScore(int client, int counts)
{
	CS_SetClientContributionScore(client, counts);
}

stock void SetClientDeaths(int client, int counts)
{
	SetEntProp(client, Prop_Data, "m_iDeaths", counts);
}

stock void SetClientMoney(int client, int counts)
{
	SetEntProp(client, Prop_Send, "m_iAccount", counts);
}

stock void ShowOverlayToClient(int client, const char[] overlaypath)
{
	ClientCommand(client, "r_screenoverlay \"%s\"", overlaypath);
}

stock void ShowOverlayToAll(const char[] overlaypath)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			ShowOverlayToClient(client, overlaypath);
		}
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
	
	CloseHandle(trace);
	
	return entity;
}

public bool TraceFilterAllEntities(int entity, int contentsMask, int client)
{
	if(entity == client || entity > MaxClients || !IsClientInGame(entity) || !IsPlayerAlive(entity))

		return false;

	return true;
}

stock void SetMenuTitleEx(Handle menu, const char[] fmt, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, fmt, 3);
	
	if(GetEngineVersion() == Engine_CSGO)
		Format(m_szBuffer, 256, "%s\n　", m_szBuffer);
	else
	{
		ReplaceString(m_szBuffer, 256, "\n \n", " - ");
		ReplaceString(m_szBuffer, 256, "\n", " - ");
	}
	
	SetMenuTitle(menu, m_szBuffer);
}

stock bool AddMenuItemEx(Handle menu, int style, const char[] info, const char[] display, any ...)
{
	char m_szBuffer[256];
	VFormat(m_szBuffer, 256, display, 5);

	if(GetEngineVersion() != Engine_CSGO)
		ReplaceString(m_szBuffer, 256, "\n", " - ");

	return AddMenuItem(menu, info, m_szBuffer, style);
}

stock void tPrintHintTextToAll(const char[] szMessage, any ...)
{
	char szBuffer[256];
	
	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, 256, szMessage, 2);
			PrintHintText(i, "%s", szBuffer);
		}
	}
}

stock void tPrintHintText(int client, const char[] szMessage, any ...)
{
	char szBuffer[256];

	SetGlobalTransTarget(client);
	VFormat(szBuffer, 256, szMessage, 3);
	PrintHintText(client, "%s", szBuffer);
}

stock void tPrintCenterTextAll(const char[] szMessage, any ...)
{
	char szBuffer[256];

	for(int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);
			VFormat(szBuffer, 256, szMessage, 2);
			PrintCenterText(i, "%s", szBuffer);
		}
	}
}

stock void tPrintCenterText(int client, const char[] szMessage, any ...)
{
	char szBuffer[256];

	SetGlobalTransTarget(client);
	VFormat(szBuffer, 256, szMessage, 3);
	PrintCenterText(client, "%s", szBuffer);
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
	if(client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if(!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char szBuffer[256];

	SetGlobalTransTarget(client);
	VFormat(szBuffer, 256, szMessage, 3);
	ReplaceColorsCode(szBuffer, 256);
	PrintToChat(client, szBuffer);
}

stock void tPrintToChatAll(const char[] szMessage, any ...)
{
	char szBuffer[256];

	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			SetGlobalTransTarget(i);			
			VFormat(szBuffer, 256, szMessage, 2);
			ReplaceColorsCode(szBuffer, 256);
			PrintToChat(i, "%s", szBuffer);
		}
	}
}
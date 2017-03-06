#include <sdktools>

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

stock bool AddMenuItemEx(Handle menu, int style, char[] info, char[] display, any ...)
{
	char m_display[256];
	VFormat(m_display, sizeof(m_display), display, 5);
	return AddMenuItem(menu, info, m_display, style);
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
	if(client <= 0 || client > MaxClients)
		ThrowError("Invalid client index %d", client);

	if(!IsClientInGame(client))
		ThrowError("Client %d is not in game", client);

	char szBuffer[256];

	VFormat(szBuffer, 256, szMessage, 3);
	ReplaceColorsCode(szBuffer, 256);
	PrintToChat(client, "[\x04Store\x01]  %s", szBuffer);
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

stock void ReplaceColorsCode(char[] message, int maxLen)
{
	ReplaceString(message, maxLen, "{normal}", "\x01", false);
	ReplaceString(message, maxLen, "{default}", "\x01", false);
	ReplaceString(message, maxLen, "{white}", "\x01", false);
	ReplaceString(message, maxLen, "{darkred}", "\x02", false);
	ReplaceString(message, maxLen, "{teamcolor}", "\x03", false);
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
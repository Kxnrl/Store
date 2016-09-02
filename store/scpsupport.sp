char g_szNameTags[STORE_MAX_ITEMS][MAXLENGTH_NAME];
char g_szNameColors[STORE_MAX_ITEMS][32];
char g_szMessageColors[STORE_MAX_ITEMS][32];

int g_iNameTags = 0;
int g_iNameColors = 0;
int g_iMessageColors = 0;

public void SCPSupport_OnPluginStart()
{
	if(FindPluginByFile("simple-chatprocessor.smx") == INVALID_HANDLE)
	{
		LogError("Simple Chat Processor isn't installed or failed to load. SCP support will be disabled. (http://forums.alliedmods.net/showthread.php?t=198501)");
		return;
	}

	Store_RegisterHandler("nametag", "tag", SCPSupport_OnMappStart, SCPSupport_Reset, NameTags_Config, SCPSupport_Equip, SCPSupport_Remove, true);
	Store_RegisterHandler("namecolor", "color", SCPSupport_OnMappStart, SCPSupport_Reset, NameColors_Config, SCPSupport_Equip, SCPSupport_Remove, true);
	Store_RegisterHandler("msgcolor", "color", SCPSupport_OnMappStart, SCPSupport_Reset, MsgColors_Config, SCPSupport_Equip, SCPSupport_Remove, true);
}

public void SCPSupport_OnMappStart()
{

}

public void SCPSupport_Reset()
{
	g_iNameTags = 0;
	g_iNameColors = 0;
	g_iMessageColors = 0;
}

public int NameTags_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameTags);
	KvGetString(kv, "tag", g_szNameTags[g_iNameTags], sizeof(g_szNameTags[]));
	++g_iNameTags;

	return true;
}

public int NameColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameColors);
	KvGetString(kv, "color", g_szNameColors[g_iNameColors], sizeof(g_szNameColors[]));
	++g_iNameColors;
	
	return true;
}

public int MsgColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iMessageColors);
	KvGetString(kv, "color", g_szMessageColors[g_iMessageColors], sizeof(g_szMessageColors[]));
	++g_iMessageColors;
	
	return true;
}

public int SCPSupport_Equip(int client, int id)
{
	return -1;
}

public int SCPSupport_Remove(int client, int id)
{

}

public Action OnChatMessage(int &client, Handle recipients, char[] name, char[] message)
{
	int m_iEquippedNameTag = Store_GetEquippedItem(client, "nametag");
	int m_iEquippedNameColor = Store_GetEquippedItem(client, "namecolor");
	int m_iEquippedMsgColor = Store_GetEquippedItem(client, "msgcolor");
	
	char m_szName[512];
	char m_szNameTag[256];
	char m_szNameColor[32];
	char m_szAuthTag[128];
	
	ReplaceAllColors(message);

	GetColorAuthName(client,  m_szAuthTag, 128);

	strcopy(STRING(m_szNameTag), m_szAuthTag);
	
	if(m_iEquippedNameTag >= 0)
	{
		int m_iNameTag = Store_GetDataIndex(m_iEquippedNameTag);
		StrCat(STRING(m_szNameTag), g_szNameTags[m_iNameTag]);
	}
	else
		StrCat(STRING(m_szNameTag), "{lightblue}[CG社区] {teamcolor}");

	if(m_iEquippedNameColor >= 0)
	{
		int m_iNameColor = Store_GetDataIndex(m_iEquippedNameColor);
		strcopy(STRING(m_szNameColor), g_szNameColors[m_iNameColor]);
	}

	Format(STRING(m_szName), "%s%s%s", m_szNameTag, m_szNameColor, name);
	ReplaceColors(STRING(m_szName), client);
	strcopy(name, MAXLENGTH_NAME, m_szName);

	if(m_iEquippedMsgColor >= 0)
	{
		char m_szMessage[MAXLENGTH_INPUT];
		strcopy(STRING(m_szMessage), message);
		Format(message, MAXLENGTH_INPUT, "%s%s", g_szMessageColors[Store_GetDataIndex(m_iEquippedMsgColor)], m_szMessage);
		ReplaceColors(message, MAXLENGTH_INPUT, client);
	}

	return Plugin_Changed;
}

stock void ReplaceAllColors(char[] message)
{
	ReplaceString(message, 256, "white", "", false);
	ReplaceString(message, 256, "default", "", false);
	ReplaceString(message, 256, "teamcolor", "", false);
	ReplaceString(message, 256, "darkred", "", false);
	ReplaceString(message, 256, "pink", "", false);
	ReplaceString(message, 256, "green", "", false);
	ReplaceString(message, 256, "lightgreen", "", false);
	ReplaceString(message, 256, "lime", "", false);
	ReplaceString(message, 256, "lightred", "", false);
	ReplaceString(message, 256, "grey", "", false);
	ReplaceString(message, 256, "gray", "", false);
	ReplaceString(message, 256, "yellow", "", false);
	ReplaceString(message, 256, "orange", "", false);
	ReplaceString(message, 256, "silver", "", false);
	ReplaceString(message, 256, "lightblue", "", false);
	ReplaceString(message, 256, "blue", "", false);
	ReplaceString(message, 256, "purple", "", false);
	ReplaceString(message, 256, "darkorange", "", false);
}

stock void GetColorAuthName(int client, char[] buffer, int maxLen)
{
	int authorized = PA_GetGroupID(client);
	PA_GetGroupName(client, buffer, maxLen);
		
	if(1 <= authorized < 400) 
		Format(buffer, maxLen, "{default}[{blue}%s{default}]", buffer);
	else if(authorized == 401) 
		Format(buffer, maxLen, "{lightblue}[%s]", buffer);
	else if(authorized == 402) 
		Format(buffer, maxLen, "{lightred}[%s]", buffer);
	else if(authorized == 403) 
		Format(buffer, maxLen, "{darkred}[%s]", buffer);
	else if(authorized == 404) 
		Format(buffer, maxLen, "{darkorange}[%s]", buffer);
	else if(authorized == 405) 
		Format(buffer, maxLen, "{orange}[%s]", buffer);
	else if(504 > authorized >= 501) 
		Format(buffer, maxLen, "{default}[{blue}%s{default}]", buffer);
	else if(authorized == 9000)
		Format(buffer, maxLen, "{default}[{darkred}%s{default}]", buffer);
	else if(authorized == 9001)
		Format(buffer, maxLen, "{default}[{darkred}%s{default}]", buffer);
	else if(9990 > authorized >= 9100)
		Format(buffer, maxLen, "{default}[{blue}%s{default}]", buffer);
	else if(authorized == 9992) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9993) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9994) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9995) 
		Format(buffer, maxLen, "{orange}[{lightred}%s{orange}]", buffer);
	else if(authorized == 9996) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9997) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9998) 
		Format(buffer, maxLen, "{green}[%s]", buffer);
	else if(authorized == 9999) 
		Format(buffer, maxLen, "{darkorange}[{purple}%s{darkorange}]", buffer);
	else if(authorized == 9951) 
		Format(buffer, maxLen, "{default}[{orange}%s{default}]", buffer);
	else if(authorized == 9952) 
		Format(buffer, maxLen, "{default}[{orange}%s{default}]", buffer);
	else
		Format(buffer, maxLen, "{default}[{lightblue}%s{default}]", buffer);	
}
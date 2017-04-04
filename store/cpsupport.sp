#define Module_Chat

char g_szNameTags[STORE_MAX_ITEMS][128];
char g_szNameColors[STORE_MAX_ITEMS][32];
char g_szMessageColors[STORE_MAX_ITEMS][32];

int g_iNameTags = 0;
int g_iNameColors = 0;
int g_iMessageColors = 0;

public void CPSupport_OnPluginStart()
{
	if(!FindPluginByFile("chat-processor.smx"))
	{
		LogError("Chat Processor isn't installed or failed to load. CP support will be disabled.");
		return;
	}

	Store_RegisterHandler("nametag", "tag", CPSupport_OnMappStart, CPSupport_Reset, NameTags_Config, CPSupport_Equip, CPSupport_Remove, true);
	Store_RegisterHandler("namecolor", "color", CPSupport_OnMappStart, CPSupport_Reset, NameColors_Config, CPSupport_Equip, CPSupport_Remove, true);
	Store_RegisterHandler("msgcolor", "color", CPSupport_OnMappStart, CPSupport_Reset, MsgColors_Config, CPSupport_Equip, CPSupport_Remove, true);
}

public void CPSupport_OnMappStart()
{

}

public void CPSupport_Reset()
{
	g_iNameTags = 0;
	g_iNameColors = 0;
	g_iMessageColors = 0;
}

public int NameTags_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameTags);
	KvGetString(kv, "tag", g_szNameTags[g_iNameTags], 128);
	++g_iNameTags;

	return true;
}

public int NameColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iNameColors);
	KvGetString(kv, "color", g_szNameColors[g_iNameColors], 32);
	++g_iNameColors;
	
	return true;
}

public int MsgColors_Config(Handle &kv, int itemid)
{
	Store_SetDataIndex(itemid, g_iMessageColors);
	KvGetString(kv, "color", g_szMessageColors[g_iMessageColors], 32);
	++g_iMessageColors;
	
	return true;
}

public int CPSupport_Equip(int client, int id)
{
	return -1;
}

public int CPSupport_Remove(int client, int id)
{

}

public Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool &processcolors, bool &removecolors)
{
	int m_iEquippedNameTag = Store_GetEquippedItem(client, "nametag");
	int m_iEquippedNameColor = Store_GetEquippedItem(client, "namecolor");
	int m_iEquippedMsgColor = Store_GetEquippedItem(client, "msgcolor");
	
	char m_szNameTag[128];
	char m_szNameColor[32];

	GetColorAuthName(client,  m_szNameTag, 128);

	if(m_iEquippedNameTag >= 0)
	{
		if(CG_GetClientUId(client) <= 0)
			StrCat(STRING(m_szNameTag), "{lightblue}[未注册]{teamcolor}");

		StrCat(STRING(m_szNameTag), g_szNameTags[Store_GetDataIndex(m_iEquippedNameTag)]);
	}
	else
	{
		switch(CG_GetClientVip(client))
		{
			case  3: StrCat(STRING(m_szNameTag), "{purple}[SVIP] {teamcolor}");
			case  2: StrCat(STRING(m_szNameTag), "{orange}[AVIP] {teamcolor}");
			case  1: StrCat(STRING(m_szNameTag), "{silver}[MVIP] {teamcolor}");
			default: StrCat(STRING(m_szNameTag), (CG_GetClientUId(client) > 0) ? "{lightblue}[CG社区] {teamcolor}" : "{lightblue}[未注册] {teamcolor}");
		}
	}

	if(m_iEquippedNameColor >= 0)
		strcopy(STRING(m_szNameColor), g_szNameColors[Store_GetDataIndex(m_iEquippedNameColor)]);

	Format(name, 128, "%s%s%s", m_szNameTag, m_szNameColor, name);

	if(m_iEquippedMsgColor >= 0)
		Format(message, 256, "%s%s", g_szMessageColors[Store_GetDataIndex(m_iEquippedMsgColor)], message);

	return Plugin_Changed;
}

stock void GetColorAuthName(int client, char[] buffer, int maxLen)
{
	int authorized = CG_GetClientGId(client);
	CG_GetClientGName(client, buffer, maxLen);
	
	if(!authorized)
		Format(buffer, maxLen, " ");
	else if(9002 >= authorized >= 9000)
		Format(buffer, maxLen, "{default}[{darkred}%s{default}]", buffer);
	else if(authorized > 9990) 
		Format(buffer, maxLen, "{green}[{purple}%s{green}]", buffer);
	else 
		Format(buffer, maxLen, "{yellow}[{blue}%s{yellow}]", buffer);
}
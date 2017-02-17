#pragma newdecls required
#include <maoling>

Handle g_tMsgFmt;
Handle g_fwdOnChatMessage;
Handle g_fwdOnChatMessagePost;
bool g_bProto;
bool g_bNewChat[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "Chat-Processor",
	author		= "Keith Warren (Drixevel) & Kyle",
	description = "",
	version		= "2.4 > CG Edition ver.2 - Include CSC",
	url			= "http://steamcommunity.com/id/_xQy_"
};

public void OnPluginStart()
{
	g_tMsgFmt = CreateTrie();
	
	AddCommandListener(Command_Say, "say");
	AddCommandListener(Command_Say, "say_team");

	g_fwdOnChatMessage = CreateGlobalForward("CP_OnChatMessage", ET_Hook, Param_CellByRef, Param_Cell, Param_String, Param_String, Param_String, Param_CellByRef, Param_CellByRef);
	g_fwdOnChatMessagePost = CreateGlobalForward("CP_OnChatMessagePost", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String, Param_String, Param_String, Param_Cell, Param_Cell);
}

public void OnAllPluginsLoaded()
{
	GenerateMessageFormats();

	UserMsg MsgId = GetUserMessageId("SayText2");

	if(MsgId != INVALID_MESSAGE_ID)
	{
		g_bProto = (GetUserMessageType() == UM_Protobuf) ? true : false;
		HookUserMessage(MsgId, OnSayText2, true);
		LogMessage("Hooking 'SayText2' chat messages, mode '%s'", g_bProto ? "Protobuf" : "non-pb");
	}
	else
		SetFailState("Error loading the plugin, both chat hooks are unavailable. (SayText2)");
}

public void OnClientConnected(int client)
{
	g_bNewChat[client] = false;
}

public Action Command_Say(int client, const char[] command, int argc)
{
	g_bNewChat[client] = true;
}

public Action OnSayText2(UserMsg msg_id, BfRead msg, const int[] players, int playersNum, bool reliable, bool init)
{
	int m_iSender = g_bProto ? PbReadInt(msg, "ent_idx") : BfReadByte(msg);
	if(m_iSender <= 0)
		return Plugin_Continue;
	
	if(g_bNewChat[m_iSender])
		g_bNewChat[m_iSender] = false;
	else
		return Plugin_Handled;

	bool m_bChat = g_bProto ? PbReadBool(msg, "chat") : view_as<bool>(BfReadByte(msg));

	char m_szFlag[32], m_szName[128], m_szMsg[256], m_szFmt[256];

	if(g_bProto)
	{
		PbReadString(msg, "msg_name", m_szFlag, 32);
		PbReadString(msg, "params", m_szName, 128, 0);
		PbReadString(msg, "params", m_szMsg, 256, 1);
	}
	else
	{
		BfReadString(msg, m_szFlag, 32);
		if(BfGetNumBytesLeft(msg)) BfReadString(msg, m_szName, 128);
		if(BfGetNumBytesLeft(msg)) BfReadString(msg, m_szMsg, 256);
	}
	
	if(!GetTrieString(g_tMsgFmt, m_szFlag, m_szFmt, 256))
		return Plugin_Continue;

	RemoveAllColors(m_szName, 128);
	RemoveAllColors(m_szMsg, 256);

	Handle m_hRecipients = CreateArray();

	for(int i = 0; i < playersNum; i++)
		if(FindValueInArray(m_hRecipients, players[i]) == -1)
			PushArrayCell(m_hRecipients, players[i]);

	if(FindValueInArray(m_hRecipients, m_iSender) == -1)
		PushArrayCell(m_hRecipients, m_iSender);

	char m_szNameCopy[128];
	strcopy(m_szNameCopy, 128, m_szName);

	char m_szFlagCopy[32];
	strcopy(m_szFlagCopy, 32, m_szFlag);
	
	bool m_bProcessColors = true;
	bool m_bRemoveColors = false;

	Call_StartForward(g_fwdOnChatMessage);
	Call_PushCellRef(m_iSender);
	Call_PushCell(m_hRecipients);
	Call_PushStringEx(m_szFlag, 32, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(m_szName, 128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(m_szMsg, 256, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushCellRef(m_bProcessColors);
	Call_PushCellRef(m_bRemoveColors);

	Action iResults;
	int error = Call_Finish(iResults);

	if(error != SP_ERROR_NONE)
	{
		CloseHandle(m_hRecipients);
		ThrowNativeError(error, "Forward has failed to fire.");
		return Plugin_Continue;
	}

	if(!StrEqual(m_szFlag, m_szFlagCopy) && !GetTrieString(g_tMsgFmt, m_szFlag, m_szFmt, 256))
		return Plugin_Continue;

	if(iResults == Plugin_Changed)
	{
		if(StrEqual(m_szNameCopy, m_szName))
			Format(m_szName, 128, "\x03%s", m_szName);

		Handle hPack = CreateDataPack();
		WritePackCell(hPack, m_iSender);
		WritePackCell(hPack, m_hRecipients);
		WritePackString(hPack, m_szName);
		WritePackString(hPack, m_szMsg);
		WritePackString(hPack, m_szFlag);
		WritePackCell(hPack, m_bProcessColors);
		WritePackCell(hPack, m_bRemoveColors);

		WritePackString(hPack, m_szFmt);
		WritePackCell(hPack, m_bChat);
		WritePackCell(hPack, iResults);

		RequestFrame(Frame_OnChatMessage_SayText2, hPack);
		return Plugin_Handled;
	}

	CloseHandle(m_hRecipients);
	return iResults;
}

public void Frame_OnChatMessage_SayText2(Handle data)
{
	ResetPack(data);

	int m_iSender = ReadPackCell(data);
	Handle m_hRecipients = ReadPackCell(data);

	char m_szName[128];
	ReadPackString(data, m_szName, 128);

	char m_szMsg[256];
	ReadPackString(data, m_szMsg, 256);

	char m_szFlag[32];
	ReadPackString(data, m_szFlag, 32);

	bool bProcessColors = ReadPackCell(data);
	bool bRemoveColors = ReadPackCell(data);

	char m_szFmt[256];
	ReadPackString(data, m_szFmt, 256);

	bool m_bChat = ReadPackCell(data);
	Action iResults = view_as<Action>(ReadPackCell(data));

	CloseHandle(data);

	// only used for non-pb messages
	int[] iRecipients = new int[MaxClients];
	int iNumRecipients = GetArraySize(m_hRecipients);

	for(int i = 0; i < iNumRecipients; i++)
		iRecipients[i] = GetArrayCell(m_hRecipients, i);

	char m_szBuffer[512];
	strcopy(m_szBuffer, 512, m_szFmt);

	ReplaceString(m_szBuffer, 512, "{1} :  {2}", "{1} {normal}:  {2}");
	ReplaceString(m_szBuffer, 512, "{1}", m_szName);
	ReplaceString(m_szBuffer, 512, "{2}", m_szMsg);

	ReplaceAllColors(m_szBuffer, 512);

	if(iResults == Plugin_Changed)
	{
		if(g_bProto)
		{
			for(int i = 0; i < GetArraySize(m_hRecipients); i++)
			{
				int client = GetArrayCell(m_hRecipients, i);
				if(IsClientInGame(client))
					SayText2(client, m_szBuffer, m_iSender, m_bChat);
			}
		}
		else
		{
			for(int i = 0; i < GetArraySize(m_hRecipients); i++)
			{
				int client = GetArrayCell(m_hRecipients, i);
				if(IsClientInGame(client))
					PrintToChat(client, m_szBuffer);
			}
		}
	}

	Call_StartForward(g_fwdOnChatMessagePost);
	Call_PushCell(m_iSender);
	Call_PushCell(m_hRecipients);
	Call_PushString(m_szFlag);
	Call_PushString(m_szFmt);
	Call_PushString(m_szName);
	Call_PushString(m_szMsg);
	Call_PushCell(bProcessColors);
	Call_PushCell(bRemoveColors);
	Call_Finish();

	CloseHandle(m_hRecipients);
}

bool GenerateMessageFormats()
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO:
		{
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT_Loc", "(CT) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT", "(CT) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_T_Loc", "(TE) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_T", "(TE) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT_Dead", "*DEAD*(TE) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_T_Dead", "*DEAD*(TE) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_Spec", "(SPEC) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_All", " {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_AllDead", "*DEAD* {1} :  {2}");
			SetTrieString(g_tMsgFmt, "Cstrike_Chat_AllSpec", "*SPEC* {1} :  {2}");
			
			return true;
		}
		case Engine_Left4Dead2, Engine_Left4Dead:
		{
			SetTrieString(g_tMsgFmt, "L4D_Chat_Infected", "(Infected) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_Survivor", "(Survivor) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_Infected_Dead", "*DEAD*(Infected) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_Survivor_Dead", "*DEAD*(Survivor) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_Spec", "(Spectator) {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_All", " {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_AllDead", "*DEAD* {1} :  {2}");
			SetTrieString(g_tMsgFmt, "L4D_Chat_AllSpec", "*SPEC* {1} :  {2}");
			
			return true;
		}
	}

	return false;
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

stock void ReplaceAllColors(char[] message, int maxLen)
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

stock void SayText2(int client, char[] message, int author, bool chat = true)
{
	Handle hMsg = StartMessageOne("SayText2", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
	if(GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(hMsg, "ent_idx", author);
		PbSetBool(hMsg, "chat", chat);
		PbSetString(hMsg, "msg_name", message);
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
		PbAddString(hMsg, "params", "");
	}
	else
	{
		BfWriteByte(hMsg, author);
		BfWriteByte(hMsg, true);
		BfWriteString(hMsg, message);
	}
	EndMessage();
}
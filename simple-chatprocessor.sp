/************************************************************************
*************************************************************************
Simple Chat Processor
Description:
		Process chat and allows other plugins to manipulate chat.
*************************************************************************
*************************************************************************
This file is part of Simple Plugins project.

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************
File Information
$Id$
$Author$
$Revision$
$Date$
$LastChangedBy$
$LastChangedDate$
$URL$
$Copyright: (c) Simple Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_VERSION				"2.1.0"
#define SENDER_WORLD			0
#define MAXLENGTH_INPUT			128 	// Inclues \0 and is the size of the chat input box.
#define MAXLENGTH_NAME			64		// This is backwords math to get compability.  Sourcemod has it set at 32, but there is room for more.
#define MAXLENGTH_MESSAGE		256		// This is based upon the SDK and the length of the entire message, including tags, name, : etc.

#define CHATFLAGS_INVALID		0
#define CHATFLAGS_ALL			(1 << 0)
#define CHATFLAGS_TEAM			(1 << 1)
#define CHATFLAGS_SPEC			(1 << 2)
#define CHATFLAGS_DEAD			(1 << 3)

#define ADDSTRING(%1) SetTrieValue(g_hChatFormats, %1, 1)

#define UPDATE_URL "http://dl.dropboxusercontent.com/u/83581539/ChatProcessor/updater.txt"

enum eMods
{
	GameType_Unknown,
	GameType_AOC,
	GameType_CSGO,
	GameType_CSS,
	GameType_DOD,
	GameType_FF,
	GameType_HIDDEN,
	GameType_HL2DM,
	GameType_INS,
	GameType_L4D,
	GameType_L4D2,
	GameType_NEO,
	GameType_SGTLS,
	GameType_TF,
	GameType_DM,
	GameType_ZPS,
};

new Handle:g_hDPArray = INVALID_HANDLE;

new eMods:g_CurrentMod;
new String:g_sGameName[eMods][32] = 
{		
	"Unknown",
	"Age of Chivalry",
	"Counter-Strike: GO",
	"Counter Strike",
	"Day Of Defeat",
	"Fortress Forever",
	"Hidden: Source",
	"Half Life 2: Deathmatch",
	"Insurgency",
	"Left 4 Dead",
	"Left 4 Dead 2",
	"Neotokyo",
	"Stargate TLS",
	"Team Fortress 2",
	"Dark Messiah",
	"Zombie Panic: Source"
};

new Handle:g_hChatFormats = INVALID_HANDLE;
new Handle:g_fwdOnChatMessage;
new Handle:g_fwdOnChatMessagePost;

new bool:g_bSayText2;
new	bool:g_bAutoUpdate;

new g_CurrentChatType = CHATFLAGS_INVALID;

public Plugin:myinfo =
{
	name = "Simple Chat Processor (Redux)",
	author = "Simple Plugins, Mini",
	description = "Process chat and allows other plugins to manipulate chat.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("GetUserMessageType");
	CreateNative("GetMessageFlags", Native_GetMessageFlags);
	RegPluginLibrary("scp");
	return APLRes_Success;
}

public OnPluginStart()
{
	new Handle:conVar = CreateConVar("sm_scp_autoupdate", "1", "Is auto-update enabled?");
	g_bAutoUpdate = GetConVarBool(conVar);
	HookConVarChange(conVar, OnAutoUpdateChange);

	g_CurrentMod = GetCurrentMod();
	g_hChatFormats = CreateTrie();
	LogMessage("[SCP] Recognized mod [%s].", g_sGameName[g_CurrentMod]);
	
	/**
	Hook the usermessage or error out if the mod doesn't support saytext2
	*/
	new UserMsg:umSayText2 = GetUserMessageId("SayText2");
	if (umSayText2 != INVALID_MESSAGE_ID)
	{
		g_bSayText2 = true;
		HookUserMessage(umSayText2, OnSayText2, true);
	}
	else
	{
		new UserMsg:umSayText = GetUserMessageId("SayText");
		if (umSayText != INVALID_MESSAGE_ID)
		{
			if (g_CurrentMod != GameType_DOD)
			{
				SetFailState("Unsupported game");
			}
			g_bSayText2 = false;
			HookUserMessage(umSayText, OnSayText, true);
		}
		else
		{
			LogError("[SCP] This mod appears not to support SayText2 or SayText.  Plugin disabled.");
			SetFailState("Error hooking usermessage saytext2 and saytext");	
		}
	}
	
	/**
	Get mod type and load the correct translation file
	*/
	if(g_bSayText2)
	{
		decl String:sGameDir[32];
		decl String:sTranslationFile[PLATFORM_MAX_PATH];
		decl String:sTranslationLocation[PLATFORM_MAX_PATH];
		GetGameFolderName(sGameDir, sizeof(sGameDir));
		Format(sTranslationFile, sizeof(sTranslationFile), "scp.%s.phrases", sGameDir);
		BuildPath(Path_SM, sTranslationLocation, sizeof(sTranslationLocation), "translations/%s.txt", sTranslationFile);
		if (FileExists(sTranslationLocation))
		{
			LogMessage("[SCP] Loading translation file [%s].", sTranslationFile);
			LoadTranslations(sTranslationFile);
			if (!GetChatFormats(sTranslationLocation))
			{
				LogError("[SCP] Could not parse the translation file");
				SetFailState("Could not parse the translation file");
			}
		}
		else
		{
			LogError("[SCP] Translation file is not present");
			SetFailState("Translation file is not present");
		}
	}

	/**
	Create the global forwards for other plugins
	*/
	g_fwdOnChatMessage = CreateGlobalForward("OnChatMessage", ET_Hook, Param_CellByRef, Param_Cell, Param_String, Param_String);
	g_fwdOnChatMessagePost = CreateGlobalForward("OnChatMessage_Post", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String);

	g_hDPArray = CreateArray();
}

public OnAutoUpdateChange(Handle:conVar, const String:oldVal[], const String:newVal[])
{
	g_bAutoUpdate = bool:StringToInt(newVal);
}

/**
 *
 * Updater Stuff
 * By Dr. McKay
 * Edited by Mini
 *
 */
public OnAllPluginsLoaded() 
{
	new Handle:convar;
	if (LibraryExists("updater")) 
	{
		Updater_AddPlugin(UPDATE_URL);
		decl String:newVersion[10];
		FormatEx(newVersion, sizeof(newVersion), "%sA", PLUGIN_VERSION);
		convar = CreateConVar("scp_version", newVersion, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);
	}
	else 
	{
		convar = CreateConVar("scp_version", PLUGIN_VERSION, "Plugin Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_CHEAT);	
	}
	HookConVarChange(convar, Callback_VersionConVarChanged);
}

public Callback_VersionConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) 
{
	ResetConVar(convar);
}

public OnLibraryAdded(const String:name[])
{
	if (!strcmp(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Updater_OnPluginDownloading()
{
	if (!g_bAutoUpdate)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Updater_OnPluginUpdated() 
{
	ReloadPlugin();
}

public Action:OnSayText2(UserMsg:msg_id, Handle:bf, const clients[], numClients, bool:reliable, bool:init)
{
	/**
	Get the sender of the usermessage and bug out if it is not a player
	*/
	new bool:bProtobuf = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf);
	new cpSender;
	if (bProtobuf)
	{
		cpSender = PbReadInt(bf, "ent_idx");
	}
	else
	{
		cpSender = BfReadByte(bf);
	}

	if (cpSender == SENDER_WORLD)
	{
		return Plugin_Continue;
	}
	
	/**
	Get the chat bool.  This determines if sent to console as well as chat
	*/
	new bool:bChat;
	if (bProtobuf)
	{
		bChat = PbReadBool(bf, "chat");
	}
	else
	{
		bChat = (BfReadByte(bf) ? true : false);
	}
	
	/**
	Make sure we have a default translation string for the message
	This also determines the message type...
	*/
	decl String:cpTranslationName[32];
	new buffer;
	if (bProtobuf)
	{
		PbReadString(bf, "msg_name", cpTranslationName, sizeof(cpTranslationName));
	}
	else
	{
		BfReadString(bf, cpTranslationName, sizeof(cpTranslationName));
	}

	if (!GetTrieValue(g_hChatFormats, cpTranslationName, buffer))
	{
		return Plugin_Continue;
	}
	else
	{
		if (StrContains(cpTranslationName, "all", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_ALL;
		}
		if (StrContains(cpTranslationName, "team", false) != -1
		|| 	StrContains(cpTranslationName, "survivor", false) != -1 
		||	StrContains(cpTranslationName, "infected", false) != -1
		||	StrContains(cpTranslationName, "Cstrike_Chat_CT", false) != -1 
		||	StrContains(cpTranslationName, "Cstrike_Chat_T", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_TEAM;
		}
		if (StrContains(cpTranslationName, "spec", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_SPEC;
		}
		if (StrContains(cpTranslationName, "dead", false) != -1)
		{
			g_CurrentChatType = g_CurrentChatType | CHATFLAGS_DEAD;
		}
	}
	
	/**
	Get the senders name
	*/
	decl String:cpSender_Name[MAXLENGTH_NAME];
	if (bProtobuf)
	{
		PbReadString(bf, "params", cpSender_Name, sizeof(cpSender_Name), 0);
	}
	else if (BfGetNumBytesLeft(bf))
	{
		BfReadString(bf, cpSender_Name, sizeof(cpSender_Name));
	}
	
	/**
	Get the message
	*/
	decl String:cpMessage[MAXLENGTH_INPUT];
	if (bProtobuf)
	{
		PbReadString(bf, "params", cpMessage, sizeof(cpMessage));
	}
	else if (BfGetNumBytesLeft(bf))
	{
		BfReadString(bf, cpMessage, sizeof(cpMessage));
	}
	
	/**
	Store the clients in an array so the call can manipulate it.
	*/
	new Handle:cpRecipients = CreateArray();
	for (new i = 0; i < numClients; i++)
	{
		PushArrayCell(cpRecipients, clients[i]);
	}
	
	/**
	Because the message could be changed but not the name
	we need to compare the original name to the returned name.
	We do this because we may have to add the team color code to the name,
	where as the message doesn't get a color code by default.
	*/
	decl String:sOriginalName[MAXLENGTH_NAME];
	strcopy(sOriginalName, sizeof(sOriginalName), cpSender_Name);
	
	/**
	Start the forward for other plugins
	*/
	new Action:fResult;
	Call_StartForward(g_fwdOnChatMessage);
	Call_PushCellRef(cpSender);
	Call_PushCell(cpRecipients);
	Call_PushStringEx(cpSender_Name, sizeof(cpSender_Name), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(cpMessage, sizeof(cpMessage), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	new fError = Call_Finish(fResult);
	
	new chatFlags = g_CurrentChatType;
	g_CurrentChatType = CHATFLAGS_INVALID;
	
	if (fError != SP_ERROR_NONE)
	{
		ThrowNativeError(fError, "Forward failed");
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult == Plugin_Continue)
	{
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult == Plugin_Stop)
	{
		CloseHandle(cpRecipients);
		return Plugin_Handled;
	}
	
	/**
	This is the check for a name change.  If it has not changed we add the team color code
	*/
	if (StrEqual(sOriginalName, cpSender_Name))
	{
		Format(cpSender_Name, sizeof(cpSender_Name), "\x03%s", cpSender_Name);
	}
	
	/**
	Create a timer to print the message on the next gameframe
	*/
	new Handle:cpPack = CreateDataPack();

	new numRecipients = GetArraySize(cpRecipients);
	
	WritePackCell(cpPack, cpSender);

	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		if (!IsValidClient(x))
		{
			numRecipients--;
			RemoveFromArray(cpRecipients, i);
		}
	}
	
	WritePackCell(cpPack, numRecipients);
	
	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		WritePackCell(cpPack, x);
	}
	
	WritePackCell(cpPack, bChat);
	WritePackString(cpPack, cpTranslationName);
	WritePackString(cpPack, cpSender_Name);
	WritePackString(cpPack, cpMessage);
	PushArrayCell(g_hDPArray, cpPack);
	WritePackCell(cpPack, bProtobuf);
	WritePackCell(cpPack, chatFlags);

	CloseHandle(cpRecipients);
	
	/**
	Stop the original message
	*/
	return Plugin_Handled;
}

public Action:OnSayText(UserMsg:msg_id, Handle:bf, const clients[], numClients, bool:reliable, bool:init)
{
	/**
	Get the sender of the usermessage and bug out if it is not a player
	*/
	new bool:bProtobuf = (CanTestFeatures() && GetFeatureStatus(FeatureType_Native, "GetUserMessageType") == FeatureStatus_Available && GetUserMessageType() == UM_Protobuf);
	new cpSender;
	if (bProtobuf)
	{
		cpSender = PbReadInt(bf, "ent_idx");
	}
	else
	{
		cpSender = BfReadByte(bf);
	}

	if (cpSender == SENDER_WORLD)
	{
		return Plugin_Continue;
	}
	
	/**
	Get the chat message
	*/
	decl String:message[MAXLENGTH_INPUT];
	if (bProtobuf)
	{
		PbReadString(bf, "text", message, sizeof(message));
	}
	else
	{
		BfReadString(bf, message, sizeof(message));
	}
	
	/**
	Get the chat bool.  This determines if sent to console as well as chat
	*/
	if (!bProtobuf)
	{
		BfReadBool(bf);
	}
	
	/**
	Store the clients in an array so the call can manipulate it.
	*/
	new Handle:cpRecipients = CreateArray();
	for (new i = 0; i < numClients; i++)
	{
		PushArrayCell(cpRecipients, clients[i]);
	}
	
	decl String:prefix[64], String:senderName[MAX_NAME_LENGTH], String:textMessage[MAXLENGTH_MESSAGE], String:buffer[MAXLENGTH_INPUT];
	GetClientName(cpSender, senderName, sizeof(senderName));
	Format(buffer, sizeof(buffer), "%s:", senderName);
	new pos = StrContains(message, buffer);
	
	if (pos == 0)
	{
		prefix[0] = '\0';
	}
	else
	{
		Format(prefix, pos + 1, "%s ", message);
	}
	
	g_CurrentChatType = CHATFLAGS_INVALID;
	
	if (StrContains(prefix, "(Team)") != -1)
	{
		g_CurrentChatType |= CHATFLAGS_TEAM;
	}
	if (GetClientTeam(cpSender) <= 1)
	{
		g_CurrentChatType |= CHATFLAGS_SPEC;
	}
	if (StrContains(prefix, "(Dead)") != -1)
	{
		g_CurrentChatType |= CHATFLAGS_DEAD;
	}
	
	if (g_CurrentChatType == CHATFLAGS_INVALID)
	{
		g_CurrentChatType = CHATFLAGS_ALL;
	}
	
	ReplaceString(message, sizeof(message), "\n", "");
	strcopy(textMessage, sizeof(textMessage), message[pos + strlen(senderName) + 2]);
	
	/**
	Start the forward for other plugins
	*/
	new Action:fResult;
	Call_StartForward(g_fwdOnChatMessage);
	Call_PushCellRef(cpSender);
	Call_PushCell(cpRecipients);
	Call_PushStringEx(senderName, sizeof(senderName), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	Call_PushStringEx(textMessage, sizeof(textMessage), SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
	new fError = Call_Finish(fResult);
	
	new chatFlags = g_CurrentChatType;
	g_CurrentChatType = CHATFLAGS_INVALID;
	
	if (fError != SP_ERROR_NONE)
	{
		ThrowNativeError(fError, "Forward failed");
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult == Plugin_Continue)
	{
		CloseHandle(cpRecipients);
		return Plugin_Continue;
	}
	else if (fResult >= Plugin_Handled)
	{
		CloseHandle(cpRecipients);
		return Plugin_Handled;
	}
	
	GetClientName(cpSender, buffer, sizeof(buffer));
	if (StrEqual(senderName, buffer))
	{
		Format(senderName, sizeof(senderName), "\x03%s", senderName);
	}
	
	/**
	Create a timer to print the message on the next gameframe
	*/
	new Handle:cpPack = CreateDataPack();

	new numRecipients = GetArraySize(cpRecipients);
	
	WritePackCell(cpPack, cpSender);

	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		if (!IsValidClient(x))
		{
			numRecipients--;
			RemoveFromArray(cpRecipients, i);
		}
	}
	
	WritePackCell(cpPack, numRecipients);
	
	for (new i = 0; i < numRecipients; i++)
	{
		new x = GetArrayCell(cpRecipients, i);
		WritePackCell(cpPack, x);
	}
	
	WritePackString(cpPack, prefix);
	WritePackString(cpPack, senderName);
	WritePackString(cpPack, textMessage);
	PushArrayCell(g_hDPArray, cpPack);
	// We don't care about saving bProtobuf since we print SayText messages with PrintToChat
	WritePackCell(cpPack, chatFlags);

	CloseHandle(cpRecipients);
	
	/**
	Stop the original message
	*/
	return Plugin_Handled;
}

public OnGameFrame()
{
	for (new i = 0; i < GetArraySize(g_hDPArray); i++)
	{
		new Handle:pack = GetArrayCell(g_hDPArray, i);
		ResetPack(pack);
		
		decl String:sSenderName[MAXLENGTH_NAME], String:sMessage[MAXLENGTH_INPUT];
		new client, Handle:recipients = CreateArray();
		if (g_bSayText2)
		{
			client = ReadPackCell(pack);
			new numClientsStart = ReadPackCell(pack);
			new numClientsFinish;
			new clients[numClientsStart];

			for (new x = 0; x < numClientsStart; x++)
			{
				new buffer = ReadPackCell(pack);
				if (IsValidClient(buffer))
				{
					clients[numClientsFinish++] = buffer;
					PushArrayCell(recipients, buffer);
				}
			}
			
			new bool:bChat = bool:ReadPackCell(pack);
			decl String:sChatType[32];
			ReadPackString(pack, sChatType, sizeof(sChatType));
			ReadPackString(pack, sSenderName, sizeof(sSenderName));
			ReadPackString(pack, sMessage, sizeof(sMessage));
			
			decl String:sTranslation[MAXLENGTH_MESSAGE];
			Format(sTranslation, sizeof(sTranslation), "%t", sChatType, sSenderName, sMessage);
			
			new Handle:bf = StartMessage("SayText2", clients, numClientsFinish, USERMSG_RELIABLE | USERMSG_BLOCKHOOKS);
			
			if (ReadPackCell(pack))
			{
				PbSetInt(bf, "ent_idx", client);
				PbSetBool(bf, "chat", bChat);

				PbSetString(bf, "msg_name", sTranslation);
				PbAddString(bf, "params", "");
				PbAddString(bf, "params", "");
				PbAddString(bf, "params", "");
				PbAddString(bf, "params", "");
			}
			else
			{
				BfWriteByte(bf, client);
				BfWriteByte(bf, bChat);
				BfWriteString(bf, sTranslation);
			}
			EndMessage();
		}
		else
		{
			client = ReadPackCell(pack);
			new numClientsStart = ReadPackCell(pack);
			new numClientsFinish;
			new clients[numClientsStart];

			for (new x = 0; x < numClientsStart; x++)
			{
				new buffer = ReadPackCell(pack);
				if (IsValidClient(buffer))
				{
					clients[numClientsFinish++] = buffer;
					PushArrayCell(recipients, buffer);
				}
			}
			
			decl String:sPrefix[MAXLENGTH_NAME];
			ReadPackString(pack, sPrefix, sizeof(sPrefix));
			ReadPackString(pack, sSenderName, sizeof(sSenderName));
			ReadPackString(pack, sMessage, sizeof(sMessage));
			
			decl String:message[MAXLENGTH_MESSAGE];
			
			new teamColor;
			switch (GetClientTeam(client))
			{
				case 0, 1: teamColor = 0xCCCCCC;
				case 2: teamColor = 0x4D7942;
				case 3: teamColor = 0xFF4040;
			}
			
			decl String:buffer[32];
			Format(buffer, sizeof(buffer), "\x07%06X", teamColor);
			ReplaceString(sSenderName, sizeof(sSenderName), "\x03", buffer);
			ReplaceString(sMessage, sizeof(sMessage), "\x03", buffer);
			
			Format(message, sizeof(message), "\x01%s%s\x01: %s", sPrefix, sSenderName, sMessage);
			PrintToServer(message);
			
			for (new j = 0; j < numClientsFinish; j++)
			{
				PrintToChat(clients[j], "%s", message);
			}
		}
		
		g_CurrentChatType = ReadPackCell(pack);
		Call_StartForward(g_fwdOnChatMessagePost);
		Call_PushCell(client);
		Call_PushCell(recipients);
		Call_PushString(sSenderName);
		Call_PushString(sMessage);
		Call_Finish();
		g_CurrentChatType = CHATFLAGS_INVALID;
		
		
		CloseHandle(recipients);
		CloseHandle(pack);

		RemoveFromArray(g_hDPArray, i);
	}
}

public Native_GetMessageFlags(Handle:plugin, numParams)
{
	return g_CurrentChatType;
}

stock bool:IsValidClient(client, bool:nobots = true) 
{  
	if (client <= 0 || client > MaxClients || !IsClientConnected(client) || (nobots && IsFakeClient(client))) 
	{  
			return false;  
	}  
	return IsClientInGame(client);  
}

stock bool:GetChatFormats(const String:file[])
{
	new Handle:hParser = SMC_CreateParser();
	new String:error[128];
	new line = 0;
	new col = 0;

	SMC_SetReaders(hParser, Config_NewSection, Config_KeyValue, Config_EndSection);
	SMC_SetParseEnd(hParser, Config_End);
	new SMCError:result = SMC_ParseFile(hParser, file, line, col);
	CloseHandle(hParser);

	if (result != SMCError_Okay) 
	{
		SMC_GetErrorString(result, error, sizeof(error));
		LogError("%s on line %d, col %d of %s", error, line, col, file);
	}
	
	return (result == SMCError_Okay);
}

public SMCResult:Config_NewSection(Handle:parser, const String:section[], bool:quotes) 
{
	if (StrEqual(section, "Phrases"))
	{
		return SMCParse_Continue;
	}
	ADDSTRING(section);
	return SMCParse_Continue;
}

public SMCResult:Config_KeyValue(Handle:parser, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	return SMCParse_Continue;
}

public SMCResult:Config_EndSection(Handle:parser) 
{
	return SMCParse_Continue;
}

public Config_End(Handle:parser, bool:halted, bool:failed) 
{
	//nothing
}

stock eMods:GetCurrentMod()
{
	decl String:sGameType[64];
	GetGameFolderName(sGameType, sizeof(sGameType));
	
	if (StrEqual(sGameType, "aoc", false))
	{
		return GameType_AOC;
	}
	if (StrEqual(sGameType, "csgo", false))
	{
		return GameType_CSGO;
	}
	if (StrEqual(sGameType, "cstrike", false))
	{
		return GameType_CSS;
	}
	if (StrEqual(sGameType, "dod", false))
	{
		return GameType_DOD;
	}
	if (StrEqual(sGameType, "ff", false))
	{
		return GameType_FF;
	}
	if (StrEqual(sGameType, "hidden", false))
	{
		return GameType_HIDDEN;
	}
	if (StrEqual(sGameType, "hl2mp", false))
	{
		return GameType_HL2DM;
	}
	if (StrEqual(sGameType, "insurgency", false) || StrEqual(sGameType, "ins", false))
	{
		return GameType_INS;
	}
	if (StrEqual(sGameType, "left4dead", false) || StrEqual(sGameType, "l4d", false))
	{
		return GameType_L4D;
	}
	if (StrEqual(sGameType, "left4dead2", false) || StrEqual(sGameType, "l4d2", false))
	{
		return GameType_L4D2;
	}
	if (StrEqual(sGameType, "nts", false))
	{
		return GameType_NEO;
	}
	if (StrEqual(sGameType, "sgtls", false))
	{
		return GameType_SGTLS;
	}
	if (StrEqual(sGameType, "tf", false))
	{
		return GameType_TF;
	}
	if (StrEqual(sGameType, "zps", false))
	{
		return GameType_ZPS;
	}
	if (StrEqual(sGameType, "mmdarkmessiah", false))
	{
		return GameType_DM;
	}
	LogMessage("Unknown Game Folder: %s", sGameType);
	return GameType_Unknown;
}
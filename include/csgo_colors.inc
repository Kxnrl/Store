/**************************************************************************
 *                             CS:GO COLORS                               *
 *                     Автор: Феникс(komashchenko)                        *
 *                            Version: 1.0                                *
 *                  http://zizt.ru/  http://hlmod.ru/                     *
 * 03.07.2014 - V1.0: Релиз                                               *
 **************************************************************************/



/**

 * Prints a message to a specific client in the chat area.

 * Supports color tags.

 * 

 * @param client		Client index.

 * @param message		Message (formatting rules).

 * @noreturn

 * 

 * On error/Errors:		If the client is not connected an error will be thrown.

 */

stock CGOPrintToChat(client, const String:message[], any:...)
{
	if(client <= 0 || client > MaxClients) ThrowError("Invalid client index %i", client);
	if(!IsClientInGame(client)) ThrowError("Client %i is not in game", client);
	decl String:text0[512], String:text[512];
	FormatEx(text0, sizeof(text0), " %s", message);
	VFormat(text, sizeof(text), text0, 3);
	ReplaceString(text, sizeof(text), "{DEFAULT}", "\x01");
	ReplaceString(text, sizeof(text), "{RED}", "\x02");
	ReplaceString(text, sizeof(text), "{LIGHTPURPLE}", "\x03");
	ReplaceString(text, sizeof(text), "{GREEN}", "\x04");
	ReplaceString(text, sizeof(text), "{LIME}", "\x05");
	ReplaceString(text, sizeof(text), "{LIGHTGREEN}", "\x06");
	ReplaceString(text, sizeof(text), "{LIGHTRED}", "\x07");
	ReplaceString(text, sizeof(text), "{GRAY}", "\x08");
	ReplaceString(text, sizeof(text), "{LIGHTOLIVE}", "\x09");
	ReplaceString(text, sizeof(text), "{OLIVE}", "\x10");
	ReplaceString(text, sizeof(text), "{PURPLE}", "\x0E");
	ReplaceString(text, sizeof(text), "{LIGHTBLUE}", "\x0B");
	ReplaceString(text, sizeof(text), "{BLUE}", "\x0C");
	PrintToChat(client, text);
}

/**

 * Prints a message to all clients in the chat area.

 * Supports color tags.

 * 

 * @param message		Message (formatting rules).

 * @noreturn

 */

stock CGOPrintToChatAll(const String:message[], any:...)
{
	decl String:text0[512], String:text[512];
	FormatEx(text0, sizeof(text0), " %s", message);
	VFormat(text, sizeof(text), text0, 2);
	ReplaceString(text, sizeof(text), "{DEFAULT}", "\x01");
	ReplaceString(text, sizeof(text), "{RED}", "\x02");
	ReplaceString(text, sizeof(text), "{LIGHTPURPLE}", "\x03");
	ReplaceString(text, sizeof(text), "{GREEN}", "\x04");
	ReplaceString(text, sizeof(text), "{LIME}", "\x05");
	ReplaceString(text, sizeof(text), "{LIGHTGREEN}", "\x06");
	ReplaceString(text, sizeof(text), "{LIGHTRED}", "\x07");
	ReplaceString(text, sizeof(text), "{GRAY}", "\x08");
	ReplaceString(text, sizeof(text), "{LIGHTOLIVE}", "\x09");
	ReplaceString(text, sizeof(text), "{OLIVE}", "\x10");
	ReplaceString(text, sizeof(text), "{PURPLE}", "\x0E");
	ReplaceString(text, sizeof(text), "{LIGHTBLUE}", "\x0B");
	ReplaceString(text, sizeof(text), "{BLUE}", "\x0C");
	PrintToChatAll(text);
}
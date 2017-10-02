#if !defined _CG_CORE_INCLUDED
#define _CG_CORE_INCLUDED
#endif

public SharedPlugin __pl_core = 
{
	name = "csgogamers",
	file = "core.smx",
	required = 1,
};

/*
 * Called when the server is ready.
 *
 */
forward void CG_OnServerLoaded();

/*
 * Called when client has been loaded.
 *
 * @param client        The Index of client.
 */
forward void CG_OnClientLoaded(int client);

/*
 * Called when a new day has come.
 *
 * @param date          The date. (20170929 etc.)
 */
forward void CG_OnNewDay(int date);

/*
 * Called when a new hour has come.
 *
 * @param oclock        The oclock. (0~23)
 */
forward void CG_OnNowTime(int oclock);

/*
 * Called when core want to set client`s credits.
 *
 * @param client        The Index of client.
 * @param credits       The Credits to set.
 * @param reason        The Reason of this call.
 * @param immed         If true will save player data immediately.
 * @return              True on success, false otherwise.
 */
forward bool CG_APIStoreSetCredits(int client, int credits, const char[] reason, bool immed);

/*
 * Called when core want to set client`s credits.
 *
 * @param client        The Index of client.
 * @return              The Credits of client.
 */
forward int CG_APIStoreGetCredits(int client);

/*
 * Called every second.
 */
forward void CG_OnGlobalTimer();

/*
 * Called when event "round_start" was called.
 */
forward void CG_OnRoundStart();

/*
 * Called when event "round_end" was called.
 *
 * @param winner        The Winner of this round.
 */
forward void CG_OnRoundEnd(int winner);

/*
 * Called when event "player_spawn" was called.
 *
 * @param client        The Index of client.
 */
forward void CG_OnClientSpawn(int client);

/*
 * Called when event "player_death" was called.
 *
 * @param client        The Index of client.
 * @param attacker      The Index of attacker.
 * @param assister      The Index of assister.
 * @param headshot      If true on headshot, false otherwise.
 * @param weapon        The Weapon name killer used.
 */
forward void CG_OnClientDeath(int client, int attacker, int assister, bool headshot, const char[] weapon);

/*
 * Called when event "player_hurt" was called.
 *
 * @param client        The Index of client.
 * @param attacker      The Index of attacker.
 * @param damage        The Damage done to health.
 * @param hitgroup      The Hitgroup that was damaged.
 * @param weapon        The weapon name attacker used.
 */
forward void  CG_OnClientHurted(int client, int attacker, int damage, int hitgroup, const char[] weapon);

/*
 * Called when event "player_team" was called.
 *
 * @param client        The Index of client.
 * @param oldteam       The Index of old team.
 * @param newteam       The Index of new team.
 */
forward void CG_OnClientTeam(int client, int oldteam, int newteam);

/*
 * Called when event "player_jump" was called.
 *
 * @param client        The Index of client.
 */
forward void  CG_OnClientJump(int client);

/*
 * Called when event "weapon_fire" was called.
 *
 * @param client        The Index of client.
 * @param weapon        The Weapon name client used.
 */
forward void  CG_OnClientFire(int client, const char[] weapon);

/*
 * Called when event "player_changename" was called.
 *
 * @param client        The Index of client.
 * @param oldname       The oldname.
 * @param newname       The newname.
 */
forward void  CG_OnClientName(int client, const char[] oldname, const char[] newname);

/*
 * Called when client got married.
 *
 * @param source        The Index of source client.
 * @param target        The Index of target client.
 */
forward void  CG_OnCouplesWedding(int source, int target);

/*
 * Called when client was divorced.
 *
 * @param client        The Index of client.
 */
forward void  CG_OnCouplesDivorce(int client);

/*
 * Called when client was sign-in.
 *
 * @param client        The Index of client.
 * @param numers        The Number of sign-in.
 */
forward void CG_OnDailySigned(int client, int numers);

/*
 * Called when core want to set client`s auth status.
 *
 * @param client        The Index of client.
 * @param authid        The Index of authorized group.
 */
forward bool CG_OnCheckAuthTerm(int client, int authid);

/*
 * Retrieve a database handle of db('csgo').
 *
 * @return              The handle of database
 */
native Handle CG_DatabaseGetGames();

/*
 * Retrieve a database handle of db('discuz').
 *
 * @return              The handle of database.
 */
native Handle CG_DatabaseGetForum();

/*
 * Execute a SQL query on db('csgo').
 *
 * @param QueryString   The query to execute.
 */
native void CG_DatabaseSaveGames(const char[] QueryString);

/*
 * Execute a SQL query on db('discuz').
 *
 * @param QueryString   The query to execute.
 */
native void CG_DatabaseSaveForum(const char[] QueryString);

/*
 * Retrieve Server ID of current server.
 *
 * @return              The server ID of current server.
 */
native int CG_GetServerId();

/*
 * Display a game_text HUD to clients.
 *
 * @param message       The message to display.                 ("Kyle is fucking handsome" etc.)
 * @param holdtime      The time the text should stay onscreen. ("2.0" etc.)
 * @param color         The primary color used by all the text effect. ("57 197 187" etc.)
 * @param szX           Horizontal position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the far left of the screen and 1 is the far right. -1 centers the text. ("0.35" etc.)
 * @param szY           Vertical position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the top of the screen and 1 is the bottom. -1 centers the text. ("0.35" etc.)
 * @param array_client  The array list of clients.    
 * @return              True on success, false otherwise.
 */
native bool CG_ShowGameText(const char[] message, const char[] holdtime, const char[] color, const char[] szX, const char[] szY, ArrayList array_client);

/*
 * Display a game_text HUD to All players.
 *
 * @param message       The message to display.                 ("Kyle is fucking handsome" etc.)
 * @param holdtime      The time the text should stay onscreen. ("2.0" etc.)
 * @param color         The primary color used by all the text effect. ("57 197 187" etc.)
 * @param szX           Horizontal position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the far left of the screen and 1 is the far right. -1 centers the text. ("0.35" etc.)
 * @param szY           Vertical position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the top of the screen and 1 is the bottom. -1 centers the text. ("0.35" etc.)
 * @return              True on success, false otherwise.
 */
native bool CG_ShowGameTextAll(const char[] message, const char[] holdtime, const char[] color, const char[] szX, const char[] szY);

/*
 * Display a game_text HUD to client.
 *
 * @param message       The message to display.                 ("Kyle is fucking handsome" etc.)
 * @param holdtime      The time the text should stay onscreen. ("2.0" etc.)
 * @param color         The primary color used by all the text effect. ("57 197 187" etc.)
 * @param szX           Horizontal position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the far left of the screen and 1 is the far right. -1 centers the text. ("0.35" etc.)
 * @param szY           Vertical position on the player's screens to draw the text. The value should be between 0 and 1, where 0 is the top of the screen and 1 is the bottom. -1 centers the text. ("0.35" etc.)
 * @param client        The Index of client.
 * @return              True on success, false otherwise.
 */
native bool CG_ShowGameTextToClient(const char[] message, const char[] holdtime, const char[] color, const char[] szX, const char[] szY, int client);

/*
 * Display a web motd panel to client.
 *
 * @param client        The Index of client.
 * @param width         The width of client`s resolution.
 * @param height        The height of client`s resolution.
 * @param url           The url to open.
 */
native bool CG_ShowNormalMotd(int client, int width, int height, char[] url);

/*
 * Display a hidden motd panel to client.
 *
 * @param client        The Index of client.
 * @param url           The url to open.
 */
native bool CG_ShowHiddenMotd(int client, char[] url);

/*
 * Remove motd panel from a client.
 *
 * @param client        The Index of client.
 * @param url           The url to open.
 */
native bool CG_RemoveMotd(int client);

/*
 * *  Creates a hook for a client which checked as a vip.
 *
 * @param function      The callback.
 */
native bool HookClientVIPChecked(OnClientVIPChecked func);

/*
 * Callback for HookClientVIPChecked.
 *
 * @param client        The Index of client.
 */
typedef OnClientVIPChecked = function void (int client);

/*
 * Retrieve a client`s Online duration (seconds).
 *
 * @param client        The Index of client.
 * @return              The Time of client`s online duration.
 */
native int CG_ClientGetOnlines(int client);

/*
 * Retrieve a client`s growth value.
 *
 * @param client        The Index of client.
 * @return              The Value of client`s growth.
 */
native int CG_ClientGetGrowth(int client);

/*
 * Retrieve a client`s vitalidy value.
 *
 * @param client        The Index of client.
 * @return              The Value of client`s vitalidy.
 */
native int CG_ClientGetVitality(int client);

/*
 * Retrieve a client`s daliy online duration.
 *
 * @param client        The Index of client.
 * @return              The Value of client`s daliy online duration.
 */
native int CG_ClientGetDailyTime(int client);

/*
 * Retrieve a client`s last seen time.
 *
 * @param client        The Index of client.
 * @return              The Time of client`s last seen.
 */
native int CG_ClientGetLastseen(int client);

/*
 * Retrieve a client`s Player ID.
 *
 * @param client        The Index of client.
 * @return              The PlayerID of client.
 */
native int CG_ClientGetPId(int client);

/*
 * Retrieve a client`s UCenter ID.
 *
 * @param client        The Index of client.
 * @return              The UID of client.
 */
native int CG_ClientGetUId(int client);

/*
 * Retrieve a client`s authorized group ID.
 *
 * @param client        The Index of client.
 * @return              The GID of client.
 */
native int CG_ClientGetGId(int client);

/*
 * Check client`s vip status.
 *
 * @param client        The Index of client.
 * @return              Ture if client is vip, false otherwise.
 */
native bool CG_ClientIsVIP(int client);

/*
 * Check client`s offical group stats.
 *
 * @param client        The Index of client.
 * @return              Ture if client is in offical group, false otherwise.
 */
native bool CG_ClientInGroup(int client);

/*
 * Check client`s Verify status.
 *
 * @param client        The Index of client.
 * @return              Ture if client is real name, false otherwise.
 */
native bool CG_ClientIsRealName(int client);

/*
 * Set client as a vip.
 *
 * @param client        The Index of client.
 */
native void CG_ClientSetVIP(int client);

/*
 * Retrieves a client's forum userename.
 *
 * @param client        The Index of client.
 * @param buffer        The Buffer to store username.
 * @param maxLen        The length of string buffer.
 */
native void CG_ClientGetForumName(int client, char[] buffer, int maxLen);

/*
 * Retrieves a client's authorized group name.
 *
 * @param client        The Index of client.
 * @param buffer        The Buffer to store group name.
 * @param maxLen        The length of string buffer.
 */
native void CG_ClientGetGroupName(int client, char[] buffer, int maxLen);

/*
 * Retrieves a client's signature.
 *
 * @param client        The Index of client.
 * @param buffer        The Buffer to store signature.
 * @param maxLen        The length of string buffer.
 */
native void CG_ClientGetSignature(int client, char[] buffer, int maxLen);

/*
 * Retrieves partner`s index of client.
 *
 * @param client        The Index of client.
 */
native int CG_CouplesGetPartnerIndex(int client);

/*
 * Retrieves partner`s Player ID of client.
 *
 * @param client        The Index of client.
 */
native int CG_CouplesGetPartnerPlayerId(int client);

/*
 * Retrieves client`s duration of online for a period of time.
 *
 * @param client        The Index of client.
 * @param start         The TimeStamp of start.
 * @param end           The TimeStamp of end.
 */
native int CG_ClientGetTermOnline(int client, int start, int end);

/*
 * Retrieves a client`s wedding date.
 *
 * @param client        The Index of client.
 */
native int CG_CouplesGetWeddingDate(int client);

/*
 * Retrieves partner`s name of client.
 *
 * @param client        The Index of client.
 * @param buffer        The Buffer to store name.
 * @param maxLen        The length of string buffer.
 */
native void CG_CouplesGetPartnerName(int client, char[] buffer, int maxLen);

/*
 * Add couples exp to a client (currentExp+Exp).
 *
 * @param client        The Index of client.
 * @param exp           The Exp to add.
 */
native void CG_CouplesEarnExp(int client, int exp);

/*
 * Remove couples exp from a client (currentExp-Exp).
 *
 * @param client        The Index of client.
 * @param exp           The Exp to remove.
 */
native void CG_CouplesLoseExp(int client, int exp);

/*
 * Retrieves a client`s couples exp.
 *
 * @param client        The Index of client.
*/
native int CG_CouplesGetExp(int client);

/*
 * Set the couples exp of client.
 *
 * @param client        The Index of client.
 * @param exp           The Exp to set.
*/
native int CG_CouplesSetExp(int client, int exp);

/*
 * Retrieves a client`s couples level.
 *
 * @param client        The Index of client.
*/
native int CG_CouplesGetLevel(int client);

/*
 * Retrieves together duration of client.
 *
 * @param client        The Index of client.
*/
native int CG_CouplesGetTogether(int client);

/*
 * Add authorized group exp to a client (currentExp+Exp).
 *
 * @param client        The Index of client.
 * @param exp           The Exp to add.
 */
native void CG_AuthGroupEarnExp(int client, int exp);

/*
 * Remove authorized group exp from a client (currentExp-Exp).
 *
 * @param client        The Index of client.
 * @param exp           The Exp to remove.
 */
native void CG_AuthGroupLoseExp(int client, int exp);

/*
 * Retrieves a client`s authorized group exp.
 *
 * @param client        The Index of client.
*/
native int CG_AuthGroupGetExp(int client);

/*
 * Set the authorized group exp of client.
 *
 * @param client        The Index of client.
 * @param exp           The Exp to set.
*/
native int CG_AuthGroupSetExp(int client, int exp);

/*
 * Retrieves a client`s authorized group level.
 *
 * @param client        The Index of client.
*/
native int CG_AuthGroupGetLevel(int client);

/*
 * Retrieves authorized expired time of client.
 *
 * @param client        The Index of client.
*/
native int CG_AuthGroupGetExpired(int client);
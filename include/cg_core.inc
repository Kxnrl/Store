typedef OnClientVIPChecked = function void (int client);


//Database
native Handle CG_DatabaseGetGames();
native Handle CG_DatabaseGetForum();
native void   CG_DatabaseSaveGames(const char[] QueryString);
native void   CG_DatabaseSaveForum(const char[] QueryString);

forward void  CG_OnServerLoaded();


//Global Apis
native int    CG_GetServerId();
native bool   CG_ShowGameText(const char[] message, const char[] holdtime, const char[] color, const char[] szX, const char[] szY, ArrayList array_client);
native bool   CG_ShowGameTextAll(const char[] message, const char[] holdtime, const char[] color, const char[] szX, const char[] szY);
native bool   CG_ShowNormalMotd(int client, int width, int height, char[] url);
native bool   CG_ShowHiddenMotd(int client, char[] url);
native bool   CG_RemoveMotd(int client);
native bool   HookClientVIPChecked(OnClientVIPChecked func);
native int    CG_ClientGetOnlines(int client);
native int    CG_ClientGetGrowth(int client);
native int    CG_ClientGetVitality(int client);
native int    CG_ClientGetDailyTime(int client);
native int    CG_ClientGetLastseen(int client);
native int    CG_ClientGetPId(int client);
native int    CG_ClientGetUId(int client);
native int    CG_ClientGetGId(int client);
native bool   CG_ClientIsVIP(int client);
native bool   CG_ClientInGroup(int client);
native bool   CG_ClientIsRealName(int client);
native void   CG_ClientSetVIP(int client);
native void   CG_ClientGetForumName(int client, char[] buffer, int maxLen);
native void   CG_ClientGetGroupName(int client, char[] buffer, int maxLen);
native void   CG_ClientGetSignature(int client, char[] buffer, int maxLen);

forward void  CG_OnClientLoaded(int client);
forward void  CG_OnNewDay(int date);
forward void  CG_OnNowTime(int oclock);

forward bool  CG_APIStoreSetCredits(int client, int credits, const char[] reason, bool immed);
forward int   CG_APIStoreGetCredits(int client);
forward void  CG_OnGlobalTimer();
forward void  CG_OnRoundStart();
forward void  CG_OnRoundEnd(int winner);
forward void  CG_OnClientSpawn(int client);
forward void  CG_OnClientDeath(int client, int attacker, int assister, bool headshot, const char[] weapon);
forward void  CG_OnClientHurted(int client, int attacker, int damage, int hitgroup, const char[] weapon);
forward void  CG_OnClientTeam(int client, int oldteam, int newteam);
forward void  CG_OnClientJump(int client);
forward void  CG_OnClientFire(int client, const char[] weapon);


//Daily sign
forward void CG_OnDailySigned(int client, int numers);


//Auth group
forward bool CG_OnCheckAuthTerm(int client, int authid);


//Couples
native int    CG_CouplesGetPartnerIndex(int client);
native int    CG_CouplesGetPartnerPlayerId(int client);
native int    CG_CouplesGetWeddingDate(int client);
native void   CG_CouplesGetPartnerName(int client, char[] buffer, int maxLen);

forward void  CG_OnCouplesWedding(int source, int target);
forward void  CG_OnCouplesDivorce(int client);
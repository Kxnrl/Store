forward void CG_OnServerLoaded();
forward void CG_OnClientDailySign(int client);
forward void CG_OnClientLoaded(int client);
forward void PA_OnClientLoaded(int client);
forward void CP_OnCPCouple(int Neptune, int Noire);
forward void CP_OnCPDivorce(int Neptune, int Noire);
forward bool CG_APIStoreSetCredits(int client, int credits, const char[] reason, bool immed);
forward  int CG_APIStoreGetCredits(int client);
forward void CG_OnNewDay(int date);

native  int CG_GetServerID();
native  int CG_GetOnlines(int client);
native  int CG_GetVitality(int client);
native  int CG_GetLastseen(int client);
native  int CG_GetPlayerID(int client);
native  int CG_GetDiscuzUID(int client);
native  int VIP_GetVipType(int client);
native  int PA_GetGroupID(int client);
native  int CP_GetPartner(int client);
native  int CP_GetDate(int client);
native  int HookClientVIPChecked(OnClientVIPCheckFunc func);
native bool VIP_IsClientVIP(int client);
native bool CG_ShowNormalMotd(int client, int width, int height, char[] url);
native bool CG_ShowHiddenMotd(int client, char[] url);
native bool CG_RemoveMotd(int client);
native void VIP_SetClientVIP(int client);
native void CG_SaveDatabase(char[] QueryString);
native void CG_SaveForumData(char[] QueryString);
native void CG_GetSignature(int client, char[] buffer, int maxLen);
native void CG_GetDiscuzName(int client, char[] buffer, int maxLen);
native void PA_GetGroupName(int client, char[] buffer, int maxLen);

native Handle CG_GetGameDatabase();
native Handle CG_GetDiscuzDatabase();

functag OnClientVIPCheckFunc public (client);
#define FAITH_COUNTS 4
#define ALLSHARE 0
#define PURPLE 1
#define BLACK 2
#define WHITE 3
#define GREEN 4

char szFaith_CNATION[5][32] = {"", "\x0EPlaneptune\x01", "\x08Lastation\x01", "\x01Lowee\x01", "\x04LeanBox\x01"};
char szFaith_NATION[5][32] = {"", "Planeptune", "Lastation", "Lowee", "LeanBox"};
char szFaith_NAME[5][32] = {"", "Purple", "Black", "White", "Green"};
char szFaith_CNAME[5][32] = {"", "\x0EPurple\x01", "\x08Black\x01", "\x01White\x01", "\x04Green\x01"};

int g_Share[FAITH_COUNTS+1];

forward void CG_OnServerLoaded();
forward void CG_OnClientDailySign(int client);
forward void CG_OnClientDataLoaded(int client);
forward void PA_OnClientLoaded(int client);
forward void CG_OnClientCompleteReq(int client, int ReqId);
forward void Lily_OnLilyCouple(int Neptune, int Noire);
forward void Lily_OnLilyDivorce(int Neptune, int Noire);

native int CG_GetServerID();
native int CG_GetShare(int faith);
native int CG_GetClientFaith(int client);
native int CG_GetClientShare(int client);
native int CG_GetSecondBuff(int client);
native int CG_GetOnlines(int client);
native int CG_GetLastseen(int client);
native int CG_GetPlayerID(int client);
native int CG_GetDiscuzUID(int client);
native int CG_GetReqID(int client);
native int CG_GetReqTerm(int client);
native int CG_GetReqRate(int client);
native int VIP_GetVipType(int client);
native int PA_GetGroupID(int client);
native int PA_GetLevel(int client);
native int Lily_GetPartner(int client);
native int Lily_GetRank(int client);
native int Lily_GetExp(int client);
native int Lily_GetDate(int client);
native int HookClientVIPChecked(OnClientVIPCheckFunc func);
native bool VIP_IsClientVIP(int client);
native void CG_SetReqID(int client, int ReqId);
native void CG_SetReqTerm(int client, int ReqTerm);
native void CG_SetReqRate(int client, int ReqRate);
native void CG_ResetReq(int client);
native void CG_SaveReq(int client);
native void CG_CheckReq(int client);
native void VIP_SetClientVIP(int client);
native void CG_GiveClientShare(int client, int Share, const char[] Reason);
native void PA_GivePlayerExp(int client, int Exp, const char[] Reason);
native void CG_SaveDatabase(char[] QueryString);
native void CG_SaveForumData(char[] QueryString);
native void CG_GetSignature(int client, char[] buffer, int maxLen);
native void CG_GetDiscuzName(int client, char[] buffer, int maxLen);
native void PA_GetGroupName(int client, char[] buffer, int maxLen);
native void Lily_SetExp(int client);
native void Lily_AddLily(int Neptune, int Noire);

functag OnClientVIPCheckFunc public(client);
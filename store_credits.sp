#include <store>
#include <steamworks>
#include <cg_core>
#include <smlib/math>
#include <sourcebans>

#pragma newdecls required

#define PF_CREDITS "\x01 \x04[Store]  "
#define PF_GLOBAL "[\x0CCG\x01]  "
#define PF_ACTIVE "[\x10新年快乐\x01]  "

Handle g_hTimer[MAXPLAYERS+1];

bool g_bInOfficalGroup[MAXPLAYERS+1];
bool g_bIsCheck[MAXPLAYERS+1];

public Plugin myinfo =
{
	name		= "Store Online Credits/Riffle",
	author		= "Kyle",
	description = "",
	version		= "1.1rc2",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("SBBanPlayer");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_signtest", Command_SignTest, ADMFLAG_ROOT);
}

public void OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);

	g_hTimer[client] = CreateTimer(300.0, CreditTimer, client, TIMER_REPEAT);
}

public void OnClientDisconnect(int client)
{
	g_bInOfficalGroup[client] = false;
	g_bIsCheck[client] = false;

	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = INVALID_HANDLE;
}

public void LookupPlayerGroups(int client)
{
	g_bIsCheck[client] = true;

	//Check CG Group
	SteamWorks_GetUserGroupStatus(client, 103582791438550612); // OFFICAL GROUP

	//Check Blacklist
	SteamWorks_GetUserGroupStatus(client, 103582791455638129); //4=1
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
	if(isMember || isOfficer) 
	{
		for(int client = 1; client <= MaxClients; ++client)
		{
            if(!g_bIsCheck[client])
                continue;

            if(!IsClientInGame(client))
                continue;

            char authidb[32];
            GetClientAuthId(client, AuthId_Engine, authidb, 32);
            char part[4];
            SplitString(authidb[8], ":", part, 4);
            if(authid == (StringToInt(authidb[10]) << 1) + StringToInt(part)) 
            {
				if(groupid == 103582791438550612)
					g_bInOfficalGroup[client] = true;

				if(groupid == 103582791455638129)
				{
					SBBanPlayer(0, client, 0, "CAT: 自动封禁4=1作弊狗");
					return;
				}

				break;
			}
		}
	}
}

public Action CreditTimer(Handle timer, int client)
{
	if(!IsClientInGame(client))
	{
		g_hTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	if(!g_bInOfficalGroup[client])
	{
		PrintToChat(client, "%s  \x07你尚未加入官方Steam组,不能通过游戏在线获得信用点", PF_CREDITS);
		PrintToChat(client, "%s  \x04按Y输入\x07!group\x04即可加入官方组", PF_CREDITS);
		g_hTimer[client] = INVALID_HANDLE;
		return Plugin_Stop;
	}

	int m_iCredits = 0;
	char szFrom[128], szReason[128];
	strcopy(szFrom, 128, "\x10[");
	strcopy(szReason, 128, "store_credits[");

	int m_iVitality = CG_GetClientVitality(client);
	if(m_iVitality)
	{
		StrCat(szReason, 128, " 热度");	
		if(200 > m_iVitality >= 100)
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x07热度+2");
		}
		else if(400 > m_iVitality >= 200)
		{
			m_iCredits += 3;
			StrCat(szFrom, 128, "\x07热度+3");
		}
		else if(700 > m_iVitality >= 400)
		{
			m_iCredits += 4;
			StrCat(szFrom, 128, "\x07热度+4");
		}
		else if(m_iVitality >= 700)
		{
			m_iCredits += 5;
			StrCat(szFrom, 128, "\x07热度+5");
		}
		else if(m_iVitality >= 999)
		{
			m_iCredits += 6;
			StrCat(szFrom, 128, "\x07热度+6");
		}
		else
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x07热度+1");
		}
	}

	int authid = CG_GetClientGId(client);
	if(authid)
	{
		int m_iPlus = 0;
		if(authid < 401)
		{
			m_iPlus += 2;
		}
		else if(500 > authid >= 401)
		{
			switch(authid)
			{
				case 401: m_iPlus += 2;
				case 402: m_iPlus += 2;
				case 403: m_iPlus += 3;
				case 404: m_iPlus += 3;
				case 405: m_iPlus += 4;
			}
		}
		else if(9000 > authid >= 500)
		{
			m_iPlus += 2;
		}
		else if(authid >= 9101)
		{
			m_iPlus += 3;
		}

		m_iCredits += m_iPlus;
		char auname[32];
		CG_GetClientGName(client, auname, 32);
		StrCat(szReason, 128, auname);
		if(authid == 9999)
			Format(auname, 32, "\x0A|\x0E%s+%d", auname, m_iPlus);
		else
			Format(auname, 32, "\x0A|\x0C%s+%d", auname, m_iPlus);
		StrCat(szFrom, 128, auname);
	}

	if(CG_IsClientVIP(client))
	{
		m_iCredits += 2;
		StrCat(szFrom, 128, "\x0A|\x0EVIP+2");
		StrCat(szReason, 128, " VIP ");
	}

	StrCat(szFrom, 128, "\x10]");
	StrCat(szReason, 128, "]");

	if(!m_iCredits)
		return Plugin_Continue;

	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

	PrintToChat(client, "%s \x10你获得了\x04 %d 信用点", PF_CREDITS, m_iCredits);
	PrintToChat(client, " \x0A积分来自%s", szFrom);

	return Plugin_Continue;
}

public Action Command_SignTest(int client, int args)
{
	if(CG_GetClientGId(client) == 9999)
	{
		Active_GiveSignCredits(client);
	}
}

public void CG_OnClientDailySign(int client)
{
	if(!g_bInOfficalGroup[client])
	{
		PrintToChat(client, "%s  检测到你当前未加入\x0C官方组\x01  你无法获得签到奖励", PF_GLOBAL);
		return;	
	}

	Active_GiveSignCredits(client);
}

void Active_GiveSignCredits(int client)
{
	int Credits = Math_GetRandomInt(1, 500);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0F信用点\x01", PF_GLOBAL, client, Credits);
}
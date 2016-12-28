#include <store>
#include <steamworks>
#include <cg_core>
#tryinclude <cg_ze>

#pragma newdecls required

#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "


Handle g_hTimer[MAXPLAYERS+1];

bool g_bInOfficalGroup[MAXPLAYERS+1];
bool g_bInMimiGameGroup[MAXPLAYERS+1];
bool g_bInOpeatorGroup[MAXPLAYERS+1];
bool g_bInZombieGroup[MAXPLAYERS+1];
bool g_bIsCheck[MAXPLAYERS+1];

int g_iNumPlayers;
bool g_bNightfever;

public Plugin myinfo =
{
	name		= "Store Online Credits/Riffle",
	author		= "maoling ( xQy )",
	description = "",
	version		= "1.0",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_signtest", Command_SignTest, ADMFLAG_ROOT);
	
	CreateTimer(120.0, TIMER_NIGHTFEVER, _, TIMER_REPEAT);
}

public Action TIMER_NIGHTFEVER(Handle timer)
{
	char time[16];
	FormatTime(time, 16, "%H", GetTime());
	int hour = StringToInt(time);
	if(hour <= 8 || hour >= 23)
		g_bNightfever = true;
	else
		g_bNightfever = false;
	
	if(g_bNightfever)
		PrintToChatAll("[\x02NightFever\x01]   \x04当前为午夜党福利时间,在线获得的信用点+5");
}

public void OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);
	
	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = CreateTimer(300.0, CreditTimer, client, TIMER_REPEAT);
	
	g_iNumPlayers = GetClientCount(true);
}

public void OnClientDisconnect(int client)
{
	g_bInOfficalGroup[client] = false;
	g_bInMimiGameGroup[client] = false;
	g_bInZombieGroup[client] = false;
	g_bInOpeatorGroup[client] = false;
	g_bIsCheck[client] = false;
	
	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = INVALID_HANDLE;
	
	g_iNumPlayers = GetClientCount(true);
}

public int ZE_GetClientGroupStats(int client)
{
	if(g_bInZombieGroup[client])
		return 2;
	
	if(g_bInOfficalGroup[client])
		return 1;
	
	return 0;
}

public void LookupPlayerGroups(int client)
{
	g_bIsCheck[client] = true;
	SteamWorks_GetUserGroupStatus(client, 103582791438550612);
	SteamWorks_GetUserGroupStatus(client, 103582791437825710);
	SteamWorks_GetUserGroupStatus(client, 103582791442277011);
	SteamWorks_GetUserGroupStatus(client, 103582791456047719);
}

public int SteamWorks_OnClientGroupStatus(int authid, int groupid, bool isMember, bool isOfficer)
{
	if(isMember || isOfficer) 
	{
		for(int client=1;client<=MAXPLAYERS;++client)
		{
            if(!g_bIsCheck[client])
                continue;
			
            if(!IsClientConnected(client))
                continue;

            char authidb[32];
            GetClientAuthId(client, AuthId_Engine, authidb, 32);
            char part[4];
            SplitString(authidb[8], ":", part, 4);
            if(authid == (StringToInt(authidb[10]) << 1) + StringToInt(part)) 
            {
				if(groupid == 103582791438550612)
					g_bInOfficalGroup[client] = true;
				if(groupid == 103582791437825710)
					g_bInMimiGameGroup[client] = true;
				if(groupid == 103582791442277011)
					g_bInOpeatorGroup[client] = true;
				if(groupid == 103582791456047719)
					g_bInZombieGroup[client] = true;

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
	
	if(!(2 <= GetClientTeam(client) <= 3))
	{
		PrintToChat(client, "%s  \x07观察者无法获得信用点", PLUGIN_PREFIX_CREDITS);
		return Plugin_Continue;
	}

	if(g_iNumPlayers < 6 && !FindPluginByFile("KZTimerGlobal.smx"))
	{
		PrintToChat(client, "%s  \x04玩家人数不足6人,不能获得在线奖励的信用点", PLUGIN_PREFIX_CREDITS);
		return Plugin_Continue;
	}

	int m_iCredits = 0;
	bool m_bGroupCreidts = false;
	char szFrom[128], szReason[128];
	strcopy(szFrom, 128, "\x10[");
	strcopy(szReason, 128, "store_credits[");
	
	m_iCredits += 1;
	StrCat(szFrom, 128, "\x04在线时间+1");
	StrCat(szReason, 128, "在线时间 ");

	int authid = PA_GetGroupID(client);
	
	if(authid > 0)
	{
		int m_iPlus = 0;
		if(authid < 401)
		{
			m_iPlus += 3;
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
			m_iPlus += 3;
		}
		else if(9990 > authid >= 9101)
		{
			m_iPlus += 4;
		}
		else if(authid > 9990)
		{
			m_iPlus += 5;
		}

		m_iCredits += m_iPlus;
		char auname[32];
		PA_GetGroupName(client, auname, 32);
		StrCat(szReason, 128, auname);
		if(authid == 9999)
			Format(auname, 32, "\x0A|\x0E%s+%d", auname, m_iPlus);
		else
			Format(auname, 32, "\x0A|\x0C%s+%d", auname, m_iPlus);
		StrCat(szFrom, 128, auname);
	}
	
	switch(VIP_GetVipType(client))
	{
		case 3:
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07永久VIP+2");
			StrCat(szReason, 128, " SVIP ");
		}
		case 2:
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07年费VIP+2");
			StrCat(szReason, 128, " AVIP ");
		}
		case 1:
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x0A|\x07月费VIP+1");
			StrCat(szReason, 128, " MVIP ");
		}
	}
	
	if(g_bInMimiGameGroup[client] && !m_bGroupCreidts)
	{
		m_iCredits += 3;
		m_bGroupCreidts = true;
		StrCat(szFrom, 128, "\x0A|\x06娱乐挂壁+2");
		StrCat(szReason, 128, "娱乐挂壁");
	}
	
	if(g_bInZombieGroup[client] && !m_bGroupCreidts)
	{
		m_iCredits += 3;
		m_bGroupCreidts = true;
		StrCat(szFrom, 128, "\x0A|\x06祈り~+2");
		StrCat(szReason, 128, "祈り~");
	}
	
	if(g_bInOfficalGroup[client] && !m_bGroupCreidts)
	{				
		m_bGroupCreidts = true;
		m_iCredits += 3;
		StrCat(szFrom, 128, "\x0A|\x06官方组+3");
		StrCat(szReason, 128, "官方组");
	}

	if(g_bInOpeatorGroup[client] && GetUserFlagBits(client) & ADMFLAG_BAN)
	{
		m_iCredits += 3;
		StrCat(szFrom, 128, "\x0A|\x10OP+3");
		StrCat(szReason, 128, "OP");		
	}
	
	int m_iVitality = CG_GetVitality(client);
	if(m_iVitality)
	{
		StrCat(szReason, 128, " 热度");	
		if(100 > m_iVitality >= 60)
		{
			m_iCredits += 2;
			StrCat(szFrom, 128, "\x0A|\x07热度+2");
		}
		else if(200 > m_iVitality >= 100)
		{
			m_iCredits += 3;
			StrCat(szFrom, 128, "\x0A|\x07热度+3");
		}
		else if(400 > m_iVitality >= 200)
		{
			m_iCredits += 4;
			StrCat(szFrom, 128, "\x0A|\x07热度+4");
		}
		else if(700 > m_iVitality >= 400)
		{
			m_iCredits += 5;
			StrCat(szFrom, 128, "\x0A|\x07热度+5");
		}
		else if(m_iVitality >= 700)
		{
			m_iCredits += 6;
			StrCat(szFrom, 128, "\x0A|\x07热度+6");
		}
		else if(m_iVitality == 1000)
		{
			m_iCredits += 10;
			StrCat(szFrom, 128, "\x0A|\x07热度+10");
		}
		else
		{
			m_iCredits += 1;
			StrCat(szFrom, 128, "\x0A|\x07热度+1");
		}
	}
	
	if(g_bNightfever)
	{
		m_iCredits += 5;
		StrCat(szFrom, 128, "\x0A|\x02午夜党福利+5");
		StrCat(szReason, 128, "午夜党福利");		
	}
	
	m_iCredits *= 2;
	
	StrCat(szFrom, 128, "\x0A|\x0C新年加倍\x10]");
	StrCat(szReason, 128, " 新年加倍]");

	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

	PrintToChat(client, "%s \x10你获得了\x04 %d 信用点", PLUGIN_PREFIX_CREDITS, m_iCredits);
	PrintToChat(client, " \x0A积分来自%s", szFrom);
	
	if(!g_bInOfficalGroup[client])
		PrintToChat(client, " \x04加入官方Steam组即可享受3倍在线积分");

	return Plugin_Continue;
}

public Action Command_SignTest(int client, int args)
{
	CG_OnClientDailySign(client);
}

public void CG_OnClientDailySign(int client)
{
	if(!g_bInOfficalGroup[client])
	{
		PrintToChat(client, "%s  检测到你当前未加入\x0C官方组\x01  你无法获得签到奖励", PLUGIN_PREFIX);
		return;	
	}

	Active_GiveSignCredits(client);
}

void Active_GiveSignCredits(int client)
{
	int Credits = GetRandomInt(2, 600);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0F信用点\x01(\x0C新年加倍\x01)", PLUGIN_PREFIX, client, Credits);
	PrintToChat(client,"%s \x10你获得了\x04%d \x0F信用点 \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits);
}
#pragma semicolon 1

//////////////////////////////
//		DEFINITIONS 		//
//////////////////////////////
#define PLUGIN_NAME " Store Credits Controler "
#define PLUGIN_AUTHOR "maoling ( xQy )"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION " 4.5.2rc2 "
#define PLUGIN_URL "http://steamcommunity.com/id/_xQy_/"
#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX "[\x0CCG\x01]  "

//////////////////////////////
//		INCLUDES			//
//////////////////////////////
#include <store>
#include <steamworks>
#include <cg_core>
#tryinclude <cg_ze>

#pragma newdecls required

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
Handle g_hTimer[MAXPLAYERS+1];

bool g_bInOfficalGroup[MAXPLAYERS+1];
bool g_bInMimiGameGroup[MAXPLAYERS+1];
bool g_bInOpeatorGroup[MAXPLAYERS+1];
bool g_bInZombieGroup[MAXPLAYERS+1];
bool g_bIsCheck[MAXPLAYERS+1];

#define CG_group_id 103582791438550612
#define GB_group_id 103582791437825710
#define OP_group_id 103582791442277011
#define ZE_group_id 103582791456047719

//////////////////////////////////
//		PLUGIN DEFINITION		//
//////////////////////////////////
public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////
public void OnPluginStart()
{
	RegAdminCmd("sm_signtest", Command_SignTest, ADMFLAG_ROOT);
}

public void OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);
	
	if(g_hTimer[client] != INVALID_HANDLE)
		KillTimer(g_hTimer[client]);
	
	g_hTimer[client] = CreateTimer(300.0, CreditTimer, client, TIMER_REPEAT);
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
	SteamWorks_GetUserGroupStatus(client, CG_group_id);
	SteamWorks_GetUserGroupStatus(client, GB_group_id);
	SteamWorks_GetUserGroupStatus(client, OP_group_id);
	SteamWorks_GetUserGroupStatus(client, ZE_group_id);
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
				if(groupid == CG_group_id)
					g_bInOfficalGroup[client] = true;
				if(groupid == GB_group_id)
					g_bInMimiGameGroup[client] = true;
				if(groupid == OP_group_id)
					g_bInOpeatorGroup[client] = true;
				if(groupid == ZE_group_id)
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
		return Plugin_Continue;
	
	int m_iCredits = 0;
	bool m_bGroupCreidts = false;
	char szFrom[128], szReason[128];
	strcopy(szFrom, 128, "\x10[");
	strcopy(szReason, 128, "store_credits[");
	
	m_iCredits += 2;
	StrCat(szFrom, 128, "\x04在线时间+2");
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
			StrCat(szReason, 128, " YVIP ");
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
		m_iCredits += 2;
		StrCat(szFrom, 128, "\x0A|\x06娱乐挂壁+2");
		StrCat(szReason, 128, "娱乐挂壁");
	}
	
	if(g_bInOfficalGroup[client] && !m_bGroupCreidts)
	{				
		m_bGroupCreidts = true;
		m_iCredits += 4;
		StrCat(szFrom, 128, "\x0A|\x06官方组+4");
		StrCat(szReason, 128, "官方组");
	}
	
	if(g_bInOpeatorGroup[client] && GetUserFlagBits(client) & ADMFLAG_BAN)
	{
		m_iCredits += 3;
		StrCat(szFrom, 128, "\x0A|\x10OP+3");
		StrCat(szReason, 128, "OP ");		
	}
	
	StrCat(szFrom, 128, "\x10]");
	StrCat(szReason, 128, "]");
	
	Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

	PrintToChat(client, "%s \x10你获得了\x04 %d 信用点 \x01[\x0A180s/次\x01]", PLUGIN_PREFIX_CREDITS, m_iCredits);
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
		PrintToChat(client, "%s 检测到你当前未加入\x0C官方组\x01  你无法获得签到奖励", PLUGIN_PREFIX);
		return;	
	}

	Active_GiveSignCredits(client);
}

void Active_GiveSignCredits(int client)
{
	int Credits = GetRandomInt(3, 300);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0F信用点\x01", PLUGIN_PREFIX, client, Credits);
	PrintToChat(client,"%s \x10你获得了\x04%d \x0F信用点 \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits);
}
#pragma semicolon 1

//////////////////////////////
//		DEFINITIONS 		//
//////////////////////////////
#define PLUGIN_NAME " Store Credits Controler "
#define PLUGIN_AUTHOR "maoling ( xQy )"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION " 4.5 "
#define PLUGIN_URL "http://steamcommunity.com/id/_xQy_/"
#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX_SIGN "[\x0EPlaneptune\x01]  "

//////////////////////////////
//		INCLUDES			//
//////////////////////////////
#include <sourcemod>
#include <cstrike>
#include <store>
#include <steamworks>
#include <cg_core>

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
Handle g_hTimer = INVALID_HANDLE;

bool g_bInOfficalGroup[MAXPLAYERS+1];
bool g_bInMimiGameGroup[MAXPLAYERS+1];
bool g_bInOpeatorGroup[MAXPLAYERS+1];
bool g_bIsCheck[MAXPLAYERS+1];

#define CG_group_id 103582791438550612
#define GB_group_id 103582791437825710
#define OP_group_id 103582791442277011

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
public OnMapStart()
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	g_hTimer = CreateTimer(300.0, CreditTimer);
}

public OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);
}

public OnClientDisconnect(client)
{
	g_bInOfficalGroup[client] = false;
	g_bInMimiGameGroup[client] = false;
	g_bInOpeatorGroup[client] = false;
	g_bIsCheck[client] = false;
}

public LookupPlayerGroups(client)
{
	g_bIsCheck[client] = true;
	SteamWorks_GetUserGroupStatus(client, CG_group_id);
	SteamWorks_GetUserGroupStatus(client, GB_group_id);
	SteamWorks_GetUserGroupStatus(client, OP_group_id);
}

public SteamWorks_OnClientGroupStatus(authid, groupid, bool isMember, bool isOfficer)
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
				//LogMessage("Client[%N] groupid[%d]", client, groupid);
				if(groupid == CG_group_id)
					g_bInOfficalGroup[client] = true;
				if(groupid == GB_group_id)
					g_bInMimiGameGroup[client] = true;
				if(groupid == OP_group_id)
					g_bInOpeatorGroup[client] = true;
				break;
			}
		}
	}
}

public Action CreditTimer(Handle timer)
{
	for(int client = 1; client <= MaxClients; ++client)
    {
		if(!IsClientInGame(client))
			continue;
		
		if(2 <= GetClientTeam(client) <= 3)
		{
			int m_iCredits = 0;
			int ifaith = CG_GetClientFaith(client);
			bool m_bGroupCreidts = false;
			char szFrom[128], szReason[128];
			Format(szFrom, 128, " \x10[");
			Format(szReason, 128, "PA-加成[");

			if(ifaith > 0)
			{
				m_iCredits += 3;
				StrCat(szFrom, 128, szFaith_CNAME[ifaith]);
				StrCat(szReason, 128, szFaith_NAME[ifaith]);
			}
			else
			{
				m_iCredits += 2;
				StrCat(szFrom, 128, "\x04在线时间");
				StrCat(szReason, 128, "在线时间 ");
			}
			
			int authid = PA_GetGroupID(client);
			if(authid > 0)
			{
				if(authid < 401)
				{
					m_iCredits += 3;
					char auname[32];
					PA_GetGroupName(client, auname, 32);
					StrCat(szReason, 128, auname);
					Format(auname, 32, "\x0A|\x0C%s", auname);
					StrCat(szFrom, 128, auname);
				}
				else if(500 > authid >= 401)
				{
					if(PA_GetGroupID(client) == 401)
						m_iCredits += 2;
					else if(PA_GetGroupID(client) == 402)
						m_iCredits += 3;
					else if(PA_GetGroupID(client) == 403)
						m_iCredits += 3;
					else if(PA_GetGroupID(client) == 404)
						m_iCredits += 4;
					else if(PA_GetGroupID(client) == 405)
						m_iCredits += 4;
					
					char auname[32];
					PA_GetGroupName(client, auname, 32);
					StrCat(szReason, 128, auname);
					Format(auname, 32, "\x0A|\x0C%s", auname);
					StrCat(szFrom, 128, auname);
				}
				else if(9000 > authid >= 500)
				{
					m_iCredits += 3;
					char auname[32];
					PA_GetGroupName(client, auname, 32);
					StrCat(szReason, 128, auname);
					Format(auname, 32, "\x0A|\x0C%s", auname);
					StrCat(szFrom, 128, auname);
				}
				else if(9990 > authid >= 9101)
				{
					m_iCredits += 4;
					char auname[32];
					PA_GetGroupName(client, auname, 32);
					StrCat(szReason, 128, auname);
					Format(auname, 32, "\x0A|\x0C%s", auname);
					StrCat(szFrom, 128, auname);
				}
				else if(authid > 9990)
				{
					m_iCredits += 5;
					char auname[32];
					PA_GetGroupName(client, auname, 32);
					StrCat(szReason, 128, auname);
					if(PA_GetGroupID(client) == 9999)
						Format(auname, 32, "\x0A|\x0E%s", auname);
					else
						Format(auname, 32, "\x0A|\x0C%s", auname);
					StrCat(szFrom, 128, auname);
				}
			}
			
			if(VIP_IsClientVIP(client))
			{
				if(VIP_GetVipType(client) == 3)
				{
					m_iCredits += 2;
					StrCat(szFrom, 128, "\x0A|\x07永久VIP");
					StrCat(szReason, 128, " SVIP ");
				}
				else if(VIP_GetVipType(client) == 2)
				{
					m_iCredits += 2;
					StrCat(szFrom, 128, "\x0A|\x07年费VIP");
					StrCat(szReason, 128, " YVIP ");
				}
				else if(VIP_GetVipType(client) == 1)
				{
					m_iCredits += 1;
					StrCat(szFrom, 128, "\x0A|\x07月费VIP");
					StrCat(szReason, 128, " MVIP ");
				}
			}

			if(g_bInOfficalGroup[client] && !m_bGroupCreidts)
			{				
				m_bGroupCreidts = true;
				m_iCredits += 2;
				StrCat(szFrom, 128, "\x0A|\x06官方组");
				StrCat(szReason, 128, "官方组");
			}
			
			if(g_bInMimiGameGroup[client] && !m_bGroupCreidts)
			{
				m_iCredits += 3;
				StrCat(szFrom, 128, "\x0A|\x06娱乐挂壁");
				StrCat(szReason, 128, "娱乐挂壁");
			}
			
			if(GetUserFlagBits(client) & ADMFLAG_BAN)
			{
				if(g_bInOpeatorGroup[client])
				{
					m_iCredits += 3;
					StrCat(szFrom, 128, "\x0A|\x10OP");
					StrCat(szReason, 128, "OP ");
				}		
			}
			
			StrCat(szFrom, 128, "\x10]");
			StrCat(szReason, 128, "]");
			
			Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

			PrintToChat(client, "%s \x10你获得了\x04 %d Credits \x0A积分来自", PLUGIN_PREFIX_CREDITS, m_iCredits);
			PrintToChat(client, "  %s", szFrom);
			
			//LogMessage("client[%N] iCredits[%d]", client, m_iCredits);
		}
	}

	g_hTimer = CreateTimer(300.0, CreditTimer);

	return Plugin_Continue;
}

public void CG_OnClientDailySign(client)
{
	if(!g_bInOfficalGroup[client])
	{
		PrintToChat(client, "%s 检测到你当前未加入\x0C官方组\x01  你无法获得签到奖励", PLUGIN_PREFIX_SIGN);
		return;	
	}
	
	if(CG_GetClientFaith(client) <= 0)
	{
		PrintToChat(client, "%s 检测到你当前没有\x0EFaith\x01  你无法获得签到奖励", PLUGIN_PREFIX_SIGN);
		return;	
	}

	int Credits = GetRandomInt(3, 300);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	CG_GiveClientShare(client, Credits/3, "签到");
	PrintToChat(client,"%s \x10你获得了\x04%d \x0FCredits \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits);
	PrintToChat(client,"%s \x10你获得了\x04%d \x10点\x0FShare \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits/3);
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0FCredits\x01, \x04%d \x10点\x0FShare", PLUGIN_PREFIX_SIGN, client, Credits, Credits/3);
}
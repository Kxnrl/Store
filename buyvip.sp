#include <sourcemod>
#include <cg_core>
#include <store>
#include <csgocolors>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name		= " Store - VIP Module ",
	author		= "maoling( xQy )",
	description	= "",
	version		= "1.0",
	url			= "http://csgogamers.com"
}

Handle g_hDatabase = INVALID_HANDLE;

public void CG_OnServerLoaded()
{
	g_hDatabase = CG_GetDiscuzDatabase();
	if(g_hDatabase == INVALID_HANDLE)
		CreateTimer(10.0, Timer_Reconnect);
}

public Action Timer_Reconnect(Handle timer)
{
	CG_OnServerLoaded();
}

public void VIP_OnMapStart()
{
}

public void VIP_Reset()
{
}

public bool VIP_Config(Handle &kv, int itemid)
{
	return true;
}

public void SQLCallback_BuyVIP(Handle db, Handle hndl, const char[] error, any userid)
{
	if(hndl==INVALID_HANDLE)
	{
		PrintToServer("Error happened: %s", error);
		return;
	}

	int client = GetClientOfUserId(userid);
	if(!client || !IsClientConnected(client))
	{
		return;
	}

	if(!SQL_HasResultSet(hndl))
	{
		CPrintToChat(client, "\x04[Store]  \x10购买VIP成功");
		Store_SaveClientAll(client);
		CG_SetClientVIP(client);
	}
	else if(SQL_FetchRow(hndl))
	{
		int result = SQL_FetchInt(hndl, 0);
		switch (result)
		{
			case 1: CPrintToChat(client, "\x04[Store]  \x07Steam账号没有和论坛账号绑定,购买失败!");
			case 2: CPrintToChat(client, "\x04[Store]  \x10你已经是VIP了");
		}
		Store_SetClientCredits(client, Store_GetClientCredits(client) + 16888, "购买一个月VIP失败退款");
	}
}

public int VIP_Equip(int client, int id)
{
	if(Store_GetClientCredits(client) < 16888)
	{
		CPrintToChat(client, "\x04[Store]  \x07你的Credits不足!");
		return -1;
	}

	if(CG_IsClientVIP(client))
	{
		CPrintToChat(client, "\x04[Store]  \x10你已经是VIP了");
		return -1;
	}

	char steamid[32], communityid[32];
	GetClientAuthId(client, AuthId_Steam2, steamid, 32, true);
	GetClientAuthId(client, AuthId_SteamID64, communityid, 32, true);

	char query[255];
	Format(query, sizeof(query), "CALL buyvip1month(%s)", communityid);
	SQL_TQuery(g_hDatabase, SQLCallback_BuyVIP, query, GetClientUserId(client));
	Store_SetClientCredits(client, Store_GetClientCredits(client) - 16888, "购买一个月VIP");
	return 0;
}

public int VIP_Remove(int client)
{
	return 0;
}

public void OnPluginStart()
{
	CG_OnServerLoaded();
	Store_RegisterHandler("buyvip", "", VIP_OnMapStart, VIP_Reset, VIP_Config, VIP_Equip, VIP_Remove, false);
}
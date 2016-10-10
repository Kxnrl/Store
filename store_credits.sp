#pragma semicolon 1

//////////////////////////////
//		DEFINITIONS 		//
//////////////////////////////
#define PLUGIN_NAME " Store Credits Controler "
#define PLUGIN_AUTHOR "maoling ( xQy )"
#define PLUGIN_DESCRIPTION ""
#define PLUGIN_VERSION " 4.5.1rc2 "
#define PLUGIN_URL "http://steamcommunity.com/id/_xQy_/"
#define PLUGIN_PREFIX_CREDITS "\x01 \x04[Store]  "
#define PLUGIN_PREFIX "[\x0EPlaneptune\x01]  "

//////////////////////////////
//		INCLUDES			//
//////////////////////////////
#include <sourcemod>
#include <cstrike>
#include <store>
#include <steamworks>
#include <cg_core>
#include <items>
#include <smlib>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////
Handle g_hTimer = INVALID_HANDLE;
Handle g_hRandom = INVALID_HANDLE;
Handle g_hDB = INVALID_HANDLE;

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
public void OnPluginStart()
{
	//IntiDatabase();
	RegAdminCmd("sm_boxtest", Command_BoxTest, ADMFLAG_ROOT);
	RegAdminCmd("sm_signtest", Command_SignTest, ADMFLAG_ROOT);
}

public void OnMapStart()
{
	if(!FindPluginByFile("rankme.smx") && !FindPluginByFile("warmod.smx"))
		PrecacheModel("models/maoling/active/gtx/titan.mdl");

	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	if(g_hRandom != INVALID_HANDLE)
	{
		KillTimer(g_hRandom);
		g_hRandom = INVALID_HANDLE;
	}
	
	g_hTimer = CreateTimer(300.0, CreditTimer);
	
	//if(!FindPluginByFile("deathmatch.smx") && !FindPluginByFile("warmod.smx"))
	//	g_hRandom = CreateTimer(GetRandomFloat(300.0,600.0), RandomDrop);
}

public void OnClientPostAdminCheck(int client)
{
	LookupPlayerGroups(client);
}

public void OnClientDisconnect(int client)
{
	g_bInOfficalGroup[client] = false;
	g_bInMimiGameGroup[client] = false;
	g_bInOpeatorGroup[client] = false;
	g_bIsCheck[client] = false;
}

public int LookupPlayerGroups(int client)
{
	g_bIsCheck[client] = true;
	SteamWorks_GetUserGroupStatus(client, CG_group_id);
	SteamWorks_GetUserGroupStatus(client, GB_group_id);
	SteamWorks_GetUserGroupStatus(client, OP_group_id);
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
	g_hTimer = INVALID_HANDLE;

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
			Format(szFrom, 128, "\x0C国庆节双倍=>\x10[");
			Format(szReason, 128, "store_credits[");

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
			
			m_iCredits *= 2;
			
			Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

			PrintToChat(client, "%s \x10你获得了\x04 %d Credits \x0A积分来自", PLUGIN_PREFIX_CREDITS, m_iCredits);
			PrintToChat(client, "  %s", szFrom);
			
			//LogMessage("client[%N] iCredits[%d]", client, m_iCredits);
		}
	}

	g_hTimer = CreateTimer(300.0, CreditTimer);
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
	
	if(CG_GetClientFaith(client) <= 0)
	{
		PrintToChat(client, "%s 检测到你当前没有\x0EFaith\x01  你无法获得签到奖励", PLUGIN_PREFIX);
		return;	
	}
	
	Active_GiveSignCredits(client);
	//Active_RandomStoreItem(client);
}

void IntiDatabase()
{
	char m_szError[128];
	g_hDB = SQL_Connect("csgo", true, m_szError, 128);

	if(g_hDB != INVALID_HANDLE)
	{
		SQL_SetCharset(g_hDB, "utf8");
		LogMessage("Connect to database successful!");
	}
	else
	{
		PrintToServer("Not connecting to database: %s", m_szError);
		LogMessage("Not connecting to database: %s", m_szError);
	}
}

void Active_GiveSignCredits(int client)
{
	int Credits = GetRandomInt(3, 300);
	Store_SetClientCredits(client, Store_GetClientCredits(client) + Credits, "PA-签到");
	CG_GiveClientShare(client, Credits/3, "签到");
	PrintToChatAll("%s \x0E%N\x01签到获得\x04 %d\x0FCredits\x01, \x04%d\x0FShare", PLUGIN_PREFIX, client, Credits, Credits/3);
	PrintToChat(client,"%s \x10你获得了\x04%d \x0FCredits \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits);
	PrintToChat(client,"%s \x10你获得了\x04%d \x0FShare \x10来自\x04[签到].", PLUGIN_PREFIX_CREDITS, Credits/3);
}

void Active_RandomStoreItem(int client)
{
	int m_iModelsID = GetRandomInt(1,24);
	int m_iTime = (GetRandomInt(1, 24)*3600);
	int userid = GetClientUserId(client);
	char m_szModelPath[128], m_szQuery[512];
	GetModelPath(m_iModelsID, m_szModelPath, 128);
	Handle pack = CreateDataPack();
	WritePackCell(pack, userid);
	WritePackCell(pack, m_iModelsID);
	WritePackCell(pack, m_iTime);
	ResetPack(pack);
	Format(m_szQuery, 512, "SELECT date_of_expiration FROM store_items WHERE player_id = %d AND unique_id='%s';", Store_GetClientID(client), m_szModelPath);
	SQL_TQuery(g_hDB, SQLCallback_SignCheckItem, m_szQuery, pack);
}

public void SQLCallback_SignCheckItem(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int m_iModelsID = ReadPackCell(pack);
	int m_iTime = ReadPackCell(pack);
	CloseHandle(pack);
	int m_iExpTime = -1;
	char m_szModelPath[128], m_szModelName[128];
	GetModelPath(m_iModelsID, m_szModelPath, 128);
	GetModelName(m_iModelsID, m_szModelName, 128);
	
	if(!client)
		return;

	Handle data = CreateDataPack();
	WritePackCell(data, userid);
	WritePackCell(data, m_iModelsID);
	WritePackCell(data, m_iTime);

	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 发放签到奖励模型失败: SQL读取数据失败SQL_CheckItem CallBack.", PLUGIN_PREFIX);
		LogError("SQL_SignCheckItem CallBack Error: %s", error);
		return;
	}

	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		m_iExpTime = SQL_FetchInt(hndl, 0);
		if(m_iExpTime == 0)
		{
			PrintToChat(client, "%s 本次你签到的奖励模型为\x04%s\x01,但你已经持有该模型永久物品,我们在此表示遗憾", PLUGIN_PREFIX, m_szModelName);
			PrintToChatAll("%s \x0C%N\x01完成了每日签到,获得了\x04%s\x01 ,按Y输入!sign来签到", PLUGIN_PREFIX, client, m_szModelName);
		}
		else
		{
			m_iExpTime += m_iTime;
			char m_szQuery[512];
			Format(m_szQuery, 512, "UPDATE store_items SET date_of_expiration = '%i' WHERE player_id = %d AND `unique_id`=\"%s\"", m_iExpTime, Store_GetClientID(client), m_szModelPath);
			WritePackCell(data, m_iExpTime);
			ResetPack(data);

			if(m_iExpTime != 0)
				SQL_TQuery(g_hDB, SQLCallback_SignUpdateExpTime, m_szQuery, data);
			else
				PrintToChat(client, "%s 本次你签到的奖励模型为\x04%s\x01,但你已经持有该模型永久物品,我们在此表示遗憾", PLUGIN_PREFIX, m_szModelName);
		}
	}
	else
	{
		char m_szQuery[512];
		m_iExpTime = GetTime()+m_iTime;
		Format(m_szQuery, 512, "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"playerskin\", \"%s\", %d, %d, 30);", Store_GetClientID(client), m_szModelPath, GetTime(), m_iExpTime);
		WritePackCell(data, m_iExpTime);
		ResetPack(data);
		SQL_TQuery(g_hDB, SQLCallback_SignItemInsert, m_szQuery, data);
	}
}

public void SQLCallback_SignUpdateExpTime(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int m_iModelsID = ReadPackCell(pack);
	int m_iTime = ReadPackCell(pack);
	int m_iExpTime = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 发放签到奖励模型失败: SQL读取数据失败SQL_UpdateExpTime CallBack.", PLUGIN_PREFIX);
		LogError("%N SQL_UpdateExpTime CallBack  Error: %s", client, error);
		return;
	}
	char m_szModelName[128];
	GetModelName(m_iModelsID, m_szModelName, 128);
	int hours = m_iTime/3600;
	PrintToChat(client, "%s 签到成功,您已获得\x04%s\x07(%i小时[从原有的基础上延长])\x01作为奖励", PLUGIN_PREFIX, m_szModelName, hours);
	PrintToChatAll("%s \x0C%N\x01完成了每日签到,获得了\x04%s\x01 ,按Y输入!sign来签到", PLUGIN_PREFIX, client, m_szModelName);
	PrintToConsole(client, "m_iTime=%i  m_iExpTime=%i", m_iTime, m_iExpTime);
}

public void SQLCallback_SignItemInsert(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int m_iModelsID = ReadPackCell(pack);
	int m_iTime = ReadPackCell(pack);
	int m_iExpTime = ReadPackCell(pack);
	CloseHandle(pack);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 发放签到奖励模型失败: SQL读取数据失败SQL_RandomItemInsert CallBack.", PLUGIN_PREFIX);
		LogError("%N SQL_UpdateExpTime CallBack  Error: %s", client, error);
		return;
	}
	char m_szModelName[128];
	GetModelName(m_iModelsID, m_szModelName, 128);
	int hours = m_iTime/3600;
	PrintToChat(client, "%s 签到成功,您已获得\x04%s\x07(%i小时[新物品获得])\x01作为奖励", PLUGIN_PREFIX, m_szModelName, hours);
	PrintToChatAll("%s \x0C%N\x01完成了每日签到,获得了\x04%s\x01 ,按Y输入!sign来签到", PLUGIN_PREFIX, client, m_szModelName);
	PrintToConsole(client, "m_iTime=%i  m_iExpTime=%i", m_iTime, m_iExpTime);
}

public Action Command_BoxTest(int client, int args)
{
	for(int x = 0; x < 5; ++x)
		CreateBoxCase();
		
	PrintToChatAll("%s 服务器内一些不为人知的角落,产生了一些宝箱", PLUGIN_PREFIX);
}

public Action RandomDrop(Handle timer)
{
	g_hRandom = INVALID_HANDLE;

	RemoveAllBox();

	int total;
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			if(GetClientTeam(i) > 1)
				total++;

	if(total >= 8)
	{
		total = total/8;
		
		for(int x = 0; x < total; ++x)
			CreateBoxCase();
		
		PrintToChatAll("%s 服务器内掉落了\x04%d\x01个宝箱", PLUGIN_PREFIX, total);
	}
	else
		PrintToChatAll("%s 服务器当前人数不足,本轮宝箱取消", PLUGIN_PREFIX);

	g_hRandom = CreateTimer(GetRandomFloat(300.0,600.0), RandomDrop);
}

public int CreateBoxCase()
{
	int client = Client_GetRandom(CLIENTFILTER_ALIVE);
	float DropPos[3];
	GetClientAbsOrigin(client, DropPos);
	DropPos[0] += GetRandomFloat(-100.0, 100.0);
	DropPos[1] += GetRandomFloat(-100.0, 100.0);
	DropPos[2] += 70.0;

	int iEntity = CreateBox(DropPos);
	
	return iEntity;
}

int CreateBox(float DropPos[3])
{
	int iEntity = CreateEntityByName("prop_physics_override");
	
	char szTargetName[32];
	Format(szTargetName, 32, "active_box_%d", iEntity);

	DispatchKeyValue(iEntity, "Solid", "6");
	DispatchKeyValue(iEntity, "model", "models/maoling/active/gtx/titan.mdl");
	DispatchKeyValue(iEntity, "spawnflags", "256");
	DispatchKeyValue(iEntity, "targetname", szTargetName);
	DispatchKeyValueVector(iEntity, "origin", DropPos);

	DispatchSpawn(iEntity);

	ActivateEntity(iEntity);

	SetEntProp(iEntity, Prop_Data, "m_takedamage", 2);
	SetEntProp(iEntity, Prop_Data, "m_iMaxHealth", 233);
	SetEntProp(iEntity, Prop_Data, "m_iHealth", 233);
	TeleportEntity(iEntity, DropPos, NULL_VECTOR, NULL_VECTOR);

	SDKHook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage);

	return iEntity;
}

public void RemoveAllBox()
{
	int iEntity = -1;
	char m_szName[64];
	while((iEntity = FindEntityByClassname(iEntity, "prop_physics_override")) != -1)
	{
		if(IsValidEntity(iEntity))
		{
			GetEntPropString(iEntity, Prop_Data, "m_iName", m_szName, 64);
			if(StrContains(m_szName, "active_box", false ) != -1)
				AcceptEntityInput(iEntity, "Kill");
		}
	}
}

void OpenBoxCase(int client, int iEntity)
{
	int iRandom_Item;
	int iRandom_Type = GetRandomInt(1, 15);
	int iRandom_Time = GetRandomInt(1, 100);
	char m_szType[16], m_szName[128], m_szPath[128], m_szTime[32], m_szQuery[512];

	if(iRandom_Type == 1)
		iRandom_Item = GetRandomInt(1, 19);
	else if(iRandom_Type == 2)
		iRandom_Item = GetRandomInt(1, 2);
	else if(iRandom_Type == 3)
		iRandom_Item = GetRandomInt(1, 8);
	else if(iRandom_Type == 4)
		iRandom_Item = GetRandomInt(1, 26);
	else if(iRandom_Type == 5)
		iRandom_Item = GetRandomInt(1, 10);
	else if(iRandom_Type == 6)
		iRandom_Item = GetRandomInt(1, 8);
	else if(iRandom_Type == 7)
		iRandom_Item = GetRandomInt(1, 22);
	else if(iRandom_Type == 8)
		iRandom_Item = GetRandomInt(1, 8);
	else if(iRandom_Type == 9)
		iRandom_Item = GetRandomInt(1, 5);
	else if(iRandom_Type == 10)
		iRandom_Item = GetRandomInt(1, 6);
	else if(iRandom_Type == 11)
		iRandom_Item = 1;
	
	if(!GetItemString(iRandom_Type, iRandom_Item, m_szType, m_szName, m_szPath) || iRandom_Type > 11)
	{
		PrintToChat(client, "%s  你的脸太黑了，居然什么都没有得到", PLUGIN_PREFIX);
		return;
	}
	
	if(iRandom_Time > 80)
		iRandom_Time = 3;
	else if(iRandom_Time >= 50)
		iRandom_Time = 2;
	else
		iRandom_Time = 1;

	if(iRandom_Time == 1)
		Format(m_szTime, 32, "1天");
	if(iRandom_Time == 2)
		Format(m_szTime, 32, "1周");
	if(iRandom_Time == 3)
		Format(m_szTime, 32, "1月");
	
	PrintToChat(client, "%s 你获得了 \x04[%s - %s] \x07%s \x01 正在检查你的库存是否有物品重复", PLUGIN_PREFIX, m_szName, m_szType, m_szTime);

	Handle pack = CreateDataPack();
	WritePackCell(pack, GetClientUserId(client));
	WritePackCell(pack, iRandom_Type);
	WritePackCell(pack, iRandom_Item);
	WritePackCell(pack, iRandom_Time);

	Format(m_szQuery, 512, "SELECT date_of_expiration FROM store_items WHERE player_id = %d AND unique_id='%s'", Store_GetClientID(client), m_szPath);
	SQL_TQuery(g_hDB, SQLCallback_CheckItem, m_szQuery, pack);
	
	CreateTimer(0.0, Timer_RemoveEntity, EntIndexToEntRef(iEntity));
}

public Action Timer_RemoveEntity(Handle timer, int iRef)
{
	int iEntity = EntRefToEntIndex(iRef);
	if(iEntity != INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(iEntity))
		{
			int iEnt = CreateEntityByName("env_explosion");
	
			if(iEnt != -1)
			{
				float fPos[3];
				GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos); //GetClientAbsOrigin(iEntity, fPos);
				
				SetEntProp(iEnt, Prop_Data, "m_spawnflags", 6146);
				SetEntProp(iEnt, Prop_Data, "m_iMagnitude", GetRandomInt(1,10));
				SetEntProp(iEnt, Prop_Data, "m_iRadiusOverride", 100);
				
				DispatchSpawn(iEnt);
				ActivateEntity(iEnt);

				TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
				SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", 0);

				AcceptEntityInput(iEnt, "Explode");
				AcceptEntityInput(iEnt, "Kill");
				
				char szSound[32];
				Format(szSound, 32, "weapons/hegrenade/explode%d.wav", GetRandomInt(3, 5));
				EmitSoundToAll(szSound);
			}
	
			SDKUnhook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage);
			AcceptEntityInput(iEntity, "Kill");
		}
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(attacker > MaxClients || attacker < 1)
		return Plugin_Continue;

	if(victim == attacker)
		return Plugin_Continue;

	if(IsValidEdict(weapon))
	{
		char szWeapon[32];
		GetEdictClassname(weapon, szWeapon, 32);
		if(StrContains(szWeapon, "knife", false) == -1)
		{
			if(FindPluginByFile("zombiereloaded.smx"))
				SlapPlayer(attacker, 10);
			else
				SlapPlayer(attacker, 35);

			PrintCenterText(attacker, "你非法破坏活动宝箱\n 你已经被天谴");
			PrintToChatAll("%s  \x02%N\x07因为非法破坏活动宝箱,已遭到天谴", PLUGIN_PREFIX, attacker);
			return Plugin_Handled;
		}
	}

	if(IsValidEdict(inflictor))
	{
		char entityclass[32];
		GetEdictClassname(inflictor, entityclass, 32);
		if(StrEqual(entityclass, "hegrenade_projectile") || StrEqual(entityclass, "inferno"))
			return Plugin_Handled;
	}
	
	int health = GetEntProp(victim, Prop_Data, "m_iHealth");
	
	if(float(health) < damage)
	{
		if(attacker > 0 && attacker <= MaxClients)
		{
			int healthleft = health - RoundToCeil(damage);
			
			if(healthleft < 0)
				healthleft = 0;
			
			PrintHintText(attacker,"宝箱剩余HP: %d / 233",healthleft);
			
			if(IsClientInGame(attacker))
				OpenBoxCase(attacker, victim);
		}
	}
	else
	{
		if(attacker > 0 && attacker <= MaxClients)
		{
			int healthleft = health - RoundToCeil(damage);
			
			if(healthleft < 0)
				healthleft = 0;

			PrintHintText(attacker,"宝箱剩余HP: %d / 233",healthleft);
		}
	}

	return Plugin_Continue;
}

public void SQLCallback_CheckItem(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	ResetPack(pack);
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int iRandom_Type = ReadPackCell(pack);
	int iRandom_Item = ReadPackCell(pack);
	int iRandom_Time = ReadPackCell(pack);
	int m_iExpTime = -1;
	char m_szType[16], m_szName[128], m_szPath[128], m_szTime[32], m_szQuery[512];
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 检查物品库存重复失败/发放宝箱奖励失败: SQLCallback_CheckItem.", PLUGIN_PREFIX);
		LogError("SQL_CheckItem CallBack Error: %s", error);
		CloseHandle(pack);
		return;
	}
	
	GetItemString(iRandom_Type, iRandom_Item, m_szType, m_szName, m_szPath);

	if(iRandom_Time == 1)
		Format(m_szTime, 32, "1天");
	if(iRandom_Time == 2)
		Format(m_szTime, 32, "1周");
	if(iRandom_Time == 3)
		Format(m_szTime, 32, "1月");

	if(SQL_HasResultSet(hndl) && SQL_FetchRow(hndl))
	{
		m_iExpTime = SQL_FetchInt(hndl, 0);
		if(m_iExpTime == 0)
		{
			PrintToChat(client, "%s 你已经持有 \x04[%s - %s] \x01永久物品,我们在此表示遗憾", PLUGIN_PREFIX, m_szName, m_szType);
			PrintToChatAll("%s \x0C%N\x01打开了宝箱,获得了 \x04[%s - %s] \x07%s", PLUGIN_PREFIX, client, m_szName, m_szType, m_szTime);
		}
		else
		{
			if(iRandom_Time == 1)
				m_iExpTime += 86400;
			else if(iRandom_Time == 2)
				m_iExpTime += 604800;
			else if(iRandom_Time == 3)
				m_iExpTime += 2592000;

			Format(m_szQuery, 512, "UPDATE store_items SET date_of_expiration = '%i' WHERE player_id = %d AND `unique_id`=\"%s\"", m_iExpTime, Store_GetClientID(client), m_szPath);
			SQL_TQuery(g_hDB, SQLCallback_UpdateExpTime, m_szQuery, pack);
		}
	}
	else
	{
		if(iRandom_Time == 1)
			m_iExpTime = GetTime()+86400;
		else if(iRandom_Time == 2)
			m_iExpTime = GetTime()+604800;
		else if(iRandom_Time == 3)
			m_iExpTime = GetTime()+2592000;
	
		Format(m_szQuery, 512, "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", %d, %d, 30);", Store_GetClientID(client), m_szType, m_szPath, GetTime(), m_iExpTime);
		SQL_TQuery(g_hDB, SQLCallback_ItemInsert, m_szQuery, pack);
	}
}

public void SQLCallback_UpdateExpTime(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	ResetPack(pack);
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int iRandom_Type = ReadPackCell(pack);
	int iRandom_Item = ReadPackCell(pack);
	int iRandom_Time = ReadPackCell(pack);
	
	CloseHandle(pack);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 发放宝箱奖励失败: SQLCallback_UpdateExpTime.", PLUGIN_PREFIX);
		LogError("%N SQL_UpdateExpTime CallBack  Error: %s", client, error);
		return;
	}
	
	char m_szType[16], m_szName[128], m_szPath[128], m_szTime[32];
	
	GetItemString(iRandom_Type, iRandom_Item, m_szType, m_szName, m_szPath);

	if(iRandom_Time == 1)
		Format(m_szTime, 32, "1天");
	if(iRandom_Time == 2)
		Format(m_szTime, 32, "1周");
	if(iRandom_Time == 3)
		Format(m_szTime, 32, "1月");

	PrintToChat(client, "%s 您已获得 \x04[%s - %s] \x07%s \x01(从原有的基础上延长)", PLUGIN_PREFIX, m_szName, m_szType, m_szTime);
	PrintToChatAll("%s \x0C%N\x01打开了宝箱,获得了 \x04[%s - %s] \x07%s", PLUGIN_PREFIX, client, m_szName, m_szType, m_szTime);
}

public void SQLCallback_ItemInsert(Handle owner, Handle hndl, const char[] error, Handle pack)
{
	ResetPack(pack);
	int userid = ReadPackCell(pack);
	int client = GetClientOfUserId(userid);
	int iRandom_Type = ReadPackCell(pack);
	int iRandom_Item = ReadPackCell(pack);
	int iRandom_Time = ReadPackCell(pack);
	
	CloseHandle(pack);
	
	if(!client)
		return;
	
	if(hndl == INVALID_HANDLE)
	{
		PrintToChat(client, "%s 发放宝箱奖励失败: SQLCallback_ItemInsert.", PLUGIN_PREFIX);
		LogError("%N SQLCallback_ItemInsert CallBack  Error: %s", client, error);
		return;
	}
	
	char m_szType[16], m_szName[128], m_szPath[128], m_szTime[32];
	
	GetItemString(iRandom_Type, iRandom_Item, m_szType, m_szName, m_szPath);
	
	if(iRandom_Time == 1)
		Format(m_szTime, 32, "1天");
	if(iRandom_Time == 2)
		Format(m_szTime, 32, "1周");
	if(iRandom_Time == 3)
		Format(m_szTime, 32, "1月");

	PrintToChat(client, "%s 您已获得 \x04[%s - %s] \x07%s \x01(新物品获得,需要重新进入服务器)", PLUGIN_PREFIX, m_szName, m_szType, m_szTime);
	PrintToChatAll("%s \x0C%N\x01打开了宝箱,获得了 \x04[%s - %s] \x07%s", PLUGIN_PREFIX, client, m_szName, m_szType, m_szTime);
}

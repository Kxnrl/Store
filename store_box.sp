#include <store>
#include <store.item>
#include <sdktools>
#include <sdkhooks>
#include <maoling>
#include <diamond>
#include <cg_core>
#include <smlib/clients>
#include <smlib/math>
#include <csc>

#define PREFIX "[\x10新年快乐\x01]  "

char logFile[128];

public Plugin myinfo =
{
	name		= "Store TreasureBox",
	author		= "Kyle",
	description = "",
	version		= "1.1rc2",
	url			= "http://steamcommunity.com/id/_xQy_/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	MarkNativeAsOptional("CG_Broadcast");
	return APLRes_Success;
}

public void OnPluginStart()
{
	RegAdminCmd("sm_boxtest", Command_BoxTest, ADMFLAG_ROOT);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	BuildPath(Path_SM, logFile, 128, "data/riffle.log");
}

public void OnAllPluginsLoaded()
{
	if(!FindPluginByFile("zombiereloaded.smx") && !FindPluginByFile("ct.smx") && !FindPluginByFile("mg_stats.smx") && !FindPluginByFile("sm_hosties.smx") && !FindPluginByFile("KZTimerGlobal.smx") && !FindPluginByFile("public_ext.smx"))
	{
		LogError("store_box is not avaliable in current server.");
		char m_szPath[128];
		BuildPath(Path_SM, m_szPath, 128, "plugins/store_box.smx");
		if(FileExists(m_szPath) && DeleteFile(m_szPath))
			LogError("Delete store_box.smx sucessfual.");
		ServerCommand("sm plugins unload store_box.smx");
		return;
	}
}

public void OnMapStart()
{
	PrecacheModel("models/maoling/active/gtx/titan.mdl");

	CreateTimer(305.0, Timer_DropBox, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	CreateTimer(GetConVarFloat(FindConVar("mp_round_restart_delay"))-2.0, Timer_Remove, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Remove(Handle timer)
{
	RemoveAllBox();
}

public Action Command_BoxTest(int client, int args)
{
	for(int x = 0; x < 5; ++x)
		CreateBoxCase();
		
	PrintToChatAll("%s 服务器内一些不为人知的角落,产生了一些宝箱", PREFIX);
}

public Action Timer_DropBox(Handle timer)
{
	RemoveAllBox();

	int total;
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i) && !IsFakeClient(i))
			if(GetClientTeam(i) > 1)
				total++;

	if(total >= 10)
	{
		total = total/6;
		
		for(int x = 0; x < total; ++x)
			CreateBoxCase();
		
		PrintToChatAll("%s  猫灵服务器内洒了\x04%d\x01个宝箱", PREFIX, total);
	}
	else
		PrintToChatAll("%s  服务器当前人数不足,本轮宝箱取消", PREFIX);
}

stock void RemoveAllBox()
{
	int iEntity = -1;
	char m_szName[64];
	while((iEntity = FindEntityByClassname(iEntity, "prop_physics_override")) != -1)
	{
		if(IsValidEntity(iEntity))
		{
			GetEntPropString(iEntity, Prop_Data, "m_iName", m_szName, 64);
			if(StrContains(m_szName, "active_box", false ) != -1)
			{
				SDKUnhook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage);
				AcceptEntityInput(iEntity, "Kill");
			}	
		}
	}
}

int CreateBoxCase()
{
	int client = Client_GetRandom(CLIENTFILTER_ALIVE);
	float m_fPos[3];
	GetClientAbsOrigin(client, m_fPos);
	m_fPos[0] += GetRandomFloat(-100.0, 100.0);
	m_fPos[1] += GetRandomFloat(-100.0, 100.0);
	m_fPos[2] += 70.0;

	int iEntity = CreateBox(m_fPos);

	return iEntity;
}

stock int CreateBox(float DropPos[3])
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
	SetEntProp(iEntity, Prop_Data, "m_iMaxHealth", 100);
	SetEntProp(iEntity, Prop_Data, "m_iHealth", 100);
	TeleportEntity(iEntity, DropPos, NULL_VECTOR, NULL_VECTOR);

	SDKHook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage);

	return iEntity;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(attacker > MaxClients || attacker < 1 || !IsClientInGame(attacker) || !IsPlayerAlive(attacker) || victim == attacker)
		return Plugin_Handled;
	
	if(IsValidEdict(inflictor))
	{
		char entityclass[32];
		GetEdictClassname(inflictor, entityclass, 32);
		if(StrEqual(entityclass, "hegrenade_projectile") || StrEqual(entityclass, "inferno"))
			return Plugin_Handled;
	}

	if(IsValidEdict(weapon))
	{
		char szWeapon[32];
		GetEdictClassname(weapon, szWeapon, 32);
		if(StrContains(szWeapon, "knife", false) == -1)
		{
			PrintCenterText(attacker, "你非法破坏活动宝箱\n 你已经被天谴");
			PrintToChatAll("%s  \x02%N\x07因为非法破坏活动宝箱,已遭到天谴", PREFIX, attacker);

			if(FindPluginByFile("zombiereloaded.smx"))
			{
				SlapPlayer(attacker, 10);
				return Plugin_Continue;
			}	
			else
			{
				ForcePlayerSuicide(attacker);
				return Plugin_Handled;
			}
		}
	}

	int health = GetEntProp(victim, Prop_Data, "m_iHealth");
	
	if(float(health) < damage)
	{
		if(attacker > 0 && attacker <= MaxClients)
		{
			int healthleft = health - RoundToCeil(damage);
			
			if(healthleft < 0)
				healthleft = 0;
			
			PrintHintText(attacker, "宝箱剩余HP: %d / 100", healthleft);

			OpenBoxCase(attacker, victim);
		}
	}
	else
	{
		int healthleft = health - RoundToCeil(damage);
		PrintHintText(attacker, "宝箱剩余HP: %d / 100", healthleft);
	}

	return Plugin_Continue;
}

void OpenBoxCase(int client, int iEntity)
{
	CreateTimer(0.0, Timer_RemoveEntity, iEntity);

	int u = Math_GetRandomInt(1, 6666);
	if(u == 1228 || u == 416 || u == 1018)
	{
		RaffleLimitedItem(client);
		return;
	}
	if(2333 <= u <= 2400)
	{
		RaffleDiamods(client);
		return;
	}
	if(2400 <= u <= 2500)
	{
		RaffleCredits(client);
		return;
	}

	int id = Math_GetRandomInt(1, 226);
	int itemid = Store_GetItem(g_szItemType[id], g_szItemUid[id]);
	if(Math_GetRandomInt(1, 100) > 80 || itemid < 0)
	{
		PrintToChat(client, "%s  你的脸太黑了，居然什么都没有得到", PREFIX);
		return;
	}

	int extime = 0;
	int rdm = Math_GetRandomInt(1, 99);
	
	if(rdm >= 95)
		extime = Math_GetRandomInt(31, 365);
	else if(95 > rdm >= 75)
		extime = Math_GetRandomInt(8, 30);
	else if(75 > rdm >= 40)
		extime = Math_GetRandomInt(2, 7);
	else
		extime = 1;

	PrintToChat(client, "%s  你获得了 \x04[%s-%s](%d天)...", PREFIX, g_szItemNick[id], g_szItemName[id], extime);

	if(Store_HasClientItem(client, itemid))
	{
		if(Store_GetItemExpiration(client, itemid) == 0)
			PrintToChat(client, "%s  \x04你已经有用此物品的永久使用权...", PREFIX);
		else
			Store_ExtClientItem(client, itemid, extime*86400);
	}
	else
		Store_GiveItem(client, itemid, GetTime(), GetTime()+(extime*86400), 30);
	
	if(extime >= 7)
	{
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F[%s-%s]\x05(%d天)", client, g_szItemNick[id], g_szItemName[id], extime);
		Boradcast((extime >= 30) ? true : false, fmt);
	}

	PrintToChatAll("%s  \x0C%N\x01打开了宝箱,获得了 \x04[%s-%s](%d天)", PREFIX, client, g_szItemNick[id], g_szItemName[id], extime);
}

public Action Timer_RemoveEntity(Handle timer, int iEntity)
{
	if(IsValidEntity(iEntity))
	{
		int iEnt = CreateEntityByName("env_explosion");

		if(iEnt != -1)
		{
			float fPos[3];
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPos); //GetClientAbsOrigin(iEntity, fPos);
			
			SetEntProp(iEnt, Prop_Data, "m_spawnflags", 6146);
			SetEntProp(iEnt, Prop_Data, "m_iMagnitude", Math_GetRandomInt(2,10));
			SetEntProp(iEnt, Prop_Data, "m_iRadiusOverride", 200);
			
			DispatchSpawn(iEnt);
			ActivateEntity(iEnt);

			TeleportEntity(iEnt, fPos, NULL_VECTOR, NULL_VECTOR);
			SetEntPropEnt(iEnt, Prop_Send, "m_hOwnerEntity", 0);

			AcceptEntityInput(iEnt, "Explode");
			AcceptEntityInput(iEnt, "Kill");
			
			char szSound[32];
			Format(szSound, 32, "weapons/hegrenade/explode%d.wav", Math_GetRandomInt(3, 5));
			EmitSoundToAll(szSound);
		}

		SDKUnhook(iEntity, SDKHook_OnTakeDamage, OnTakeDamage);
		AcceptEntityInput(iEntity, "Kill");
	}
}

void RaffleLimitedItem(int client)
{
	char name[64], type[32], uid[128];
	switch(Math_GetRandomInt(1, 3))
	{
		case 1:
		{
			strcopy(name, 64, "普魯魯特(Pururut)[线下见面会专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/neptunia/pururut/normal/pururut.mdl");
		}
		case 2:
		{
			strcopy(name, 64, "Re0.艾米莉亚(Emilia)[新年活动专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/re0/emilia_v2/emilia.mdl");
		}
		case 3:
		{
			strcopy(name, 64, "夕立(Yuudachi)[周年庆专属]");
			strcopy(type, 32, "playerskin");
			strcopy(uid, 128, "models/player/custom_player/maoling/kantai_collection/yuudachi/yuudachi.mdl");
		}
	}

	int rdm = Math_GetRandomInt(1, 100000), itemid = Store_GetItem(type, uid);
	if(itemid <= 0) return;

	if(rdm == 1228 || rdm == 416 || rdm == 1018)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 0);
		else
			Store_GiveItem(client, itemid, GetTime(), 0, 306);
		
		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(永久)", PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F%s\x05(永久)", client, name);
		Boradcast(true, fmt);
		
		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (永久)", rdm, client, name);
	}
	else if(233 <= rdm <= 288)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 31536000);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+31536000, 305);

		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(1年)", PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F%s\x05(1年)", client, name);
		Boradcast(true, fmt);
		
		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (1年)", rdm, client, name);
	}
	else if(666 <= rdm <= 888)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 2592000);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+2592000, 304);

		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(1月)", PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F%s\x05(1月)", client, name);
		Boradcast(true, fmt);
		
		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (1月)", rdm, client, name);
	}
	else if(2333 <= rdm <= 2888)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 604800);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+604800, 303);

		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(1周)", PREFIX, client, name);
		
		char fmt[256];
		Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F%s\x05(1周)", client, name);
		Boradcast(true, fmt);
		
		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (1周)", rdm, client, name);
	}
	else if(6888 <= rdm <= 8888)
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 86400);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+86400, 302);

		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(1天)", PREFIX, client, name);

		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (1天)", rdm, client, name);
	}
	else
	{
		if(Store_HasClientItem(client, itemid))
			Store_ExtClientItem(client, itemid, 7200);
		else
			Store_GiveItem(client, itemid, GetTime(), GetTime()+7200, 301);

		PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%s\x05(2小时)", PREFIX, client, name);
		
		LogToFileEx(logFile, " [%d]%N 打开宝箱获得了 %s (2小时)", rdm, client, name);
	}
}

void RaffleDiamods(int client)
{
	if(CG_GetDiscuzUID(client) < 1)
	{
		PrintToChat(client, "%s  你没有注册论坛会员,无法参与钻石活动", PREFIX);
		return;
	}
	
	int rdm = Math_GetRandomInt(5, 20);
	PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%d钻石", PREFIX, client, rdm);
	CG_SetClientDiamond(client, CG_GetClientDiamond(client)+rdm);
	
	char fmt[256];
	Format(fmt, 256, "\x0C%N\x04打开宝箱获得了\x0F%d钻石", client, rdm);
	Boradcast(false, fmt);
}

void RaffleCredits(int client)
{
	int rdm = Math_GetRandomInt(50, 300);
	PrintToChatAll("%s  \x0C%N\x04打开宝箱获得了\x0F%d信用点", PREFIX, client, rdm);
	Store_SetClientCredits(client, Store_GetClientCredits(client)+rdm, "新年活动-开宝箱");
}

stock void Boradcast(bool db, const char[] content)
{
	if(GetFeatureStatus(FeatureType_Native, "CG_Broadcast") != FeatureStatus_Available)
		return;
	
	CG_Broadcast(db, content);
}
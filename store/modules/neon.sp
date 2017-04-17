#define Module_Neon

enum Neon
{
	iColor[4],
	iBright,
	iDistance,
	iFade
}

Neon g_eNeons[STORE_MAX_ITEMS][Neon];
int g_iNeons = 0;
int g_iClientNeon[MAXPLAYERS+1] = {INVALID_ENT_REFERENCE, ...};

public int Neon_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iNeons); 
	KvGetColor(kv, "neoncolor", g_eNeons[g_iNeons][iColor][0], g_eNeons[g_iNeons][iColor][1], g_eNeons[g_iNeons][iColor][2], g_eNeons[g_iNeons][iColor][3]); 
	g_eNeons[g_iNeons][iBright] = KvGetNum(kv, "brightness");
	g_eNeons[g_iNeons][iDistance] = KvGetNum(kv, "distance");
	g_eNeons[g_iNeons][iFade] = KvGetNum(kv, "distancefade");
	++g_iNeons;
	return true; 
}

public void Neon_OnMapStart()
{
	
}

public void Neon_OnClientDisconnect(int client)
{
	Store_RemoveClientNeon(client);
}

public void Neon_Reset()
{
	g_iNeons = 0;
}

public int Neon_Equip(int client, int id)
{
	RequestFrame(EquipNeon_Delay, client);

	return 0;
}

public void EquipNeon_Delay(int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
		Store_SetClientNeon(client);
}

public int Neon_Remove(int client) 
{
	Store_RemoveClientNeon(client);
	return 0; 
}

#if defined AllowHide
public Action Hook_SetTransmit_Neon(int ent, int client)
{
	if(GetEdictFlags(ent) & FL_EDICT_ALWAYS)
		SetEdictFlags(ent, GetEdictFlags(ent) ^ FL_EDICT_ALWAYS & FL_EDICT_DONTSEND);

	return !(g_bHideMode[client]) ? Plugin_Continue : Plugin_Handled;
}
#endif

void Store_RemoveClientNeon(int client)
{
	if(g_iClientNeon[client] != INVALID_ENT_REFERENCE)
	{
		int entity = EntRefToEntIndex(g_iClientNeon[client]);
		if(IsValidEdict(entity))
		{
#if defined AllowHide
			SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Neon);
#endif
			AcceptEntityInput(entity, "Kill");
		}
		g_iClientNeon[client] = INVALID_ENT_REFERENCE;
	}
}

void Store_SetClientNeon(int client)
{
	Store_RemoveClientNeon(client);

	int m_iEquipped = Store_GetEquippedItem(client, "neon", 0); 
	if(m_iEquipped < 0) 
		return;

	int m_iData = Store_GetDataIndex(m_iEquipped);

	if(g_eNeons[m_iData][iColor][3] != 0)
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		int iNeon = CreateEntityByName("light_dynamic");
		
		char m_szString[100];
		IntToString(g_eNeons[m_iData][iBright], m_szString, 100);
		DispatchKeyValue(iNeon, "brightness", m_szString);

		Format(m_szString, 100, "%d %d %d %d", g_eNeons[m_iData][iColor][0], g_eNeons[m_iData][iColor][1], g_eNeons[m_iData][iColor][2], g_eNeons[m_iData][iColor][3]);
		DispatchKeyValue(iNeon, "_light", m_szString);
		
		IntToString(g_eNeons[m_iData][iFade], m_szString, 100);
		DispatchKeyValue(iNeon, "spotlight_radius", m_szString);

		IntToString(g_eNeons[m_iData][iDistance], m_szString, 100);
		DispatchKeyValue(iNeon, "distance", m_szString);

		DispatchKeyValue(iNeon, "style", "0");

		SetEntPropEnt(iNeon, Prop_Send, "m_hOwnerEntity", client);

		DispatchSpawn(iNeon);
		AcceptEntityInput(iNeon, "TurnOn");

		TeleportEntity(iNeon, clientOrigin, NULL_VECTOR, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(iNeon, "SetParent", client, iNeon, 0);
		
		g_iClientNeon[client] = EntIndexToEntRef(iNeon);

#if defined AllowHide		
		SDKHook(iNeon, SDKHook_SetTransmit, Hook_SetTransmit_Neon);
#endif
	}
}
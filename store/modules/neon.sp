enum Neon
{
	iColor[4],
	iBright,
	iDistance,
	iFade
}

Neon g_eNeons[STORE_MAX_ITEMS][Neon];
int g_iNeons = 0;
int g_iClientNeon[MAXPLAYERS+1];

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
	g_iClientNeon[client] = 0;
}


public void Neon_Reset()
{
	g_iNeons = 0;
}

public int Neon_Equip(int client, int id)
{
	RequestFrame(NeonEquipDelay, client);
	return 0;
}

public int Neon_Remove(int client) 
{
	Store_RemoveClientNeon(client);
	g_iClientNeon[client] = 0;
	return 0; 
}

public Action Hook_SetTransmit_Neon(int ent, int client)
{
	if(GetEdictFlags(ent) & FL_EDICT_ALWAYS)
		SetEdictFlags(ent, GetEdictFlags(ent) ^ FL_EDICT_ALWAYS & FL_EDICT_DONTSEND);

	return !(g_bHideMode[client]) ? Plugin_Continue : Plugin_Handled;
}

void NeonEquipDelay(int client)
{
	Store_SetClientNeon(client);
}

void Store_RemoveClientNeon(int client)
{
	if(g_iClientNeon[client] != 0)
	{
		if(IsValidEdict(g_iClientNeon[client]))
		{
			SDKUnhook(g_iClientNeon[client], SDKHook_SetTransmit, Hook_SetTransmit_Neon);
			AcceptEntityInput(g_iClientNeon[client], "Kill");
		}

		g_iClientNeon[client] = 0;
	}
}

void Store_SetClientNeon(int client)
{
	if(g_iClientNeon[client] != 0)
		Store_RemoveClientNeon(client);

	if(g_eGameMode == GameMode_Zombie)
		return;

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
		
		g_iClientNeon[client] = iNeon;
		
		SDKHook(iNeon, SDKHook_SetTransmit, Hook_SetTransmit_Neon);
	}
}
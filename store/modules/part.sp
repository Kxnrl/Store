#define Module_Part

int g_iParts = 0; 
int g_iClientPart[MAXPLAYERS+1];
char g_szPartName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szPartClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Part_OnClientDisconnect(int client)
{
	Store_RemoveClientPart(client);
	g_iClientPart[client] = 0;
	g_szPartClient[client] = "";
}

public void Part_Reset() 
{ 
	g_iParts = 0;
}

public int Part_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iParts); 
	KvGetString(kv, "Name", g_szPartName[g_iParts], PLATFORM_MAX_PATH);
	++g_iParts;
	return true;
}

public int Part_Equip(int client, int id)
{
	g_szPartClient[client] = g_szPartName[Store_GetDataIndex(id)];

	Store_SetClientPart(client);

	return 0;
}

public int Part_Remove(int client) 
{
	g_szPartClient[client] = "";
	Store_RemoveClientPart(client);

	return 0; 
}

public void Part_OnMapStart()
{
	PreDownload("particles/FX.pcf");
	PrecacheGeneric("particles/FX.pcf", true);
}

void Store_RemoveClientPart(int client)
{
	if(g_iClientPart[client] != 0)
	{
		if(IsValidEdict(g_iClientPart[client]))
			AcceptEntityInput(g_iClientPart[client], "Kill");

		g_iClientPart[client] = 0;
	}
}

void Store_SetClientPart(int client)
{
	if(g_iClientPart[client] != 0)
		Store_RemoveClientPart(client);

	if(!(strcmp(g_szPartClient[client], "", false) == 0))
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		g_iClientPart[client] = CreateEntityByName("info_particle_system");
		
		DispatchKeyValue(g_iClientPart[client], "start_active", "1");
		DispatchKeyValue(g_iClientPart[client], "effect_name", g_szPartClient[client]);
		DispatchSpawn(g_iClientPart[client]);
		
		TeleportEntity(g_iClientPart[client], clientOrigin, NULL_VECTOR,NULL_VECTOR);
		
		ActivateEntity(g_iClientPart[client]);
		
		SetVariantString("!activator");
		AcceptEntityInput(g_iClientPart[client], "SetParent", client, g_iClientPart[client], 0);
	}
}
#define Module_Aura

int g_iAuras = 0; 
int g_iClientAura[MAXPLAYERS+1];
char g_szAuraName[STORE_MAX_ITEMS][PLATFORM_MAX_PATH];  
char g_szAuraClient[MAXPLAYERS+1][PLATFORM_MAX_PATH];

public void Aura_OnMapStart()
{
	//PreDownload("materials/ex/gl.vmt");
	//PreDownload("materials/ex/gl.vtf");
	//PreDownload("materials/ex/ballX.vmt");
	//PreDownload("materials/ex/ES.vmt");
	//PreDownload("materials/ex/ballX.vtf");
	//PreDownload("materials/ex/ES.vtf");
	PreDownload("particles/FX.pcf");
	PrecacheGeneric("particles/FX.pcf", true);
	//PrecacheModel("materials/ex/ballX.vmt");
	//PrecacheModel("materials/ex/ES.vmt");
	//PrecacheModel("materials/ex/gl.vmt");
}

void PreDownload(const char[] path)
{
	if(FileExists(path))
	{
		AddFileToDownloadsTable(path);
	}
}

public void Aura_OnClientDisconnect(int client)
{
	Store_RemoveClientAura(client);
	g_iClientAura[client] = 0;
	g_szAuraClient[client] = "";
}

public int Aura_Config(Handle &kv, int itemid) 
{ 
	Store_SetDataIndex(itemid, g_iAuras); 
	KvGetString(kv, "Name", g_szAuraName[g_iAuras], PLATFORM_MAX_PATH);
	++g_iAuras;
	if(!FileExists("particles/FX.pcf"))
		return false;

	return true; 
}

public void Aura_Reset() 
{ 
	g_iAuras = 0; 
}

public int Aura_Equip(int client, int id) 
{
	g_szAuraClient[client] = g_szAuraName[Store_GetDataIndex(id)];

	Store_SetClientAura(client);

	return 0; 
}

public int Aura_Remove(int client) 
{
	g_szAuraClient[client] = "";
	Store_RemoveClientAura(client);

	return 0; 
}

void Store_RemoveClientAura(int client)
{
	if(g_iClientAura[client] != 0)
	{
		if(IsValidEdict(g_iClientAura[client]))
		{
			AcceptEntityInput(g_iClientAura[client], "Kill");
		}
		g_iClientAura[client] = 0;
	}
}

void Store_SetClientAura(int client)
{
	if(g_iClientAura[client] != 0)
		Store_RemoveClientAura(client);

	if(!(strcmp(g_szAuraClient[client], "", false) == 0))
	{
		float clientOrigin[3];
		GetClientAbsOrigin(client, clientOrigin);

		g_iClientAura[client] = CreateEntityByName("info_particle_system");
		
		DispatchKeyValue(g_iClientAura[client] , "start_active", "1");
		DispatchKeyValue(g_iClientAura[client] , "effect_name", g_szAuraClient[client]);
		DispatchSpawn(g_iClientAura[client]);
		
		TeleportEntity(g_iClientAura[client], clientOrigin, NULL_VECTOR, NULL_VECTOR);
		
		ActivateEntity(g_iClientAura[client]);

		SetVariantString("!activator");
		
		AcceptEntityInput(g_iClientAura[client], "SetParent", client, g_iClientAura[client], 0);
	}
}
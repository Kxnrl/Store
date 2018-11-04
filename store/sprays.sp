#define Module_Spray

static char g_szSprays[STORE_MAX_ITEMS][256];
static int g_iSprayPrecache[STORE_MAX_ITEMS] = {-1,...};
static int g_iSprayCache[MAXPLAYERS+1] = {-1,...};
static int g_iSprayLimit[MAXPLAYERS+1] = {0,...};
static int g_iSprays = 0;
static int g_iCGLOGO = -1;

public void Sprays_OnPluginStart()
{
    Store_RegisterHandler("spray", Sprays_OnMapStart, Sprays_Reset, Sprays_Config, Sprays_Equip, Sprays_Remove, true);
    
    RegConsoleCmd("spray", Command_Spray);
    RegConsoleCmd("sprays", Command_Spray);
}

public void Sprays_OnMapStart()
{
    char m_szDecal[256];

    for(int i = 0; i < g_iSprays; ++i)
    {
        if(FileExists(g_szSprays[i], true))
        {
            strcopy(STRING(m_szDecal), g_szSprays[i][10]);
            m_szDecal[strlen(m_szDecal)-4]=0;

            g_iSprayPrecache[i] = PrecacheDecal(m_szDecal, true);
            Downloader_AddFileToDownloadsTable(g_szSprays[i]);
        }
    }
}

public void Sprays_OnClientConnected(int client)
{
    g_iSprayCache[client] = -1;
}

public void Spray_OnClientDeath(int client)
{
    g_iSprayLimit[client] = -1;
}

public Action Command_Spray(int client, int args)
{
    if(g_iSprayCache[client] == -1)
    {
        if(g_iCGLOGO != -1)
            tPrintToChat(client, "%T", "spray auto equip", client);
        else
            tPrintToChat(client, "%T", "spray no equip", client);
        
        g_iSprayCache[client] = g_iCGLOGO;
        
        return Plugin_Handled;
    }
    
    if(g_iSprayLimit[client] > GetTime())
    {
        tPrintToChat(client, "%T", "spray cooldown", client);
        return Plugin_Handled;
    }
    
    Sprays_Create(client);
    
    return Plugin_Handled;
}

public int Sprays_Reset()
{
    g_iSprays = 0;
    g_iCGLOGO = -1;
}

public bool Sprays_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iSprays);
    KvGetString(kv, "material", g_szSprays[g_iSprays], 256);

    if(FileExists(g_szSprays[g_iSprays], true))
    {
        if(StrContains(g_szSprays[g_iSprays], "cglogo2", false) != -1)
            g_iCGLOGO = g_iSprays;

        ++g_iSprays;
        return true;
    }

    return false;
}

public int Sprays_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    g_iSprayCache[client] = m_iData;
    return 0;
}

public int Sprays_Remove(int client)
{
    g_iSprayCache[client]=-1;
    return 0;
}

void Sprays_Create(int client)
{
    if(!IsPlayerAlive(client))
        return;

    float m_flEye[3];
    GetClientEyePosition(client, m_flEye);

    float m_flView[3];
    GetPlayerEyeViewPoint(client, m_flView);
    
    float distance = GetVectorDistance(m_flEye, m_flView);

    if(distance > 115.0)
    {
        tPrintToChat(client, "%T", "spray distance", client);
        return;    
    }

    g_iSprayLimit[client] = GetTime()+30;

    TE_Start("World Decal");
    TE_WriteVector("m_vecOrigin",m_flView);
    TE_WriteNum("m_nIndex", g_iSprayPrecache[g_iSprayCache[client]]);
    TE_SendToAll();
}

void GetPlayerEyeViewPoint(int client, float m_fPosition[3])
{
    float m_flRotation[3];
    float m_flPosition[3];

    GetClientEyeAngles(client, m_flRotation);
    GetClientEyePosition(client, m_flPosition);

    TR_TraceRayFilter(m_flPosition, m_flRotation, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client);
    TR_GetEndPosition(m_fPosition);
}

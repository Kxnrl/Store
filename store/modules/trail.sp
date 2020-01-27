#define Module_Trail

enum Trail
{
    String:szMaterial[PLATFORM_MAX_PATH],
    iSlot
}

static any g_eTrails[STORE_MAX_ITEMS][Trail];

static int g_iTrails = 0;
static int g_iClientTrails[MAXPLAYERS+1][STORE_MAX_SLOTS];

public bool Trails_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iTrails);
    
    kv.GetString("material", g_eTrails[g_iTrails][szMaterial], PLATFORM_MAX_PATH);
    g_eTrails[g_iTrails][iSlot] = kv.GetNum("slot");

    if(FileExists(g_eTrails[g_iTrails][szMaterial], true))
    {
        ++g_iTrails;
        return true;
    }

    return false;
}

public void Trails_OnMapStart()
{
    for(int a = 0; a <= MaxClients; ++a)
        for(int b = 0; b < STORE_MAX_SLOTS; ++b)
            g_iClientTrails[a][b] = INVALID_ENT_REFERENCE;

    for(int i = 0; i < g_iTrails; ++i)
        Downloader_AddFileToDownloadsTable(g_eTrails[i][szMaterial]);
}

public void Trails_Reset()
{
    g_iTrails = 0;
}

public int Trails_Equip(int client, int id)
{
    if(IsPlayerAlive(client))
        Store_SetClientTrail(client);

    return g_eTrails[Store_GetDataIndex(id)][iSlot];
}

public int Trails_Remove(int client, int id)
{
    Store_SetClientTrail(client);

    return  g_eTrails[Store_GetDataIndex(id)][iSlot];
}

void Store_RemoveClientTrail(int client, int slot)
{
    if(g_iClientTrails[client][slot] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientTrails[client][slot]);
        if(entity > 0 && IsValidEdict(entity))
        {
            AcceptEntityInput(entity, "Kill");
        }
    }

    g_iClientTrails[client][slot] = INVALID_ENT_REFERENCE;
}

void Trails_OnClientDisconnect(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        Store_RemoveClientTrail(client, i);
}

void Store_SetClientTrail(int client)
{
    RequestFrame(Store_PreSetTrail, client);
}

public void Store_PreSetTrail(int client)
{
    if(!IsClientInGame(client))
        return;

    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        Store_RemoveClientTrail(client, i);
        CreateTrail(client, -1, i);
    }
}

void CreateTrail(int client, int itemid = -1, int slot = 0)
{
    int m_iEquipped = (itemid == -1) ? Store_GetEquippedItem(client, "trail", slot) : itemid;

    if(m_iEquipped < 0)
        return;
    
    int m_iData = Store_GetDataIndex(m_iEquipped);
    
    int m_aEquipped[STORE_MAX_SLOTS] = {-1,...};
    int m_iNumEquipped = 0;

    int m_iCurrent;

    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        if((m_aEquipped[m_iNumEquipped] = Store_GetEquippedItem(client, "trail", i)) >= 0)
        {
            if(i == g_eTrails[m_iData][iSlot])
                m_iCurrent = m_iNumEquipped;
            ++m_iNumEquipped;
        }
    }
    
    int entity = g_iClientTrails[client][slot] == INVALID_ENT_REFERENCE ? -1 : EntRefToEntIndex( g_iClientTrails[client][slot]);

    if(IsValidEdict(entity))
        return;

    entity = CreateEntityByName("env_spritetrail");
    DispatchKeyValue(entity, "classname", "env_spritetrail");
    DispatchKeyValue(entity, "renderamt", "255");
    DispatchKeyValue(entity, "rendercolor", "255 255 255");
    DispatchKeyValue(entity, "lifetime", "1.0");
    DispatchKeyValue(entity, "rendermode", "5");
    DispatchKeyValue(entity, "spritename", g_eTrails[m_iData][szMaterial]);
    DispatchKeyValue(entity, "startwidth", "10.0");
    DispatchKeyValue(entity, "endwidth", "10.0");
    SetEntPropFloat(entity, Prop_Send, "m_flTextureRes", 0.05);
    DispatchSpawn(entity);
    AttachTrail(entity, client, m_iCurrent, m_iNumEquipped);    

    g_iClientTrails[client][slot] = EntIndexToEntRef(entity);

    Call_OnTrailsCreated(client, entity, slot);
}

void AttachTrail(int ent, int client, int current, int num)
{
    float m_fOrigin[3];
    float m_fAngle[3];
    float m_fTemp[3] = {0.0, 90.0, 0.0};
    GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
    SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
    float m_fX = (30.0*((num-1)%3))/2-(30.0*(current%3));
    float m_fPosition[3];
    m_fPosition[0] = m_fX;
    m_fPosition[1] = 0.0;
    m_fPosition[2]= 5.0+(current/3)*30.0;
    GetClientAbsOrigin(client, m_fOrigin);
    AddVectors(m_fOrigin, m_fPosition, m_fOrigin);
    TeleportEntity(ent, m_fOrigin, m_fTemp, NULL_VECTOR);
    SetVariantString("!activator");
    AcceptEntityInput(ent, "SetParent", client, ent);
    SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
    
    SetVariantString("OnUser1 !self:SetScale:1:0.5:-1");
    AcceptEntityInput(ent, "AddOutput");
    AcceptEntityInput(ent, "FireUser1");
}

stock void Call_OnTrailsCreated(int client, int entity, int slot)
{
    static Handle gf = null;
    if (gf == null)
    {
        // create
        gf = CreateGlobalForward("Store_OnTrailsCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_PushCell(slot);
    Call_Finish();
}

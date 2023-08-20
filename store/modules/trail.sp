// MAIN_FILE ../../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Trail

abstract_struct Trail
{
    char szMaterial[PLATFORM_MAX_PATH];
    int  iSlot;
}

static Trail g_eTrails[STORE_MAX_ITEMS];

static int g_iTrails = 0;
static int g_iClientTrails[MAXPLAYERS + 1][STORE_MAX_SLOTS];

bool Trails_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iTrails);

    kv.GetString("material", g_eTrails[g_iTrails].szMaterial, PLATFORM_MAX_PATH);
    g_eTrails[g_iTrails].iSlot = kv.GetNum("slot");

    if (FileExists(g_eTrails[g_iTrails].szMaterial, true))
    {
        ++g_iTrails;
        return true;
    }

#if defined LOG_NOT_FOUND
    // missing model
    char auth[32], name[32];
    kv.GetString("auth", auth, 32);
    kv.GetString("name", name, 32);
    if (strcmp(auth, "STEAM_ID_INVALID") != 0)
    {
        LogError("Missing trail <%s> -> [%s]", name, g_eTrails[g_iTrails].szMaterial);
    }
    else
    {
        LogMessage("Skipped trail <%s> -> [%s]", name, g_eTrails[g_iTrails].szMaterial);
    }
#endif

    return false;
}

void Trails_OnMapStart()
{
    for (int a = 0; a <= MaxClients; ++a)
        for (int b = 0; b < STORE_MAX_SLOTS; ++b)
            g_iClientTrails[a][b] = INVALID_ENT_REFERENCE;

    for (int i = 0; i < g_iTrails; ++i)
    {
        if (PrecacheModel(g_eTrails[i].szMaterial) > 0)
        {
            AddFileToDownloadsTable(g_eTrails[i].szMaterial);
        }
    }
}

void Trails_Reset()
{
    g_iTrails = 0;
}

int Trails_Equip(int client, int id)
{
    if (IsPlayerAlive(client))
        Trails_SetClientTrail(client);

    return g_eTrails[Store_GetDataIndex(id)].iSlot;
}

int Trails_Remove(int client, int id)
{
    Trails_SetClientTrail(client);

    return g_eTrails[Store_GetDataIndex(id)].iSlot;
}

void Trails_RemoveClientTrail(int client, int slot)
{
    if (g_iClientTrails[client][slot] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientTrails[client][slot]);
        if (entity > MaxClients)
        {
            RemoveEntity(entity);
        }
    }

    g_iClientTrails[client][slot] = INVALID_ENT_REFERENCE;
}

void Trails_OnClientDisconnect(int client)
{
    for (int i = 0; i < STORE_MAX_SLOTS; ++i)
        Trails_RemoveClientTrail(client, i);
}

void Trails_SetClientTrail(int client)
{
    RequestFrame(PreSetTrail, client);
}

static void PreSetTrail(int client)
{
    if (!IsClientInGame(client) || !IsPlayerAlive(client))
        return;

    for (int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        Trails_RemoveClientTrail(client, i);
        CreateTrail(client, -1, i);
    }
}

static void CreateTrail(int client, int itemid = -1, int slot = 0)
{
#if defined GM_ZE
    if (GetClientTeam(client) == TEAM_ZM)
        return;
#endif

    int m_iEquipped = (itemid == -1) ? Store_GetEquippedItem(client, "trail", slot) : itemid;

    if (m_iEquipped < 0)
        return;

    int m_iData = Store_GetDataIndex(m_iEquipped);

    int m_aEquipped[STORE_MAX_SLOTS] = { -1, ... };
    int m_iNumEquipped               = 0;

    int m_iCurrent;

    for (int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        if ((m_aEquipped[m_iNumEquipped] = Store_GetEquippedItem(client, "trail", i)) >= 0)
        {
            if (i == g_eTrails[m_iData].iSlot)
                m_iCurrent = m_iNumEquipped;
            ++m_iNumEquipped;
        }
    }

    int entity = g_iClientTrails[client][slot] == INVALID_ENT_REFERENCE ? -1 : EntRefToEntIndex(g_iClientTrails[client][slot]);

    if (entity > MaxClients)
        return;

    entity = CreateEntityByName("env_spritetrail");
    DispatchKeyValue(entity, "targetname", "store_item_trail");
    DispatchKeyValue(entity, "renderamt", "255");
    DispatchKeyValue(entity, "rendercolor", "255 255 255");
    DispatchKeyValue(entity, "lifetime", "1.0");
    DispatchKeyValue(entity, "rendermode", "5");
    DispatchKeyValue(entity, "spritename", g_eTrails[m_iData].szMaterial);
    DispatchKeyValue(entity, "startwidth", "10.0");
    DispatchKeyValue(entity, "endwidth", "10.0");
    SetEntPropFloat(entity, Prop_Send, "m_flTextureRes", 0.05);
    DispatchSpawn(entity);
    AttachTrail(entity, client, m_iCurrent, m_iNumEquipped);

    g_iClientTrails[client][slot] = EntIndexToEntRef(entity);

    Call_OnTrailsCreated(client, entity, slot);
}

static void AttachTrail(int ent, int client, int current, int num)
{
    float m_fOrigin[3];
    float m_fAngle[3];
    float m_fTemp[3] = { 0.0, 90.0, 0.0 };
    GetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fAngle);
    SetEntPropVector(client, Prop_Data, "m_angAbsRotation", m_fTemp);
    float m_fX = (30.0 * ((num - 1) % 3)) / 2 - (30.0 * (current % 3));
    float m_fPosition[3];
    m_fPosition[0] = m_fX;
    m_fPosition[1] = 0.0;
    m_fPosition[2] = 0.5 + (current / 3) * 30.0;
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
    static GlobalForward gf = null;
    if (gf == null)
    {
        // create
        gf = new GlobalForward("Store_OnTrailsCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_PushCell(slot);
    Call_Finish();
}

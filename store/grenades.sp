// MAIN_FILE ../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Grenade

abstract_struct GrenadeSkin
{
    char szModel[PLATFORM_MAX_PATH];
    char szWeapon[64];
    int  iLength;
    int  iSlot;
}

abstract_struct GrenadeTrail
{
    char  szMaterial[PLATFORM_MAX_PATH];
    char  szWidth[16];
    char  szColor[16];
    float fWidth;
    int   iColor[4];
    int   iSlot;
    int   iCacheID;
}

static GrenadeSkin  g_eGrenadeSkins[STORE_MAX_ITEMS];
static GrenadeTrail g_eGrenadeTrails[STORE_MAX_ITEMS];
static int          g_iGrenadeSkins  = 0;
static int          g_iSlots         = 0;
static int          g_iGrenadeTrails = 0;
static char         g_szSlots[6][64];

void Grenades_OnPluginStart()
{
    Store_RegisterHandler("nadetrail", GrenadeTrails_OnMapStart, GrenadeTrails_Reset, GrenadeTrails_Config, GrenadeTrails_Equip, GrenadeTrails_Remove, true);
    Store_RegisterHandler("nadeskin", GrenadeSkins_OnMapStart, GrenadeSkins_Reset, GrenadeSkins_Config, GrenadeSkins_Equip, GrenadeSkins_Remove, true);
}

static void GrenadeSkins_OnMapStart()
{
    for (int i = 0; i < g_iGrenadeSkins; ++i)
    {
        PrecacheModel(g_eGrenadeSkins[i].szModel, false);
        AddFileToDownloadsTable(g_eGrenadeSkins[i].szModel);
    }
}

static void GrenadeTrails_OnMapStart()
{
    for (int i = 0; i < g_iGrenadeTrails; ++i)
    {
        g_eGrenadeTrails[i].iCacheID = PrecacheModel(g_eGrenadeTrails[i].szMaterial, false);
        AddFileToDownloadsTable(g_eGrenadeTrails[i].szMaterial);
    }
}

static void GrenadeSkins_Reset()
{
    g_iGrenadeSkins = 0;
}

static void GrenadeTrails_Reset()
{
    g_iGrenadeTrails = 0;
}

static bool GrenadeSkins_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iGrenadeSkins);
    kv.GetString("model", g_eGrenadeSkins[g_iGrenadeSkins].szModel, PLATFORM_MAX_PATH);
    kv.GetString("grenade", g_eGrenadeSkins[g_iGrenadeSkins].szWeapon, PLATFORM_MAX_PATH);

    g_eGrenadeSkins[g_iGrenadeSkins].iSlot   = GrenadeSkins_GetSlot(g_eGrenadeSkins[g_iGrenadeSkins].szWeapon);
    g_eGrenadeSkins[g_iGrenadeSkins].iLength = strlen(g_eGrenadeSkins[g_iGrenadeSkins].szWeapon);

    if (!(FileExists(g_eGrenadeSkins[g_iGrenadeSkins].szModel, true)))
        return false;

    ++g_iGrenadeSkins;
    return true;
}

static bool GrenadeTrails_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iGrenadeTrails);
    kv.GetString("material", g_eGrenadeTrails[g_iGrenadeTrails].szMaterial, PLATFORM_MAX_PATH, "materials/sprites/laserbeam.vmt");
    kv.GetString("width", g_eGrenadeTrails[g_iGrenadeTrails].szWidth, sizeof(GrenadeTrail::szWidth), "10.0");
    g_eGrenadeTrails[g_iGrenadeTrails].fWidth = kv.GetFloat("width", 10.0);
    kv.GetString("color", g_eGrenadeTrails[g_iGrenadeTrails].szColor, sizeof(GrenadeTrail::szColor), "255 255 255 255");
    kv.GetColor("color", g_eGrenadeTrails[g_iGrenadeTrails].iColor[0], g_eGrenadeTrails[g_iGrenadeTrails].iColor[1], g_eGrenadeTrails[g_iGrenadeTrails].iColor[2], g_eGrenadeTrails[g_iGrenadeTrails].iColor[3]);
    g_eGrenadeTrails[g_iGrenadeTrails].iSlot = kv.GetNum("slot");

    if (FileExists(g_eGrenadeTrails[g_iGrenadeTrails].szMaterial, true))
    {
        ++g_iGrenadeTrails;
        return true;
    }

    return false;
}

static int GrenadeSkins_Equip(int client, int id)
{
    return g_eGrenadeSkins[Store_GetDataIndex(id)].iSlot;
}

static int GrenadeTrails_Equip(int client, int id)
{
    return 0;
}

static int GrenadeSkins_Remove(int client, int id)
{
    return g_eGrenadeSkins[Store_GetDataIndex(id)].iSlot;
}

static int GrenadeTrails_Remove(int client, int id)
{
    return 0;
}

static int GrenadeSkins_GetSlot(char[] weapon)
{
    for (int i = 0; i < g_iSlots; ++i)
        if (strcmp(weapon, g_szSlots[i]) == 0)
            return i;

    strcopy(g_szSlots[g_iSlots], sizeof(g_szSlots[]), weapon);
    return g_iSlots++;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (g_iGrenadeTrails == 0 && g_iGrenadeSkins == 0)
        return;

    if (StrContains(classname, "_projectile") > 0)
        SDKHook(entity, SDKHook_SpawnPost, Grenades_OnEntitySpawned);
}

static void Grenades_OnEntitySpawned(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, Grenades_OnEntitySpawned);

    RequestFrame(Grenades_OnEntitySpawnedPost, EntIndexToEntRef(entity));
}

static void Grenades_OnEntitySpawnedPost(int ref)
{
    int entity = EntRefToEntIndex(ref);
    if (entity < MaxClients)
        return;

    int client = GetEntPropEnt(entity, Prop_Send, "m_hThrower");
    if (client == -1)
        return;

    char m_szClassname[64];
    GetEdictClassname(entity, STRING(m_szClassname));

    int char = FindCharInString(m_szClassname, '_');
    if (char == -1)
        return;

    m_szClassname[char] = 0;

    OnGrenadeModel(client, entity, m_szClassname);

    OnGrenadeTrail(client, entity, m_szClassname);
}

static void OnGrenadeModel(int client, int entity, const char[] classname)
{
    int m_iSlot     = GrenadeSkins_GetSlot(classname);
    int m_iEquipped = Store_GetEquippedItem(client, "nadeskin", m_iSlot);

    if (m_iEquipped >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquipped);
        SetEntityModel(entity, g_eGrenadeSkins[m_iData].szModel);
    }
}

static void OnGrenadeTrail(int client, int entity, const char[] classname)
{
    int m_iEquipped = Store_GetEquippedItem(client, "nadetrail", 0);
    if (m_iEquipped >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquipped);

        // Ugh...
        int m_iColor[4];
        m_iColor[0] = g_eGrenadeTrails[m_iData].iColor[0];
        m_iColor[1] = g_eGrenadeTrails[m_iData].iColor[1];
        m_iColor[2] = g_eGrenadeTrails[m_iData].iColor[2];
        m_iColor[3] = g_eGrenadeTrails[m_iData].iColor[3];
        TE_SetupBeamFollow(entity, g_eGrenadeTrails[m_iData].iCacheID, 0, 2.0, g_eGrenadeTrails[m_iData].fWidth, g_eGrenadeTrails[m_iData].fWidth, 10, m_iColor);
        TE_SendToAll();
    }
}
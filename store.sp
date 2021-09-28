#pragma semicolon 1
#pragma newdecls required

//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Store - The Resurrection"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "a sourcemod store system"
#define PLUGIN_VERSION      "2.4.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};


//////////////////////////////
//          INCLUDES        //
//////////////////////////////
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <store>
#include <store_stock>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <clientprefs>
#include <fys.opts>
#include <fys.pupd>
#define REQUIRE_EXTENSIONS
#define REQUIRE_PLUGIN

//////////////////////////////
//        DEFINITIONS       //
//////////////////////////////

// Server
#define GM_EF // <Compile_Environment>
//GM_TT -> ttt server
//GM_ZE -> zombie escape server
//GM_MG -> mini games server
//GM_JB -> jail break server
//GM_KZ -> kreedz server
//GM_HZ -> casual server
//GM_PR -> pure|competitive server
//GM_HG -> hunger game server
//GM_SR -> death surf server
//GM_BH -> bhop server
//GM_IS -> insurgency
//GM_EF -> left 4 dead(2)

// VERIFY CREDITS
//#define DATA_VERIFY

// [CT] [TE] tag in player skin title -> enabled by default
#define Skin_TeamTag

// Custom Module
// skin does not match with team
#if defined GM_TT || defined GM_ZE || defined GM_KZ || defined GM_BH || defined GM_SR || defined GM_JB
#define Global_Skin
#undef Skin_TeamTag
#endif
//fix arms when client team
#if defined GM_MG
#define TeamArms
#endif
// death chat
#if defined GM_ZE || defined GM_JB || defined GM_MG || defined GM_KZ || defined GM_SR || defined GM_BH
#define DeathChat
#endif

#define MAX_SKIN_LEVEL 6

//////////////////////////////
//     GLOBAL VARIABLES     //
//////////////////////////////
Database g_hDatabase = null;
Handle g_hOnStoreAvailable = null;
Handle g_hOnStoreInit = null;
Handle g_hOnClientLoaded = null;
Handle g_hOnClientBuyItem = null;
Handle g_hOnClientPurchased = null;
Handle g_hOnClientComposed = null;
Handle g_hOnClientComposing = null;
Handle g_hOnGiveClientItem = null;

ArrayList g_aCaseSkins[3];
StringMap g_smParentMap = null;

Store_Item g_Items[STORE_MAX_ITEMS];
Client_Data g_ClientData[MAXPLAYERS+1];
Client_Item g_ClientItem[MAXPLAYERS+1][STORE_MAX_ITEMS];
Type_Handler g_TypeHandlers[STORE_MAX_HANDLERS];
Menu_Handler g_MenuHandlers[STORE_MAX_HANDLERS];
Item_Plan g_PurchasePlan[STORE_MAX_ITEMS][STORE_MAX_PLANS];
Compose_Data g_Compose[MAXPLAYERS+1];

int g_iItems = 0;
int g_iTypeHandlers = 0;
int g_iMenuHandlers = 0;
int g_iPackageHandler = -1;

int g_iClientCase[MAXPLAYERS+1];
int g_iMenuBack[MAXPLAYERS+1];
int g_iLastSelection[MAXPLAYERS+1];
int g_iSelectedItem[MAXPLAYERS+1];
int g_iSelectedPlan[MAXPLAYERS+1];
int g_iMenuNum[MAXPLAYERS+1];
int g_iSpam[MAXPLAYERS+1];
int g_iDataProtect[MAXPLAYERS+1];
int g_iClientTeam[MAXPLAYERS+1];

bool g_bInvMode[MAXPLAYERS+1];

bool g_bLateLoad;

bool g_bInterMission;

// library
bool g_pClientprefs;
bool g_pfysOptions;

// Case Options
static int   g_inCase[4] = {999999, 3888, 8888, 23888};
static char  g_szCase[4][32] = {"", "Normal Case", "Advanced Case", "Ultima Case"};
static float g_fCreditsTimerInterval = 0.0;
static int   g_iCreditsTimerOnline = 2;
static char  g_szComposeFee[][] = {"5888", "9888", "15888", "21888", "29888", "38888"};


//////////////////////////////
//         MODULES          //
//////////////////////////////
// Module Global Module
#include "store/cpsupport.sp"
#include "store/tpmode.sp" // Module TP

// Module Hats
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_BH
#include "store/modules/hats.sp"
#endif
// Module Skin
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/skin.sp"
#endif
// Module Neon
#if defined GM_TT || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/neon.sp"
#endif
// Module Aura & Part
#if defined GM_TT || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH || defined GM_ZE
#include "store/modules/aura.sp"
#include "store/modules/part.sp"
#endif
// Module Trail
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/trail.sp"
#endif
// Module PLAYERS
#if defined Module_Hats || defined Module_Skin || defined Module_Neon || defined Module_Aura || defined Module_Part || defined Module_Trail
#include "store/players.sp"
#endif
// Module Grenade
#if defined GM_TT || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG
#include "store/grenades.sp"
#endif
// Module Spray
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH || defined GM_IS || defined GM_EF
#include "store/sprays.sp"
#endif
// Module Sound
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH || defined GM_IS || defined GM_EF
#include "store/sounds.sp"
#endif


//////////////////////////////
//     PLUGIN UPDATER       //
//////////////////////////////
public void Pupd_OnCheckAllPlugins()
{
#if defined GM_TT
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/TT/");
#endif

#if defined GM_ZE
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/ZE/");
#endif

#if defined GM_MG
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/MG/");
#endif

#if defined GM_JB
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/JB/");
#endif

#if defined GM_KZ
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/KZ/");
#endif

#if defined GM_HZ
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/HZ/");
#endif

#if defined GM_PR
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/PR/");
#endif

#if defined GM_HG
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/HG/");
#endif

#if defined GM_SR
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/SR/");
#endif

#if defined GM_BH
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/BH/");
#endif

#if defined GM_IS
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/IS/");
#endif

#if defined GM_EF
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/EF/");
#endif

    Pupd_CheckTranslation("store.phrases.txt", "https://build.kxnrl.com/updater/Store/translation/");
}

//////////////////////////////
//     PLUGIN FORWARDS      //
//////////////////////////////
public void OnPluginStart()
{
    EngineVersion engine = GetEngineVersion();
    #if defined GM_IS
    if (engine != Engine_Insurgency)
        SetFailState("Current game is not be supported! Insurgency only!");
    #elseif defined GM_EF
    if(!(engine == Engine_Left4Dead || engine == Engine_Left4Dead2))
        SetFailState("Current game is not be supported! Left 4 Dead(2) only!");
    #else
    // Check Engine
    if (engine != Engine_CSGO)
        SetFailState("Current game is not be supported! CSGO only!");
    #endif

    if(g_smParentMap == null)
        g_smParentMap = new StringMap();

    // Setting default values
    for(int client = 1; client <= MaxClients; ++client)
    {
        g_ClientData[client].iCredits            = 0;
        g_ClientData[client].iOriginalCredits    = 0;
        g_ClientData[client].iItems              = 0;
    }

    // Register Commands
    RegConsoleCmd("sm_store",       Command_Store);
    RegConsoleCmd("buyammo1",       Command_Store);
    RegConsoleCmd("sm_shop",        Command_Store);
    RegConsoleCmd("sm_inv",         Command_Inventory);
    RegConsoleCmd("sm_inventory",   Command_Inventory);
    RegConsoleCmd("sm_credits",     Command_Credits);
    RegConsoleCmd("sm_case",        Command_Case);
    RegConsoleCmd("sm_opencase",    Command_Case);

    HookEvent("round_start",        OnRoundStart,   EventHookMode_Post);
    HookEvent("player_death",       OnPlayerDeath,  EventHookMode_Post);

    // Prevent Server freezing by SQL databsae?
    if (engine == Engine_CSGO)
        HookEvent("cs_win_panel_match", OnGameOver, EventHookMode_Post);
    else if (engine == Engine_Insurgency)
        HookEvent("game_end", OnGameOver, EventHookMode_Post);

    // Load the translations file
    LoadTranslations("store.phrases");

    // Connect to the database
    Database.Connect(SQLCallback_Connection, "csgo", 0);

    for(int x = 0; x < 3; ++x) g_aCaseSkins[x] = new ArrayList(ByteCountToCells(256));

    ConVar mp_match_restart_delay = FindConVar("mp_match_restart_delay");
    if(mp_match_restart_delay != null)
    {
        // 30 sec to exec sql command.
        mp_match_restart_delay.SetFloat(20.0, true, true);
        mp_match_restart_delay.AddChangeHook(InterMissionLock);
    }
}

public void OnAllPluginsLoaded()
{
    g_pClientprefs = LibraryExists("clientprefs");
    g_pfysOptions = LibraryExists("fys-Opts");

    if(g_pClientprefs)
    {
#if defined Module_Sound
        Sounds_OnClientprefs();
#endif
    }

    if(g_pfysOptions)
    {

    }
}

public void OnPluginEnd()
{
    for(int client = 1; client <= MaxClients; ++client)
    if(IsClientInGame(client))
    if(g_ClientData[client].bLoaded)
        OnClientDisconnect(client);
}

public void OnLibraryAdded(const char[] name)
{
    if(strcmp(name, "clientprefs") == 0)
    {
        g_pClientprefs = true;

#if defined Module_Sound
        Sounds_OnClientprefs();
#endif
    }

    if(strcmp(name, "fys-Opts") == 0)
        g_pfysOptions = true;
}

public void OnLibraryRemoved(const char[] name)
{
    if(strcmp(name, "clientprefs") == 0)
    {
        g_pClientprefs = false;

#if defined Module_Sound
        Sounds_OnClientprefs();
#endif
    }

    if(strcmp(name, "fys-Opts") == 0)
        g_pfysOptions = false;
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_hOnStoreAvailable  = CreateGlobalForward("Store_OnStoreAvailable",  ET_Ignore, Param_Cell);
    g_hOnStoreInit       = CreateGlobalForward("Store_OnStoreInit",       ET_Ignore, Param_Cell);
    g_hOnClientLoaded    = CreateGlobalForward("Store_OnClientLoaded",    ET_Ignore, Param_Cell);
    g_hOnClientBuyItem   = CreateGlobalForward("Store_OnClientBuyItem",   ET_Event,  Param_Cell, Param_String,    Param_Cell, Param_Cell);
    g_hOnClientPurchased = CreateGlobalForward("Store_OnClientPurchased", ET_Ignore, Param_Cell, Param_String,    Param_Cell, Param_Cell);
    g_hOnClientComposing = CreateGlobalForward("Store_OnClientComposing", ET_Hook,   Param_Cell, Param_CellByRef, Param_Cell, Param_String, Param_String, Param_String);
    g_hOnClientComposed  = CreateGlobalForward("Store_OnClientComposed",  ET_Ignore, Param_Cell, Param_Cell,      Param_Cell, Param_String, Param_String);
    g_hOnGiveClientItem  = CreateGlobalForward("Store_OnGiveClientItem",  ET_Hook,   Param_Cell, Param_String,    Param_Cell, Param_Cell,   Param_Cell);

    CreateNative("Store_RegisterHandler",       Native_RegisterHandler);
    CreateNative("Store_RegisterMenuHandler",   Native_RegisterMenuHandler);
    CreateNative("Store_SetDataIndex",          Native_SetDataIndex);
    CreateNative("Store_GetDataIndex",          Native_GetDataIndex);
    CreateNative("Store_GetEquippedItem",       Native_GetEquippedItem);
    CreateNative("Store_IsClientLoaded",        Native_IsClientLoaded);
    CreateNative("Store_DisplayPreviousMenu",   Native_DisplayPreviousMenu);
    CreateNative("Store_SetClientMenu",         Native_SetClientMenu);
    CreateNative("Store_GetClientCredits",      Native_GetClientCredits);
    CreateNative("Store_SetClientCredits",      Native_SetClientCredits);
    CreateNative("Store_IsItemInBoughtPackage", Native_IsItemInBoughtPackage);
    CreateNative("Store_DisplayConfirmMenu",    Native_DisplayConfirmMenu);
    CreateNative("Store_UseItem",               Native_UseItem);
    CreateNative("Store_GiveItem",              Native_GiveItem);
    CreateNative("Store_GetItemId",             Native_GetItemId);
    CreateNative("Store_GetTypeId",             Native_GetTypeId);
    CreateNative("Store_GetItemData",           Native_GetItemData);
    CreateNative("Store_RemoveItem",            Native_RemoveItem);
    CreateNative("Store_HasClientItem",         Native_HasClientItem);
    CreateNative("Store_ExtClientItem",         Native_ExtClientItem);
    CreateNative("Store_GetItemExpiration",     Native_GetItemExpiration);
    CreateNative("Store_SaveClientAll",         Native_SaveClientAll);
    CreateNative("Store_GetClientID",           Native_GetClientID);
    CreateNative("Store_IsClientBanned",        Native_IsClientBanned);
    CreateNative("Store_SetClientBanState",     Native_SetClientBanState);
    CreateNative("Store_HasPlayerSkin",         Native_HasPlayerSkin);
    CreateNative("Store_GetPlayerSkin",         Native_GetPlayerSkin);
    CreateNative("Store_GetClientPlayerSkins",  Native_GetClientPlayerSkins);
    CreateNative("Store_GetAllPlayerSkins",     Native_GetAllPlayerSkins);
    CreateNative("Store_GetSkinLevel",          Native_GetSkinLevel);
    CreateNative("Store_GetItemList",           Native_GetItemList);
    CreateNative("Store_IsPlayerTP",            Native_IsPlayerTP);
    CreateNative("Store_IsPlayerHide",          Native_IsPlayerHide);
    CreateNative("Store_IsStoreSpray",          Native_IsStoreSpray);
    CreateNative("Store_ApplyPlayerSkin",       Native_ApplyPlayerSkin);
    CreateNative("Store_LogOpencase",           Native_LogOpenCase);
    CreateNative("Store_IsInDeathCamera",       Native_InDeathCamera);

    MarkNativeAsOptional("RegClientCookie");
    MarkNativeAsOptional("GetClientCookie");
    MarkNativeAsOptional("SetClientCookie");

    MarkNativeAsOptional("Opts_GetOptBool");
    MarkNativeAsOptional("Opts_SetOptBool");
    MarkNativeAsOptional("Opts_GetOptFloat");

    MarkNativeAsOptional("Pupd_CheckPlugin");
    MarkNativeAsOptional("Pupd_CheckTranslation");

    g_bLateLoad = late;

    // RegLibrary
    RegPluginLibrary("store");

    return APLRes_Success;
}

//////////////////////////////
//  REST OF PLUGIN FORWARD  //
//////////////////////////////
public void OnMapStart()
{
    g_bInterMission = false;
    
    for(int i = 0; i < g_iTypeHandlers; ++i)
    if(g_TypeHandlers[i].fnMapStart != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[i].hPlugin, g_TypeHandlers[i].szPlFile))
    {
        Call_StartFunction(g_TypeHandlers[i].hPlugin, g_TypeHandlers[i].fnMapStart);
        Call_Finish();
    }
}

public void OnMapEnd()
{
#if defined Module_Skin
    PlayerSkins_OnMapEnd();
#endif
}

//////////////////////////////
//         NATIVES          //
//////////////////////////////
public int Native_GetItemId(Handle myself, int numParams)
{
    char uid[256];
    if(GetNativeString(1, STRING(uid)) != SP_ERROR_NONE)
        return -1;

    return UTIL_GetItemId(uid, -1);
}

public int Native_GetTypeId(Handle myself, int numParams)
{
    char type[32];
    if(GetNativeString(1, STRING(type)) != SP_ERROR_NONE)
        return -1;

    return UTIL_GetTypeHandler(type);
}

public int Native_GetItemData(Handle myself, int numParams)
{
    int itemid = GetNativeCell(1);
    if(itemid < 0 || itemid > STORE_MAX_ITEMS)
        ThrowNativeError(SP_ERROR_PARAM, "ItemId [%d] is not allowed.", itemid);
    SetNativeArray(2, g_Items[itemid], sizeof(Store_Item));
    return true;
}

public int Native_SaveClientAll(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    UTIL_SaveClientData(client, false);
    UTIL_SaveClientInventory(client);
    UTIL_SaveClientEquipment(client);
}

public int Native_GetClientID(Handle myself, int numParams)
{
    return g_ClientData[GetNativeCell(1)].iId;
}

public int Native_IsClientBanned(Handle myself, int numParams)
{
    return g_ClientData[GetNativeCell(1)].bBan;
}

public int Native_SetClientBanState(Handle myself, int numParams)
{
    g_ClientData[GetNativeCell(1)].bBan = GetNativeCell(2);
}

public int Native_RegisterHandler(Handle plugin, int numParams)
{
    if(g_iTypeHandlers == STORE_MAX_HANDLERS)
        return -1;

    char m_szType[32];
    GetNativeString(1, STRING(m_szType));
    int m_iHandler = UTIL_GetTypeHandler(m_szType);
    int m_iId = g_iTypeHandlers;
    
    if(m_iHandler != -1)
        return m_iHandler;

    ++g_iTypeHandlers;

    g_TypeHandlers[m_iId].hPlugin = plugin;
    g_TypeHandlers[m_iId].fnMapStart = GetNativeFunction(2);
    g_TypeHandlers[m_iId].fnReset = GetNativeFunction(3);
    g_TypeHandlers[m_iId].fnConfig = GetNativeFunction(4);
    g_TypeHandlers[m_iId].fnUse = GetNativeFunction(5);
    g_TypeHandlers[m_iId].fnRemove = GetNativeFunction(6);
    g_TypeHandlers[m_iId].bEquipable = GetNativeCell(7);
    g_TypeHandlers[m_iId].bRaw = GetNativeCell(8);
    g_TypeHandlers[m_iId].bDisposable = GetNativeCell(9);
    strcopy(g_TypeHandlers[m_iId].szType, sizeof(Type_Handler::szType), m_szType);

    char file[64];
    GetPluginFilename(plugin, STRING(file));
    strcopy(g_TypeHandlers[m_iId].szPlFile, sizeof(Type_Handler::szPlFile), file);

    return m_iId;
}

public int Native_RegisterMenuHandler(Handle plugin, int numParams)
{
    if(g_iMenuHandlers == STORE_MAX_HANDLERS)
        return -1;

    char m_szIdentifier[64];
    GetNativeString(1, STRING(m_szIdentifier));
    int m_iHandler = UTIL_GetMenuHandler(m_szIdentifier);    
    int m_iId = g_iMenuHandlers;
    
    if(m_iHandler != -1)
        return (g_MenuHandlers[m_iId].hPlugin == plugin) ? m_iId : -1; // Unique Plugin
 
    ++g_iMenuHandlers;

    g_MenuHandlers[m_iId].hPlugin = plugin;
    g_MenuHandlers[m_iId].fnMenu = GetNativeFunction(2);
    g_MenuHandlers[m_iId].fnHandler = GetNativeFunction(3);
    strcopy(g_MenuHandlers[m_iId].szIdentifier, sizeof(Menu_Handler::szIdentifier), m_szIdentifier);

    char file[64];
    GetPluginFilename(plugin, STRING(file));
    strcopy(g_MenuHandlers[m_iId].szPlFile, sizeof(Menu_Handler::szPlFile), file);

    return m_iId;
}

public int Native_SetDataIndex(Handle myself, int numParams)
{
    g_Items[GetNativeCell(1)].iData = GetNativeCell(2);
}

public int Native_GetDataIndex(Handle myself, int numParams)
{
    return g_Items[GetNativeCell(1)].iData;
}

public int Native_GetEquippedItem(Handle myself, int numParams)
{
    char m_szType[16];
    GetNativeString(2, STRING(m_szType));
    
    int m_iHandler = UTIL_GetTypeHandler(m_szType);
    if(m_iHandler == -1)
        return -1;

    return UTIL_GetEquippedItemFromHandler(GetNativeCell(1), m_iHandler, GetNativeCell(3));
}

public int Native_IsClientLoaded(Handle myself, int numParams)
{
    return g_ClientData[GetNativeCell(1)].bLoaded;
}

public int Native_DisplayPreviousMenu(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    switch(g_iMenuNum[client])
    {
        case 1: DisplayStoreMenu  (client, g_iMenuBack[client], g_iLastSelection[client]);
        case 2: DisplayItemMenu   (client, g_iSelectedItem[client]);
        case 3: DisplayPlayerMenu (client);
        case 4: DisplayPlanMenu   (client, g_iSelectedItem[client]);
        case 5: DisplayComposeMenu(client, false);
    }
}

public int Native_SetClientMenu(Handle myself, int numParams)
{
    g_iMenuNum[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetClientCredits(Handle myself, int numParams)
{
    int client = GetNativeCell(1);

    if (g_ClientData[client].bBan)
        return 0;

    return g_ClientData[client].iCredits;
}

public int Native_SetClientCredits(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    if(IsFakeClient(client) || !g_ClientData[client].bLoaded || g_ClientData[client].bBan)
        return false;

    int m_iCredits = GetNativeCell(2);
    int difference = m_iCredits-g_ClientData[client].iCredits;
    
    // maybe not needed?
    // if going to intermission, after 3 seconds, we force disconnect client then mark as not load.
    /*
    if(g_bInterMission)
    {
        char path[128];
        BuildPath(Path_SM, STRING(path), "logs/store.warn.log");
        LogToFileEx(path, "Native_SetClientCredits -> %L -> %d -> %d -> %d", client, g_ClientData[client].iId, m_iCredits, difference);
        return false;
    }
    */

    if (numParams < 3)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Reason is not nullable.");
        return false;
    }

    char logMsg[128];
    if(GetNativeString(3, STRING(logMsg)) != SP_ERROR_NONE)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Failed to get reason in native call.");
        return false;
    }

    if (strcmp(logMsg, "未知") == 0)
    {
        ThrowNativeError(SP_ERROR_NATIVE, "Reason is not nullable.");
        return false;
    }

    if(g_ClientData[client].bRefresh)
    {
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteCell(difference);
        pack.WriteCell(g_ClientData[client].iId);
        pack.WriteCell(GetTime());
        pack.WriteString(logMsg);
        CreateTimer(1.0, Timer_SetCreditsDelay, pack, TIMER_REPEAT);
        return true;
    }

    g_ClientData[client].iCredits = m_iCredits;

    UTIL_LogMessage(client, difference, logMsg);
    
    UTIL_SaveClientData(client, false);

    return true;
}

public Action Timer_SetCreditsDelay(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    int difference = pack.ReadCell();
    int m_iStoreId = pack.ReadCell();
    int iTimeStamp = pack.ReadCell();
    char logMsg[256];
    pack.ReadString(STRING(logMsg));

    if(!IsClientInGame(client))
    {
        delete pack;
        char m_szQuery[512], eReason[256];
        FormatEx(STRING(m_szQuery), "UPDATE store_players SET credits=credits+%d WHERE id=%d", difference, m_iStoreId);
        SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
        g_hDatabase.Escape(logMsg, STRING(eReason));
        FormatEx(STRING(m_szQuery), "INSERT INTO store_newlogs VALUES (DEFAULT, %d, %d, %d, \"%s\", FROM_UNIXTIME(%d))", m_iStoreId, g_ClientData[client].iCredits + difference, difference, eReason, iTimeStamp);
        SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
        return Plugin_Stop;
    }

    if(g_ClientData[client].bRefresh)
        return Plugin_Continue;

    delete pack;

    if(m_iStoreId != g_ClientData[client].iId)
    {
        LogStoreError("SetCreditsDelay -> id not match -> id.%d ? real.%d -> \"%L\" ", m_iStoreId, g_ClientData[client].iId, client);
        return Plugin_Stop;
    }

    g_ClientData[client].iCredits += difference;

    UTIL_LogMessage(client, difference, logMsg);
    UTIL_SaveClientData(client, false);

    return Plugin_Stop;
} 

public int Native_IsItemInBoughtPackage(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    int uid = GetNativeCell(3);

    if(itemid >= 0)
        return false;

    int m_iParent = g_Items[itemid].iParent;

    while(m_iParent != -1)
    {
        for(int i = 0; i < g_ClientData[client].iItems; ++i)
            if(((uid == -1 && g_ClientItem[client][i].iUniqueId == m_iParent) || (uid != -1 && g_ClientItem[client][i].iUniqueId == uid)) && !g_ClientItem[client][i].bDeleted)
                return true;
        m_iParent = g_Items[m_iParent].iParent;
    }
    return false;
}

public int Native_DisplayConfirmMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    char title[255], m_szCallback[32], m_szData[11];
    GetNativeString(2, STRING(title));

    DataPack pack = new DataPack();
    pack.WriteCell(plugin);
    pack.WriteFunction(GetNativeFunction(3));

    char file[64];
    GetPluginFilename(plugin, STRING(file));
    pack.WriteString(file);

    pack.Reset();

    Menu m_hMenu = new Menu(MenuHandler_Confirm);
 
    m_hMenu.SetTitle("%s\n ", title);

    IntToString(view_as<int>(pack), STRING(m_szCallback));
    IntToString(GetNativeCell(4), STRING(m_szData));

    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szCallback, "%T", "Confirm_Yes", client);
    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szData, "%T", "Confirm_No", client);

    m_hMenu.ExitButton = false;
    m_hMenu.Display(client, 0);
}

public int Native_UseItem(Handle plugin, int numParams)
{
    int  client = GetNativeCell(1);
    int  itemid = GetNativeCell(2);
    bool synced = GetNativeCell(3);
    int  slot   = GetNativeCell(4);

    if (!Store_HasClientItem(client, itemid))
        return -1;

    return UTIL_UseItem(client, itemid, synced, slot);
}

public int Native_GiveItem(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    int purchase = GetNativeCell(3);
    int expiration = GetNativeCell(4);
    int price = GetNativeCell(5);

    if (expiration < GetTime() && expiration > 0)
        return false;

    if(IsFakeClient(client) || !g_ClientData[client].bLoaded || g_ClientData[client].bBan)
    {
        LogStoreError("Native_GiveItem -> %N itemid %d purchase %d expiration %d price %d -> ban? loaded? fakeclient?", client, itemid, purchase, expiration, price);
        return false;
    }

    if(itemid < 0)
    {
        LogStoreError("Native_GiveItem -> %N itemid %d purchase %d expiration %d price %d", client, itemid, purchase, expiration, price);
        return false;
    }

    Action res = Plugin_Continue;
    Call_StartForward(g_hOnGiveClientItem);
    Call_PushCell(client);
    Call_PushString(g_Items[itemid].szUniqueId);
    Call_PushCell(purchase);
    Call_PushCell(expiration);
    Call_PushCell(price);
    Call_Finish(res);
    if (res >= Plugin_Handled)
        return false;

    char pFile[32];
    GetPluginFilename(plugin, STRING(pFile));

    if(!Store_HasClientItem(client, itemid))
    {
        int m_iDateOfPurchase = (purchase==0 ? GetTime() : purchase);
        int m_iDateOfExpiration = expiration;

        int m_iId = g_ClientData[client].iItems++;
        g_ClientItem[client][m_iId].iId = -1;
        g_ClientItem[client][m_iId].iUniqueId = itemid;
        g_ClientItem[client][m_iId].iDateOfPurchase = m_iDateOfPurchase;
        g_ClientItem[client][m_iId].iDateOfExpiration = m_iDateOfExpiration;
        g_ClientItem[client][m_iId].iPriceOfPurchase = price;
        g_ClientItem[client][m_iId].bSynced = false;
        g_ClientItem[client][m_iId].bDeleted = false;
        UTIL_LogMessage(client, 0, "Give item [%s][%s] via native, p[%d], e[%d] from %s", g_Items[itemid].szUniqueId, g_Items[itemid].szName, m_iDateOfPurchase, expiration, pFile);
        return true;
    }

    UTIL_LogMessage(client, 0, "Give and Ext item [%s][%s] via native, e[%d] from %s", g_Items[itemid].szUniqueId, g_Items[itemid].szName, expiration, pFile);

    int ext = Store_GetItemExpiration(client, itemid);
    if (ext > 0)
    {
        if(!Store_ExtClientItem(client, itemid, expiration == 0 ? expiration : expiration - GetTime()))
            LogStoreError("Ext \"%L\" %s failed. purchase %d expiration %d price %d", client, g_Items[itemid].szName , purchase, expiration, price);
    }
    else
    {
        LogMessage("Try to extend item at %L but have ext %d", client, ext);
    }

    return true;
}

public int Native_RemoveItem(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);

    if(itemid > 0 && g_TypeHandlers[g_Items[itemid].iHandler].fnRemove != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].szPlFile))
    {
        Call_StartFunction(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].fnRemove);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish();
    }

    UTIL_UnequipItem(client, itemid, false);

    int m_iId = UTIL_GetClientItemId(client, itemid);
    if(m_iId != -1)
        g_ClientItem[client][m_iId].bDeleted = true;
}

public int Native_GetItemExpiration(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    
    // Check if item is available?
    if(itemid < 0)
        return -1;
    
    if(!g_ClientData[client].bLoaded)
        return -1;
    
    // Can he even have it?    
    if(g_Items[itemid].szSteam[0] != 0)
        return (AllowItemForAuth(client, g_Items[itemid].szSteam)) ? 0 : -1;

    if(g_Items[itemid].bVIP && AllowItemForVIP(client, true) && g_Items[itemid].iPrice <= 0 && g_Items[itemid].iPlans==0)
        return 0;

    // Is the item free (available for everyone)?
    if((!g_Items[itemid].bIgnore || g_Items[itemid].bBuyable) && g_Items[itemid].iPrice <= 0 && g_Items[itemid].iPlans==0)
        return -1;

    for(int i = 0; i < g_ClientData[client].iItems; ++i)
    if(g_ClientItem[client][i].iUniqueId == itemid && !g_ClientItem[client][i].bDeleted)
        return g_ClientItem[client][i].iDateOfExpiration;

    return -1;
}

public int Native_HasClientItem(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    
    // Check if item is available?
    if(itemid < 0)
        return false;

    // Personal item?
    if(g_Items[itemid].szSteam[0] != 0)
        return AllowItemForAuth(client, g_Items[itemid].szSteam);

    // VIP item?
    if(g_Items[itemid].bVIP && !AllowItemForVIP(client, true) && g_Items[itemid].iPrice <= 0 && g_Items[itemid].iPlans==0)
        return false;

    // Is the item free (available for everyone)?
    if((!g_Items[itemid].bIgnore || g_Items[itemid].bBuyable) && g_Items[itemid].iPrice <= 0 && g_Items[itemid].iPlans==0)
        return true;

    // Check if the client actually has the item
    for(int i = 0; i < g_ClientData[client].iItems; ++i)
    if(g_ClientItem[client][i].iUniqueId == itemid && !g_ClientItem[client][i].bDeleted)
        return (g_ClientItem[client][i].iDateOfExpiration==0 || (g_ClientItem[client][i].iDateOfExpiration && GetTime()<g_ClientItem[client][i].iDateOfExpiration));

    // Check if the item is part of a group the client already has
    if(Store_IsItemInBoughtPackage(client, itemid))
        return true;

    return false;
}

public int Native_ExtClientItem(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    int extime = GetNativeCell(3);
    
    if(!g_ClientData[client].bLoaded || g_ClientData[client].bBan)
        return false;

    for(int i = 0; i < g_ClientData[client].iItems; ++i)
    if(g_ClientItem[client][i].iUniqueId == itemid && !g_ClientItem[client][i].bDeleted)
    {
        if(g_ClientItem[client][i].iDateOfExpiration == 0)
            return true;

        if(extime == 0)
            g_ClientItem[client][i].iDateOfExpiration = 0;
        else
            g_ClientItem[client][i].iDateOfExpiration += extime;

        if(g_ClientItem[client][i].iId==-1 && !g_ClientItem[client][i].bSynced)
            return true;

        char m_szQuery[256];
        FormatEx(STRING(m_szQuery), "UPDATE `store_items` SET `date_of_expiration` = '%d' WHERE `id`=%d AND `player_id`=%d", g_ClientItem[client][i].iDateOfExpiration, g_ClientItem[client][i].iId, g_ClientData[client].iId);
        SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
        UTIL_LogMessage(client, 0, "Ext item [%s][%s][%d] via native, e[%d]", g_Items[itemid].szUniqueId, g_Items[itemid].szName,  g_ClientItem[client][i].iId, extime);

        return true;
    }

    return false;
}

public int Native_GetSkinLevel(Handle myself, int numParams)
{
#if defined Module_Skin
    return Store_GetPlayerSkinLevel(GetNativeCell(1));
#else
    return 0;
#endif
}

public any Native_GetItemList(Handle myself, int numParams)
{
    ArrayList items = new ArrayList(sizeof(Store_Item));

    for(int itemid = 0; itemid < g_iItems; ++itemid)
    {
        items.PushArray(g_Items[itemid]);
    }

    ArrayList result = view_as<ArrayList>(CloneHandle(items, myself));
    delete items;
    return result;
}

public int Native_HasPlayerSkin(Handle myself, int numParams)
{
#if defined Module_Skin
    int client = GetNativeCell(1);

    char model[2][192];
    Store_GetClientSkinModel(client, model[0], 192);
    Store_GetPlayerSkinModel(client, model[1], 192);

    return (StrContains(model[1], "#default") == -1 && StrContains(model[1], "#zombie") == -1 && StrContains(model[0], "models/player/custom_player/legacy/") == -1);
#else
    return false;
#endif
}

public int Native_GetPlayerSkin(Handle myself, int numParams)
{
#if defined Module_Skin
    int client = GetNativeCell(1);
    
    char model[2][192];
    Store_GetClientSkinModel(client, model[0], 192);
    Store_GetPlayerSkinModel(client, model[1], 192);

    if(StrContains(model[1], "#default") != -1 || StrContains(model[1], "#zombie") != -1 || StrContains(model[0], "models/player/custom_player/legacy/") != -1)
        return false;

    if(SetNativeString(2, model[1], GetNativeCell(3)) == SP_ERROR_NONE)
        return true;
#endif
    return false;
}

public any Native_GetClientPlayerSkins(Handle myself, int numParmas)
{
#if defined Module_Skin
    int client = GetNativeCell(1);
    ArrayList array = view_as<ArrayList>(GetNativeCell(2));
    if (array == null)
        return false;

    array.Clear();

    int handler = UTIL_GetTypeHandler("playerskin");
    if (handler == -1)
        return false;

    for (int i = 0; i < g_iItems; i++)
    {
        char m[128], a[128]; int b;
        if (g_Items[i].iHandler == handler && Store_HasClientItem(client, i) && GetSkinData(i, m, a, b))
        {
            SkinData_t s;
            strcopy(s.m_Name, sizeof(SkinData_t::m_Name), g_Items[i].szName);
            strcopy(s.m_UId, sizeof(SkinData_t::m_UId), g_Items[i].szUniqueId);
            strcopy(s.m_Skin, sizeof(SkinData_t::m_Skin), m);
            strcopy(s.m_Arms, sizeof(SkinData_t::m_Arms), a);
            s.m_Body = b;
            array.PushArray(s, sizeof(SkinData_t));
        }
    }

    return array.Length > 0;
#else
    return false;
#endif
}

public any Native_GetAllPlayerSkins(Handle myself, int numParams)
{
#if defined Module_Skin
    ArrayList array = view_as<ArrayList>(GetNativeCell(1));
    if (array == null)
        return false;

    array.Clear();

    int handler = UTIL_GetTypeHandler("playerskin");
    if (handler == -1)
        return false;

    for (int i = 0; i < g_iItems; i++)
    {
        char m[128], a[128]; int b;
        if (g_Items[i].iHandler == handler && GetSkinData(i, m, a, b))
        {
            SkinData_t s;
            strcopy(s.m_Name, sizeof(SkinData_t::m_Name), g_Items[i].szName);
            strcopy(s.m_UId, sizeof(SkinData_t::m_UId), g_Items[i].szUniqueId);
            strcopy(s.m_Skin, sizeof(SkinData_t::m_Skin), m);
            strcopy(s.m_Arms, sizeof(SkinData_t::m_Arms), a);
            s.m_Body = b;
            array.PushArray(s, sizeof(SkinData_t));
        }
    }

    return array.Length > 0;
#else
    return false;
#endif
}

public any Native_ApplyPlayerSkin(Handle myself, int numParams)
{
#if defined Module_Skin
    int client = GetNativeCell(1);
    Store_RemoveClientGloves(client, -1);
    Store_ResetPlayerSkin(client);
    Store_PreSetClientModel(client);
    return true;
#else
    return false;
#endif
}

public int Native_IsPlayerTP(Handle plugin, int numParams)
{
    return IsPlayerTP(GetNativeCell(1));
}

public int Native_IsPlayerHide(Handle plugin, int numParams)
{
    return false;
}

public int Native_IsStoreSpray(Handle plugin, int numParams)
{
#if defined Module_Spray
    return Spray_IsSpray(GetNativeCell(1));
#else
    return false;
#endif
}

public int Native_LogOpenCase(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    if (!g_ClientData[client].bLoaded)
        ThrowNativeError(SP_ERROR_NATIVE, "Client %L is not load.", client);

    int itemid = GetNativeCell(2);
    int length = GetNativeCell(3);
    int caseid = GetNativeCell(5);

    char handle[16];
    GetNativeString(4, STRING(handle));

    UTIL_LogOpencase(client, itemid, length, handle, caseid);
}

public int Native_InDeathCamera(Handle plugin, int numParams)
{
#if defined Module_Skin
    return IsInDeathCamera(GetNativeCell(1));
#else
    return false;
#endif
}

//////////////////////////////
//      CLIENT FORWARD      //
//////////////////////////////
public void OnClientConnected(int client)
{
    g_iSpam[client]        = 0;
    g_iClientTeam[client]  = 0;
    g_iClientCase[client]  = 1;
    g_iDataProtect[client] = GetTime()+300;
    
    g_ClientData[client].iId              = -1;
    g_ClientData[client].iUserId          = GetClientUserId(client);
    g_ClientData[client].iCredits         = 0;
    g_ClientData[client].iOriginalCredits = 0;
    g_ClientData[client].iItems           = 0;
    g_ClientData[client].bLoaded          = false;

    g_Compose[client].item1 = -1;
    g_Compose[client].item2 = -1;
    g_Compose[client].types = -1;

    for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
    for(int a = 0; a < STORE_MAX_SLOTS; ++a)
    {
        g_ClientData[client].aEquipment[i*STORE_MAX_SLOTS+a] = -2;
        g_ClientData[client].aEquipmentSynced[i*STORE_MAX_SLOTS+a] = -2;
    }

#if defined Module_Spray
    Sprays_OnClientConnected(client);
#endif

#if defined Module_Sound
    Sound_OnClientConnected(client);
#endif

    TPMode_OnClientConnected(client);
}

public void OnClientPostAdminCheck(int client)
{
    if(IsFakeClient(client))
        return;

    g_iDataProtect[client] = GetTime()+300;

    UTIL_LoadClientInventory(client);
}

public void OnClientDisconnect(int client)
{
    if(IsFakeClient(client))
        return;

#if defined Module_Player
    Players_OnClientDisconnect(client);
#endif

    UTIL_SaveClientData(client, true);
    UTIL_SaveClientInventory(client);
    UTIL_SaveClientEquipment(client);
    UTIL_DisconnectClient(client);
}

public void OnClientCookiesCached(int client)
{
#if defined Module_Sound
    Sounds_OnLoadOptions(client);
#endif
}

public void Opts_OnClientLoad(int client)
{
#if defined Module_Sound
    Sounds_OnLoadOptions(client);
#endif
}

//////////////////////////////
//         COMMAND          //
//////////////////////////////
public Action Command_Store(int client, int args)
{
    if(!IsClientInGame(client))
        return Plugin_Handled;

    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

    if(!g_ClientData[client].bLoaded)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }

    if(g_ClientData[client].bBan)
    {
        tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
        return Plugin_Handled;
    }    

    g_bInvMode[client]=false;
    DisplayStoreMenu(client);

    return Plugin_Handled;
}

public Action Command_Inventory(int client, int args)
{    
    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

    if(!g_ClientData[client].bLoaded)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }
    
    if(g_ClientData[client].bBan)
    {
        tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
        return Plugin_Handled;
    }    
    
    g_bInvMode[client] = true;
    DisplayStoreMenu(client);

    return Plugin_Handled;
}

public Action Command_Credits(int client, int args)
{    
    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

    if(!g_ClientData[client].bLoaded)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }
    
    if(g_ClientData[client].bBan)
    {
        tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
        return Plugin_Handled;
    }    

    if(g_iSpam[client]<GetTime())
    {
        tPrintToChatAll("%t", "Player Credits", client, g_ClientData[client].iCredits);
        g_iSpam[client] = GetTime()+30;
    }
    
    return Plugin_Handled;
}

//////////////////////////////
//           MENU           //
//////////////////////////////
void DisplayStoreMenu(int client, int parent = -1, int last = -1)
{
    if(!client || !IsClientInGame(client))
        return;

    g_iMenuNum[client] = 1;

    Menu m_hMenu = new Menu(MenuHandler_Store);
    if(parent != -1)
    {
        m_hMenu.ExitBackButton = true;
        m_hMenu.SetTitle("%s\n%T\n ", g_Items[parent].szName, "Title Credits", client, g_ClientData[client].iCredits);

        g_iMenuBack[client] = g_Items[parent].iParent;
    }
    else
        m_hMenu.SetTitle("%T\n%T\n ", "Title Store", client, "Title Credits", client, g_ClientData[client].iCredits);

    char m_szId[11];
    int m_iPosition = 0;

    g_iSelectedItem[client] = parent;
    if(parent != -1)
    {
        if(g_Items[parent].iPrice>0)
        {
            if(!Store_IsItemInBoughtPackage(client, parent))
            {
                AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "sell_package", "%T", "Package Sell", client, RoundToFloor(g_Items[parent].iPrice*0.6));
                ++m_iPosition;

                if(g_Items[parent].bGiftable)
                {
                    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "gift_package", "%T", "Package Gift", client);
                    ++m_iPosition;
                }

                for(int i = 0; i < g_iMenuHandlers; ++i)
                {
                    if(g_MenuHandlers[i].hPlugin == null || !IsPluginRunning(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].szPlFile))
                        continue;
    
                    Call_StartFunction(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].fnMenu);
                    Call_PushCellRef(m_hMenu);
                    Call_PushCell(client);
                    Call_PushCell(parent);
                    Call_Finish();
                }
            }
        }
    }

    for(int i = 0; i < g_iItems; ++i)
    {
        if(g_Items[i].iParent==parent)
        {
            int m_iPrice = UTIL_GetLowestPrice(i);

            // This is a package
            if(g_Items[i].iHandler == g_iPackageHandler)
            {
                if(!UTIL_PackageHasClientItem(client, i, g_bInvMode[client]))
                    continue;

                int m_iStyle = ITEMDRAW_DEFAULT;
                if(!AllowItemForAuth(client, g_Items[i].szSteam) || !AllowItemForVIP(client, g_Items[i].bVIP))
                    m_iStyle = ITEMDRAW_DISABLED;

                IntToString(i, STRING(m_szId));
                if(g_Items[i].iPrice == -1 || Store_HasClientItem(client, i))
                    AddMenuItem(m_hMenu, m_szId, g_Items[i].szName, m_iStyle);
                else if(!g_bInvMode[client] && g_Items[i].iPlans==0 && g_Items[i].bBuyable)
                    InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_ClientData[client].iCredits && !g_Items[i].bCompose) || g_Items[i].bCompose)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Available", client, g_Items[i].szName, g_Items[i].iPrice);
                else if(!g_bInvMode[client])
                    InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_ClientData[client].iCredits && !g_Items[i].bCompose) || g_Items[i].bCompose)?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Plan Available", client, g_Items[i].szName);
                ++m_iPosition;
            }
            // This is a normal item
            else
            {
                IntToString(i, STRING(m_szId));
                if(Store_HasClientItem(client, i))
                {
                    InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, FormatSkinTag(client, i, UTIL_IsEquipped(client, i)));
                }
                else if(!g_bInvMode[client])
                {
                    // hide personal item
                    if (strlen(g_Items[i].szSteam) > 8)
                        continue;

                    int m_iStyle = ITEMDRAW_DEFAULT;
                    if((g_Items[i].iPlans==0 && g_ClientData[client].iCredits<m_iPrice) || !AllowItemForAuth(client, g_Items[i].szSteam) || !AllowItemForVIP(client, g_Items[i].bVIP))
                        m_iStyle = ITEMDRAW_DISABLED;

                    if(strcmp(g_TypeHandlers[g_Items[i].iHandler].szType, "playerskin") == 0)
                    {
#if defined Global_Skin
                        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Preview Available", client, g_Items[i].szName);
#else
                        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, "[%s] %T", g_Items[i].iTeam == 2 ? "TE" : "CT", "Item Preview Available", client, g_Items[i].szName);
#endif
                        continue;
                    }

                    if(!g_Items[i].bBuyable)
                        continue;

                    if(g_Items[i].iPlans==0)
                        AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Available", client, g_Items[i].szName, g_Items[i].iPrice);
                    else
                        AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Plan Available", client, g_Items[i].szName, g_Items[i].iPrice);
                }
            }
        }
    }

    if (m_hMenu.ItemCount == 0)
    {
        delete m_hMenu;
        if (parent == -1)
        {
            tPrintToChat(client, "%T","store empty", client);
        }
        else
        {
            tPrintToChat(client, "%T", "category empty", client);
            DisplayStoreMenu(client, g_iMenuBack[client], g_iLastSelection[client]);
        }
        return;
    }
    
    if(last == -1)
        m_hMenu.Display(client, 0);
    else
        m_hMenu.DisplayAt(client, (last/m_hMenu.Pagination)*m_hMenu.Pagination, 0);
}

static char[] FormatSkinTag(int client, int itemid, bool equip)
{
    char buffer[128];

#if defined Skin_TeamTag
    FormatEx(STRING(buffer), "%s%T", (strcmp(g_TypeHandlers[g_Items[itemid].iHandler].szType, "playerskin") == 0) ? (g_Items[itemid].iTeam == 2 ? "[TE] " : "[CT] ") : "", equip ? "Item Equipped" : "Item Bought", client, g_Items[itemid].szName);
#else
    FormatEx(STRING(buffer), "%T", equip ? "Item Equipped" : "Item Bought", client, g_Items[itemid].szName);
#endif

    return buffer;
}

public int MenuHandler_Store(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        // Confirmation was given
        if(menu == null)
        {
            if(param2 == 0)
            {
                g_iMenuBack[client]=1;
                int m_iPrice = 0;
                if(g_iSelectedPlan[client]==-1)
                    m_iPrice = g_Items[g_iSelectedItem[client]].iPrice;
                else
                    m_iPrice = g_PurchasePlan[g_iSelectedItem[client]][g_iSelectedPlan[client]].iPrice;

                if(g_ClientData[client].iCredits>=m_iPrice && !Store_HasClientItem(client, g_iSelectedItem[client]))
                    UTIL_BuyItem(client);
            }
            else if(param2 == 1)
                UTIL_SellItem(client, g_iSelectedItem[client]);
        }
        else
        {
            char m_szId[64];
            menu.GetItem(param2, STRING(m_szId));
            
            g_iLastSelection[client]=param2;
            
            // We are selling a package
            if(strcmp(m_szId, "sell_package")==0)
            {
                char m_szTitle[128];
                FormatEx(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_Items[g_iSelectedItem[client]].szName, g_TypeHandlers[g_Items[g_iSelectedItem[client]].iHandler].szType, RoundToFloor(g_Items[g_iSelectedItem[client]].iPrice*0.6));
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 1);
                return;
            }
            // We are gifting a package
            else if(strcmp(m_szId, "gift_package")==0)
            {
                DisplayPlayerMenu(client);
            }
            // This is menu handler stuff
            else if(!(48 <= m_szId[0] <= 57))
            {
                int ret;
                for(int i = 0; i < g_iMenuHandlers; ++i)
                {
                    if(g_MenuHandlers[i].hPlugin == null || !IsPluginRunning(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].szPlFile))
                        continue;
                    
                    Call_StartFunction(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].fnHandler);
                    Call_PushCell(client);
                    Call_PushString(m_szId);
                    Call_PushCell(g_iSelectedItem[client]);
                    Call_Finish(ret);

                    if(ret) break;
                }
            }
            // We are being boring
            else
            {
                int m_iId = StringToInt(m_szId);
                g_iMenuBack[client]=g_Items[m_iId].iParent;
                g_iSelectedItem[client] = m_iId;
                g_iSelectedPlan[client] = -1;
                
                if(!Store_HasClientItem(client, m_iId))
                {
                    if(StrEqual(g_TypeHandlers[g_Items[m_iId].iHandler].szType, "playerskin"))
                    {
                        DisplayPreviewMenu(client, m_iId);
                        return;
                    }

                    if(g_Items[m_iId].bCompose)
                    {
                        if(g_ClientData[client].iCredits >= g_inCase[1])
                        {
                            g_Compose[client].item1=-1;
                            g_Compose[client].item2=-1;
                            g_Compose[client].types=-1;
                            DisplayComposeMenu(client, false);
                        }
                        else
                            tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, g_inCase[1]);
                        return;
                    }
                    else
                    {
                        if((g_ClientData[client].iCredits>=g_Items[m_iId].iPrice || g_Items[m_iId].iPlans>0 && g_ClientData[client].iCredits>=UTIL_GetLowestPrice(m_iId)) && g_Items[m_iId].iPrice != -1)
                        {
                            if(g_Items[m_iId].iPlans > 0)
                                DisplayPlanMenu(client, m_iId);
                            else
                            {
                                char m_szTitle[128];
                                FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_Items[m_iId].szName, g_TypeHandlers[g_Items[m_iId].iHandler].szType);
                                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
                            }
                            return;
                        }
                    }
                }

                if(g_Items[m_iId].iHandler != g_iPackageHandler)
                {
                    if(Store_HasClientItem(client, m_iId))
                    {
                        if(g_TypeHandlers[g_Items[m_iId].iHandler].bRaw)
                        {
                            if(IsPluginRunning(g_TypeHandlers[g_Items[m_iId].iHandler].hPlugin, g_TypeHandlers[g_Items[m_iId].iHandler].szPlFile))
                            {
                                Call_StartFunction(g_TypeHandlers[g_Items[m_iId].iHandler].hPlugin, g_TypeHandlers[g_Items[m_iId].iHandler].fnUse);
                                Call_PushCell(client);
                                Call_PushCell(m_iId);
                                Call_Finish();
                            }
                        }
                        else DisplayItemMenu(client, m_iId);
                    }
                    else DisplayStoreMenu(client, g_iMenuBack[client]);                    
                }
                else DisplayStoreMenu(client, (Store_HasClientItem(client, m_iId) || g_Items[m_iId].iPrice == -1) ? m_iId : g_Items[m_iId].iParent);
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

void UTIL_GetLevelType(int client, int itemid, char[] buffer, int maxLen)
{
    switch(g_Items[itemid].iLevels)
    {
        case  2: FormatEx(buffer, maxLen, "%T", "level 2", client);
        case  3: FormatEx(buffer, maxLen, "%T", "level 3", client);
        case  4: FormatEx(buffer, maxLen, "%T", "level 4", client);
        case  5: FormatEx(buffer, maxLen, "%T", "level 5", client);
        case  6: FormatEx(buffer, maxLen, "%T", "level 6", client);
        default: FormatEx(buffer, maxLen, "%T", "level 1", client);
    }
}

void DisplayPreviewMenu(int client, int itemid)
{
    if(Store_HasClientItem(client, itemid))
        return;
    
    g_iMenuNum[client]  = 1;
    g_iMenuBack[client] = g_Items[itemid].iParent;

    Menu m_hMenu = new Menu(MenuHandler_Preview);
    m_hMenu.ExitBackButton = true;

    m_hMenu.SetTitle("%s\n%T\n ", g_Items[itemid].szName, "Title Credits", client, g_ClientData[client].iCredits);

    AddMenuItemEx(m_hMenu, (g_Items[itemid].szDesc[0] == '\0') ? ITEMDRAW_SPACER : ITEMDRAW_DISABLED, "3", "%s", g_Items[itemid].szDesc);

    char leveltype[32];
    UTIL_GetLevelType(client, itemid, STRING(leveltype));
    AddMenuItemEx(m_hMenu, (g_Items[itemid].iLevels <= 0) ? ITEMDRAW_SPACER : ITEMDRAW_DISABLED, "3", "%T", "Playerskins Level", client, g_Items[itemid].iLevels, leveltype);

    AddMenuItemEx(m_hMenu, (g_aCaseSkins[0].Length > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_SPACER, "3", "%T", "Open Case Available", client);

    if(g_Items[itemid].bCompose)  //合成
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Preview Compose Available", client);
    else if(g_Items[itemid].szSteam[0] != 0) //专个人属
        AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    else if(g_Items[itemid].bIgnore) //组专属或活动限定
        AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    else
    {
        if(g_Items[itemid].bBuyable)
        {
            int m_iStyle = ITEMDRAW_DEFAULT;
            if((g_Items[itemid].iPlans==0 && g_ClientData[client].iCredits<UTIL_GetLowestPrice(itemid)) || !AllowItemForAuth(client, g_Items[itemid].szSteam) || !AllowItemForVIP(client, g_Items[itemid].bVIP))
                m_iStyle = ITEMDRAW_DISABLED;
            
            if(g_Items[itemid].iPlans==0)
                AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Available", client, g_Items[itemid].iPrice);
            else
                AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Plan Available", client);
        }
        else
            AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    }

    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Preview", client);

    m_hMenu.Display(client, 0);
}

public int MenuHandler_Preview(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        char m_szId[64];
        menu.GetItem(param2, STRING(m_szId));
        int selected = StringToInt(m_szId);
        int m_iId = g_iSelectedItem[client];

        if(selected == 0)
        {
            if(g_ClientData[client].iCredits >= g_inCase[1])
            {
                g_Compose[client].item1=-1;
                g_Compose[client].item2=-1;
                g_Compose[client].types=-1;
                DisplayComposeMenu(client, false);
            }
            else
                tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, g_inCase[1]);
        }
        else if(selected == 1)
        {
            if((g_ClientData[client].iCredits>=g_Items[m_iId].iPrice || g_Items[m_iId].iPlans>0 && g_ClientData[client].iCredits>=UTIL_GetLowestPrice(m_iId)) && g_Items[m_iId].iPrice != -1)
            {
                if(g_Items[m_iId].iPlans > 0)
                    DisplayPlanMenu(client, m_iId);
                else
                {
                    char m_szTitle[128];
                    FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_Items[m_iId].szName, g_TypeHandlers[g_Items[m_iId].iHandler].szType);
                    Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
                }
            }
        }
        else if(selected == 2)
        {
#if defined Module_Skin
            Store_PreviewSkin(client, m_iId);
            DisplayPreviewMenu(client, m_iId);
#else
            DisplayPreviewMenu(client, m_iId);
            tPrintToChat(client, "%T", "Chat Preview Cooldown", client);
#endif
        }
        else if(selected == 3)
        {
#if defined Module_Skin
            if(g_ClientData[client].iCredits >= g_inCase[1])
                UTIL_OpenSkinCase(client);
            else
                tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, g_inCase[1]);
#else
            tPrintToChat(client, "%T", "Open Case not available", client);
#endif
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

public Action Command_Case(int client, int args)
{
    if(!IsClientInGame(client))
        return Plugin_Handled;

    if(LibraryExists("OpenCase"))
        return Plugin_Handled;

    if(args > 0)
    {
        tPrintToChat(client, "Invalid parameter.");
        return Plugin_Handled;
    }

    if(!g_ClientData[client].bLoaded)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }

    if(g_ClientData[client].bBan)
    {
        tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
        return Plugin_Handled;
    }    

#if defined Module_Skin
    if(g_ClientData[client].iCredits >= g_inCase[1])
        UTIL_OpenSkinCase(client);
    else
        tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, g_inCase[1]);
#else
    tPrintToChat(client, "%T", "Open Case not available", client);
#endif

    return Plugin_Handled;
}

void UTIL_OpenSkinCase(int client)
{
    if(LibraryExists("OpenCase"))
        return;

    Menu menu = new Menu(MenuHandler_SelectCase);
    menu.SetTitle("%T\n%T: %d\n ", "select case", client, "credits", client, g_ClientData[client].iCredits);
    menu.ExitBackButton = true;

    AddMenuItemEx(menu, (g_ClientData[client].iCredits >= g_inCase[1] && g_aCaseSkins[0].Length > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "1", "%T(%d%T)\nSkin Level: 1|2|3(7day~%T)", g_szCase[1], client, g_inCase[1], "credits", client, "permanent", client);
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, (g_ClientData[client].iCredits >= g_inCase[2] && g_aCaseSkins[1].Length > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "2", "%T(%d%T)\nSkin Level: 1|2|3|4(15day~%T)", g_szCase[2], client, g_inCase[2], "credits", client, "permanent", client);
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, (g_ClientData[client].iCredits >= g_inCase[3] && g_aCaseSkins[2].Length > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "3", "%T(%d%T)\nSkin Level: 2|3|4(#%T#)", g_szCase[3], client, g_inCase[3], "credits", client, "permanent", client);

    menu.Display(client, 0);
}

public int MenuHandler_SelectCase(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End: delete menu;
        case MenuAction_Select:
        {
            if(g_iDataProtect[client] > GetTime())
            {
                tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
                UTIL_OpenSkinCase(client);
                return;
            }

            char info[32];
            menu.GetItem(param2, STRING(info));

            g_iClientCase[client] = StringToInt(info);
            
            if(g_iSelectedItem[client] > -1 && g_Items[g_iSelectedItem[client]].bIgnore)
            {
                if(g_iClientCase[client] == 1)
                    tPrintToChat(client, "%T", "Item not in case", client);
                else if(g_Items[g_iSelectedItem[client]].szSteam[0] != 0)
                    tPrintToChat(client, "%T", "Item not in case", client);
            }

            g_iDataProtect[client] = GetTime()+300;

            char m_szQuery[255];
            FormatEx(STRING(m_szQuery), "SELECT credits FROM store_players WHERE `id`=%d", g_ClientData[client].iId);
            g_hDatabase.Query(SQLCallback_OpenCase, m_szQuery, g_ClientData[client].iUserId, DBPrio_High);
            g_ClientData[client].bRefresh = true;
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
                DisplayItemMenu(client, g_iSelectedItem[client]);
        }
    }
}

public void SQLCallback_OpenCase(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    g_ClientData[client].bRefresh = false;

    if(!results.FetchRow())
        return;

    int dbCredits = results.FetchInt(0);

    if(dbCredits != g_ClientData[client].iOriginalCredits)
    {
        int diff = dbCredits - g_ClientData[client].iOriginalCredits;
        g_ClientData[client].iOriginalCredits = dbCredits;
        g_ClientData[client].iCredits += diff;
        UTIL_LogMessage(client, diff, "Credits changed in database (sync credits from database)");
        Store_SaveClientAll(client);
    }

    switch(g_iClientCase[client])
    {
        case 1 : if(g_ClientData[client].iCredits < g_inCase[1]) return;
        case 2 : if(g_ClientData[client].iCredits < g_inCase[2]) return;
        case 3 : if(g_ClientData[client].iCredits < g_inCase[3]) return;
        default: return;
    }

    g_iDataProtect[client] = GetTime() + 10;

    CreateTimer(0.1, Timer_OpeningCase, userid);
}

public Action Timer_OpeningCase(Handle timer, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!client || !IsClientInGame(client))
        return Plugin_Stop;

    g_iDataProtect[client] = GetTime() + 10;

    switch(g_iClientCase[client])
    {
        case 1 : if(g_ClientData[client].iCredits < g_inCase[1]) return Plugin_Stop;
        case 2 : if(g_ClientData[client].iCredits < g_inCase[2]) return Plugin_Stop;
        case 3 : if(g_ClientData[client].iCredits < g_inCase[3]) return Plugin_Stop;
        default: return Plugin_Stop;
    }

    static int times[MAXPLAYERS+1];

    if((g_iClientCase[client] == 1 && g_aCaseSkins[0].Length == 0) || (g_iClientCase[client] == 2 && g_aCaseSkins[1].Length == 0) || (g_iClientCase[client] == 3 && g_aCaseSkins[2].Length == 0))
        return Plugin_Stop;

    int type = 0;
    int radm = UTIL_GetRandomInt(1, 999);

    // Ultima
    if(g_iClientCase[client] == 3)
    {
        // 3.5% SSR | 96.5% SR
        type = (radm >= 965) ? 2 : ((g_aCaseSkins[1].Length > 0) ? 1 : 0);
    }
    // advance
    else if(g_iClientCase[client] == 2)
    {
        if(radm >= 850)
        {
            // 15% SSR
            type = ((g_aCaseSkins[2].Length > 0) ? 2 : 1);
        }
        else if(radm >= 500)
        {
            // 35% SR
            type = 1;
        }
        else
        {
            type = 0;
        }
    }
    else
    {
        if(radm >= 800)
        {
            // 20% SR
            type = ((g_aCaseSkins[1].Length > 0) ? 1 : 0);
        }
        else
        {
            type = 0;
        }
    }

    if(g_aCaseSkins[type].Length <= 0)
    {
        tPrintToChat(client, "{red}%T {silver}->{darkred} Null Array", "unknown error", client);
        LogStoreError("Null Array in Case Array [%s]", g_szCase[type+1]);
        return Plugin_Stop;
    }

    int aid = UTIL_GetRandomInt(0, g_aCaseSkins[type].Length-1);
    char modelname[32];
    g_aCaseSkins[type].GetString(aid, STRING(modelname));

    int itemid = UTIL_GetItemId(modelname);

    if(itemid < 0)
    {
        LogStoreError("Item Id Error %s", modelname);
        tPrintToChat(client, "{red}%T {silver}->{darkred} Invalid Item", "unknown error", client);
        return Plugin_Stop;
    }

    int days = 7;

    int rdm = UTIL_GetRandomInt(1, 1000);

    if(++times[client] < 28)
    {
        if(rdm >= 800)
            days = 0;
        else
            days = UTIL_GetRandomInt(14, 365);

        if(g_iClientCase[client] == 3)
            days = 0;
    }
    else
    {
        if(g_iClientCase[client] == 3)
        {
            // always
            days = 0;
        }
        else if(g_iClientCase[client] == 2)
        {
            if(type == 2)
            {
                // ult case?
                days = (rdm >= 990) ? 0 : UTIL_GetRandomInt(15, 30);
            }
            else
            {
                if(rdm >= 990)
                    days = 0;
                else if(rdm >= 950)
                    days = UTIL_GetRandomInt(91, 365);
                else if(rdm >= 750)
                    days = UTIL_GetRandomInt(31, 90);
                else
                    days = UTIL_GetRandomInt((g_iClientCase[client] == 2 ? 15 : 7), 30);
            }
        }
        else
        {
            if(rdm >= 990)
                days = 0;
            else if(rdm >= 920)
                days = UTIL_GetRandomInt(91, 365);
            else if(rdm >= 700)
                days = UTIL_GetRandomInt(31, 90);
            else
                days = UTIL_GetRandomInt((g_iClientCase[client] == 2 ? 15 : 7), 30);
        }

        times[client] = 0;
        EndingCaseMenu(client, days, itemid);
        return Plugin_Stop;
    }

    OpeningCaseMenu(client, days, g_Items[itemid].szName);

    if(12 >= times[client])     CreateTimer(0.2, Timer_OpeningCase, userid);
    else if(times[client] > 12) CreateTimer(0.3, Timer_OpeningCase, userid);
    else if(times[client] > 20) CreateTimer(0.5, Timer_OpeningCase, userid);
    else if(times[client] > 23) CreateTimer(0.8, Timer_OpeningCase, userid);
    else if(times[client] > 25) CreateTimer(1.2, Timer_OpeningCase, userid);
    else if(times[client] > 27) CreateTimer(1.8, Timer_OpeningCase, userid);
    else if(times[client] > 28) CreateTimer(2.6, Timer_OpeningCase, userid);

    return Plugin_Stop;
}

void OpeningCaseMenu(int client, int days, const char[] name)
{
    static Panel m_hCasePanel = null;

    if(m_hCasePanel != null)
        delete m_hCasePanel;

    m_hCasePanel = new Panel();

    char fmt[128];

    FormatEx(STRING(fmt), "   %T", g_szCase[g_iClientCase[client]], client);
    m_hCasePanel.DrawText(fmt);
    m_hCasePanel.DrawText(" ");

    m_hCasePanel.DrawText("░░░░░░░░░░░░░░░░░░");
    m_hCasePanel.DrawText("░░░░░░░░░░░░░░░░░░");
    m_hCasePanel.DrawText("                 ");

    if(days)
    {
        FormatEx(STRING(fmt), "  %s (%d day%s)", name, days, days > 1 ? "s" : "");
        PrintCenterText(client, "%s (%d day%s)", name, days, days > 1 ? "s" : "");
    }
    else
    {
        FormatEx(STRING(fmt), "  %s (%T)", name, "permanent", client);
        PrintCenterText(client, "%s (%T)", name, "permanent", client);
    }
    m_hCasePanel.DrawText(fmt);

    m_hCasePanel.DrawText("                 ");
    m_hCasePanel.DrawText("░░░░░░░░░░░░░░░░░░");
    m_hCasePanel.DrawText("░░░░░░░░░░░░░░░░░░");

    ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");

    m_hCasePanel.Send(client, MenuHandler_OpeningCase, 5);
}

public int MenuHandler_OpeningCase(Menu menu, MenuAction action, int client, int param2)
{
    // Do nothing...
}

int UTIL_GetSkinSellPrice(int client, int itemid, int days)
{
    if(days == 0)
        return RoundToCeil(g_inCase[g_iClientCase[client]] * 0.8);

    if(g_Items[itemid].iPlans > 0)
    {
        if(days > 30)
            return (g_PurchasePlan[itemid][2].iPrice > 0) ? RoundToCeil(float(days) / 365.0 * g_PurchasePlan[itemid][2].iPrice * 0.85) : 100;
        else if(days > 7)
            return (g_PurchasePlan[itemid][1].iPrice > 0) ? RoundToCeil(float(days) /  30.0 * g_PurchasePlan[itemid][1].iPrice * 0.85) : 100;

        return     (g_PurchasePlan[itemid][0].iPrice > 0) ? RoundToCeil(float(days) /   1.0 * g_PurchasePlan[itemid][0].iPrice * 0.85) : 100;
    }

    return RoundToCeil(float(g_Items[itemid].iPrice) / 180.0 * days * 0.85);
}

public Action Timer_ReEndingCase(Handle timer, DataPack pack)
{
    int client = GetClientOfUserId(pack.ReadCell());
    int itemid = pack.ReadCell();
    int length = pack.ReadCell();
    delete pack;
    if (!client)
        return Plugin_Stop;

    //LogMessage("Redraw EndingCaseMenu to %L with %d and %d", client, g_Items[itemid].szUniqueId, length);
    EndingCaseMenu(client, length, itemid, false);

    return Plugin_Stop;
}

void EndingCaseMenu(int client, int days, int itemid, bool sound = true)
{
    if(g_bInterMission)
    {
        LogMessage("Stop EndingCaseMenu in g_bInterMission");
        return;
    }

    if(!g_ClientData[client].bLoaded)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return;
    }

    if(g_ClientData[client].bBan)
    {
        tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
        return;
    }

    g_iDataProtect[client] = GetTime()+10;

    Menu menu = new Menu(MenuHandler_OpenSuccessful);
    menu.SetTitle("%T\n%T\n ", "Open case successful", client, g_szCase[g_iClientCase[client]], client);
    menu.ExitButton = false;

    char name[128];
    strcopy(STRING(name), g_Items[itemid].szName);

    char leveltype[32];
    UTIL_GetLevelType(client, itemid, STRING(leveltype));
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %s - %s", "playerskin", client, name, leveltype);
    if(days)
    {
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %d day%s", "time limit", client, days, days > 1 ? "s" : "");
        PrintCenterText(client, "%s (%d day%s)", name, days, days > 1 ? "s" : "");
    }
    else
    {
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %T", "time limit", client, "permanent", client);
        PrintCenterText(client, "%s (%T)", name, "permanent", client);
    }

    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");

    int crd = UTIL_GetSkinSellPrice(client, itemid, days);
    char fmt[32];
    FormatEx(STRING(fmt), "sell_%d_%d", itemid, days);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, fmt, "%T(%d)", "quickly sell", client, crd);
    FormatEx(STRING(fmt), "add_%d_%d", itemid, days);
    AddMenuItemEx(menu, Store_HasClientItem(client, itemid) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, fmt, "%T", "income", client);

    menu.Display(client, 0);

    if (sound)
    ClientCommand(client, "playgamesound ui/item_drop3_rare.wav");
}

public int MenuHandler_OpenSuccessful(Menu menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End: delete menu;
        case MenuAction_Select:
        {
            if(g_bInterMission)
            {
                LogMessage("Stop MenuHandler_OpenSuccessful in g_bInterMission");
                return;
            }

            if(!g_ClientData[client].bLoaded)
            {
                tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
                return;
            }

            if(g_ClientData[client].bBan)
            {
                tPrintToChat(client,"[{red}CAT{white}]  %T", "cat banned", client);
                return;
            }

            if(g_ClientData[client].iCredits < g_inCase[g_iClientCase[client]] || g_iClientCase[client] < 0 || g_iClientCase[client] > 3)
                return;

            char info[32];
            menu.GetItem(param2, STRING(info));

            char data[3][16];
            ExplodeString(info, "_", data, 3, 16);

            int itemid = StringToInt(data[1]);
            int days = StringToInt(data[2]);

            char name[128];
            strcopy(STRING(name), g_Items[itemid].szName);

            if(days)
            {
                tPrintToChatAll("%t", "opencase earned day", client, g_szCase[g_iClientCase[client]], name, days);
            }
            else
            {
                tPrintToChatAll("%t", "opencase earned perm", client, g_szCase[g_iClientCase[client]], name);
            }

            if(StrEqual(data[0], "sell"))
            {
                int crd = UTIL_GetSkinSellPrice(client, itemid, days);
                char reason[128];
                FormatEx(STRING(reason), "open %s and quickly sell [%s] c[%d] e[%d]", g_szCase[g_iClientCase[client]], name, g_inCase[g_iClientCase[client]], crd);
                Store_SetClientCredits(client, Store_GetClientCredits(client)+crd-g_inCase[g_iClientCase[client]], reason);
                if(days) tPrintToChat(client, "%t", "open and sell day chat", name, days, crd);
                else tPrintToChat(client, "%t", "open and sell permanent chat", name, crd);
                UTIL_LogOpencase(client, itemid, days, "sell", g_iClientCase[client]);
                UTIL_OpenSkinCase(client);
                if(g_iClientCase[client] > 1)
                {
                    g_iDataProtect[client] = GetTime()+15;
                    Store_SaveClientAll(client);
                }
            }
            else if(StrEqual(data[0], "add"))
            {
                char reason[128];
                FormatEx(STRING(reason), "open %s and add [%s] d[%d] c[%d]", g_szCase[g_iClientCase[client]], name, days, g_inCase[g_iClientCase[client]]);
                Store_SetClientCredits(client, Store_GetClientCredits(client)-g_inCase[g_iClientCase[client]], reason);
                Store_GiveItem(client, itemid, GetTime(), (days == 0) ? 0 : GetTime()+days*86400, -11);
                if(days) tPrintToChat(client, "%t", "open and add day chat", g_szCase[g_iClientCase[client]], name, days);
                else tPrintToChat(client, "%t", "open and add permanent chat", g_szCase[g_iClientCase[client]], name);
                Store_SaveClientAll(client);
                UTIL_LogOpencase(client, itemid, days, "add", g_iClientCase[client]);
                g_iDataProtect[client] = GetTime()+15;
                g_iSelectedItem[client] = itemid;
                DisplayItemMenu(client, itemid);
            }
            else LogStoreError("\"%L\" Open case error: %s", client, info);
        }
        case MenuAction_Cancel:
        {
            if(IsClientInGame(client) && param2 == MenuCancel_Interrupted)
            {
                char info[32];
                menu.GetItem(5, STRING(info));
                
                char data[3][16];
                ExplodeString(info, "_", data, 3, 16);
                
                int itemid = StringToInt(data[1]);
                int days = StringToInt(data[2]);

                DataPack pack = new DataPack();
                pack.WriteCell(GetClientUserId(client));
                pack.WriteCell(itemid);
                pack.WriteCell(days);
                pack.Reset();
                CreateTimer(0.1, Timer_ReEndingCase, pack);
            }
            else if (param2 == MenuCancel_Disconnected)
            {
                char m_szQuery[128];
                FormatEx(STRING(m_szQuery), "UPDATE store_players SET `credits`=`credits`-%d WHERE `id`=%d", g_inCase[g_iClientCase[client]], g_ClientData[client].iId);
                SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
                LogStoreError("EndingCaseMenu -> %d disconnected -> %d", g_ClientData[client].iId, g_inCase[g_iClientCase[client]]);
            }
        }
    }
}

void DisplayItemMenu(int client, int itemid)
{
    if(!Store_HasClientItem(client, itemid))
    {
        if(StrEqual(g_TypeHandlers[g_Items[itemid].iHandler].szType, "playerskin"))
            DisplayPreviewMenu(client, itemid);
        return;
    }

    g_iMenuNum[client] = 1;
    g_iMenuBack[client] = g_Items[itemid].iParent;

    Menu m_hMenu = new Menu(MenuHandler_Item);
    m_hMenu.ExitBackButton = true;
    
    bool m_bEquipped = UTIL_IsEquipped(client, itemid);
    char m_szTitle[256];
    int idx = 0;
    if(m_bEquipped)
        idx = FormatEx(STRING(m_szTitle), "%T\n%T ", "Item Equipped", client, g_Items[itemid].szName, "Title Credits", client, g_ClientData[client].iCredits);
    else
        idx = FormatEx(STRING(m_szTitle), "%s\n%T ", g_Items[itemid].szName, "Title Credits", client, g_ClientData[client].iCredits);

    int m_iExpiration = UTIL_GetExpiration(client, itemid);
    if(m_iExpiration > 0)
    {
        m_iExpiration = m_iExpiration-GetTime();
        int m_iDays = m_iExpiration/(24*60*60);
        int m_iHours = (m_iExpiration-m_iDays*24*60*60)/(60*60);
        FormatEx(m_szTitle[idx-1], sizeof(m_szTitle)-idx-1, "\n%T", "Title Expiration", client, m_iDays, m_iHours);
    }
    else if(m_iExpiration == 0)
    {
        // PM item
        FormatEx(m_szTitle[idx-1], sizeof(m_szTitle)-idx-1, "\n%T", "Title Expiration PM", client);
    }

    m_hMenu.SetTitle("%s\n ", m_szTitle);

    if(g_TypeHandlers[g_Items[itemid].iHandler].bEquipable)
    {
        if(StrEqual(g_TypeHandlers[g_Items[itemid].iHandler].szType, "playerskin"))
        {
            AddMenuItemEx(m_hMenu, (g_Items[g_iItems].szDesc[0] == '\0') ? ITEMDRAW_SPACER : ITEMDRAW_DISABLED, "", "%s", g_Items[itemid].szDesc);
    
            char leveltype[32];
            UTIL_GetLevelType(client, itemid, STRING(leveltype));
            AddMenuItemEx(m_hMenu, (g_Items[itemid].iLevels == 0) ? ITEMDRAW_SPACER : ITEMDRAW_DISABLED, "", "%T", "Playerskins Level", client, g_Items[itemid].iLevels, leveltype);
            AddMenuItemEx(m_hMenu, (g_aCaseSkins[0].Length > 0) ? ITEMDRAW_DEFAULT : ITEMDRAW_SPACER, "4", "%T", "Open Case Available", client);
        }

        if(!m_bEquipped)
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Item Equip", client);
        else
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%T", "Item Unequip", client);

        if(StrEqual(g_TypeHandlers[g_Items[itemid].iHandler].szType, "playerskin") && LibraryExists("store-randomskin"))
        {
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "5", "%T", "random skin", client);
        }
    }
    else
    {
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Item Use", client);
    }

    if(!Store_IsItemInBoughtPackage(client, itemid))
    {
        int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, itemid)*0.6);
        if(m_iCredits!=0)
        {
            int uid = UTIL_GetClientItemId(client, itemid);
            if(g_ClientItem[client][uid].iDateOfExpiration != 0)
            {
                int m_iLength = g_ClientItem[client][uid].iDateOfExpiration-g_ClientItem[client][uid].iDateOfPurchase;
                int m_iLeft = g_ClientItem[client][uid].iDateOfExpiration-GetTime();
                if(m_iLeft < 0)
                    m_iLeft = 0;
                m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
            }

            AddMenuItemEx(m_hMenu, m_iCredits > 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "1", "%T", "Item Sell", client, m_iCredits);
            if(g_Items[itemid].bGiftable)
                AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Gift", client);
        }
    }

    for(int i = 0; i < g_iMenuHandlers; ++i)
    {
        if(g_MenuHandlers[i].hPlugin == null || !IsPluginRunning(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].szPlFile))
            continue;
        Call_StartFunction(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].fnMenu);
        Call_PushCellRef(m_hMenu);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish();
    }

    m_hMenu.Display(client, 0);
}

void DisplayPlanMenu(int client, int itemid)
{
    g_iMenuNum[client] = 1;

    Menu m_hMenu = new Menu(MenuHandler_Plan);
    m_hMenu.ExitBackButton = true;

    m_hMenu.SetTitle("%s\n%T\n ", g_Items[itemid].szName, "Title Credits", client, g_ClientData[client].iCredits);

    for(int i = 0; i < g_Items[itemid].iPlans; ++i)
    {
        AddMenuItemEx(m_hMenu, (g_ClientData[client].iCredits>=g_PurchasePlan[itemid][i].iPrice?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), "", "%T",  "Item Available", client, g_PurchasePlan[itemid][i].szName, g_PurchasePlan[itemid][i].iPrice);
    }
    
    m_hMenu.Display(client, 0);
}

// 合成菜单
void DisplayComposeMenu(int client, bool last)
{
    // data protection
    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        DisplayPreviewMenu(client, g_iSelectedItem[client]);
        return;
    }
    
    // 当前菜单层级
    g_iMenuNum[client] = 1;
    Menu m_hMenu = new Menu(MenuHandler_Compose);
    m_hMenu.ExitBackButton = true;
    
    // 合成道具1
    char sitem1[64];
    if(g_Compose[client].item1 >= 0)
        strcopy(STRING(sitem1), g_Items[g_Compose[client].item1].szName);
    else
        FormatEx(STRING(sitem1), "%T", "unselect", client);
    
    // 合成道具2
    char sitem2[64];
    if(g_Compose[client].item2 >= 0)
        strcopy(STRING(sitem2), g_Items[g_Compose[client].item2].szName);
    else
        FormatEx(STRING(sitem2), "%T", "unselect", client);

    m_hMenu.SetTitle("%T\n ", "Title Compose", client, g_Items[g_iSelectedItem[client]].szName, sitem1, sitem2);

    // 只能使用等级-1的物品, 比如5级皮肤只能用2个4级的合成
    int level = g_Items[g_iSelectedItem[client]].iLevels - 1;

    // 已选择全部道具
    if(!last)
    {
        char m_szId[8];
        for(int i = 0; i < g_iItems; ++i)
        {
            if(g_Items[i].iHandler == g_iPackageHandler)
                continue;
            
            if(!Store_HasClientItem(client, i))
                continue;

            if(i == g_Compose[client].item1 || i == g_Compose[client].item2)
                continue;

            if(!StrEqual(g_TypeHandlers[g_Items[i].iHandler].szType, "playerskin"))
                continue;

            // if level not match or is personal item.
            if (g_Items[i].iLevels != level || g_Items[i].bIgnore)
                continue;

            int uid = UTIL_GetClientItemId(client, i);
            
            if(uid < 0 || g_ClientItem[client][uid].iDateOfExpiration != 0)
                continue;

            IntToString(i, STRING(m_szId));
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, g_Items[i].szName);
        }
    }
    // 选择合成器
    else
    {
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "[30%%] Iron furnace (%s%t)",     g_szComposeFee[0], "credits");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "[40%%] Bronze furnace (%s%t)",   g_szComposeFee[1], "credits");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "[50%%] Silver furnace (%s%t)",   g_szComposeFee[2], "credits");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "[60%%] Gold furnace (%s%t)",     g_szComposeFee[3], "credits");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "4", "[70%%] Platinum furnace (%s%t)", g_szComposeFee[4], "credits");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "5", "[80%%] Diamond furnace (%s%t)",  g_szComposeFee[5], "credits");
    }

    if(m_hMenu.ItemCount > 0)
    {
        m_hMenu.Display(client, 0);
        return;
    }

    delete m_hMenu;
    tPrintToChat(client, "%T", "Compose no material", client);
    Store_DisplayPreviousMenu(client);
}

public int MenuHandler_Compose(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        // Confirmation was sent
        if(menu == null)
        {
            if(param2 == 0)
            {
                UTIL_ComposeItem(client);
            }
        }
        else
        {
            char m_szId[64];
            menu.GetItem(param2, STRING(m_szId));
            int itemid = StringToInt(m_szId);
            g_iMenuNum[client] = 1;
            if(g_Compose[client].item1==-1)
            {
                g_Compose[client].item1=itemid;
                DisplayComposeMenu(client, false);
            }
            else if(g_Compose[client].item2==-1)
            {
                g_Compose[client].item2=itemid;
                DisplayComposeMenu(client, true);
            }
            else if(0 <= itemid <= 5 && g_Compose[client].item1 >= 0 && g_Compose[client].item2 >= 0 && Store_HasClientItem(client, g_Compose[client].item1) && Store_HasClientItem(client, g_Compose[client].item2))
            {
                g_Compose[client].types=itemid;
                char m_szTitle[256];
                FormatEx(STRING(m_szTitle), "%T", "Confirm_Compose", client, g_Items[g_iSelectedItem[client]].szName, g_Items[g_Compose[client].item1].szName, g_Items[g_Compose[client].item2].szName, g_szComposeFee[itemid]);
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Compose, 0);
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
        {
            g_Compose[client].item1 = -1;
            g_Compose[client].item2 = -1;
            g_Compose[client].types = -1;
            Store_DisplayPreviousMenu(client);
        }
}

public int MenuHandler_Plan(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        g_iSelectedPlan[client]=param2;
        g_iMenuNum[client]=4;

        char m_szTitle[128];
        FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_Items[g_iSelectedItem[client]].szName, g_TypeHandlers[g_Items[g_iSelectedItem[client]].iHandler].szType);
        Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

public int MenuHandler_Item(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        // Confirmation was sent
        if(menu == null)
        {
            if(param2 == 0)
            {
                g_iMenuNum[client] = 1;
                UTIL_SellItem(client, g_iSelectedItem[client]);
            }
        }
        else
        {
            char m_szId[64];
            menu.GetItem(param2, STRING(m_szId));
            
            int m_iId = StringToInt(m_szId);
            
            // Menu handlers
            if(!(48 <= m_szId[0] <= 57)) //ASCII 0~9
            {
                int ret;
                for(int i=0;i<g_iMenuHandlers;++i)
                {
                    if(g_MenuHandlers[i].hPlugin == null || !IsPluginRunning(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].szPlFile))
                        continue;
                    Call_StartFunction(g_MenuHandlers[i].hPlugin, g_MenuHandlers[i].fnHandler);
                    Call_PushCell(client);
                    Call_PushString(m_szId);
                    Call_PushCell(g_iSelectedItem[client]);
                    Call_Finish(ret);

                    if(ret)
                        break;
                }
            }
            // Player wants to equip this item
            else if(m_iId == 0)
            {
                int m_iRet = UTIL_UseItem(client, g_iSelectedItem[client]);
                if(GetClientMenu(client)==MenuSource_None && m_iRet == 0)
                    DisplayItemMenu(client, g_iSelectedItem[client]);
            }
            // Player wants to sell this item
            else if(m_iId == 1)
            {
                int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, g_iSelectedItem[client])*0.6);
                int uid = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
                if(g_ClientItem[client][uid].iDateOfExpiration != 0)
                {
                    int m_iLength = g_ClientItem[client][uid].iDateOfExpiration-g_ClientItem[client][uid].iDateOfPurchase;
                    int m_iLeft = g_ClientItem[client][uid].iDateOfExpiration-GetTime();
                    if(m_iLeft < 0)
                        m_iLeft = 0;
                    m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
                }

                char m_szTitle[128];
                FormatEx(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_Items[g_iSelectedItem[client]].szName, g_TypeHandlers[g_Items[g_iSelectedItem[client]].iHandler].szType, m_iCredits);
                g_iMenuNum[client] = 2;
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Item, 0);
            }
            // Player wants to gift this item
            else if(m_iId == 2)
            {
                g_iMenuNum[client] = 2;
                DisplayPlayerMenu(client);
            }
            // Player wants to unequip this item
            else if(m_iId == 3)
            {
                UTIL_UnequipItem(client, g_iSelectedItem[client]);
                DisplayItemMenu(client, g_iSelectedItem[client]);
            }
            // Player want to open case
            else if(m_iId == 4)
            {
#if defined Module_Skin
                if(g_ClientData[client].iCredits >= g_inCase[1])
                    UTIL_OpenSkinCase(client);
                else
                    tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, g_inCase[1]);
#else
                tPrintToChat(client, "%T", "Open Case not available", client);
#endif
            }
            // call random skin plugin.
            else if(m_iId == 5)
            {
                FakeClientCommandEx(client, "sm_rs");
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

void DisplayPlayerMenu(int client)
{
    g_iMenuNum[client] = 3;

    Menu m_hMenu = new Menu(MenuHandler_Gift);
    m_hMenu.ExitBackButton = true;
    m_hMenu.SetTitle("%T\n%T\n ", "Title Gift", client, "Title Credits", client, g_ClientData[client].iCredits);

    char m_szID[11];
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientInGame(i) || IsFakeClient(i))
            continue;

        if(!AllowItemForAuth(client, g_Items[g_iSelectedItem[client]].szSteam) || !AllowItemForVIP(client, g_Items[g_iSelectedItem[client]].bVIP))
            continue;
        if(i != client && IsClientInGame(i) && !Store_HasClientItem(i, g_iSelectedItem[client]))
        {
            IntToString(g_ClientData[i].iUserId, STRING(m_szID));
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szID, "%N", i);
        }
    }
    
    if(m_hMenu.ItemCount <= 0)
    {
        delete m_hMenu;
        g_iMenuNum[client] = 1;
        DisplayItemMenu(client, g_iSelectedItem[client]);
        tPrintToChat(client, "%T", "Gift No Players", client);
        return;
    }

    m_hMenu.Display(client, 0);
}

public int MenuHandler_Gift(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {
        int m_iItem, m_iReceiver;
    
        // Confirmation was given
        if(menu == null)
        {
            m_iItem = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
            m_iReceiver = GetClientOfUserId(param2);
            if(!m_iReceiver)
            {
                tPrintToChat(client, "%T", "Gift Player Left", client);
                return;
            }
            UTIL_GiftItem(client, m_iReceiver, m_iItem);
            g_iMenuNum[client] = 1;
            Store_DisplayPreviousMenu(client);
        }
        else
        {
            char m_szId[11];
            menu.GetItem(param2, STRING(m_szId));
            
            int m_iId = StringToInt(m_szId);
            m_iReceiver = GetClientOfUserId(m_iId);
            if(!m_iReceiver)
            {
                tPrintToChat(client, "%T", "Gift Player Left", client);
                return;
            }

            m_iItem = UTIL_GetClientItemId(client, g_iSelectedItem[client]);
            
            char m_szTitle[128];
            int m_iFees = UTIL_GetClientHandleFees(client, g_iSelectedItem[client]);
            if(m_iFees > 0)
            {
                FormatEx(STRING(m_szTitle), "%T\n%T", "Confirm_Gift", client, g_Items[g_iSelectedItem[client]].szName, g_TypeHandlers[g_Items[g_iSelectedItem[client]].iHandler].szType, m_iReceiver, "Gift_Handing", client, m_iFees);
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Gift, m_iId);
            }
            else
                tPrintToChat(client, " {darkred}UNKNOWN ERROR{white} :  {red}%d", UTIL_GetRandomInt(100000, 999999));
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            DisplayItemMenu(client, g_iSelectedItem[client]);
}

public int MenuHandler_Confirm(Menu menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        delete menu;
    else if(action == MenuAction_Select)
    {        
        if(param2 == 0)
        {
            char m_szCallback[32];
            char m_szData[11];
            char m_szFile[64];
            menu.GetItem(0, STRING(m_szCallback));
            menu.GetItem(1, STRING(m_szData));
            DataPack pack = view_as<DataPack>(StringToInt(m_szCallback));
            Handle m_hPlugin = pack.ReadCell();
            Function fnMenuCallback = pack.ReadFunction();
            pack.ReadString(STRING(m_szFile));
            delete pack;
            if(m_hPlugin != null && fnMenuCallback != INVALID_FUNCTION && IsPluginRunning(m_hPlugin, m_szFile))
            {
                Call_StartFunction(m_hPlugin, fnMenuCallback);
                Call_PushCell(INVALID_HANDLE);
                Call_PushCell(MenuAction_Select);
                Call_PushCell(client);
                Call_PushCell(StringToInt(m_szData));
                Call_Finish();
            }
            else Store_DisplayPreviousMenu(client);
        }
        else Store_DisplayPreviousMenu(client);
    }
}

//////////////////////////////
//          TIMER           //
//////////////////////////////
public Action Timer_DababaseRetry(Handle timer, int retry)
{
    // Database is connected successfully
    if(g_hDatabase != null)
        return Plugin_Stop;

    if(retry >= 100)
    {
        SetFailState("Database connection failed to initialize after 100 retrie");
        return Plugin_Stop;
    }

    Database.Connect(SQLCallback_Connection, "csgo", retry);
 
    return Plugin_Stop;
}

//////////////////////////////
//       SQL CALLBACK       //
//////////////////////////////
public void SQLCallback_Connection(Database db, const char[] error, int retry)
{
    retry++;

    if(db == null || error[0])
    {
        LogStoreError("Failed to connect to SQL database. [%03d] Error: %s", retry, error);
        CreateTimer(5.0, Timer_DababaseRetry, retry);
        return;
    }

    // If it's already connected we are good to go
    if(g_hDatabase != null)
    {
        delete db;
        return;
    }

    g_hDatabase = db;

    // Do some housekeeping
    if(!g_hDatabase.SetCharset("utf8mb4"))
    {
        // if failure
        g_hDatabase.SetCharset("utf8");
    }

    char m_szQuery[256];
    FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `date_of_expiration` <> 0 AND `date_of_expiration` < %d", GetTime());
    SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);

    // Load configs
    UTIL_ReloadConfig();

    // if Loaded late.
    if(g_bLateLoad)
    {
        for(int client = 1; client <= MaxClients; ++client)
        {
            if(!IsClientConnected(client))
                continue;

            OnClientConnected(client);

            if(!IsClientInGame(client) || !IsClientAuthorized(client))
                continue;

            OnClientPostAdminCheck(client);
        }
    }
}

public void SQLCallback_LoadClientInventory_Credits(Database db, DBResultSet results, const char[] error, int userid)
{
    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if(!client || g_bInterMission)
        return;

    char m_szQuery[512], m_szSteamID[32];
    int m_iTime = GetTime();
    g_ClientData[client].iUserId = userid;
    g_ClientData[client].iItems = 0;
    GetClientAuthId(client, AuthId_Steam2, STRING(m_szSteamID), true);
    strcopy(g_ClientData[client].szAuthId, sizeof(Client_Data::szAuthId), m_szSteamID[8]);

    if(results.FetchRow() && results.RowCount > 0)
    {
        g_ClientData[client].iId = results.FetchInt(0);
        g_ClientData[client].iCredits = results.FetchInt(3);
        g_ClientData[client].iOriginalCredits = results.FetchInt(3);
        g_ClientData[client].iDateOfJoin = results.FetchInt(4);
        g_ClientData[client].iDateOfLastJoin = m_iTime;
        g_ClientData[client].bBan = (results.FetchInt(6) == 1 || g_ClientData[client].iCredits < 0) ? true : false;

        if(g_ClientData[client].bBan)
        {
            g_ClientData[client].iItems = 0;
            Call_OnClientLoaded(client);
        }
        else
        {
            FormatEx(STRING(m_szQuery), "SELECT `id`, `player_id`, `type`, `unique_id`, UNIX_TIMESTAMP(date_of_purchase) as `date_of_purchase`, date_of_expiration, price_of_purchase FROM store_items WHERE `player_id`=%d", g_ClientData[client].iId);
            g_hDatabase.Query(SQLCallback_LoadClientInventory_Items, m_szQuery, userid, DBPrio_Normal);
        }

        UTIL_LogMessage(client, 0, "Joined");
        g_iDataProtect[client] = GetTime()+90;
    }
    else
    {
        char m_szName[64], m_szEName[128];
        GetClientName(client, STRING(m_szName));
        g_hDatabase.Escape(m_szName, STRING(m_szEName));
        FormatEx(STRING(m_szQuery), "INSERT INTO store_players (`authid`, `name`, `credits`, `date_of_join`, `date_of_last_join`, `ban`) VALUES(\"%s\", '%s', 300, NOW(), NOW(), '0')", g_ClientData[client].szAuthId, m_szEName);
        g_hDatabase.Query(SQLCallback_InsertClient, m_szQuery, userid, DBPrio_High);
    }
}

public void SQLCallback_LoadClientInventory_Items(Database db, DBResultSet results, const char[] error, int userid)
{
    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if(!client || g_bInterMission)
        return;

    char m_szQuery[512];

    if(results.RowCount <= 0)
    {
        if(UTIL_GetTotalInventoryItems(client) > 0)
        {
            FormatEx(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_ClientData[client].iId);
            g_hDatabase.Query(SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid, DBPrio_High);
            return;
        }

        Call_OnClientLoaded(client);
        //FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d", g_ClientData[client].iId);
        //SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);

        return;
    }

    char m_szUniqueId[PLATFORM_MAX_PATH];
    char m_szType[16];
    int m_iExpiration;
    int m_iUniqueId;
    int m_iTime = GetTime();
    
    int i = 0;
    while(results.FetchRow())
    {
        m_iUniqueId = -1;
        m_iExpiration = results.FetchInt(5);
        if(m_iExpiration && m_iExpiration <= m_iTime)
            continue;
        
        results.FetchString(2, STRING(m_szType));
        results.FetchString(3, STRING(m_szUniqueId));

        while((m_iUniqueId = UTIL_GetItemId(m_szUniqueId, m_iUniqueId)) != -1)
        {
            g_ClientItem[client][i].iId = results.FetchInt(0);
            g_ClientItem[client][i].iUniqueId = m_iUniqueId;
            g_ClientItem[client][i].bSynced = true;
            g_ClientItem[client][i].bDeleted = false;
            g_ClientItem[client][i].iDateOfPurchase = results.FetchInt(4);
            g_ClientItem[client][i].iDateOfExpiration = m_iExpiration;
            g_ClientItem[client][i].iPriceOfPurchase = results.FetchInt(6);
            i++;
        }
    }
    g_ClientData[client].iItems = i;
    g_iDataProtect[client] = GetTime()+15;

#if defined DATA_VERIFY
    FormatEx(STRING(m_szQuery), "SELECT * FROM `store_newlogs` WHERE `store_id` = '%d' AND (`reason` = 'Disconnect' OR `reason` = 'Add Funds')  ORDER BY `timestamp` DESC LIMIT 1", g_ClientData[client].iId);
    g_hDatabase.Query(SQLCallback_LoadClientInventory_DATAVERIFY, m_szQuery, userid, DBPrio_Low);
#endif

    if(i > 0)
    {
        FormatEx(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_ClientData[client].iId);
        g_hDatabase.Query(SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid, DBPrio_Normal);
    }
    else
    {
        //FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d", g_ClientData[client].iId);
        //SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
        
        Call_OnClientLoaded(client);
    }
}

#if defined DATA_VERIFY
public void SQLCallback_LoadClientInventory_DATAVERIFY(Database db, DBResultSet results, const char[] error, int userid)
{
    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    if(results.FetchRow())
    {
        int client = GetClientOfUserId(userid);
        if(!client || g_bInterMission)
            return;
        
        int credits = results.FetchInt(0);
        
        int diff = g_ClientData[client].iCredits - credits;
        
        if(diff > 1000)
        {
            char m_szQuery[256];
            FormatEx(STRING(m_szQuery), "UPDATE `store_players` SET `ban` = 1, `credits` = -1 WHERE `id` = '%d';", g_ClientData[client].iId);
            SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);

            LogMessage("[CAT]  Store Inject detected :  \"%L\" -> credits[%d] -> loaded[%d] -> diff[%d]", client, credits, g_ClientData[client].iCredits, diff);
            ServerCommand("sm_ban #%d 0 \"[CAT] Store Inject detected.\"", GetClientUserId(client));
            //BanClient(client, 0, BANFLAG_IP|BANFLAG_AUTHID, "[CAT] Store Inject detected", "[CAT] Store Inject detected");
            return;
        }

        g_iDataProtect[client] = GetTime()+30;
    }
    else
    {
        int client = GetClientOfUserId(userid);
        if(!client)
            return;

        LogMessage("[CAT]  Store invalid data detected :  \"%L\" -> no results", client);
        KickClient(client, "[CAT] Store invalid data detected.");
    }
}
#endif

public void SQLCallback_LoadClientInventory_Equipment(Database db, DBResultSet results, const char[] error, int userid)
{
    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    int client = GetClientOfUserId(userid);
    if(!client || g_bInterMission)
        return;

    char m_szUniqueId[PLATFORM_MAX_PATH];
    char m_szType[16];
    int m_iUniqueId, m_iSlot;

    while(results.FetchRow())
    {
        results.FetchString(1, STRING(m_szType));
        results.FetchString(2, STRING(m_szUniqueId));
        m_iUniqueId = UTIL_GetItemId(m_szUniqueId);
        if(m_iUniqueId == -1)
            continue;

        m_iSlot = results.FetchInt(3);

        if(StrEqual(m_szType, "playerskin"))
        {
#if defined Global_Skin
            if(m_iSlot != 2)
                continue;
#else
            if(m_iSlot >= 2)
                continue;
#endif
        }

        if(Store_HasClientItem(client, m_iUniqueId))
            UTIL_UseItem(client, m_iUniqueId, true, m_iSlot);
        else
            UTIL_UnequipItem(client, m_iUniqueId);
    }

    Call_OnClientLoaded(client);
}

public void SQLCallback_InsertClient(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client || g_bInterMission)
        return;

    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        KickClient(client, "Failed to check your store account.");
        return;
    }

    g_ClientData[client].iId = results.InsertId;
    g_ClientData[client].iCredits = 300;
    g_ClientData[client].iOriginalCredits = 0;
    g_ClientData[client].iDateOfJoin = GetTime();
    g_ClientData[client].iDateOfLastJoin = g_ClientData[client].iDateOfJoin;
    g_ClientData[client].iItems = 0;
    
    Call_OnClientLoaded(client);

    g_iDataProtect[client] = GetTime()+90;
}

//////////////////////////////
//          STOCK           //
//////////////////////////////
void UTIL_LoadClientInventory(int client)
{
    if(g_hDatabase == null)
    {
        LogStoreError("Database connection is lost or not yet initialized.");
        return;
    }
    
    char m_szQuery[512];
    char m_szAuthId[32];

    GetClientAuthId(client, AuthId_Steam2, STRING(m_szAuthId), true);
    if(m_szAuthId[0] == 0 || g_bInterMission)
        return;

    FormatEx(STRING(m_szQuery), "SELECT `id`, `authid`, `name`, `credits`, UNIX_TIMESTAMP(date_of_join) as `date_of_join`, UNIX_TIMESTAMP(date_of_last_join) as `date_of_last_join`, `ban` FROM store_players WHERE `authid`=\"%s\"", m_szAuthId[8]);
    g_hDatabase.Query(SQLCallback_LoadClientInventory_Credits, m_szQuery, g_ClientData[client].iUserId, DBPrio_Normal);
}

void UTIL_SaveClientInventory(int client)
{
    if(g_hDatabase == null)
    {
        LogStoreError("Database connection is lost or not yet initialized.");
        return;
    }
    
    // Player disconnected before his inventory was even fetched
    if(!g_ClientData[client].bLoaded)
        return;

    char m_szQuery[512];
    char m_szType[16];
    char m_szUniqueId[PLATFORM_MAX_PATH];

    for(int i = 0; i < g_ClientData[client].iItems; ++i)
    {
        strcopy(STRING(m_szType), g_TypeHandlers[g_Items[g_ClientItem[client][i].iUniqueId].iHandler].szType);
        strcopy(STRING(m_szUniqueId), g_Items[g_ClientItem[client][i].iUniqueId].szUniqueId);
    
        if(!g_ClientItem[client][i].bSynced && !g_ClientItem[client][i].bDeleted)
        {
            g_ClientItem[client][i].bSynced = true;
            FormatEx(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", FROM_UNIXTIME(%d), %d, %d)", g_ClientData[client].iId, m_szType, m_szUniqueId, g_ClientItem[client][i].iDateOfPurchase, g_ClientItem[client][i].iDateOfExpiration, g_ClientItem[client][i].iPriceOfPurchase);
            SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
        }
        else if(g_ClientItem[client][i].bSynced && g_ClientItem[client][i].bDeleted)
        {
            // Might have been synced already but ID wasn't acquired
            if(g_ClientItem[client][i].iId==-1)
                FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `player_id`=%d AND `type`=\"%s\" AND `unique_id`=\"%s\"", g_ClientData[client].iId, m_szType, m_szUniqueId);
            else
                FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `id`=%d", g_ClientItem[client][i].iId);
            SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
            g_ClientItem[client][i].bSynced = false;
        }
    }
}

void UTIL_SaveClientEquipment(int client)
{
    if(g_hDatabase == null)
    {
        LogStoreError("Database connection is lost or not yet initialized.");
        return;
    }

    // Player disconnected before his inventory was even fetched
    if(!g_ClientData[client].bLoaded)
        return;

    char m_szQuery[512];
    int m_iId;
    for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
    {
        for(int a = 0; a < STORE_MAX_SLOTS; ++a)
        {
            m_iId = i*STORE_MAX_SLOTS+a;
            if(g_ClientData[client].aEquipmentSynced[m_iId] == g_ClientData[client].aEquipment[m_iId])
                continue;
            else if(g_ClientData[client].aEquipmentSynced[m_iId] != -2)
            {
                if(g_ClientData[client].aEquipment[m_iId]==-1)
                    FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_ClientData[client].iId, g_TypeHandlers[i].szType, a);
                else
                    FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_ClientData[client].iId, g_TypeHandlers[i].szType, g_Items[g_ClientData[client].aEquipment[m_iId]].szUniqueId, a);

                //FormatEx(STRING(m_szQuery), "UPDATE store_equipment SET `unique_id`=\"%s\" WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_Items[g_ClientData[client].aEquipment[m_iId]].szUniqueId, g_ClientData[client].iId, g_TypeHandlers[i].szType, a);
            }
            else
                FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_ClientData[client].iId, g_TypeHandlers[i].szType, g_Items[g_ClientData[client].aEquipment[m_iId]].szUniqueId, a);
            
            //FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d)", g_ClientData[client].iId, g_TypeHandlers[i].szType, g_Items[g_ClientData[client].aEquipment[m_iId]].szUniqueId, a);

            SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
            g_ClientData[client].aEquipmentSynced[m_iId] = g_ClientData[client].aEquipment[m_iId];
        }
    }
}

void UTIL_SaveClientData(int client, bool disconnect)
{
    if(g_hDatabase == null)
    {
        LogStoreError("Database connection is lost or not yet initialized.");
        return;
    }
    
    if(!g_ClientData[client].bLoaded)
        return;

    if(!disconnect && g_ClientData[client].bRefresh)
        return;
    
    char m_szQuery[512], m_szName[64], m_szEName[128];
    GetClientName(client, STRING(m_szName));
    g_hDatabase.Escape(m_szName, STRING(m_szEName));
    FormatEx(STRING(m_szQuery), "UPDATE store_players SET `credits`=`credits`+%d, `date_of_last_join`=FROM_UNIXTIME(%d), `name`='%s' WHERE `id`=%d", g_ClientData[client].iCredits-g_ClientData[client].iOriginalCredits, g_ClientData[client].iDateOfLastJoin, m_szEName, g_ClientData[client].iId);

    if(disconnect)
    {
        g_ClientData[client].iOriginalCredits = g_ClientData[client].iCredits;
        SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_High);
        UTIL_LogMessage(client, 0, "Disconnect");
    }
    else
    {
        g_ClientData[client].bRefresh = true;
        g_hDatabase.Query(SQLCallback_RefreshCredits, m_szQuery, GetClientUserId(client), DBPrio_High);
    }
}

public void SQLCallback_RefreshCredits(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    
    g_ClientData[client].bRefresh = false;
    
    if(results == null || error[0])
    {
        LogStoreError("Refresh \"%L\" data failed :  %s", client, error);
        return;
    }

    g_ClientData[client].iOriginalCredits = g_ClientData[client].iCredits;
}

void UTIL_DisconnectClient(int client, bool pre = false)
{
    ClearTimer(g_ClientData[client].hTimer);

    if(pre)
    {
        g_ClientData[client].iCredits         = 0;
        g_ClientData[client].iOriginalCredits = 0;
        g_ClientData[client].iItems           = 0;
    }

    g_ClientData[client].bLoaded = false;
}

int UTIL_GetItemId(const char[] uid, int start = -1)
{
    for(int i = start+1; i < g_iItems; ++i)
        if(strcmp(g_Items[i].szUniqueId, uid)==0 && g_Items[i].iPrice >= 0)
            return i;
    return -1;
}

public void SQLCallback_BuyItem(Database db, DBResultSet results, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(results == null || error[0])
    {
        LogStoreError("Error happened. Error: %s", error);
        return;
    }

    if(!results.FetchRow())
        return;

    int dbCredits = results.FetchInt(0);
    int itemid = g_iSelectedItem[client];
    int plan = g_iSelectedPlan[client];

    int m_iPrice = 0;
    if(plan==-1)
        m_iPrice = g_Items[itemid].iPrice;
    else
        m_iPrice = g_PurchasePlan[itemid][plan].iPrice;    
    
    if(dbCredits != g_ClientData[client].iOriginalCredits)
    {
        int diff = dbCredits - g_ClientData[client].iOriginalCredits;
        g_ClientData[client].iOriginalCredits = dbCredits;
        g_ClientData[client].iCredits += diff;
        UTIL_LogMessage(client, diff, "Credits changed in database (sync credits from database)");
    }
    
    g_ClientData[client].bRefresh = false;

    if(g_ClientData[client].iCredits<m_iPrice || g_Items[itemid].bCompose)
    {
        DisplayItemMenu(client, g_iSelectedItem[client]);
        return;
    }

    Action ret = Plugin_Continue;
    Call_StartForward(g_hOnClientBuyItem);
    Call_PushCell(client);
    Call_PushString(g_Items[itemid].szUniqueId);
    Call_PushCell(plan==-1 ? 0 : g_PurchasePlan[itemid][plan].iTime);
    Call_PushCell(m_iPrice);
    Call_Finish(ret);

    if (ret > Plugin_Continue)
    {
        // blocked
        return;
    }

    if(g_ClientData[client].iItems == -1)
        g_ClientData[client].iItems = 0;

    if (!g_TypeHandlers[g_Items[itemid].iHandler].bDisposable)
    {
        int m_iId = g_ClientData[client].iItems++;
        g_ClientItem[client][m_iId].iId = -1;
        g_ClientItem[client][m_iId].iUniqueId = itemid;
        g_ClientItem[client][m_iId].iDateOfPurchase = GetTime();
        g_ClientItem[client][m_iId].iDateOfExpiration = (plan==-1?0:(g_PurchasePlan[itemid][plan].iTime?GetTime()+g_PurchasePlan[itemid][plan].iTime:0));
        g_ClientItem[client][m_iId].iPriceOfPurchase = m_iPrice;
        g_ClientItem[client][m_iId].bSynced = false; //true
        g_ClientItem[client][m_iId].bDeleted = false;
    }

    g_ClientData[client].iCredits -= m_iPrice;
    UTIL_LogMessage(client, -m_iPrice, "Bought %s %s", g_Items[itemid].szName, g_TypeHandlers[g_Items[itemid].iHandler].szType);

    Store_SaveClientAll(client);

    tPrintToChat(client, "%T", "Chat Bought Item", client, g_Items[itemid].szName, g_TypeHandlers[g_Items[itemid].iHandler].szType);

    Call_StartForward(g_hOnClientPurchased);
    Call_PushCell(client);
    Call_PushString(g_Items[itemid].szUniqueId);
    Call_PushCell(plan==-1 ? 0 : g_PurchasePlan[itemid][plan].iTime);
    Call_PushCell(m_iPrice);
    Call_Finish();

    DisplayItemMenu(client, g_iSelectedItem[client]);
}

void UTIL_ComposeItem(int client)
{
    if(g_Compose[client].item2 < 0 || g_Compose[client].item1 < 0 || g_Compose[client].types < 0 || g_iSelectedItem[client] < 0 || g_bInterMission)
        return;
    
    if(!Store_HasClientItem(client, g_Compose[client].item2) || !Store_HasClientItem(client, g_Compose[client].item1) || Store_HasClientItem(client, g_iSelectedItem[client]))
        return;
    
    int m_iFees = StringToInt(g_szComposeFee[g_Compose[client].types]);

    if(Store_GetClientCredits(client) < m_iFees)
    {
        tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
        return;
    }

    int level = g_Items[g_iSelectedItem[client]].iLevels - 1;
    if (g_Items[g_Compose[client].item2].iLevels < level || g_Items[g_Compose[client].item1].iLevels < level)
    {
        tPrintToChat(client, "%T", "Compose no material", client);
        return;
    }

    int probability = 0;
    switch(g_Compose[client].types)
    {
        case 0 : probability = 300000;
        case 1 : probability = 400000;
        case 2 : probability = 500000;
        case 3 : probability = 600000;
        case 4 : probability = 700000;
        case 5 : probability = 800000;
        default: probability =      1;
    }

    int successful = UTIL_GetRandomInt(0, 1000000);

    LogMessage("PreCompose -> %L -> compose -> %s -> %s -> [%s:%s] -> [%s:%s] -> %d -> %d -> %d", 
        client, 
        g_Items[g_iSelectedItem[client]].szUniqueId, 
        g_Items[g_iSelectedItem[client]].szName,
        g_Items[g_Compose[client].item1].szUniqueId,
        g_Items[g_Compose[client].item2].szUniqueId,
        g_Items[g_Compose[client].item1].szName,
        g_Items[g_Compose[client].item2].szName,
        m_iFees,
        probability,
        successful);

    Action res = Plugin_Continue;
    Call_StartForward(g_hOnClientComposing);
    Call_PushCell(client);
    Call_PushCellRef(successful);
    Call_PushCell(g_iSelectedItem[client]);
    Call_PushString(g_Items[g_iSelectedItem[client]].szUniqueId);
    Call_PushString(g_Items[g_iSelectedItem[client]].szName);
    Call_PushString(g_Items[g_Items[g_iSelectedItem[client]].iParent].szName);
    Call_Finish(res);
    if (res >= Plugin_Handled)
    {
        // block outside
        return;
    }

    LogMessage("PostCompose -> %L -> compose -> %s -> %s -> [%s:%s] -> [%s:%s] -> %d -> %d -> %d", 
        client, 
        g_Items[g_iSelectedItem[client]].szUniqueId, 
        g_Items[g_iSelectedItem[client]].szName,
        g_Items[g_Compose[client].item1].szUniqueId,
        g_Items[g_Compose[client].item2].szUniqueId,
        g_Items[g_Compose[client].item1].szName,
        g_Items[g_Compose[client].item2].szName,
        m_iFees,
        probability,
        successful);

    char reason[128];
    FormatEx(STRING(reason), "Compose Fee[%s]", g_Items[g_iSelectedItem[client]].szName);
    Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, reason);

    char m_szQuery[256];

    if(successful >= probability)
    {
        int rd = UTIL_GetRandomInt(0, 1000000);
        Store_RemoveItem(client, rd > 500000 ? g_Compose[client].item2 : g_Compose[client].item1);
        tPrintToChat(client, "%t", "Compose Failed");
        //tPrintToChat(client, "%t {green} %s", "Compose lost", rd > 500000 ? g_Items[g_Compose[client].item2].szName : g_Items[g_Compose[client].item1].szName);
        tPrintToChat(client, "%t {orange}%d%t", "Compose cost", m_iFees, "credits");
        Store_SaveClientAll(client);
        g_iDataProtect[client] = GetTime()+30;
        Call_StartForward(g_hOnClientComposed);
        Call_PushCell(client);
        Call_PushCell(false);
        Call_PushCell(g_iSelectedItem[client]);
        Call_PushString(g_Items[g_iSelectedItem[client]].szName);
        Call_PushString(g_Items[g_Items[g_iSelectedItem[client]].iParent].szName);
        Call_Finish();
        FormatEx(STRING(m_szQuery), "INSERT INTO store_compose VALUES (DEFAULT, %d, '%s', '%s', '%s', 0, DEFAULT)", g_ClientData[client].iId, g_Items[g_iSelectedItem[client]].szUniqueId, g_Items[g_Compose[client].item1].szUniqueId, g_Items[g_Compose[client].item2].szUniqueId);
        SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
        return;
    }

    Store_RemoveItem(client, g_Compose[client].item1);
    Store_RemoveItem(client, g_Compose[client].item2);
    Store_GiveItem(client, g_iSelectedItem[client], GetTime(), 0, -13);
    
    Store_SaveClientAll(client);
    
    g_iDataProtect[client] = GetTime()+30;

    tPrintToChat(client, "Compose successfully", client, g_Items[g_iSelectedItem[client]].szName);

    tPrintToChatAll("%t", "Compose successfully broadcast", client, g_Items[g_iSelectedItem[client]].szName);

    Call_StartForward(g_hOnClientComposed);
    Call_PushCell(client);
    Call_PushCell(true);
    Call_PushCell(g_iSelectedItem[client]);
    Call_PushString(g_Items[g_iSelectedItem[client]].szName);
    Call_PushString(g_Items[g_Items[g_iSelectedItem[client]].iParent].szName);
    Call_Finish();

    FormatEx(STRING(m_szQuery), "INSERT INTO store_compose VALUES (DEFAULT, %d, '%s', '%s', '%s', 1, DEFAULT)", g_ClientData[client].iId, g_Items[g_iSelectedItem[client]].szUniqueId, g_Items[g_Compose[client].item1].szUniqueId, g_Items[g_Compose[client].item2].szUniqueId);
    SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
}

void UTIL_BuyItem(int client)
{
#if defined Module_Skin
    if(g_tKillPreview[client] != null) TriggerTimer(g_tKillPreview[client], false);
#endif

    if(g_Items[g_iSelectedItem[client]].iHandler == g_iPackageHandler)
        return;

    if(Store_HasClientItem(client, g_iSelectedItem[client]))
    {
        DisplayItemMenu(client, g_iSelectedItem[client]);
        return;
    }

    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        Store_DisplayPreviousMenu(client);
        return;
    }
    g_iDataProtect[client] = GetTime()+15;
    char m_szQuery[255];
    FormatEx(STRING(m_szQuery), "SELECT credits FROM store_players WHERE `id`=%d", g_ClientData[client].iId);
    g_hDatabase.Query(SQLCallback_BuyItem, m_szQuery, g_ClientData[client].iUserId, DBPrio_High);
    g_ClientData[client].bRefresh = true;
}

void UTIL_SellItem(int client, int itemid)
{
    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        Store_DisplayPreviousMenu(client);
        return;
    }

    g_iDataProtect[client] = GetTime()+15;
    int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, itemid)*0.6);
    if (m_iCredits <= 0)
        return;
    int uid = UTIL_GetClientItemId(client, itemid);
    if(g_ClientItem[client][uid].iDateOfExpiration != 0)
    {
        int m_iLength = g_ClientItem[client][uid].iDateOfExpiration-g_ClientItem[client][uid].iDateOfPurchase;
        int m_iLeft = g_ClientItem[client][uid].iDateOfExpiration-GetTime();
        if(m_iLeft<0)
            m_iLeft = 0;
        m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
    }
    g_ClientData[client].iCredits += m_iCredits;
    tPrintToChat(client, "%T", "Chat Sold Item", client, g_Items[itemid].szName, g_TypeHandlers[g_Items[itemid].iHandler].szType);

    UTIL_LogMessage(client, m_iCredits, "Sold %s %s", g_Items[itemid].szName, g_TypeHandlers[g_Items[itemid].iHandler].szType);

    Store_RemoveItem(client, itemid);

    Store_SaveClientAll(client);
    
    Store_DisplayPreviousMenu(client);
}

void UTIL_GiftItem(int client, int receiver, int item)
{
    int m_iId = g_ClientItem[client][item].iUniqueId;

    if(!g_ClientData[client].bLoaded || !g_ClientData[receiver].bLoaded)
        return;

    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        Store_DisplayPreviousMenu(client);
        return;
    }
    
    if(IsFakeClient(receiver) || IsClientSourceTV(receiver))
    {
        tPrintToChat(client, "%T", "receiver BOT");
        return;
    }

    g_iDataProtect[client] = GetTime()+15;
    g_iDataProtect[receiver] = GetTime()+15;

    int m_iFees = UTIL_GetClientHandleFees(client, m_iId);
    
    if(m_iFees < 0)
    {
        tPrintToChat(client, " {darkred}UNKNOWN ERROR{white} :  {red}%d", UTIL_GetRandomInt(100000, 999999));
        return;
    }

    if(m_iFees > g_ClientData[client].iCredits)
    {
        tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
        return;
    }

    char reason[128];
    FormatEx(STRING(reason), "Giftd [%s] Fee", g_Items[m_iId].szName);
    Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, reason);

    g_ClientItem[client][item].bDeleted = true;
    UTIL_UnequipItem(client, m_iId);

    if(g_ClientData[receiver].iItems == -1)
        g_ClientData[receiver].iItems = 0;

    int id = g_ClientData[receiver].iItems++;

    g_ClientItem[receiver][id].iId = -1;
    g_ClientItem[receiver][id].iUniqueId = m_iId;
    g_ClientItem[receiver][id].bSynced = false;
    g_ClientItem[receiver][id].bDeleted = false;
    g_ClientItem[receiver][id].iDateOfPurchase = g_ClientItem[client][item].iDateOfPurchase;
    g_ClientItem[receiver][id].iDateOfExpiration = g_ClientItem[client][item].iDateOfExpiration;
    g_ClientItem[receiver][id].iPriceOfPurchase = g_ClientItem[client][item].iPriceOfPurchase;

    tPrintToChat(client, "%T", "Chat Gift Item Sent", client, receiver, g_Items[m_iId].szName, g_TypeHandlers[g_Items[m_iId].iHandler].szType);
    tPrintToChat(receiver, "%T", "Chat Gift Item Received", receiver, client, g_Items[m_iId].szName, g_TypeHandlers[g_Items[m_iId].iHandler].szType);

    UTIL_LogMessage(client  , 0, "Giftd %s to %N[%s]", g_Items[m_iId].szName, receiver, g_ClientData[receiver].szAuthId);
    UTIL_LogMessage(receiver, 0, "Received %s from %N[%s]", g_Items[m_iId].szName, client, g_ClientData[client].szAuthId);

    Store_SaveClientAll(client);
    Store_SaveClientAll(receiver);
}

int UTIL_GetClientItemId(int client, int itemid)
{
    for(int i = 0; i < g_ClientData[client].iItems; ++i)
    if(g_ClientItem[client][i].iUniqueId == itemid && !g_ClientItem[client][i].bDeleted)
        return i;
    return -1;
}

void Store_ResetAll()
{
    for(int x = 0; x < 3; ++x) g_aCaseSkins[x].Clear();

    for(int i = 0; i < g_iTypeHandlers; ++i)
    {
        g_TypeHandlers[i].szType[0]   = '\0';
        g_TypeHandlers[i].bEquipable  = false;
        g_TypeHandlers[i].bRaw        = false;
        g_TypeHandlers[i].bDisposable = false;
        g_TypeHandlers[i].hPlugin     = INVALID_HANDLE;
        g_TypeHandlers[i].fnMapStart  = INVALID_FUNCTION;
        g_TypeHandlers[i].fnReset     = INVALID_FUNCTION;
        g_TypeHandlers[i].fnConfig    = INVALID_FUNCTION;
        g_TypeHandlers[i].fnUse       = INVALID_FUNCTION;
        g_TypeHandlers[i].fnRemove    = INVALID_FUNCTION;
    }

    g_iItems = 0;
    g_iTypeHandlers = 0;
    g_iMenuHandlers = 0;
    
    // Initiaze the fake package handler
    g_iPackageHandler = Store_RegisterHandler("package", INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION);
}

void UTIL_ReloadConfig()
{
    Store_ResetAll();

    Call_StartForward(g_hOnStoreInit);
    Call_PushCell(GetMyHandle());
    Call_Finish();

    // Initiaze module
    UTIL_CheckModules();

    for(int i = 0; i < g_iTypeHandlers; ++i)
    if(g_TypeHandlers[i].fnReset != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[i].hPlugin, g_TypeHandlers[i].szPlFile))
    {
        Call_StartFunction(g_TypeHandlers[i].hPlugin, g_TypeHandlers[i].fnReset);
        Call_Finish();
    }

    g_hDatabase.Query(SQL_LoadParents, "SELECT * FROM store_item_parent ORDER BY `parent` ASC, `id` ASC;", 0, DBPrio_High);
}

public void SQL_LoadParents(Database db, DBResultSet item_parent, const char[] error, any data)
{
    if(item_parent == null)
        SetFailState("Can not retrieve item.parent from database: %s", error);

    if(item_parent.RowCount <= 0)
        SetFailState("Can not retrieve item.parent from database: no result row");

    g_smParentMap.Clear();

    char parent_str[12];

    int validCategories = 0;
    while(item_parent.FetchRow())
    {
        // Store to Map
        IntToString(item_parent.FetchInt(0), STRING(parent_str));
        if(!g_smParentMap.SetValue(parent_str, g_iItems, true))
        {
            LogStoreError("Failed to bind itemId[%d] to parentId[%s]", g_iItems, parent_str);
            continue;
        }

        // name
        item_parent.FetchString(1, g_Items[g_iItems].szName, sizeof(Store_Item::szName));

        // parent
        g_Items[g_iItems].iParent = item_parent.FetchInt(2);

        // package handler
        g_Items[g_iItems].iHandler = g_iPackageHandler;

        g_iItems++;
        validCategories++;
    }

    if (validCategories == 0)
        SetFailState("Can not retrieve item.parent from database: fetched %d rows, but they are invalid.", item_parent.RowCount);
    
    // Refresh Parent's parent.
    for(int parent = 0; parent < g_iItems; parent++)
    {
        // Interval
        g_Items[parent].iParent = UTIL_GetParent(parent, g_Items[parent].iParent);
    }

#if defined Global_Skin
    g_hDatabase.Query(SQL_LoadChildren, "SELECT a.*,b.name as title FROM store_item_child a LEFT JOIN store_item_parent b ON b.id = a.parent ORDER BY b.id ASC, a.parent ASC, a.pm ASC", 0, DBPrio_High);
#else
    g_hDatabase.Query(SQL_LoadChildren, "SELECT a.*,b.name as title FROM store_item_child a LEFT JOIN store_item_parent b ON b.id = a.parent ORDER BY b.id ASC, a.team ASC, a.parent ASC, a.pm ASC", 0, DBPrio_High);
#endif
}

public void SQL_LoadChildren(Database db, DBResultSet item_child, const char[] error, any data)
{
    if(item_child == null)
        SetFailState("Can not retrieve item.child from database: %s", error);

    if(item_child.RowCount <= 0)
        SetFailState("Can not retrieve item.child from database: no result row");

    ArrayList item_array = new ArrayList(ByteCountToCells(32));

    int validItems = 0;
    while(item_child.FetchRow())
    {
        // Field 1 -> type
        char m_szType[32];
        item_child.FetchString(1, STRING(m_szType));
        if(strcmp(m_szType, "ITEM_ERROR") == 0)
        {
            //LogStoreError("Failed to loaded %s -> ITEM_ERROR", g_Items[g_iItems].szName);
            continue;
        }

        int m_iHandler = UTIL_GetTypeHandler(m_szType);
        if(m_iHandler == -1)
        {
            //LogStoreError("Failed to loaded %s -> Invalid m_iHandler", g_Items[g_iItems].szName);
            continue;
        }
        g_Items[g_iItems].iHandler = m_iHandler;
        
        // Field 2 -> uid
        char m_szUniqueId[32];
        item_child.FetchString(2, STRING(m_szUniqueId));

        // Ignore bad item or dumplicate item
        if(strcmp(m_szUniqueId, "ITEM_ERROR") == 0 || item_array.FindString(m_szUniqueId) != -1)
        {
            //LogStoreError("Failed to loaded %s -> Ignore bad item or dumplicate item", g_Items[g_iItems].szName);
            continue;
        }
        item_array.PushString(m_szUniqueId);
        g_Items[g_iItems].szUniqueId[0] = '\0';
        strcopy(g_Items[g_iItems].szUniqueId, sizeof(Store_Item::szUniqueId), m_szUniqueId);

        // Field 3 -> buyable
        char m_bitBuyable[2];
        item_child.FetchString(3, m_bitBuyable, 2);
        g_Items[g_iItems].bBuyable = (m_bitBuyable[0] == 1) ? true : false;

        // Field 4 -> giftable
        char m_bitGiftable[2];
        item_child.FetchString(4, m_bitGiftable, 2);
        g_Items[g_iItems].bGiftable = (m_bitGiftable[0] == 1) ? true : false;

        // Field 5 -> only
        char m_bitOnly[2];
        item_child.FetchString(5, m_bitOnly, 2);
        g_Items[g_iItems].bIgnore = (m_bitOnly[0] == 1) ? true : false;

        // Field 6 -> auth
        char m_szAuth[256];
        item_child.FetchString(6, STRING(m_szAuth));
        g_Items[g_iItems].szSteam[0] = '\0';
        if(strcmp(m_szAuth, "ITEM_NOT_PERSONAL") != 0)
            strcopy(g_Items[g_iItems].szSteam, sizeof(Store_Item::szSteam), m_szAuth);

        // Field 7 -> vip
        char m_bitVIP[2];
        item_child.FetchString(7, m_bitVIP, 2);
        g_Items[g_iItems].bVIP = (m_bitVIP[0] == 1) ? true : false;

        // Field 8 -> name
        item_child.FetchString(8, g_Items[g_iItems].szName, sizeof(Store_Item::szName));

        // Field 9 -> lvls
        g_Items[g_iItems].iLevels = item_child.FetchInt(9);
        if (g_Items[g_iItems].iLevels > MAX_SKIN_LEVEL) // override to max
            g_Items[g_iItems].iLevels = MAX_SKIN_LEVEL;

        // Field 10 -> desc
        char m_szDesc[128];
        item_child.FetchString(10, STRING(m_szDesc));
        g_Items[g_iItems].szDesc[0] = '\0';
        if(StrContains(m_szDesc, "ITEM_NO") == -1)
            strcopy(g_Items[g_iItems].szDesc, sizeof(Store_Item::szDesc), m_szDesc);

        // Field 11 -> case
        int caseType = item_child.FetchInt(11);
        g_Items[g_iItems].iCaseType = caseType;

        // Field 12 -> Compose
        char m_bitCompose[2];
        item_child.FetchString(12, m_bitCompose, 2);
        g_Items[g_iItems].bCompose = (m_bitCompose[0] == 1) ? true : false;

        // Field 13,14,15 -> price
        int price_1d = item_child.FetchInt(13);
        int price_1m = item_child.FetchInt(14);
        int price_pm = item_child.FetchInt(15);

        // skip m_nBody
        // #18

        // team
        g_Items[g_iItems].iTeam = item_child.FetchInt(19);
        
        if(price_1d != 0 || price_1m != 0)
        {
            g_Items[g_iItems].iPlans = 0;

            if(price_1d > 0)
            {
                strcopy(g_PurchasePlan[g_iItems][0].szName, sizeof(Item_Plan::szName), "1 day");
                g_PurchasePlan[g_iItems][0].iPrice = price_1d;
                g_PurchasePlan[g_iItems][0].iTime = 86400;
                g_Items[g_iItems].iPlans++;
            }
            
            if(price_1m > 0)
            {
                strcopy(g_PurchasePlan[g_iItems][1].szName, sizeof(Item_Plan::szName), "1 month");
                g_PurchasePlan[g_iItems][1].iPrice = price_1m;
                g_PurchasePlan[g_iItems][1].iTime = 2592000;
                g_Items[g_iItems].iPlans++;
            }
            
            if(price_pm > 0)
            {
                strcopy(g_PurchasePlan[g_iItems][2].szName, sizeof(Item_Plan::szName), "Permanent");
                g_PurchasePlan[g_iItems][2].iPrice = price_pm;
                g_PurchasePlan[g_iItems][2].iTime = 0;
                g_Items[g_iItems].iPlans++;
            }
        }
        else
        {
            g_Items[g_iItems].iPrice = price_pm;
        }

        // Field 16 ~ 
        KeyValues kv = new KeyValues("Store", "", "");
        kv.JumpToKey(g_Items[g_iItems].szName, true);
        //for(int field = 16; field < item_child.FieldCount; ++field)
        int count = item_child.FieldCount - 1;
        for(int field = 1; field < count; ++field)
        {
            char key[32], values[192];
            item_child.FieldNumToName(field, STRING(key));
            item_child.FetchString(field, STRING(values));
            if(StrContains(values, "ITEM_NO") == -1)
                kv.SetString(key, values);
        }

        bool m_bSuccess = true;
        if(g_TypeHandlers[m_iHandler].fnConfig != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[m_iHandler].hPlugin, g_TypeHandlers[m_iHandler].szPlFile))
        {
            Call_StartFunction(g_TypeHandlers[m_iHandler].hPlugin, g_TypeHandlers[m_iHandler].fnConfig);
            Call_PushCell(kv);
            Call_PushCell(g_iItems);
            Call_Finish(m_bSuccess); 
        }

        delete kv;
        
        //LogMessage("Loaded Item -> %s", g_Items[g_iItems].szName);

        if(!m_bSuccess)
            continue;
        
        // Field 0 -> parent
        g_Items[g_iItems].iParent = UTIL_GetParent(g_iItems, item_child.FetchInt(0));
        
        if(g_Items[g_iItems].iParent == -1)
            continue;

        if(!g_Items[g_iItems].bIgnore && strcmp(m_szType, "playerskin", false) == 0 && caseType >= 0 && caseType <= 2)
        {
            g_aCaseSkins[caseType].PushString(m_szUniqueId);
        }

        g_iItems++;
        validItems++;
    }

    if (validItems == 0)
        SetFailState("Can not retrieve item.child from database: fetched %d rows, but they are invalid.", item_child.RowCount);

    ArrayList items = new ArrayList(sizeof(Store_Item));

    for(int itemid = 0; itemid < g_iItems; ++itemid)
    {
        items.PushArray(g_Items[itemid]);
    }

    Call_StartForward(g_hOnStoreAvailable);
    Call_PushCell(items);
    Call_Finish();

    delete items;
    delete item_array;

    if (FindPluginByFile("sm_downloader.smx") != INVALID_HANDLE)
    {
        LogMessage("Force reload downloader plugin.");
        ServerCommand("sm plugins reload sm_downloader.smx");
    }

    char map[128];
    GetCurrentMap(STRING(map));
    if(strlen(map) > 3 && IsMapValid(map))
    {
        LogMessage("Force reload map to prevent server crash!"); //late precache will crash server.
        ForceChangeLevel(map, "Reload Map to prevent server crash!");
    }
}

int UTIL_GetParent(int itemId, int parentId)
{
    if(parentId > -1)
    {
        int index;
        char parent_str[12];
        IntToString(parentId, STRING(parent_str));

        if(!g_smParentMap.GetValue(parent_str, index))
        {
            LogStoreError("Id [%s] not found in parent_map -> %s", parent_str, g_Items[itemId].szName);
            return -1;
        }

        return index;
    }

    return -1;
}

int UTIL_GetTypeHandler(const char[] type)
{
    for(int i = 0; i < g_iTypeHandlers; ++i)
    if(strcmp(g_TypeHandlers[i].szType, type)==0)
        return i;
    return -1;
}

int UTIL_GetMenuHandler(const char[] id)
{
    for(int i = 0; i < g_iMenuHandlers; ++i)
    if(strcmp(g_MenuHandlers[i].szIdentifier, id)==0)
        return i;
    return -1;
}

bool UTIL_IsEquipped(int client, int itemid)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    if(g_ClientData[client].aEquipment[g_Items[itemid].iHandler*STORE_MAX_SLOTS+i] == itemid)
        return true;
    return false;
}

int UTIL_GetExpiration(int client, int itemid)
{
    //if(g_Items[itemid].bVIP && AllowItemForVIP(client, true))
    if(g_Items[itemid].bVIP && AllowItemForVIP(client, true) && g_Items[itemid].iPrice <= 0 && g_Items[itemid].iPlans==0)
        return 0;

    if(g_Items[itemid].bIgnore && strlen(g_Items[itemid].szSteam) > 3 && AllowItemForAuth(client, g_Items[itemid].szSteam))
        return 0;

    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid < 0) return -1; //ThrowError("UTIL_GetExpiration -> %L -> %d -> uid -1", client, itemid);
    return g_ClientItem[client][uid].iDateOfExpiration;
}

int UTIL_UseItem(int client, int itemid, bool synced = false, int slot = 0)
{
    int m_iSlot = slot;
    if(g_TypeHandlers[g_Items[itemid].iHandler].fnUse != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].szPlFile))
    {
        int m_iReturn = -1;
        Call_StartFunction(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].fnUse);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(m_iReturn);
        
        if(m_iReturn != -1)
            m_iSlot = m_iReturn;
    }

    if(g_TypeHandlers[g_Items[itemid].iHandler].bEquipable)
    {
        g_ClientData[client].aEquipment[g_Items[itemid].iHandler*STORE_MAX_SLOTS+m_iSlot]=itemid;
        if(synced)
            g_ClientData[client].aEquipmentSynced[g_Items[itemid].iHandler*STORE_MAX_SLOTS+m_iSlot]=itemid;
    }
    else if(m_iSlot == 0)
    {
        Store_RemoveItem(client, itemid);
        return 1;
    }
    return 0;
}

int UTIL_UnequipItem(int client, int itemid, bool fn = true)
{
    int m_iSlot = 0;
    if(fn && itemid > 0 && g_TypeHandlers[g_Items[itemid].iHandler].fnRemove != INVALID_FUNCTION && IsPluginRunning(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].szPlFile))
    {
        Call_StartFunction(g_TypeHandlers[g_Items[itemid].iHandler].hPlugin, g_TypeHandlers[g_Items[itemid].iHandler].fnRemove);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(m_iSlot);
    }

    int m_iId;
    if(g_Items[itemid].iHandler != g_iPackageHandler)
    {
        m_iId = g_Items[itemid].iHandler*STORE_MAX_SLOTS+m_iSlot;
        if(g_ClientData[client].aEquipmentSynced[m_iId]==-2)
            g_ClientData[client].aEquipment[m_iId]=-2;
        else
            g_ClientData[client].aEquipment[m_iId]=-1;
    }
    else
    {
        for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
        {
            for(int a = 0; i < STORE_MAX_SLOTS; ++i)
            {
                if(g_ClientData[client].aEquipment[i+a] < 0)
                    continue;
                m_iId = i*STORE_MAX_SLOTS+a;
                if(Store_IsItemInBoughtPackage(client, g_ClientData[client].aEquipment[m_iId], itemid))
                    if(g_ClientData[client].aEquipmentSynced[m_iId]==-2)
                        g_ClientData[client].aEquipment[m_iId]=-2;
                    else
                        g_ClientData[client].aEquipment[m_iId]=-1;
            }
        }
    }
}

int UTIL_GetEquippedItemFromHandler(int client, int handler, int slot = 0)
{
    return g_ClientData[client].aEquipment[handler*STORE_MAX_SLOTS+slot];
}

bool UTIL_PackageHasClientItem(int client, int packageid, bool invmode = false)
{
    if(g_Items[packageid].szSteam[0] != 0 && !AllowItemForAuth(client, g_Items[packageid].szSteam))
        return false;

    for(int i = 0; i < g_iItems; ++i)
    if(g_Items[i].iParent == packageid && ((invmode && Store_HasClientItem(client, i)) || !invmode))
    if((g_Items[i].iHandler == g_iPackageHandler && UTIL_PackageHasClientItem(client, i, invmode)) || g_Items[i].iHandler != g_iPackageHandler)
        return true;

    return false;
}

// new table 
// field -> id  storeid  credits  diff  reason  timestamp
// modify in 1.91
void UTIL_LogMessage(int client, int diff, const char[] message, any ...)
{
    if(IsFakeClient(client))
        return;

    char m_szReason[256];
    VFormat(STRING(m_szReason), message, 4);

    char m_szQuery[512], EszReason[513];
    g_hDatabase.Escape(m_szReason, STRING(EszReason));
    FormatEx(STRING(m_szQuery), "INSERT INTO store_newlogs VALUES (DEFAULT, %d, %d, %d, \"%s\", FROM_UNIXTIME(%d))", g_ClientData[client].iId, g_ClientData[client].iCredits, diff, EszReason, GetTime());
    SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
}

void UTIL_LogOpencase(int client, int itemid, int length, const char[] handle, int caseid)
{
    char eHandle[32];
    g_hDatabase.Escape(handle, STRING(eHandle));

    char m_szQuery[256];
    FormatEx(STRING(m_szQuery), "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, FROM_UNIXTIME(%d), '%s', %d)", g_ClientData[client].iId, g_Items[itemid].szUniqueId, length, GetTime(), eHandle, caseid);
    SQL_TVoid(g_hDatabase, m_szQuery, DBPrio_Low);
}

int UTIL_GetLowestPrice(int itemid)
{
    if(g_Items[itemid].iPlans==0)
        return g_Items[itemid].iPrice;

    int m_iLowest=g_PurchasePlan[itemid][0].iPrice;
    for(int i = 1; i < g_Items[itemid].iPlans; ++i)
    if(m_iLowest>g_PurchasePlan[itemid][i].iPrice)
        m_iLowest = g_PurchasePlan[itemid][i].iPrice;

    return m_iLowest;
}

int UTIL_GetHighestPrice(int itemid)
{
    if(g_Items[itemid].iPlans==0)
        return g_Items[itemid].iPrice;

    int m_iHighest=g_PurchasePlan[itemid][0].iPrice;
    for(int i = 1; i < g_Items[itemid].iPlans; ++i)
    if(m_iHighest<g_PurchasePlan[itemid][i].iPrice)
        m_iHighest = g_PurchasePlan[itemid][i].iPrice;

    return m_iHighest;
}

int UTIL_GetClientItemPrice(int client, int itemid)
{
    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid<0)
        return 0;
        
    if(g_ClientItem[client][uid].iPriceOfPurchase < 0)
        return 0; //g_Items[itemid].iPrice;

    return g_ClientItem[client][uid].iPriceOfPurchase;
}

int UTIL_GetClientHandleFees(int client, int itemid)
{
    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid<0)
        return 9999999;

    if(g_ClientItem[client][uid].iDateOfExpiration == 0)
    {
        if(!g_Items[itemid].bBuyable)
        {
            if(g_Items[itemid].bCompose)
                return 15000;
            else
                return 30000;
        }
        else
        {
            if(g_ClientItem[client][uid].iPriceOfPurchase < 1000)
                return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.2);
            else
                return RoundToFloor(g_ClientItem[client][uid].iPriceOfPurchase*0.1);
        }
    }

    if(g_ClientItem[client][uid].iDateOfExpiration-g_ClientItem[client][uid].iDateOfPurchase <= 2678400)
        return 100;

    if(g_ClientItem[client][uid].iPriceOfPurchase < 1000)
        return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.2);

    return RoundToFloor(g_ClientItem[client][uid].iPriceOfPurchase*0.1);
}

int UTIL_GetTotalInventoryItems(int client)
{
    int total = 0;
    for(int i = 0; i < g_iItems; ++i)
    if(g_Items[i].iHandler != g_iPackageHandler)
    if(Store_HasClientItem(client, i))
        total++;
    return total;
}

void UTIL_CheckModules()
{
#if defined Module_Chat
    CPSupport_OnPluginStart();
#endif

#if defined Module_Grenade
    Grenades_OnPluginStart();
#endif

#if defined Module_Spray
    Sprays_OnPluginStart();
#endif

#if defined Module_Sound
    Sounds_OnPluginStart();
#endif

    TPMode_OnPluginStart();

#if defined Module_Player
    Players_OnPluginStart();
#endif

#if defined Module_VIP
    VIP_OnPluginStart();
#endif
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
    for(int client = 1; client <= MaxClients; ++client)
    {
#if defined Module_Spray
        Spray_OnClientDeath(client);
#endif

#if defined Module_Sound
        Sound_OnClientDeath(client, client);
#endif
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
#if defined Module_Spray || defined Module_Sound
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
#endif

    ToggleTp(client, false);
    CheckMirror(client);

#if defined Module_Spray
    Spray_OnClientDeath(attacker);
#endif

#if defined Module_Sound
    Sound_OnClientDeath(client, attacker);
#endif
}

stock bool IsPlayerTP(int client)
{
    if(g_bThirdperson[client])
        return true;

    if(g_bMirror[client])
        return true;

    return false;
}

public void OnGameOver(Event e, const char[] name, bool dB)
{
    g_bInterMission = true;

    //InterMissionConVars();

    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            g_iDataProtect[client] = GetTime() + 99999999;

    CreateTimer(3.0, Timer_InterMission, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_InterMission(Handle timer)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && g_ClientData[client].bLoaded)
        {
            UTIL_SaveClientData(client, true);
            UTIL_SaveClientInventory(client);
            UTIL_SaveClientEquipment(client);
            UTIL_DisconnectClient(client, true);
        }
    return Plugin_Stop;
}

public Action Timer_OnlineCredit(Handle timer, int client)
{
    if(!IsClientInGame(client))
    {
        g_ClientData[client].hTimer = null;
        return Plugin_Stop;
    }

    int m_iCredits = 0;
    char szFrom[128], szReason[128];
    FormatEx(STRING(szFrom), "{gold}[");
    FormatEx(STRING(szReason), "%T[", "online earn credits", client);

    m_iCredits += g_iCreditsTimerOnline;
    StrCat(STRING(szFrom), "{green}Online");
    StrCat(STRING(szReason), "Online");

    StrCat(STRING(szFrom), "{gold}]");
    StrCat(STRING(szReason), "]");

    if(!m_iCredits)
        return Plugin_Continue;

    Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

    tPrintToChat(client, "{gold}%T", "earn credits chat", client, m_iCredits);
    PrintToChat(client, " {silver}%T%s", "earn credits from chat", client, szFrom);

    return Plugin_Continue;
}

void Call_OnClientLoaded(int client)
{
    g_ClientData[client].bLoaded = true;

    Call_StartForward(g_hOnClientLoaded);
    Call_PushCell(client);
    Call_Finish();

    tPrintToChat(client, "%T", "Inventory has been loaded", client);
    
    if (g_fCreditsTimerInterval > 1.0)
    g_ClientData[client].hTimer = CreateTimer(g_fCreditsTimerInterval, Timer_OnlineCredit, client, TIMER_REPEAT);
}

public void InterMissionLock(ConVar convar, const char[] oldValue, const char[] newValue)
{
    convar.SetFloat(20.0, true, true);
    LogMessage("Lock Convar [mp_match_restart_delay] to 20.0, from [%s] to [%s].", oldValue, newValue);
}

/*
void InterMissionConVars()
{
    int players = GetClientCount(true);
    
    float delay = players * 0.5 + 5.0;

    if(delay < 15.0) delay = 15.0;
    if(delay > 30.0) delay = 30.0;

    // Lookup cvars
    ConVar mp_match_restart_delay = FindConVar("mp_match_restart_delay");
    if(mp_match_restart_delay != null)
    {
        // 30 sec to exec sql command.
        mp_match_restart_delay.SetFloat(delay, true, true);
    }
    
    ConVar mp_win_panel_display_time = FindConVar("mp_win_panel_display_time");
    if(mp_win_panel_display_time != null)
    {
        // set value to half of mp_match_restart_delay
        mp_win_panel_display_time.SetFloat(delay / 2.0, true, true);
    }
}
*/

bool IsPluginRunning(Handle plugin, const char[] file)
{
    if(plugin == INVALID_HANDLE)
        return false;

    if(strlen(file) < 4)
        return false;

    Handle dummy = FindPluginByFile(file);

    if(dummy == INVALID_HANDLE || dummy != plugin)
    {
        if (StrContains(file, "store.smx", false) != -1)
        {
            return true;
        }
        
        return false;
    }

    return (GetPluginStatus(plugin) == Plugin_Running);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
#if defined Module_Spray
    Spray_OnRunCmd(client, buttons);
#endif

#if defined Module_Skin
    Skin_OnRunCmd(client);
#endif

    return Plugin_Continue;
}
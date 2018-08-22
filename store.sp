#pragma semicolon 1
#pragma newdecls required

//////////////////////////////
//    PLUGIN DEFINITION     //
//////////////////////////////
#define PLUGIN_NAME         "Store - The Resurrection"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "a sourcemod store system"
#define PLUGIN_VERSION      "2.2.<commit_count>"
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
#include <sdkhooks>
#include <cstrike>
#include <store>
#include <store_stock>

//////////////////////////////
//        DEFINITIONS       //
//////////////////////////////

// Server
#define <Compile_Environment>
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

// VERIFY CREDITS
#define DATA_VERIFY

// Custom Module
// skin does not match with team
#if defined GM_TT || defined GM_ZE || defined GM_KZ || defined GM_BH
#define Global_Skin
#endif
//fix arms when client team
#if defined GM_MG
#define TeamArms
#endif
// hide mode
#if defined GM_ZE || defined GM_JB || defined GM_MG || defined GM_KZ || defined GM_BH
#define AllowHide
#endif

//////////////////////////////
//     GLOBAL VARIABLES     //
//////////////////////////////
Handle g_hDatabase = null;
Handle g_ArraySkin = null;
Handle g_hOnStoreAvailable = null;

int g_eItems[STORE_MAX_ITEMS][Store_Item];
int g_eClients[MAXPLAYERS+1][Client_Data];
int g_eClientItems[MAXPLAYERS+1][STORE_MAX_ITEMS][Client_Item];
int g_eTypeHandlers[STORE_MAX_HANDLERS][Type_Handler];
int g_eMenuHandlers[STORE_MAX_HANDLERS][Menu_Handler];
int g_ePlans[STORE_MAX_ITEMS][STORE_MAX_PLANS][Item_Plan];
int g_eCompose[MAXPLAYERS+1][Compose_Data];

int g_iItems = 0;
int g_iTypeHandlers = 0;
int g_iMenuHandlers = 0;
int g_iPackageHandler = -1;
int g_iDatabaseRetries = 0;

int g_iClientCase[MAXPLAYERS+1];
int g_iMenuBack[MAXPLAYERS+1];
int g_iLastSelection[MAXPLAYERS+1];
int g_iSelectedItem[MAXPLAYERS+1];
int g_iSelectedPlan[MAXPLAYERS+1];
int g_iMenuNum[MAXPLAYERS+1];
int g_iSpam[MAXPLAYERS+1];
int g_iDataProtect[MAXPLAYERS+1];
int g_iClientTeam[MAXPLAYERS+1];

#if defined AllowHide
bool g_bHideMode[MAXPLAYERS+1];
#endif

bool g_bInvMode[MAXPLAYERS+1];

bool g_bLateLoad;
char g_szCase[4][32] = {"", "Normal Case", "Advanced Case", "Ultima Case"};


//////////////////////////////
//         MODULES          //
//////////////////////////////
// Module Global Module
#include "store/cpsupport.sp"
#include "store/tpmode.sp" // Module TP

// Module Hats
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/hats.sp"
#endif
// Module Skin
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/skin.sp"
#endif
// Module Neon
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/neon.sp"
#endif
// Module Aura & Part
#if defined GM_TT || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/aura.sp"
#include "store/modules/part.sp"
#endif
// Module Trail
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/modules/trail.sp"
#endif
// Module PLAYERS
#if defined Module_Hats || defined Module_Skin || defined Module_Neon || defined Module_Aura || defined Module_Part || defined Module_Trail || defined Module_Model
#include "store/players.sp"
#endif
// Module Grenade
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR
#include "store/grenades.sp"
#endif
// Module Spray
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/sprays.sp"
#endif
// Module FPVMI
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HZ || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/models.sp"
#endif
// Module Sound
#if defined GM_TT || defined GM_ZE || defined GM_MG || defined GM_JB || defined GM_HG || defined GM_SR || defined GM_KZ || defined GM_BH
#include "store/sounds.sp"
#endif

//ZE Credits timer
#if defined GM_ZE
#include <cstrike>
#endif


//////////////////////////////
//     PLUGIN FORWARDS      //
//////////////////////////////
public void OnPluginStart()
{
    // Check Engine
    if(GetEngineVersion() != Engine_CSGO)
        SetFailState("Current game is not be supported! CSGO only!");

    // Setting default values
    for(int client = 1; client <= MaxClients; ++client)
    {
        g_eClients[client][iCredits] = -1;
        g_eClients[client][iOriginalCredits] = 0;
        g_eClients[client][iItems] = -1;
    }

    // Register Commands
    RegConsoleCmd("sm_store", Command_Store);
    RegConsoleCmd("buyammo1", Command_Store);
    RegConsoleCmd("sm_shop", Command_Store);
    RegConsoleCmd("sm_inv", Command_Inventory);
    RegConsoleCmd("sm_inventory", Command_Inventory);
    RegConsoleCmd("sm_credits", Command_Credits);

#if defined AllowHide
    RegConsoleCmd("sm_hide", Command_Hide, "Hide Trail / Neon / Aura");
#endif

    HookEvent("round_start", OnRoundStart, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);

    // Load the translations file
    LoadTranslations("store.phrases");

    // Connect to the database
    if(g_hDatabase == null)
    {
        SQL_TConnect(SQLCallback_Connect, "csgo");
        CreateTimer(30.0, Timer_DatabaseTimeout);
    }

    // Initiaze the fake package handler
    g_iPackageHandler = Store_RegisterHandler("package", INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION);
}

public void OnAllPluginsLoaded()
{
    // Initiaze module
    UTIL_CheckModules();
}

public void OnPluginEnd()
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client))
            if(g_eClients[client][bLoaded])
                OnClientDisconnect(client);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_hOnStoreAvailable = CreateGlobalForward("Store_OnStoreAvailable", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell);

    CreateNative("Store_RegisterHandler", Native_RegisterHandler);
    CreateNative("Store_RegisterMenuHandler", Native_RegisterMenuHandler);
    CreateNative("Store_SetDataIndex", Native_SetDataIndex);
    CreateNative("Store_GetDataIndex", Native_GetDataIndex);
    CreateNative("Store_GetEquippedItem", Native_GetEquippedItem);
    CreateNative("Store_IsClientLoaded", Native_IsClientLoaded);
    CreateNative("Store_DisplayPreviousMenu", Native_DisplayPreviousMenu);
    CreateNative("Store_SetClientMenu", Native_SetClientMenu);
    CreateNative("Store_GetClientCredits", Native_GetClientCredits);
    CreateNative("Store_SetClientCredits", Native_SetClientCredits);
    CreateNative("Store_IsItemInBoughtPackage", Native_IsItemInBoughtPackage);
    CreateNative("Store_DisplayConfirmMenu", Native_DisplayConfirmMenu);
    CreateNative("Store_GiveItem", Native_GiveItem);
    CreateNative("Store_GetItemId", Native_GetItemId);
    CreateNative("Store_RemoveItem", Native_RemoveItem);
    CreateNative("Store_HasClientItem", Native_HasClientItem);
    CreateNative("Store_ExtClientItem", Native_ExtClientItem);
    CreateNative("Store_GetItemExpiration", Native_GetItemExpiration);
    CreateNative("Store_SaveClientAll", Native_SaveClientAll);
    CreateNative("Store_GetClientID", Native_GetClientID);
    CreateNative("Store_IsClientBanned", Native_IsClientBanned);
    CreateNative("Store_HasPlayerSkin", Native_HasPlayerSkin);
    CreateNative("Store_GetPlayerSkin", Native_GetPlayerSkin);
    CreateNative("Store_GetSkinLevel", Native_GetSkinLevel);
    CreateNative("Store_GetItemList", Native_GetItemList);

#if defined Module_Model
    MarkNativeAsOptional("FPVMI_SetClientModel");
    MarkNativeAsOptional("FPVMI_RemoveViewModelToClient");
    MarkNativeAsOptional("FPVMI_RemoveWorldModelToClient");
    MarkNativeAsOptional("FPVMI_RemoveDropModelToClient");
#endif

#if defined Module_Sound
    MarkNativeAsOptional("RegClientCookie");
    MarkNativeAsOptional("GetClientCookie");
    MarkNativeAsOptional("SetClientCookie");
#endif

#if defined Module_Skin
    MarkNativeAsOptional("ArmsFix_ModelSafe");
#endif

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
    for(int i = 0; i < g_iTypeHandlers; ++i)
    {
        if(g_eTypeHandlers[i][fnMapStart] != INVALID_FUNCTION)
        {
            Call_StartFunction(g_eTypeHandlers[i][hPlugin], g_eTypeHandlers[i][fnMapStart]);
            Call_Finish();
        }
    }
}

//////////////////////////////
//         NATIVES          //
//////////////////////////////
public int Native_GetItemId(Handle myself, int numParams)
{
    char uid[256];
    if(GetNativeString(1, uid, 256) != SP_ERROR_NONE)
        return -1;

    return UTIL_GetItemId(uid, -1);
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
    return g_eClients[GetNativeCell(1)][iId];
}

public int Native_IsClientBanned(Handle myself, int numParams)
{
    return g_eClients[GetNativeCell(1)][bBan];
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
    
    g_eTypeHandlers[m_iId][hPlugin] = plugin;
    g_eTypeHandlers[m_iId][fnMapStart] = GetNativeCell(2);
    g_eTypeHandlers[m_iId][fnReset] = GetNativeCell(3);
    g_eTypeHandlers[m_iId][fnConfig] = GetNativeCell(4);
    g_eTypeHandlers[m_iId][fnUse] = GetNativeCell(5);
    g_eTypeHandlers[m_iId][fnRemove] = GetNativeCell(6);
    g_eTypeHandlers[m_iId][bEquipable] = GetNativeCell(7);
    g_eTypeHandlers[m_iId][bRaw] = GetNativeCell(8);
    strcopy(g_eTypeHandlers[m_iId][szType], 32, m_szType);

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
        m_iId = m_iHandler;
    else
        ++g_iMenuHandlers;
    
    g_eMenuHandlers[m_iId][hPlugin] = plugin;
    g_eMenuHandlers[m_iId][fnMenu] = GetNativeCell(2);
    g_eMenuHandlers[m_iId][fnHandler] = GetNativeCell(3);
    strcopy(g_eMenuHandlers[m_iId][szIdentifier], 64, m_szIdentifier);

    return m_iId;
}

public int Native_SetDataIndex(Handle myself, int numParams)
{
    g_eItems[GetNativeCell(1)][iData] = GetNativeCell(2);
}

public int Native_GetDataIndex(Handle myself, int numParams)
{
    return g_eItems[GetNativeCell(1)][iData];
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
    return g_eClients[GetNativeCell(1)][bLoaded];
}

public int Native_DisplayPreviousMenu(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    switch(g_iMenuNum[client])
    {
        case 1: DisplayStoreMenu(client, g_iMenuBack[client], g_iLastSelection[client]);
        case 2: DisplayItemMenu(client, g_iSelectedItem[client]);
        case 3: DisplayPlayerMenu(client);
        case 4: DisplayPlanMenu(client, g_iSelectedItem[client]);
        case 5: DisplayComposeMenu(client, false);
    }
}

public int Native_SetClientMenu(Handle myself, int numParams)
{
    g_iMenuNum[GetNativeCell(1)] = GetNativeCell(2);
}

public int Native_GetClientCredits(Handle myself, int numParams)
{
    return g_eClients[GetNativeCell(1)][iCredits];
}

public int Native_SetClientCredits(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    if(IsFakeClient(client) || !g_eClients[client][bLoaded] || g_eClients[client][bBan])
        return false;
    
    int m_iCredits = GetNativeCell(2);
    int difference = m_iCredits-g_eClients[client][iCredits];

    char logMsg[128];
    if(GetNativeString(3, logMsg, 128) != SP_ERROR_NONE)
        strcopy(STRING(logMsg), "unknown SP_ERROR");
    
    if(g_eClients[client][bRefresh])
    {
        DataPack pack = new DataPack();
        pack.WriteCell(client);
        pack.WriteCell(m_iCredits);
        pack.WriteCell(difference);
        pack.WriteCell(g_eClients[client][iId]);
        pack.WriteCell(g_eClients[client][iCredits]);
        pack.WriteCell(GetTime());
        pack.WriteString(logMsg);
        CreateTimer(1.0, Timer_SetCreditsDelay, pack, TIMER_REPEAT);
        return true;
    }

    g_eClients[client][iCredits] = m_iCredits;

    UTIL_LogMessage(client, difference, logMsg);
    
    UTIL_SaveClientData(client, false);

    return true;
}

public Action Timer_SetCreditsDelay(Handle timer, DataPack pack)
{
    pack.Reset();
    int client = pack.ReadCell();
    int m_iCredits = pack.ReadCell();
    int difference = pack.ReadCell();
    int m_iStoreId = pack.ReadCell();
    int OrgCredits = pack.ReadCell();
    int iTimeStamp = pack.ReadCell();
    char logMsg[256];
    pack.ReadString(STRING(logMsg));

    if(!IsClientInGame(client))
    {
        delete pack;
        LogError("SetCreditsDelay -> id.%d -> diff.%d -> reason.%s", m_iStoreId, difference, logMsg);
        char m_szQuery[512], eReason[256];
        FormatEx(STRING(m_szQuery), "UPDATE store_players SET credits=credits+%d WHERE id=%d", difference, m_iStoreId);
        SQL_TVoid(g_hDatabase, m_szQuery);
        SQL_EscapeString(g_hDatabase, logMsg, eReason, 256);
        FormatEx(STRING(m_szQuery), "INSERT INTO store_newlogs VALUES (DEFAULT, %d, %d, %d, \"%s\", %d)", m_iStoreId, OrgCredits, difference, eReason, iTimeStamp);
        SQL_TVoid(g_hDatabase, m_szQuery);
        return Plugin_Stop;
    }

    if(g_eClients[client][bRefresh])
        return Plugin_Continue;
    
    if(m_iStoreId != g_eClients[client][iId])
    {
        LogError("SetCreditsDelay -> id not match -> id.%d ? real.%d -> \"%L\" ", m_iStoreId, g_eClients[client][iId], client);
        return Plugin_Stop;
    }
    
    delete pack;
    
    g_eClients[client][iCredits] = m_iCredits;

    UTIL_LogMessage(client, difference, logMsg);
    
    UTIL_SaveClientData(client, false);
    
    return Plugin_Stop;
} 

public int Native_IsItemInBoughtPackage(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    int uid = GetNativeCell(3);

    int m_iParent;
    if(itemid<0)
        m_iParent = g_eItems[itemid][iParent];
    else
        return false;
        
    while(m_iParent != -1)
    {
        for(int i = 0; i < g_eClients[client][iItems]; ++i)
            if(((uid == -1 && g_eClientItems[client][i][iUniqueId] == m_iParent) || (uid != -1 && g_eClientItems[client][i][iUniqueId] == uid)) && !g_eClientItems[client][i][bDeleted])
                return true;
        m_iParent = g_eItems[m_iParent][iParent];
    }
    return false;
}

public int Native_DisplayConfirmMenu(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);
    char title[255], m_szCallback[32], m_szData[11];
    GetNativeString(2, STRING(title));

    DataPack pack = CreateDataPack();
    WritePackCell(pack, plugin);
    WritePackCell(pack, GetNativeCell(3));
    ResetPack(pack);

    Handle m_hMenu = CreateMenu(MenuHandler_Confirm);
    SetMenuTitleEx(m_hMenu, title);
    SetMenuExitButton(m_hMenu, false);
    IntToString(view_as<int>(pack), STRING(m_szCallback));
    IntToString(GetNativeCell(4), STRING(m_szData));
    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szCallback, "%T", "Confirm_Yes", client);
    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szData, "%T", "Confirm_No", client);
    DisplayMenu(m_hMenu, client, 0);
}

public int Native_GiveItem(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    int purchase = GetNativeCell(3);
    int expiration = GetNativeCell(4);
    int price = GetNativeCell(5);
    
    if(itemid < 0)
    {
        LogError("Give %N itemid %d purchase %d expiration %d price %d", client, itemid, purchase, expiration, price);
        return;
    }

    if(!Store_HasClientItem(client, itemid))
    {
        int m_iDateOfPurchase = (purchase==0 ? GetTime() : purchase);
        int m_iDateOfExpiration = expiration;

        int m_iId = g_eClients[client][iItems]++;
        g_eClientItems[client][m_iId][iId] = -1;
        g_eClientItems[client][m_iId][iUniqueId] = itemid;
        g_eClientItems[client][m_iId][iDateOfPurchase] = m_iDateOfPurchase;
        g_eClientItems[client][m_iId][iDateOfExpiration] = m_iDateOfExpiration;
        g_eClientItems[client][m_iId][iPriceOfPurchase] = price;
        g_eClientItems[client][m_iId][bSynced] = false;
        g_eClientItems[client][m_iId][bDeleted] = false;
    }
    else
    {
        int exp = Store_GetItemExpiration(client, itemid);
        if(exp > 0 && exp < expiration)
        {
            if(!Store_ExtClientItem(client, itemid, expiration-exp))
                LogError("Ext %N %s failed. purchase %d expiration %d price %d", client, g_eItems[itemid][szName] , purchase, expiration, price);
        }
    }
}

public int Native_RemoveItem(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    if(itemid > 0 && g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove] != INVALID_FUNCTION)
    {
        Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove]);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish();
    }
    
    UTIL_UnequipItem(client, itemid, false);

    int m_iId = UTIL_GetClientItemId(client, itemid);
    if(m_iId != -1)
        g_eClientItems[client][m_iId][bDeleted] = true;
}

public int Native_GetItemExpiration(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    int itemid = GetNativeCell(2);
    
    // Check if item is available?
    if(itemid < 0)
        return -1;
    
    if(!g_eClients[client][bLoaded])
        return -1;
    
    // Can he even have it?    
    if(g_eItems[itemid][szSteam][0] != 0)
        return (AllowItemForAuth(client, g_eItems[itemid][szSteam])) ? 0 : -1;

    if(g_eItems[itemid][bVIP])
        return (AllowItemForVIP(client, g_eItems[itemid][bVIP])) ? 0 : -1;
    
    // Is the item free (available for everyone)?
    if(g_eItems[itemid][iPrice] <= 0 && g_eItems[itemid][iPlans]==0)
        return -1;

    for(int i = 0; i < g_eClients[client][iItems]; ++i)
    {
        if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
            return g_eClientItems[client][i][iDateOfExpiration];
    }

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
    if(g_eItems[itemid][szSteam][0] != 0)
        return AllowItemForAuth(client, g_eItems[itemid][szSteam]);

    // VIP item?
    if(g_eItems[itemid][bVIP])
        return AllowItemForVIP(client, g_eItems[itemid][bVIP]);

    // Is the item free (available for everyone)?
    if(!g_eItems[itemid][bIgnore] && !g_eItems[itemid][bCase] && !g_eItems[itemid][bCompose] && g_eItems[itemid][iPrice] <= 0 && g_eItems[itemid][iPlans]==0)
        return true;

    // Check if the client actually has the item
    for(int i = 0; i < g_eClients[client][iItems]; ++i)
    {
        if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
            if(g_eClientItems[client][i][iDateOfExpiration]==0 || (g_eClientItems[client][i][iDateOfExpiration] && GetTime()<g_eClientItems[client][i][iDateOfExpiration]))
                return true;
            else
                return false;
    }

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
    
    if(!g_eClients[client][bLoaded])
        return false;

    for(int i = 0; i < g_eClients[client][iItems]; ++i)
        if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
        {
            if(g_eClientItems[client][i][iDateOfExpiration] == 0)
                return true;

            if(extime == 0)
                g_eClientItems[client][i][iDateOfExpiration] = 0;
            else
                g_eClientItems[client][i][iDateOfExpiration] += extime;

            if(g_eClientItems[client][i][iId]==-1 && !g_eClientItems[client][i][bSynced])
                return true;

            char m_szQuery[256];
            FormatEx(STRING(m_szQuery), "UPDATE `store_items` SET `date_of_expiration` = '%d' WHERE `id`=%d AND `player_id`=%d", g_eClientItems[client][i][iDateOfExpiration], g_eClientItems[client][i][iId], g_eClients[client][iId]);
            SQL_TVoid(g_hDatabase, m_szQuery);

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

public int Native_GetItemList(Handle myself, int numParams)
{
    if(g_iItems <= 0)
        return false;
    
    // girls frontline -> active
    ArrayList item_name = GetNativeCell(1);
    ArrayList item_uid  = GetNativeCell(2);
    ArrayList item_idx  = GetNativeCell(3);
    ArrayList item_lvl  = GetNativeCell(4);

    for(int item = 0; item < g_iItems; ++item)
    {
        item_name.PushString(g_eItems[item][szName]);
        item_uid.PushString(g_eItems[item][szUniqueId]);
        item_idx.Push(g_eItems[item][iId]);
        item_lvl.Push(g_eItems[item][iLevels]);
    }

    return true;
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

//////////////////////////////
//      CLIENT FORWARD      //
//////////////////////////////
public void OnClientConnected(int client)
{
    g_iSpam[client] = 0;
    g_iClientTeam[client] = 0;
    g_iClientCase[client] = 1;
    g_iDataProtect[client] = GetTime()+300;
    g_eClients[client][iUserId] = GetClientUserId(client);
    g_eClients[client][iCredits] = -1;
    g_eClients[client][iOriginalCredits] = 0;
    g_eClients[client][iItems] = -1;
    g_eClients[client][bLoaded] = false;
    
#if defined AllowHide
    g_bHideMode[client] = false;
#endif
    
    g_eCompose[client][item1] = -1;
    g_eCompose[client][item2] = -1;
    g_eCompose[client][types] = -1;

    for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
    {
        for(int a = 0; a < STORE_MAX_SLOTS; ++a)
        {
            g_eClients[client][aEquipment][i*STORE_MAX_SLOTS+a] = -2;
            g_eClients[client][aEquipmentSynced][i*STORE_MAX_SLOTS+a] = -2;
        }
    }

#if defined Module_Spray
    Sprays_OnClientConnected(client);
#endif

#if defined Module_Sound
    Sound_OnClientConnected(client);
#endif

#if defined Module_Chat
    Chat_OnClientConnected(client);
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

#if defined Module_Model
    Models_OnClientDisconnect(client);
#endif

    UTIL_SaveClientData(client, true);
    UTIL_SaveClientInventory(client);
    UTIL_SaveClientEquipment(client);
    UTIL_DisconnectClient(client);
}

//////////////////////////////
//         COMMAND          //
//////////////////////////////
public Action Command_Store(int client, int args)
{
    if(!IsClientInGame(client))
        return Plugin_Handled;
    
    if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }

    if(g_eClients[client][bBan])
    {
        tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
        return Plugin_Handled;
    }    

    g_bInvMode[client]=false;
    DisplayStoreMenu(client);

    return Plugin_Handled;
}

public Action Command_Inventory(int client, int args)
{    
    if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }
    
    if(g_eClients[client][bBan])
    {
        tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
        return Plugin_Handled;
    }    
    
    g_bInvMode[client] = true;
    DisplayStoreMenu(client);

    return Plugin_Handled;
}

public Action Command_Credits(int client, int args)
{    
    if(g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1)
    {
        tPrintToChat(client, "%T", "Inventory hasnt been fetched", client);
        return Plugin_Handled;
    }
    
    if(g_eClients[client][bBan])
    {
        tPrintToChat(client,"[\x02CAT\x01]  %T", "cat banned", client);
        return Plugin_Handled;
    }    

    if(g_iSpam[client]<GetTime())
    {
        tPrintToChatAll("%t", "Player Credits", client, g_eClients[client][iCredits]);
        g_iSpam[client] = GetTime()+30;
    }
    
    return Plugin_Handled;
}

#if defined AllowHide
public Action Command_Hide(int client, int args)
{
    if(!IsClientInGame(client))
        return Plugin_Handled;

    g_bHideMode[client] = !g_bHideMode[client];
    tPrintToChat(client, "%T", "hide setting", client, g_bHideMode[client] ? "on" : "off");

    return Plugin_Handled;
}
#endif

//////////////////////////////
//           MENU           //
//////////////////////////////
void DisplayStoreMenu(int client, int parent = -1, int last = -1)
{
    if(!client || !IsClientInGame(client))
        return;

    g_iMenuNum[client] = 1;

    Handle m_hMenu = CreateMenu(MenuHandler_Store);
    if(parent != -1)
    {
        SetMenuExitBackButton(m_hMenu, true);
        SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[parent][szName], "Title Credits", client, g_eClients[client][iCredits]);
        g_iMenuBack[client] = g_eItems[parent][iParent];
    }
    else
        SetMenuTitleEx(m_hMenu, "%T\n%T", "Title Store", client, "Title Credits", client, g_eClients[client][iCredits]);
    
    char m_szId[11];
    int m_iPosition = 0;
    
    g_iSelectedItem[client] = parent;
    if(parent != -1)
    {
        if(g_eItems[parent][iPrice]>0)
        {
            if(!Store_IsItemInBoughtPackage(client, parent))
            {
                AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "sell_package", "%T", "Package Sell", client, RoundToFloor(g_eItems[parent][iPrice]*0.6));
                ++m_iPosition;

                if(g_eItems[parent][bGiftable])
                {
                    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "gift_package", "%T", "Package Gift", client);
                    ++m_iPosition;
                }

                for(int i = 0; i < g_iMenuHandlers; ++i)
                {
                    if(g_eMenuHandlers[i][hPlugin] == null)
                        continue;
    
                    Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnMenu]);
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
        if(g_eItems[i][iParent]==parent)
        {
            int m_iPrice = UTIL_GetLowestPrice(i);

            // This is a package
            if(g_eItems[i][iHandler] == g_iPackageHandler)
            {
                if(!UTIL_PackageHasClientItem(client, i, g_bInvMode[client]))
                    continue;

                int m_iStyle = ITEMDRAW_DEFAULT;
                if(!AllowItemForAuth(client, g_eItems[i][szSteam]) || !AllowItemForVIP(client, g_eItems[i][bVIP]))
                    m_iStyle = ITEMDRAW_DISABLED;

                IntToString(i, STRING(m_szId));
                if(g_eItems[i][iPrice] == -1 || Store_HasClientItem(client, i))
                    AddMenuItem(m_hMenu, m_szId, g_eItems[i][szName], m_iStyle);
                else if(!g_bInvMode[client] && g_eItems[i][iPlans]==0 && g_eItems[i][bBuyable])
                    InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_eClients[client][iCredits] && !g_eItems[i][bCompose]) || g_eItems[i][bCompose])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
                else if(!g_bInvMode[client])
                    InsertMenuItemEx(m_hMenu, m_iPosition, ((m_iPrice<=g_eClients[client][iCredits] && !g_eItems[i][bCompose]) || g_eItems[i][bCompose])?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED, m_szId, "%T", "Item Plan Available", client, g_eItems[i][szName]);
                ++m_iPosition;
            }
            // This is a normal item
            else
            {
                IntToString(i, STRING(m_szId));
                if(Store_HasClientItem(client, i))
                {
                    if(UTIL_IsEquipped(client, i))
                        InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Equipped", client, g_eItems[i][szName]);
                    else
                        InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Bought", client, g_eItems[i][szName]);
                }
                else if(!g_bInvMode[client])
                {                
                    int m_iStyle = ITEMDRAW_DEFAULT;
                    if((g_eItems[i][iPlans]==0 && g_eClients[client][iCredits]<m_iPrice) || !AllowItemForAuth(client, g_eItems[i][szSteam]) || !AllowItemForVIP(client, g_eItems[i][bVIP]))
                        m_iStyle = ITEMDRAW_DISABLED;

                    if(StrEqual(g_eTypeHandlers[g_eItems[i][iHandler]][szType], "playerskin"))
                    {
                        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, "%T", "Item Preview Available", client, g_eItems[i][szName]);
                        continue;
                    }

                    if(!g_eItems[i][bBuyable])
                        continue;

                    if(g_eItems[i][iPlans]==0)
                        AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
                    else
                        AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%T", "Item Plan Available", client, g_eItems[i][szName], g_eItems[i][iPrice]);
                }
            }
        }
    }
    
    if(last == -1)
        DisplayMenu(m_hMenu, client, 0);
    else
        DisplayMenuAtItem(m_hMenu, client, (last/GetMenuPagination(m_hMenu))*GetMenuPagination(m_hMenu), 0);
}

public int MenuHandler_Store(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
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
                    m_iPrice = g_eItems[g_iSelectedItem[client]][iPrice];
                else
                    m_iPrice = g_ePlans[g_iSelectedItem[client]][g_iSelectedPlan[client]][iPrice];

                if(g_eClients[client][iCredits]>=m_iPrice && !Store_HasClientItem(client, g_iSelectedItem[client]))
                    UTIL_BuyItem(client);
            }
            else if(param2 == 1)
                UTIL_SellItem(client, g_iSelectedItem[client]);
        }
        else
        {
            char m_szId[64];
            GetMenuItem(menu, param2, STRING(m_szId));
            
            g_iLastSelection[client]=param2;
            
            // We are selling a package
            if(strcmp(m_szId, "sell_package")==0)
            {
                char m_szTitle[128];
                FormatEx(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], RoundToFloor(g_eItems[g_iSelectedItem[client]][iPrice]*0.6));
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
                    Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnHandler]);
                    Call_PushCell(client);
                    Call_PushString(m_szId);
                    Call_PushCell(g_iSelectedItem[client]);
                    Call_Finish(ret);

                    if(ret)
                        break;
                }
            }
            // We are being boring
            else
            {
                int m_iId = StringToInt(m_szId);
                g_iMenuBack[client]=g_eItems[m_iId][iParent];
                g_iSelectedItem[client] = m_iId;
                g_iSelectedPlan[client] = -1;
                
                if(!Store_HasClientItem(client, m_iId))
                {
                    if(StrEqual(g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType], "playerskin"))
                    {
                        DisplayPreviewMenu(client, m_iId);
                        return;
                    }

                    if(g_eItems[m_iId][bCompose])
                    {
                        if(g_eClients[client][iCredits] >= 10000)
                        {
                            g_eCompose[client][item1]=-1;
                            g_eCompose[client][item2]=-1;
                            g_eCompose[client][types]=-1;
                            DisplayComposeMenu(client, false);
                        }
                        else
                            tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 10000);
                        return;
                    }
                    else
                    {
                        if((g_eClients[client][iCredits]>=g_eItems[m_iId][iPrice] || g_eItems[m_iId][iPlans]>0 && g_eClients[client][iCredits]>=UTIL_GetLowestPrice(m_iId)) && g_eItems[m_iId][iPrice] != -1)
                        {
                            if(g_eItems[m_iId][iPlans] > 0)
                                DisplayPlanMenu(client, m_iId);
                            else
                            {
                                char m_szTitle[128];
                                FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
                                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
                            }
                            return;
                        }
                    }
                }

                if(g_eItems[m_iId][iHandler] != g_iPackageHandler)
                {
                    if(Store_HasClientItem(client, m_iId))
                    {
                        if(g_eTypeHandlers[g_eItems[m_iId][iHandler]][bRaw])
                        {
                            Call_StartFunction(g_eTypeHandlers[g_eItems[m_iId][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[m_iId][iHandler]][fnUse]);
                            Call_PushCell(client);
                            Call_PushCell(m_iId);
                            Call_Finish();
                        }
                        else
                            DisplayItemMenu(client, m_iId);
                    }
                    else
                        DisplayStoreMenu(client, g_iMenuBack[client]);                    
                }
                else
                {            
                    if(Store_HasClientItem(client, m_iId) || g_eItems[m_iId][iPrice] == -1)
                        DisplayStoreMenu(client, m_iId);
                    else
                        DisplayStoreMenu(client, g_eItems[m_iId][iParent]);
                }
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

void UTIL_GetLevelType(int itemid, char[] buffer, int maxLen)
{
    switch(g_eItems[itemid][iLevels])
    {
        case  2: strcopy(buffer, maxLen, "保密"); //合成
        case  3: strcopy(buffer, maxLen, "隐秘"); //开箱
        case  4: strcopy(buffer, maxLen, "违禁"); //活动
        case  5: strcopy(buffer, maxLen, "专属"); //专属
        case  6: strcopy(buffer, maxLen, "隐藏"); //专属
        default: strcopy(buffer, maxLen, "受限"); //普通
    }
}

public void DisplayPreviewMenu(int client, int itemid)
{
    if(Store_HasClientItem(client, itemid))
        return;
    
    g_iMenuNum[client] = 1;
    g_iMenuBack[client] = g_eItems[itemid][iParent];

    Handle m_hMenu = CreateMenu(MenuHandler_Preview);
    SetMenuExitBackButton(m_hMenu, true);
    
    SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);

    AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "3", "%s", g_eItems[itemid][szDesc]);
    
    char leveltype[32];
    UTIL_GetLevelType(itemid, leveltype, 32);
    AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "3", "%T", "Playerskins Level", client, g_eItems[itemid][iLevels], leveltype);

    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%T", "Open Case Available", client);

    if(g_eItems[itemid][bCompose])  //合成
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Preview Compose Available", client);
    else if(g_eItems[itemid][szSteam][0] != 0) //专个人属
        AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    else if(g_eItems[itemid][bIgnore]) //组专属或活动限定
        AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    else if(g_eItems[itemid][bCase]) //开箱专属
        AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    else
    {
        if(g_eItems[itemid][bBuyable])
        {
            int m_iStyle = ITEMDRAW_DEFAULT;
            if((g_eItems[itemid][iPlans]==0 && g_eClients[client][iCredits]<UTIL_GetLowestPrice(itemid)) || !AllowItemForAuth(client, g_eItems[itemid][szSteam]) || !AllowItemForVIP(client, g_eItems[itemid][bVIP]))
                m_iStyle = ITEMDRAW_DISABLED;
            
            if(g_eItems[itemid][iPlans]==0)
                AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Available", client, g_eItems[itemid][iPrice]);
            else
                AddMenuItemEx(m_hMenu, m_iStyle, "1", "%T", "Preview Plan Available", client);
        }
        else
            AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "1", "%T", "Item not Buyable", client);
    }

    AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Preview", client);

    DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Preview(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
    else if(action == MenuAction_Select)
    {
        char m_szId[64];
        GetMenuItem(menu, param2, STRING(m_szId));
        int selected = StringToInt(m_szId);
        int m_iId = g_iSelectedItem[client];

        if(selected == 0)
        {
            if(g_eClients[client][iCredits] >= 10000)
            {
                g_eCompose[client][item1]=-1;
                g_eCompose[client][item2]=-1;
                g_eCompose[client][types]=-1;
                DisplayComposeMenu(client, false);
            }
            else
                tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 10000);
        }
        else if(selected == 1)
        {
            if((g_eClients[client][iCredits]>=g_eItems[m_iId][iPrice] || g_eItems[m_iId][iPlans]>0 && g_eClients[client][iCredits]>=UTIL_GetLowestPrice(m_iId)) && g_eItems[m_iId][iPrice] != -1)
            {
                if(g_eItems[m_iId][iPlans] > 0)
                    DisplayPlanMenu(client, m_iId);
                else
                {
                    char m_szTitle[128];
                    FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
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
            if(g_eClients[client][iCredits] >= 8888)
                UTIL_OpenSkinCase(client);
            else
                tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 8888);
#else
            tPrintToChat(client, "%T", "Open Case not available", client);
#endif
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

void UTIL_OpenSkinCase(int client)
{
    Handle menu = CreateMenu(MenuHandler_SelectCase);
    SetMenuTitleEx(menu, "%T\n%T: %d", "select case", client, "credits", client, g_eClients[client][iCredits]);
    SetMenuExitBackButton(menu, true);

    AddMenuItemEx(menu, g_eClients[client][iCredits] >=  8888 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "1", "%s(8888%T)\nSkin Level: 2|3(1day~%T)", g_szCase[1], "credits", client, "permanent", client);
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, g_eClients[client][iCredits] >= 23333 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "2", "%s(23333%T)\nSkin Level: 2|3|4(1day~%T)", g_szCase[2], "credits", client, "permanent", client);
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, g_eClients[client][iCredits] >= 68888 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "3", "%s(68888%T)\nSkin Level: 2|3|4(#%T#)", g_szCase[3], "credits", client, "permanent", client);

    DisplayMenu(menu, client, 0);
}

public int MenuHandler_SelectCase(Handle menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End: CloseHandle(menu);
        case MenuAction_Select:
        {
            if(g_iDataProtect[client] > GetTime())
            {
                tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
                UTIL_OpenSkinCase(client);
                return;
            }

            char info[32];
            GetMenuItem(menu, param2, STRING(info));

            g_iClientCase[client] = StringToInt(info);
            
            if(g_eItems[g_iSelectedItem[client]][bIgnore])
            {
                if(g_iClientCase[client] == 1)
                    tPrintToChat(client, "%T", "Item not in case", client);
                else if(g_eItems[g_iSelectedItem[client]][szSteam][0] != 0)
                    tPrintToChat(client, "%T", "Item not in case", client);
            }

            CreateTimer(0.1, Timer_OpeningCase, client);
        }
        case MenuAction_Cancel:
        {
            if(param2 == MenuCancel_ExitBack)
                DisplayItemMenu(client, g_iSelectedItem[client]);
        }
    }
}

public Action Timer_OpeningCase(Handle timer, int client)
{
    if(!IsClientInGame(client))
        return Plugin_Stop;
    
    switch(g_iClientCase[client])
    {
        case 1 : if(g_eClients[client][iCredits] <  8888) return Plugin_Stop;
        case 2 : if(g_eClients[client][iCredits] < 23333) return Plugin_Stop;
        case 3 : if(g_eClients[client][iCredits] < 68888) return Plugin_Stop;
        default: return Plugin_Stop;
    }

    static int times[MAXPLAYERS+1];
    
    int size = GetArraySize(g_ArraySkin);
    int aid = UTIL_GetRandomInt(0, size-1);
    char modelname[32];
    GetArrayString(g_ArraySkin, aid, modelname, 32);
    
    if(g_iClientCase[client] > 1)
    {
        int rp = (times[client] < 13) ? 750 : 970;
        if(UTIL_GetRandomInt(1, 1000) > rp)
        {
            switch(UTIL_GetRandomInt(1, 5))
            {
                // 夕立
                case 1: strcopy(modelname, 32, "skin_yuudachi_kai2");
                // 艾米莉亚
                case 2: strcopy(modelname, 32, "skin_emilia_normal");
                // 普魯魯特
                case 3: strcopy(modelname, 32, "skin_pururut_normal");
                // 巡音流歌
                case 4: strcopy(modelname, 32, "skin_luka_punk");
                // NextBlack
                case 5: strcopy(modelname, 32, "skin_noire_nextform");
                // 神崎兰子
                case 6: strcopy(modelname, 32, "skin_kanzaki_normal");
                // IA
                case 7: strcopy(modelname, 32, "skin_ia_tda");
            }
        }
    }

    int itemid = UTIL_GetItemId(modelname);

    if(itemid < 0)
    {
        LogError("Item Id Error %s", modelname);
        tPrintToChat(client, "\x07%T", "unknown error", client);
        return Plugin_Stop;
    }

    int days;

    int rdm = UTIL_GetRandomInt(1, 1000);

    if(++times[client] < 15)
    {
        if(rdm >= 850)
            days = 0;
        else
            days = UTIL_GetRandomInt(1, 365);

        if(g_iClientCase[client] == 3)
            days = 0;
    }
    else
    {
        if(rdm >= 970)
            days = 0;
        else if(rdm >= 900)
            days = UTIL_GetRandomInt(32, 365);
        else
            days = UTIL_GetRandomInt(1, 31);

        if(g_iClientCase[client] == 3)
            days = 0;

        times[client] = 0;
        EndingCaseMenu(client, days, itemid);
        return Plugin_Stop;
    }

    OpeningCaseMenu(client, days, g_eItems[itemid][szName]);

    if(5 >= times[client]) CreateTimer(0.2, Timer_OpeningCase, client);
    else if(times[client] > 5)  CreateTimer(0.3, Timer_OpeningCase, client);
    else if(times[client] > 10) CreateTimer(0.4, Timer_OpeningCase, client);
    else if(times[client] > 15) CreateTimer(0.5, Timer_OpeningCase, client);
    else CreateTimer(0.6, Timer_OpeningCase, client);

    return Plugin_Stop;
}

void OpeningCaseMenu(int client, int days, const char[] name)
{
    Handle menu = CreateMenu(MenuHandler_OpeningCase);
    SetMenuTitleEx(menu, "Opening Case...\n%s", g_szCase[g_iClientCase[client]]);
    SetMenuExitButton(menu, false);
    
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "   %s", name);
    if(days)
    {
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "   %d day%s", days, days > 1 ? "s" : "");
        PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>%d Day%s</center>", name, days, days > 1 ? "s" : "");
    }
    else
    {
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "%T", "permanent", client);
        PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>Permanent</center>", name);
    }

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "", "░░░░░░░░░░░░░░░░░░");
    
    DisplayMenu(menu, client, 1);
    
    ClientCommand(client, "playgamesound ui/csgo_ui_crate_item_scroll.wav");
}

public int MenuHandler_OpeningCase(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
}

int UTIL_GetSkinSellPrice(int client, int days)
{
    if(days == 0)
        return (g_iClientCase[client] == 3) ? 38888 : 50000;

    int buyc = 233;

    if(days > 150)
        buyc = days*200;
    else if(days > 31)
        buyc = days*250;
    else if(days > 7)
        buyc = days*300;
    else
        buyc = days*350;

    if(buyc > 50000)
        buyc = 50000;

    return buyc;
}

void EndingCaseMenu(int client, int days, int itemid)
{
    switch(g_iClientCase[client])
    {
        case 1: Store_SetClientCredits(client, Store_GetClientCredits(client)- 8888, "Normal Case");
        case 2: Store_SetClientCredits(client, Store_GetClientCredits(client)-23333, "Advanced Case");
        case 3: Store_SetClientCredits(client, Store_GetClientCredits(client)-68888, "Ultima Case");
        default: return;
    }

    Handle menu = CreateMenu(MenuHandler_OpenSuccessful);
    SetMenuTitleEx(menu, "%T\n%s", "Open case successful", client, g_szCase[g_iClientCase[client]]);
    SetMenuExitButton(menu, false);

    char name[128];
    strcopy(name, 128, g_eItems[itemid][szName]);
    
    char leveltype[32];
    UTIL_GetLevelType(itemid, leveltype, 32);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %s - %s", "playerskin", client, name, leveltype);
    if(days)
    {
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %d day%s", "time limit", client, days, days > 1 ? "s" : "");
        PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>%d Day%s</center>", name, days, days > 1 ? "s" : "");
        tPrintToChatAll("%t", "opencase earned day", client, g_szCase[g_iClientCase[client]], name, days);
    }
    else
    {
        AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "%T: %T", "time limit", client, "permanent", client);
        PrintCenterText(client, "<big><u><b><font color='#dd2f2f' size='25'><center>%s</font> <font color='#15fb00' size='25'>Permanent</center>", name);
        tPrintToChatAll("%t", "opencase earned perm", client, g_szCase[g_iClientCase[client]], name);
    }

    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");
    AddMenuItemEx(menu, ITEMDRAW_SPACER, "", "");

    int crd = UTIL_GetSkinSellPrice(client, days);
    char fmt[32];
    FormatEx(fmt, 32, "sell_%d_%d", itemid, days);
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, fmt, "%T(%d)", "quickly sell", client, crd);
    FormatEx(fmt, 32, "add_%d_%d", itemid, days);
    AddMenuItemEx(menu, Store_HasClientItem(client, itemid) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT, fmt, "%T", "income", client);
    
    DisplayMenu(menu, client, 0);
    
    ClientCommand(client, "playgamesound ui/item_drop3_rare.wav");
}

public int MenuHandler_OpenSuccessful(Handle menu, MenuAction action, int client, int param2)
{
    switch(action)
    {
        case MenuAction_End: CloseHandle(menu);
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, param2, STRING(info));
            
            char data[3][16];
            ExplodeString(info, "_", data, 3, 16);
            
            int itemid = StringToInt(data[1]);
            int days = StringToInt(data[2]);
            
            char name[128];
            strcopy(name, 128, g_eItems[itemid][szName]);

            char m_szQuery[256];

            if(StrEqual(data[0], "sell"))
            {
                int crd = UTIL_GetSkinSellPrice(client, days);
                char reason[128];
                FormatEx(STRING(reason), "%T[%s]", "open case and quickly sell", client, name);
                Store_SetClientCredits(client, Store_GetClientCredits(client)+crd, reason);
                if(days) tPrintToChat(client, "%t", "open and sell day chat", name, days, crd);
                else tPrintToChat(client, "%t", "open and sell permanent chat", name, crd);
                FormatEx(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'sell', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
                SQL_TVoid(g_hDatabase, m_szQuery);
                UTIL_OpenSkinCase(client);
                if(g_iClientCase[client] > 1)
                {
                    g_iDataProtect[client] = GetTime()+15;
                    Store_SaveClientAll(client);
                }
            }
            else if(StrEqual(data[0], "add"))
            {
                Store_GiveItem(client, itemid, GetTime(), (days == 0) ? 0 : GetTime()+days*86400, 233);
                if(days) tPrintToChat(client, "%t", "open and add day chat", g_szCase[g_iClientCase[client]], name, days);
                else tPrintToChat(client, "%t", "open and sell permanent chat", g_szCase[g_iClientCase[client]], name);
                Store_SaveClientAll(client);
                FormatEx(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'add', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
                SQL_TVoid(g_hDatabase, m_szQuery);
                g_iDataProtect[client] = GetTime()+15;
                g_iSelectedItem[client] = itemid;
                DisplayItemMenu(client, itemid);
            }
            else
                LogError("%N Open case error: %s", client, info);
        }
        case MenuAction_Cancel:
        {
            if(IsClientInGame(client) && param2 != MenuCancel_Disconnected && param2 != MenuCancel_NoDisplay)
            {
                char info[32];
                GetMenuItem(menu, 5, STRING(info));
                
                char data[3][16];
                ExplodeString(info, "_", data, 3, 16);
                
                int itemid = StringToInt(data[1]);
                int days = StringToInt(data[2]);
                
                char name[128];
                strcopy(name, 128, g_eItems[itemid][szName]);
                
                char m_szQuery[256];
                
                if(Store_HasClientItem(client, itemid))
                {
                    int crd = UTIL_GetSkinSellPrice(client, days);
                    char reason[128];
                    FormatEx(STRING(reason), "%T[%s]", "open and cancel", client, name);
                    Store_SetClientCredits(client, Store_GetClientCredits(client)+crd, reason);
                    if(days) tPrintToChat(client, "%t", "open and sell day chat", name, days, crd);
                    else tPrintToChat(client, "%t", "open and sell permanent chat", name, crd);
                    if(g_iClientCase[client] > 1)
                    {
                        g_iDataProtect[client] = GetTime()+10;
                        Store_SaveClientAll(client);
                    }
                    FormatEx(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'sell', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
                }
                else
                {
                    Store_GiveItem(client, itemid, GetTime(), (days == 0) ? 0 : GetTime()+days*86400, 233);
                    if(days) tPrintToChat(client, "%t", "open and add day chat", g_szCase[g_iClientCase[client]], name, days);
                    else tPrintToChat(client, "%t", "open and sell permanent chat", g_szCase[g_iClientCase[client]], name);
                    Store_SaveClientAll(client);
                    g_iDataProtect[client] = GetTime()+10;
                    g_iSelectedItem[client] = itemid;
                    FormatEx(m_szQuery, 256, "INSERT INTO store_opencase VALUES (DEFAULT, %d, '%s', %d, %d, 'add', %d)", g_eClients[client][iId], g_eItems[itemid][szUniqueId], days, GetTime(), g_iClientCase[client]);
                }

                SQL_TVoid(g_hDatabase, m_szQuery);
            }
        }
    }
}

public void DisplayItemMenu(int client, int itemid)
{
    if(!Store_HasClientItem(client, itemid))
    {
        if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "playerskin"))
            DisplayPreviewMenu(client, itemid);
        return;
    }

    g_iMenuNum[client] = 1;
    g_iMenuBack[client] = g_eItems[itemid][iParent];

    Handle m_hMenu = CreateMenu(MenuHandler_Item);
    SetMenuExitBackButton(m_hMenu, true);
    
    bool m_bEquipped = UTIL_IsEquipped(client, itemid);
    char m_szTitle[256];
    int idx = 0;
    if(m_bEquipped)
        idx = FormatEx(STRING(m_szTitle), "%T\n%T", "Item Equipped", client, g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);
    else
        idx = FormatEx(STRING(m_szTitle), "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);

    int m_iExpiration = UTIL_GetExpiration(client, itemid);
    if(m_iExpiration != 0)
    {
        m_iExpiration = m_iExpiration-GetTime();
        int m_iDays = m_iExpiration/(24*60*60);
        int m_iHours = (m_iExpiration-m_iDays*24*60*60)/(60*60);
        FormatEx(m_szTitle[idx-1], sizeof(m_szTitle)-idx-1, "\n%T", "Title Expiration", client, m_iDays, m_iHours);
    }
    
    SetMenuTitleEx(m_hMenu, m_szTitle);

    if(g_eTypeHandlers[g_eItems[itemid][iHandler]][bEquipable])
    {
        if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "playerskin"))
        {
            AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%s", g_eItems[itemid][szDesc]);
    
            char leveltype[32];
            UTIL_GetLevelType(itemid, leveltype, 32);
            AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%T", "Playerskins Level", client, g_eItems[itemid][iLevels], leveltype);
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "4", "%T", "Open Case Available", client);
        }

        if(!m_bEquipped)
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%T", "Item Equip", client);
        else
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%T", "Item Unequip", client);
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
            if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
            {
                int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
                int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
                if(m_iLeft < 0)
                    m_iLeft = 0;
                m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
            }

            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "%T", "Item Sell", client, m_iCredits);
            if(g_eItems[itemid][bGiftable])
                AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%T", "Item Gift", client);
        }
    }

    for(int i = 0; i < g_iMenuHandlers; ++i)
    {
        if(g_eMenuHandlers[i][hPlugin] == null)
            continue;
        Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnMenu]);
        Call_PushCellRef(m_hMenu);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish();
    }

    DisplayMenu(m_hMenu, client, 0);
}

public void DisplayPlanMenu(int client, int itemid)
{
    g_iMenuNum[client] = 1;

    Handle m_hMenu = CreateMenu(MenuHandler_Plan);
    SetMenuExitBackButton(m_hMenu, true);
    
    SetMenuTitleEx(m_hMenu, "%s\n%T", g_eItems[itemid][szName], "Title Credits", client, g_eClients[client][iCredits]);
    
    for(int i = 0; i < g_eItems[itemid][iPlans]; ++i)
    {
        AddMenuItemEx(m_hMenu, (g_eClients[client][iCredits]>=g_ePlans[itemid][i][iPrice]?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), "", "%T",  "Item Available", client, g_ePlans[itemid][i][szName], g_ePlans[itemid][i][iPrice]);
    }
    
    DisplayMenu(m_hMenu, client, 0);
}

public void DisplayComposeMenu(int client, bool last)
{
    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        DisplayPreviewMenu(client, g_iSelectedItem[client]);
        return;
    }
    
    g_iMenuNum[client] = 1;
    Handle m_hMenu = CreateMenu(MenuHandler_Compose);
    SetMenuExitBackButton(m_hMenu, true);
    
    char sitem1[64];
    if(g_eCompose[client][item1] >= 0)
        strcopy(sitem1, 64, g_eItems[g_eCompose[client][item1]][szName]);
    else
        FormatEx(sitem1, 64, "%T", "unselect", client);
    
    char sitem2[64];
    if(g_eCompose[client][item2] >= 0)
        strcopy(sitem2, 64, g_eItems[g_eCompose[client][item2]][szName]);
    else
        FormatEx(sitem2, 64, "%T", "unselect", client);

    SetMenuTitleEx(m_hMenu, "%T", "Title Compose", client, g_eItems[g_iSelectedItem[client]][szName], sitem1, sitem2);

    int num=0;

    if(!last)
    {
        char m_szId[8];
        for(int i = 0; i < g_iItems; ++i)
        {
            if(g_eItems[i][iHandler] == g_iPackageHandler)
                continue;
            
            if(!Store_HasClientItem(client, i))
                continue;

            if(i == g_eCompose[client][item1] || i == g_eCompose[client][item2])
                continue;

            if(!StrEqual(g_eTypeHandlers[g_eItems[i][iHandler]][szType], "playerskin"))
                continue;
            
            if(!g_eItems[i][bGiftable] || g_eItems[i][bCompose])
                continue;

            int uid = UTIL_GetClientItemId(client, i);
            
            if(uid < 0 || g_eClientItems[client][uid][iDateOfExpiration] != 0 || g_eClientItems[client][uid][iPriceOfPurchase] < 1)
                continue;

            num++;
            IntToString(i, m_szId, 8);
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szId, g_eItems[i][szName]);
        }
    }
    else
    {
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "Mode ① [60%%]");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "Mode ② [65%%]");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "Mode ③ [70%%]");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "Mode ④ [75%%]");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "4", "Mode ⑤ [80%%]");
        AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "5", "Mode ⑥ [99%%]");
        num=6;
    }

    if(num > 0)
        DisplayMenu(m_hMenu, client, 0);
    else
    {
        CloseHandle(m_hMenu);
        tPrintToChat(client, "%T", "Compose no material", client);
        Store_DisplayPreviousMenu(client);
    }
}

public int MenuHandler_Compose(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
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
            GetMenuItem(menu, param2, STRING(m_szId));
            int itemid = StringToInt(m_szId);
            g_iMenuNum[client] = 6;
            if(g_eCompose[client][item1]==-1)
            {
                g_eCompose[client][item1]=itemid;
                DisplayComposeMenu(client, false);
            }
            else if(g_eCompose[client][item2]==-1)
            {
                g_eCompose[client][item2]=itemid;
                DisplayComposeMenu(client, true);
            }
            else if(0 <= itemid <= 5 && g_eCompose[client][item1] >= 0 && g_eCompose[client][item2] >= 0 && Store_HasClientItem(client, g_eCompose[client][item1]) && Store_HasClientItem(client, g_eCompose[client][item2]))
            {
                g_eCompose[client][types]=itemid;
                char m_szTitle[256], m_szTypes[32];
                switch(itemid)
                {
                    case 0: strcopy(m_szTypes, 32,  "5000");
                    case 1: strcopy(m_szTypes, 32, "10000");
                    case 2: strcopy(m_szTypes, 32, "15000");
                    case 3: strcopy(m_szTypes, 32, "20000");
                    case 4: strcopy(m_szTypes, 32, "25000");
                    case 5: strcopy(m_szTypes, 32, "88888");
                }
                FormatEx(m_szTitle, 256, "%T", "Confirm_Compose", client, g_eItems[g_iSelectedItem[client]][szName], g_eItems[g_eCompose[client][item1]][szName], g_eItems[g_eCompose[client][item2]][szName], m_szTypes);
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Compose, 0);
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
        {
            g_eCompose[client][item1] = -1;
            g_eCompose[client][item2] = -1;
            g_eCompose[client][types] = -1;
            Store_DisplayPreviousMenu(client);
        }
}

public int MenuHandler_Plan(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
    else if(action == MenuAction_Select)
    {
        g_iSelectedPlan[client]=param2;
        g_iMenuNum[client]=5;

        char m_szTitle[128];
        FormatEx(STRING(m_szTitle), "%T", "Confirm_Buy", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType]);
        Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
        return;
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

public int MenuHandler_Item(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
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
            GetMenuItem(menu, param2, STRING(m_szId));
            
            int m_iId = StringToInt(m_szId);
            
            // Menu handlers
            if(!(48 <= m_szId[0] <= 57)) //ASCII 0~9
            {
                int ret;
                for(int i=0;i<g_iMenuHandlers;++i)
                {
                    if(g_eMenuHandlers[i][hPlugin] == null)
                        continue;
                    Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnHandler]);
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
                if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
                {
                    int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
                    int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
                    if(m_iLeft < 0)
                        m_iLeft = 0;
                    m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
                }

                char m_szTitle[128];
                FormatEx(STRING(m_szTitle), "%T", "Confirm_Sell", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], m_iCredits);
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
                if(g_eClients[client][iCredits] >= 8888)
                    UTIL_OpenSkinCase(client);
                else
                    tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, 8888);
#else
                tPrintToChat(client, "%T", "Open Case not available", client);
#endif
            }
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            Store_DisplayPreviousMenu(client);
}

public void DisplayPlayerMenu(int client)
{
    g_iMenuNum[client] = 3;

    int m_iCount = 0;
    Handle m_hMenu = CreateMenu(MenuHandler_Gift);
    SetMenuExitBackButton(m_hMenu, true);
    SetMenuTitleEx(m_hMenu, "%T\n%T", "Title Gift", client, "Title Credits", client, g_eClients[client][iCredits]);
    
    char m_szID[11];
    for(int i = 1; i <= MaxClients; ++i)
    {
        if(!IsClientInGame(i))
            continue;

        if(!AllowItemForAuth(client, g_eItems[g_iSelectedItem[client]][szSteam]) || !AllowItemForVIP(client, g_eItems[g_iSelectedItem[client]][bVIP]))
            continue;
        if(i != client && IsClientInGame(i) && !Store_HasClientItem(i, g_iSelectedItem[client]))
        {
            IntToString(g_eClients[i][iUserId], STRING(m_szID));
            AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szID, "%N", i);
            ++m_iCount;
        }
    }
    
    if(m_iCount == 0)
    {
        CloseHandle(m_hMenu);
        g_iMenuNum[client] = 1;
        DisplayItemMenu(client, g_iSelectedItem[client]);
        tPrintToChat(client, "%T", "Gift No Players", client);
    }
    else
        DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Gift(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
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
            GetMenuItem(menu, param2, STRING(m_szId));
            
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
                FormatEx(STRING(m_szTitle), "%T\n%T", "Confirm_Gift", client, g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], m_iReceiver, "Gift_Handing", client, m_iFees);
                Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Gift, m_iId);
            }
            else
                tPrintToChat(client, " \x02UNKNOWN ERROR\x01 :  \x07%d", UTIL_GetRandomInt(100000, 999999));
        }
    }
    else if(action==MenuAction_Cancel)
        if(param2 == MenuCancel_ExitBack)
            DisplayItemMenu(client, g_iSelectedItem[client]);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int param2)
{
    if(action == MenuAction_End)
        CloseHandle(menu);
    else if(action == MenuAction_Select)
    {        
        if(param2 == 0)
        {
            char m_szCallback[32];
            char m_szData[11];
            GetMenuItem(menu, 0, STRING(m_szCallback));
            GetMenuItem(menu, 1, STRING(m_szData));
            Handle pack = view_as<Handle>(StringToInt(m_szCallback));
            Handle m_hPlugin = ReadPackCell(pack);
            Function fnMenuCallback = ReadPackCell(pack);
            CloseHandle(pack);
            if(m_hPlugin != null && fnMenuCallback != INVALID_FUNCTION)
            {
                Call_StartFunction(m_hPlugin, fnMenuCallback);
                Call_PushCell(INVALID_HANDLE);
                Call_PushCell(MenuAction_Select);
                Call_PushCell(client);
                Call_PushCell(StringToInt(m_szData));
                Call_Finish();
            }
            else
                Store_DisplayPreviousMenu(client);
        }
        else
        {
            Store_DisplayPreviousMenu(client);
        }
    }
}

//////////////////////////////
//          TIMER           //
//////////////////////////////
public Action Timer_DatabaseTimeout(Handle timer, int userid)
{
    // Database is connected successfully
    if(g_hDatabase != null)
        return Plugin_Stop;

    if(g_iDatabaseRetries < 100)
    {
        SQL_TConnect(SQLCallback_Connect, "csgo");
        CreateTimer(30.0, Timer_DatabaseTimeout);
        ++g_iDatabaseRetries;
    }
    else
    {
        SetFailState("Database connection failed to initialize after 100 retrie");
    }

    return Plugin_Stop;
}

//////////////////////////////
//       SQL CALLBACK       //
//////////////////////////////
public void SQLCallback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
    if(hndl==null)
        LogError("Failed to connect to SQL database. Error: %s", error);
    else
    {
        // If it's already connected we are good to go
        if(g_hDatabase != null)
            return;

        g_hDatabase = hndl;

        // Do some housekeeping
        SQL_SetCharset(g_hDatabase, "utf8");
        
        char m_szQuery[256];
        FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `date_of_expiration` <> 0 AND `date_of_expiration` < %d", GetTime());
        SQL_TVoid(g_hDatabase, m_szQuery);

        // Load configs
        UTIL_ReloadConfig();

        // if Loaded late.
        if(g_bLateLoad)
        {
            for(int client = 1; client <= MaxClients; ++client)
            {
                if(!IsClientInGame(client))
                    continue;

                OnClientConnected(client);
                OnClientPostAdminCheck(client);
            }
        }
    }
}

public void SQLCallback_LoadClientInventory_Credits(Handle owner, Handle hndl, const char[] error, int userid)
{
    if(hndl==null)
        LogError("Error happened. Error: %s", error);
    else
    {
        int client = GetClientOfUserId(userid);
        if(!client)
            return;
        
        char m_szQuery[512], m_szSteamID[32];
        int m_iTime = GetTime();
        g_eClients[client][iUserId] = userid;
        g_eClients[client][iItems] = -1;
        GetClientAuthId(client, AuthId_Steam2, STRING(m_szSteamID), true);
        strcopy(g_eClients[client][szAuthId], 32, m_szSteamID[8]);
        
        if(SQL_FetchRow(hndl))
        {
            g_eClients[client][iId] = SQL_FetchInt(hndl, 0);
            g_eClients[client][iCredits] = SQL_FetchInt(hndl, 3);
            g_eClients[client][iOriginalCredits] = SQL_FetchInt(hndl, 3);
            g_eClients[client][iDateOfJoin] = SQL_FetchInt(hndl, 4);
            g_eClients[client][iDateOfLastJoin] = m_iTime;
            g_eClients[client][bBan] = (SQL_FetchInt(hndl, 6) == 1 || g_eClients[client][iCredits] < 0) ? true : false;
            
            if(g_eClients[client][bBan])
            {
                g_eClients[client][bLoaded] = true;
                g_eClients[client][iItems] = 0;
                tPrintToChat(client, "%T", "Inventory has been loaded", client);
            }
            else
            {
                FormatEx(STRING(m_szQuery), "SELECT * FROM store_items WHERE `player_id`=%d", g_eClients[client][iId]);
                SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Items, m_szQuery, userid);
            }

            UTIL_LogMessage(client, 0, "Joined");
            g_iDataProtect[client] = GetTime()+90;
        }
        else
        {
            char m_szName[64], m_szEName[128];
            GetClientName(client, m_szName, 64);
            SQL_EscapeString(g_hDatabase, m_szName, m_szEName, 128);
            FormatEx(STRING(m_szQuery), "INSERT INTO store_players (`authid`, `name`, `credits`, `date_of_join`, `date_of_last_join`, `ban`) VALUES(\"%s\", '%s', 300, %d, %d, '0')", g_eClients[client][szAuthId], m_szEName, m_iTime, m_iTime);
            SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, userid);
        }
    }
}

public void SQLCallback_LoadClientInventory_Items(Handle owner, Handle hndl, const char[] error, int userid)
{
    if(hndl==null)
        LogError("Error happened. Error: %s", error);
    else
    {    
        int client = GetClientOfUserId(userid);
        if(!client)
            return;
        
        char m_szQuery[512];

        if(SQL_GetRowCount(hndl) <= 0)
        {
            if(UTIL_GetTotalInventoryItems(client) > 0)
            {
                FormatEx(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
                SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid);
                return;
            }
            g_eClients[client][bLoaded] = true;
            tPrintToChat(client, "%T", "Inventory has been loaded", client);
            g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
            FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
            SQL_TVoid(g_hDatabase, m_szQuery);
        }

        char m_szUniqueId[PLATFORM_MAX_PATH];
        char m_szType[16];
        int m_iExpiration;
        int m_iUniqueId;
        int m_iTime = GetTime();
        
        int i = 0;
        while(SQL_FetchRow(hndl))
        {
            m_iUniqueId = -1;
            m_iExpiration = SQL_FetchInt(hndl, 5);
            if(m_iExpiration && m_iExpiration <= m_iTime)
                continue;
            
            SQL_FetchString(hndl, 2, STRING(m_szType));
            SQL_FetchString(hndl, 3, STRING(m_szUniqueId));

            while((m_iUniqueId = UTIL_GetItemId(m_szUniqueId, m_iUniqueId)) != -1)
            {
                g_eClientItems[client][i][iId] = SQL_FetchInt(hndl, 0);
                g_eClientItems[client][i][iUniqueId] = m_iUniqueId;
                g_eClientItems[client][i][bSynced] = true;
                g_eClientItems[client][i][bDeleted] = false;
                g_eClientItems[client][i][iDateOfPurchase] = SQL_FetchInt(hndl, 4);
                g_eClientItems[client][i][iDateOfExpiration] = m_iExpiration;
                g_eClientItems[client][i][iPriceOfPurchase] = SQL_FetchInt(hndl, 6);
                ++i;
            }
        }
        g_eClients[client][iItems] = i;
        g_iDataProtect[client] = GetTime()+15;
        
#if defined DATA_VERIFY
        FormatEx(STRING(m_szQuery), "SELECT * FROM `store_newlogs` WHERE `store_id` = '%d' AND (`reason` = 'Disconnect' OR `reason` = 'Add Funds')  ORDER BY `timestamp` DESC LIMIT 1", g_eClients[client][iId]);
        SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_DATAVERIFY, m_szQuery, userid);
#endif

        if(i > 0)
        {
            FormatEx(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
            SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid);
        }
        else
        {
            g_eClients[client][bLoaded] = true;
            tPrintToChat(client, "%T", "Inventory has been loaded", client);
            g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
            FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
            SQL_TVoid(g_hDatabase, m_szQuery);
        }
    }
}

#if defined DATA_VERIFY
public void SQLCallback_LoadClientInventory_DATAVERIFY(Handle owner, Handle hndl, const char[] error, int userid)
{
    if(hndl==null)
        LogError("Error happened. Error: %s", error);
    else if(SQL_FetchRow(hndl))
    {
        int client = GetClientOfUserId(userid);
        if(!client)
            return;
        
        int credits = SQL_FetchInt(hndl, 0);
        
        int diff = g_eClients[client][iCredits] - credits;
        
        if(diff > 1000)
        {
            char m_szQuery[256];
            FormatEx(STRING(m_szQuery), "UPDATE `store_players` SET `ban` = 1, `credits` = -1 WHERE `id` = '%d';", g_eClients[client][iId]);
            SQL_TVoid(g_hDatabase, m_szQuery);

            LogMessage("[CAT]  Store Inject detected :  \"%L\" -> credits[%d] -> loaded[%d] -> diff[%d]", client, credits, g_eClients[client][iCredits], diff);
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

public void SQLCallback_LoadClientInventory_Equipment(Handle owner, Handle hndl, const char[] error, int userid)
{
    if(hndl==null)
        LogError("Error happened. Error: %s", error);
    else
    {
        int client = GetClientOfUserId(userid);
        if(!client)
            return;

        char m_szUniqueId[PLATFORM_MAX_PATH];
        char m_szType[16];
        int m_iUniqueId, m_iSlot;

        while(SQL_FetchRow(hndl))
        {
            SQL_FetchString(hndl, 1, STRING(m_szType));
            SQL_FetchString(hndl, 2, STRING(m_szUniqueId));
            m_iUniqueId = UTIL_GetItemId(m_szUniqueId);
            if(m_iUniqueId == -1)
                continue;

            m_iSlot = SQL_FetchInt(hndl, 3);

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
        g_eClients[client][bLoaded] = true;
        tPrintToChat(client, "%T", "Inventory has been loaded", client);
        g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
    }
}

public void SQLCallback_InsertClient(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    if(hndl==null)
    {
        LogError("Error happened. Error: %s", error);
        KickClient(client, "Failed to check your store account.");
    }
    else
    {
        g_eClients[client][iId] = SQL_GetInsertId(hndl);
        g_eClients[client][iCredits] = 0;
        g_eClients[client][iOriginalCredits] = 0;
        g_eClients[client][iDateOfJoin] = GetTime();
        g_eClients[client][iDateOfLastJoin] = g_eClients[client][iDateOfJoin];
        g_eClients[client][iItems] = 0;
        g_eClients[client][bLoaded] = true;
        g_iDataProtect[client] = GetTime()+90;
        g_eClients[client][hTimer] = CreateTimer(300.0, Timer_OnlineCredit, client, TIMER_REPEAT);
    }
}

//////////////////////////////
//          STOCK           //
//////////////////////////////
void UTIL_LoadClientInventory(int client)
{
    if(g_hDatabase == null)
    {
        LogError("Database connection is lost or not yet initialized.");
        return;
    }
    
    char m_szQuery[512];
    char m_szAuthId[32];

    GetClientAuthId(client, AuthId_Steam2, STRING(m_szAuthId), true);
    if(m_szAuthId[0] == 0)
        return;

    FormatEx(STRING(m_szQuery), "SELECT * FROM store_players WHERE `authid`=\"%s\"", m_szAuthId[8]);

    SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Credits, m_szQuery, g_eClients[client][iUserId]);
}

void UTIL_SaveClientInventory(int client)
{
    if(g_hDatabase == null)
    {
        LogError("Database connection is lost or not yet initialized.");
        return;
    }
    
    // Player disconnected before his inventory was even fetched
    if(g_eClients[client][iCredits]==-1 && g_eClients[client][iItems]==-1)
        return;
    
    char m_szQuery[512];
    char m_szType[16];
    char m_szUniqueId[PLATFORM_MAX_PATH];

    for(int i = 0; i < g_eClients[client][iItems]; ++i)
    {
        strcopy(STRING(m_szType), g_eTypeHandlers[g_eItems[g_eClientItems[client][i][iUniqueId]][iHandler]][szType]);
        strcopy(STRING(m_szUniqueId), g_eItems[g_eClientItems[client][i][iUniqueId]][szUniqueId]);
    
        if(!g_eClientItems[client][i][bSynced] && !g_eClientItems[client][i][bDeleted])
        {
            g_eClientItems[client][i][bSynced] = true;
            FormatEx(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", %d, %d, %d)", g_eClients[client][iId], m_szType, m_szUniqueId, g_eClientItems[client][i][iDateOfPurchase], g_eClientItems[client][i][iDateOfExpiration], g_eClientItems[client][i][iPriceOfPurchase]);
            SQL_TVoid(g_hDatabase, m_szQuery);
        }
        else if(g_eClientItems[client][i][bSynced] && g_eClientItems[client][i][bDeleted])
        {
            // Might have been synced already but ID wasn't acquired
            if(g_eClientItems[client][i][iId]==-1)
                FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `player_id`=%d AND `type`=\"%s\" AND `unique_id`=\"%s\"", g_eClients[client][iId], m_szType, m_szUniqueId);
            else
                FormatEx(STRING(m_szQuery), "DELETE FROM store_items WHERE `id`=%d", g_eClientItems[client][i][iId]);
            SQL_TVoid(g_hDatabase, m_szQuery);
            g_eClientItems[client][i][bSynced] = false;
        }
    }
}

void UTIL_SaveClientEquipment(int client)
{
    char m_szQuery[512];
    int m_iId;
    for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
    {
        for(int a = 0; a < STORE_MAX_SLOTS; ++a)
        {
            m_iId = i*STORE_MAX_SLOTS+a;
            if(g_eClients[client][aEquipmentSynced][m_iId] == g_eClients[client][aEquipment][m_iId])
                continue;
            else if(g_eClients[client][aEquipmentSynced][m_iId] != -2)
            {
                if(g_eClients[client][aEquipment][m_iId]==-1)
                    FormatEx(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
                else
                    FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);

                //FormatEx(STRING(m_szQuery), "UPDATE store_equipment SET `unique_id`=\"%s\" WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
            }
            else
                FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d) ON DUPLICATE KEY UPDATE `unique_id` = VALUES(`unique_id`)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);
            
            //FormatEx(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);

            SQL_TVoid(g_hDatabase, m_szQuery);
            g_eClients[client][aEquipmentSynced][m_iId] = g_eClients[client][aEquipment][m_iId];
        }
    }
}

void UTIL_SaveClientData(int client, bool disconnect)
{
    if(g_hDatabase == null)
    {
        LogError("Database connection is lost or not yet initialized.");
        return;
    }
    
    if((g_eClients[client][iCredits]==-1 && g_eClients[client][iItems]==-1) || !g_eClients[client][bLoaded])
        return;
    
    if(!disconnect && g_eClients[client][bRefresh])
        return;
    
    char m_szQuery[512], m_szName[64], m_szEName[128];
    GetClientName(client, m_szName, 64);
    SQL_EscapeString(g_hDatabase, m_szName, m_szEName, 128);
    FormatEx(STRING(m_szQuery), "UPDATE store_players SET `credits`=`credits`+%d, `date_of_last_join`=%d, `name`='%s' WHERE `id`=%d", g_eClients[client][iCredits]-g_eClients[client][iOriginalCredits], g_eClients[client][iDateOfLastJoin], m_szEName, g_eClients[client][iId]);

    if(disconnect)
    {
        g_eClients[client][iOriginalCredits] = g_eClients[client][iCredits];
        SQL_TVoid(g_hDatabase, m_szQuery);
        UTIL_LogMessage(client, 0, "Disconnect");
    }
    else
    {
        g_eClients[client][bRefresh] = true;
        SQL_TQuery(g_hDatabase, SQLCallback_RefreshCredits, m_szQuery, GetClientUserId(client));
    }
}

public void SQLCallback_RefreshCredits(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;
    
    g_eClients[client][bRefresh] = false;
    
    if(hndl == null)
    {
        LogError("Refresh \"%L\" data failed :  %s", client, error);
        return;
    }

    g_eClients[client][iOriginalCredits] = g_eClients[client][iCredits];
}

void UTIL_DisconnectClient(int client)
{
    ClearTimer(g_eClients[client][hTimer]);
    g_eClients[client][iCredits] = -1;
    g_eClients[client][iOriginalCredits] = -1;
    g_eClients[client][iItems] = -1;
    g_eClients[client][bLoaded] = false;
}

int UTIL_GetItemId(const char[] uid, int start = -1)
{
    for(int i = start+1; i < g_iItems; ++i)
        if(strcmp(g_eItems[i][szUniqueId], uid)==0 && g_eItems[i][iPrice] >= 0)
            return i;
    return -1;
}

public void SQLCallback_BuyItem(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);
    if(!client)
        return;

    if(hndl == null)
    {
        LogError("Error happened. Error: %s", error);
    }
    else
    {
        if(SQL_FetchRow(hndl))
        {
            int dbCredits = SQL_FetchInt(hndl, 0);
            int itemid = g_iSelectedItem[client];
            int plan = g_iSelectedPlan[client];

            int m_iPrice = 0;
            if(plan==-1)
                m_iPrice = g_eItems[itemid][iPrice];
            else
                m_iPrice = g_ePlans[itemid][plan][iPrice];    
            
            if(dbCredits != g_eClients[client][iOriginalCredits])
            {
                int diff = dbCredits - g_eClients[client][iOriginalCredits];
                g_eClients[client][iOriginalCredits] = dbCredits;
                g_eClients[client][iCredits] += diff;
                UTIL_LogMessage(client, diff, "Credits changed in database (sync credits from database)");
            }
            
            g_eClients[client][bRefresh] = false;

            if(g_eClients[client][iCredits]<m_iPrice || g_eItems[itemid][bCompose])
            {
                DisplayItemMenu(client, g_iSelectedItem[client]);
                return;
            }

            int m_iId = g_eClients[client][iItems]++;
            g_eClientItems[client][m_iId][iId] = -1;
            g_eClientItems[client][m_iId][iUniqueId] = itemid;
            g_eClientItems[client][m_iId][iDateOfPurchase] = GetTime();
            g_eClientItems[client][m_iId][iDateOfExpiration] = (plan==-1?0:(g_ePlans[itemid][plan][iTime]?GetTime()+g_ePlans[itemid][plan][iTime]:0));
            g_eClientItems[client][m_iId][iPriceOfPurchase] = m_iPrice;
            g_eClientItems[client][m_iId][bSynced] = false; //true
            g_eClientItems[client][m_iId][bDeleted] = false;

            g_eClients[client][iCredits] -= m_iPrice;
            UTIL_LogMessage(client, -m_iPrice, "Bought %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

            Store_SaveClientAll(client);

            tPrintToChat(client, "%T", "Chat Bought Item", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

            DisplayItemMenu(client, g_iSelectedItem[client]);
        }
    }
}

void UTIL_ComposeItem(int client)
{
    if(g_eCompose[client][item2] < 0 || g_eCompose[client][item1] < 0 || g_eCompose[client][types] < 0 || g_iSelectedItem[client] < 0)
        return;
    
    if(!Store_HasClientItem(client, g_eCompose[client][item2]) || !Store_HasClientItem(client, g_eCompose[client][item1]) || Store_HasClientItem(client, g_iSelectedItem[client]))
        return;
    
    int m_iFees;
    switch(g_eCompose[client][types])
    {
        case 0 : m_iFees =  5000;
        case 1 : m_iFees = 10000;
        case 2 : m_iFees = 15000;
        case 3 : m_iFees = 20000;
        case 4 : m_iFees = 25000;
        case 5 : m_iFees = 88888;
        default: m_iFees = 999999;
    }

    if(Store_GetClientCredits(client) < m_iFees || m_iFees < 0)
    {
        tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
        return;
    }

    Store_RemoveItem(client, g_eCompose[client][item2]);
    Store_RemoveItem(client, g_eCompose[client][item1]);
    
    char reason[128];
    FormatEx(STRING(reason), "Compose Fee[%s]", g_eItems[g_iSelectedItem[client]][szName]);
    Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, reason);
    
    int probability = 0;
    switch(g_eCompose[client][types])
    {
        case 0 : probability = 600000;
        case 1 : probability = 650000;
        case 2 : probability = 700000;
        case 3 : probability = 750000;
        case 4 : probability = 800000;
        case 5 : probability = 999999;
        default: probability = 0;
    }

    if(UTIL_GetRandomInt(0, 1000000) > probability)
    {
        tPrintToChat(client, "Compose Failed", client);
        return;
    }

    Store_GiveItem(client, g_iSelectedItem[client], GetTime(), 0, 99999);
    
    Store_SaveClientAll(client);
    
    g_iDataProtect[client] = GetTime()+30;

    tPrintToChat(client, "Compose successfully", client, g_eItems[g_iSelectedItem[client]][szName]);
    
    tPrintToChatAll("%t", "Compose successfully broadcast", client, g_eItems[g_iSelectedItem[client]][szName]);
}

void UTIL_BuyItem(int client)
{
#if defined Module_Skin
    if(g_tKillPreview[client] != null) TriggerTimer(g_tKillPreview[client], false);
#endif

    if(g_eItems[g_iSelectedItem[client]][iHandler] == g_iPackageHandler)
        return;

    if(Store_HasClientItem(client, g_iSelectedItem[client]))
    {
        DisplayItemMenu(client, g_iSelectedItem[client]);
        return;
    }

    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        DisplayItemMenu(client, g_iSelectedItem[client]);
        return;
    }
    g_iDataProtect[client] = GetTime()+15;
    char m_szQuery[255];
    FormatEx(STRING(m_szQuery), "SELECT credits FROM store_players WHERE `id`=%d", g_eClients[client][iId]);
    SQL_TQuery(g_hDatabase, SQLCallback_BuyItem, m_szQuery, g_eClients[client][iUserId]);
    g_eClients[client][bRefresh] = true;
}

void UTIL_SellItem(int client, int itemid)
{
    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        DisplayItemMenu(client, itemid);
        return;
    }

    g_iDataProtect[client] = GetTime()+15;
    int m_iCredits = RoundToFloor(UTIL_GetClientItemPrice(client, itemid)*0.6);
    int uid = UTIL_GetClientItemId(client, itemid);
    if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
    {
        int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
        int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
        if(m_iLeft<0)
            m_iLeft = 0;
        m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
    }
    g_eClients[client][iCredits] += m_iCredits;
    tPrintToChat(client, "%T", "Chat Sold Item", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

    UTIL_LogMessage(client, m_iCredits, "Sold %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

    Store_RemoveItem(client, itemid);

    Store_SaveClientAll(client);
    
    Store_DisplayPreviousMenu(client);
}

void UTIL_GiftItem(int client, int receiver, int item)
{
    int m_iId = g_eClientItems[client][item][iUniqueId];

    if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded]
        || (g_eClients[receiver][iCredits] == -1 && g_eClients[receiver][iItems] == -1) || !g_eClients[receiver][bLoaded]) {
        return;
    }

    if(g_iDataProtect[client] > GetTime())
    {
        tPrintToChat(client, "%T", "data protect", client, g_iDataProtect[client]-GetTime());
        DisplayItemMenu(client, m_iId);
        return;
    }

    g_iDataProtect[client] = GetTime()+15;
    g_iDataProtect[receiver] = GetTime()+15;

    int m_iFees = UTIL_GetClientHandleFees(client, m_iId);
    
    if(m_iFees < 0)
    {
        tPrintToChat(client, " \x02UNKNOWN ERROR\x01 :  \x07%d", UTIL_GetRandomInt(100000, 999999));
        return;
    }

    if(m_iFees > g_eClients[client][iCredits])
    {
        tPrintToChat(client, "%T", "Chat Not Enough Handing Fee", client, m_iFees);
        return;
    }

    char reason[128];
    FormatEx(STRING(reason), "Giftd [%s] Fee", g_eItems[m_iId][szName]);
    Store_SetClientCredits(client, Store_GetClientCredits(client)-m_iFees, reason);

    g_eClientItems[client][item][bDeleted] = true;
    UTIL_UnequipItem(client, m_iId);

    g_eClientItems[receiver][g_eClients[receiver][iItems]][iId] = -1;
    g_eClientItems[receiver][g_eClients[receiver][iItems]][iUniqueId] = m_iId;
    g_eClientItems[receiver][g_eClients[receiver][iItems]][bSynced] = false;
    g_eClientItems[receiver][g_eClients[receiver][iItems]][bDeleted] = false;
    g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfPurchase] = g_eClientItems[client][item][iDateOfPurchase];
    g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfExpiration] = g_eClientItems[client][item][iDateOfExpiration];
    g_eClientItems[receiver][g_eClients[receiver][iItems]][iPriceOfPurchase] = g_eClientItems[client][item][iPriceOfPurchase];

    ++g_eClients[receiver][iItems];

    tPrintToChat(client, "%T", "Chat Gift Item Sent", client, receiver, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
    tPrintToChat(receiver, "%T", "Chat Gift Item Received", receiver, client, g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);

    UTIL_LogMessage(client  , 0, "Giftd %s to %N[%s]", g_eItems[m_iId][szName], receiver, g_eClients[receiver][szAuthId]);
    UTIL_LogMessage(receiver, 0, "Received %s from %N[%s]", g_eItems[m_iId][szName], client, g_eClients[client][szAuthId]);
    
    Store_SaveClientAll(client);
    Store_SaveClientAll(receiver);
}

int UTIL_GetClientItemId(int client, int itemid)
{
    for(int i = 0; i < g_eClients[client][iItems]; ++i)
    {
        if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
            return i;
    }

    return -1;
}

void UTIL_ReloadConfig()
{
    g_iItems = 0;

    for(int i = 0; i < g_iTypeHandlers; ++i)
    {
        if(g_eTypeHandlers[i][fnReset] != INVALID_FUNCTION)
        {
            Call_StartFunction(g_eTypeHandlers[i][hPlugin], g_eTypeHandlers[i][fnReset]);
            Call_Finish();
        }
    }

    char error[256];
    Database ItemDB = SQL_Connect("csgo", false, error, 256);
    if(ItemDB == null)
        SetFailState("Connect to Item Database failed: %s", error);
    else
        SQL_SetCharset(ItemDB, "utf8");

    DBResultSet item_parent = SQL_Query(ItemDB, "SELECT * FROM store_item_parent ORDER BY `parent` ASC, `id` ASC;");
    if(item_parent == null)
    {
        SQL_GetError(ItemDB, error, 256);
        SetFailState("Can not retrieve item.parent from database: %s", error);
    }

    if(item_parent.RowCount <= 0)
        SetFailState("Can not retrieve item.child from database: no result row");

    while(item_parent.FetchRow())
    {
        g_iItems = item_parent.FetchInt(0);
        item_parent.FetchString(1, g_eItems[g_iItems][szName], 64);
        g_eItems[g_iItems][iParent] = item_parent.FetchInt(2);
        g_eItems[g_iItems][iHandler] = g_iPackageHandler;
    }
    
    g_iItems++;

    DBResultSet item_child = SQL_Query(ItemDB, "SELECT a.*,b.name as title FROM store_item_child a LEFT JOIN store_item_parent b ON b.id = a.parent ORDER BY b.id ASC, a.parent ASC");
    if(item_child == null)
    {
        SQL_GetError(ItemDB, error, 256);
        SetFailState("Can not retrieve item.child from database: %s", error);
    }

    if(item_child.RowCount <= 0)
        SetFailState("Can not retrieve item.child from database: no result row");
    
    ArrayList item_array = new ArrayList(ByteCountToCells(256));

    while(item_child.FetchRow())
    {
        // Field 0 -> parent
        g_eItems[g_iItems][iParent] = item_child.FetchInt(0);

        // Field 1 -> type
        char m_szType[32];
        item_child.FetchString(1, m_szType, 32);
        if(strcmp(m_szType, "ITEM_ERROR") == 0)
            continue;

        int m_iHandler = UTIL_GetTypeHandler(m_szType);
        if(m_iHandler == -1)
            continue;
        g_eItems[g_iItems][iHandler] = m_iHandler;
        
        // Field 2 -> uid
        char m_szUniqueId[32];
        item_child.FetchString(2, m_szUniqueId, 32);

        // Ignore bad item or dumplicate item
        if(strcmp(m_szUniqueId, "ITEM_ERROR") == 0 || item_array.FindString(m_szUniqueId) != -1)
            continue;
        item_array.PushString(m_szUniqueId);
        g_eItems[g_iItems][szUniqueId][0] = '\0';
        strcopy(g_eItems[g_iItems][szUniqueId], 32, m_szUniqueId);

        // Field 3 -> buyable
        char m_bitBuyable[2];
        item_child.FetchString(3, m_bitBuyable, 2);
        g_eItems[g_iItems][bBuyable] = (m_bitBuyable[0] == 1) ? true : false;

        // Field 4 -> giftable
        char m_bitGiftable[2];
        item_child.FetchString(4, m_bitGiftable, 2);
        g_eItems[g_iItems][bGiftable] = (m_bitGiftable[0] == 1) ? true : false;

        // Field 5 -> only
        char m_bitOnly[2];
        item_child.FetchString(5, m_bitOnly, 2);
        g_eItems[g_iItems][bIgnore] = (m_bitOnly[0] == 1) ? true : false;

        // Field 6 -> auth
        char m_szAuth[256];
        item_child.FetchString(6, m_szAuth, 256);
        g_eItems[g_iItems][szSteam][0] = '\0';
        if(strcmp(m_szAuth, "ITEM_NOT_PERSONAL") != 0)
            strcopy(g_eItems[g_iItems][szSteam], 256, m_szAuth);

        // Field 7 -> vip
        char m_bitVIP[2];
        item_child.FetchString(7, m_bitVIP, 2);
        g_eItems[g_iItems][bVIP] = (m_bitVIP[0] == 1) ? true : false;

        // Field 8 -> name
        item_child.FetchString(8, g_eItems[g_iItems][szName], 32);

        // Field 9 -> lvls
        g_eItems[g_iItems][iLevels] = item_child.FetchInt(9) + 1;

        // Field 10 -> desc
        char m_szDesc[128];
        item_child.FetchString(10, m_szDesc, 128);
        g_eItems[g_iItems][szDesc][0] = '\0';
        if(strcmp(m_szAuth, "ITEM_NO_DESC") != 0)
            strcopy(g_eItems[g_iItems][szDesc], 128, m_szDesc);

        // Field 11 -> case
        char m_bitCase[2];
        item_child.FetchString(11, m_bitCase, 2);
        g_eItems[g_iItems][bCase] = (m_bitCase[0] == 1) ? true : false;

        // Field 12 -> Compose
        char m_bitCompose[2];
        item_child.FetchString(12, m_bitCompose, 2);
        g_eItems[g_iItems][bCompose] = (m_bitCompose[0] == 1) ? true : false;

        // Field 13,14,15 -> price
        int price_1d = item_child.FetchInt(13);
        int price_1m = item_child.FetchInt(14);
        int price_pm = item_child.FetchInt(15);
        
        if(price_1d != 0 && price_1m != 0)
        {
            strcopy(g_ePlans[g_iItems][0][szName], 32, "1 day");
            g_ePlans[g_iItems][0][iPrice] = price_1d;
            g_ePlans[g_iItems][0][iTime] = 86400;
            
            strcopy(g_ePlans[g_iItems][1][szName], 32, "1 month");
            g_ePlans[g_iItems][1][iPrice] = price_1m;
            g_ePlans[g_iItems][1][iTime] = 2592000;
            
            strcopy(g_ePlans[g_iItems][2][szName], 32, "Permanent");
            g_ePlans[g_iItems][2][iPrice] = price_pm;
            g_ePlans[g_iItems][2][iTime] = 0;
   
            g_eItems[g_iItems][iPlans] = 3;
        }
        else
        {
            g_eItems[g_iItems][iPrice] = price_pm;
        }

        // Field 16 ~ 
        KeyValues kv = new KeyValues("Store", "", "");
        kv.JumpToKey(g_eItems[g_iItems][szName], true);
        //for(int field = 16; field < item_child.FieldCount; ++field)
        int count = item_child.FieldCount - 1;
        for(int field = 1; field < count; ++field)
        {
            char key[32], values[192];
            item_child.FieldNumToName(field, key, 32);
            item_child.FetchString(field, values, 192);
            if(StrContains(values, "ITEM_NO") == -1)
                kv.SetString(key, values);
        }
        
        bool m_bSuccess = true;
        if(g_eTypeHandlers[m_iHandler][fnConfig] != INVALID_FUNCTION)
        {
            Call_StartFunction(g_eTypeHandlers[m_iHandler][hPlugin], g_eTypeHandlers[m_iHandler][fnConfig]);
            Call_PushCell(kv);
            Call_PushCell(g_iItems);
            Call_Finish(m_bSuccess); 
        }

        delete kv;

        if(!m_bSuccess)
            continue;

        if(!g_eItems[g_iItems][bIgnore] && strcmp(m_szType, "playerskin", false) == 0 && StrContains(m_szUniqueId, "skin_", false) == 0)
            PushArrayString(g_ArraySkin, m_szUniqueId);

        ++g_iItems;
    }

    // girls frontline -> active
    ArrayList item_name = new ArrayList(ByteCountToCells(ITEM_NAME_LENGTH));
    ArrayList item_uid  = new ArrayList(ByteCountToCells(32));
    ArrayList item_idx  = new ArrayList();
    ArrayList item_lvl  = new ArrayList();
    
    for(int item = 0; item < g_iItems; ++item)
    {
        item_name.PushString(g_eItems[item][szName]);
        item_uid.PushString(g_eItems[item][szUniqueId]);
        item_idx.Push(g_eItems[item][iId]);
        item_lvl.Push(g_eItems[item][iLevels]);
    }

    Call_StartForward(g_hOnStoreAvailable);
    Call_PushCell(item_name);
    Call_PushCell(item_uid);
    Call_PushCell(item_idx);
    Call_PushCell(item_lvl);
    Call_Finish();

    delete item_name;
    delete item_uid;
    delete item_idx;
    delete item_lvl;
    delete item_array;
    delete item_parent;
    delete item_child;
    delete ItemDB;

    //OnMapStart();
    char map[128];
    GetCurrentMap(map, 128);
    if(strlen(map) > 3 && IsMapValid(map))
        ForceChangeLevel(map, "Reload Map to prevent server crash!");
}

int UTIL_GetTypeHandler(const char[] type)
{
    for(int i = 0; i < g_iTypeHandlers; ++i)
    {
        if(strcmp(g_eTypeHandlers[i][szType], type)==0)
            return i;
    }
    return -1;
}

int UTIL_GetMenuHandler(const char[] id)
{
    for(int i = 0; i < g_iMenuHandlers; ++i)
    {
        if(strcmp(g_eMenuHandlers[i][szIdentifier], id)==0)
            return i;
    }
    return -1;
}

bool UTIL_IsEquipped(int client, int itemid)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
        if(g_eClients[client][aEquipment][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+i] == itemid)
            return true;
    return false;
}

int UTIL_GetExpiration(int client, int itemid)
{
    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid<0)
        return 0;
    return g_eClientItems[client][uid][iDateOfExpiration];
}

int UTIL_UseItem(int client, int itemid, bool synced = false, int slot = 0)
{
    int m_iSlot = slot;
    if(g_eTypeHandlers[g_eItems[itemid][iHandler]][fnUse] != INVALID_FUNCTION)
    {
        int m_iReturn = -1;
        Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnUse]);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(m_iReturn);
        
        if(m_iReturn != -1)
            m_iSlot = m_iReturn;
    }

    if(g_eTypeHandlers[g_eItems[itemid][iHandler]][bEquipable])
    {
        g_eClients[client][aEquipment][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot]=itemid;
        if(synced)
            g_eClients[client][aEquipmentSynced][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot]=itemid;
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
    if(fn && itemid > 0 && g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove] != INVALID_FUNCTION)
    {
        Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove]);
        Call_PushCell(client);
        Call_PushCell(itemid);
        Call_Finish(m_iSlot);
    }

    int m_iId;
    if(g_eItems[itemid][iHandler] != g_iPackageHandler)
    {
        m_iId = g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+m_iSlot;
        if(g_eClients[client][aEquipmentSynced][m_iId]==-2)
            g_eClients[client][aEquipment][m_iId]=-2;
        else
            g_eClients[client][aEquipment][m_iId]=-1;
    }
    else
    {
        for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
        {
            for(int a = 0; i < STORE_MAX_SLOTS; ++i)
            {
                if(g_eClients[client][aEquipment][i+a] < 0)
                    continue;
                m_iId = i*STORE_MAX_SLOTS+a;
                if(Store_IsItemInBoughtPackage(client, g_eClients[client][aEquipment][m_iId], itemid))
                    if(g_eClients[client][aEquipmentSynced][m_iId]==-2)
                        g_eClients[client][aEquipment][m_iId]=-2;
                    else
                        g_eClients[client][aEquipment][m_iId]=-1;
            }
        }
    }
}

int UTIL_GetEquippedItemFromHandler(int client, int handler, int slot = 0)
{
    return g_eClients[client][aEquipment][handler*STORE_MAX_SLOTS+slot];
}

bool UTIL_PackageHasClientItem(int client, int packageid, bool invmode = false)
{
    if(g_eItems[packageid][szSteam][0] != 0 && AllowItemForAuth(client, g_eItems[packageid][szSteam]))
        return false;

    for(int i =0;i<g_iItems;++i)
       if(g_eItems[i][iParent] == packageid && ((invmode && Store_HasClientItem(client, i)) || !invmode))
            if((g_eItems[i][iHandler] == g_iPackageHandler && UTIL_PackageHasClientItem(client, i, invmode)) || g_eItems[i][iHandler] != g_iPackageHandler)
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
    SQL_EscapeString(g_hDatabase, m_szReason, EszReason, 513);
    FormatEx(STRING(m_szQuery), "INSERT INTO store_newlogs VALUES (DEFAULT, %d, %d, %d, \"%s\", %d)", g_eClients[client][iId], g_eClients[client][iCredits], diff, EszReason, GetTime());
    SQL_TVoid(g_hDatabase, m_szQuery);
}

int UTIL_GetLowestPrice(int itemid)
{
    if(g_eItems[itemid][iPlans]==0)
        return g_eItems[itemid][iPrice];

    int m_iLowest=g_ePlans[itemid][0][iPrice];
    for(int i = 1; i < g_eItems[itemid][iPlans]; ++i)
    {
        if(m_iLowest>g_ePlans[itemid][i][iPrice])
            m_iLowest = g_ePlans[itemid][i][iPrice];
    }

    return m_iLowest;
}

int UTIL_GetHighestPrice(int itemid)
{
    if(g_eItems[itemid][iPlans]==0)
        return g_eItems[itemid][iPrice];

    int m_iHighest=g_ePlans[itemid][0][iPrice];
    for(int i = 1; i < g_eItems[itemid][iPlans]; ++i)
    {
        if(m_iHighest<g_ePlans[itemid][i][iPrice])
            m_iHighest = g_ePlans[itemid][i][iPrice];
    }

    return m_iHighest;
}

int UTIL_GetClientItemPrice(int client, int itemid)
{
    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid<0)
        return 0;
        
    if(g_eClientItems[client][uid][iPriceOfPurchase] == 0)
        return g_eItems[itemid][iPrice];

    return g_eClientItems[client][uid][iPriceOfPurchase];
}

int UTIL_GetClientHandleFees(int client, int itemid)
{
    int uid = UTIL_GetClientItemId(client, itemid);
    if(uid<0)
        return 9999999;

    if(g_eClientItems[client][uid][iDateOfExpiration] == 0)
    {
        if(!g_eItems[itemid][bBuyable])
        {
            if(g_eItems[itemid][bCompose])
                return 15000;
            else
                return 30000;
        }
        else
        {
            if(g_eClientItems[client][uid][iPriceOfPurchase] < 1000)
                return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.2);
            else
                return RoundToFloor(g_eClientItems[client][uid][iPriceOfPurchase]*0.1);
        }
    }

    if(g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase] <= 2678400)
        return 100;

    if(g_eClientItems[client][uid][iPriceOfPurchase] < 1000)
        return RoundToFloor(UTIL_GetHighestPrice(itemid)*0.2);
    else
        return RoundToFloor(g_eClientItems[client][uid][iPriceOfPurchase]*0.1);
}

int UTIL_GetTotalInventoryItems(int client)
{
    int total = 0;
    for(int i = 0; i < g_iItems; ++i)
        if(g_eItems[i][iHandler] != g_iPackageHandler)
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

#if defined Module_Model
    Models_OnPluginStart();
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

    CheckClientTP(client);

#if defined Module_Model
    Models_OnPlayerDeath(client);
#endif

#if defined Module_Spray
    Spray_OnClientDeath(attacker);
#endif

#if defined Module_Sound
    Sound_OnClientDeath(client, attacker);
#endif
}

stock bool IsPlayerTP(int client)
{
#if defined Module_TPMode
    if(g_bThirdperson[client])
        return true;

    if(g_bMirror[client])
        return true;
#endif
    return false;
}

#define SIZE_OF_INT 2147483647
int UTIL_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();
    
    if(random == 0)
        random++;

    return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}

public Action Timer_OnlineCredit(Handle timer, int client)
{
    if(!IsClientInGame(client))
    {
        g_eClients[client][hTimer] = null;
        return Plugin_Stop;
    }

    int m_iCredits = 0;
    char szFrom[128], szReason[128];
    FormatEx(szFrom, 128, "\x10[");
    FormatEx(szReason, 128, "%T[", "online earn credits", client);

    m_iCredits += 2;
    StrCat(szFrom, 128, "\x04Online");
    StrCat(szReason, 128, "Online");

    StrCat(szFrom, 128, "\x10]");
    StrCat(szReason, 128, "]");

    if(!m_iCredits)
        return Plugin_Continue;

    Store_SetClientCredits(client, Store_GetClientCredits(client) + m_iCredits, szReason);

    tPrintToChat(client, "\x10%T", "earn credits chat", client, m_iCredits);
    PrintToChat(client, " \x0A%T%s", "earn credits from chat", client, szFrom);

    return Plugin_Continue;
}

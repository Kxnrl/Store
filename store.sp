#pragma semicolon 1
#pragma newdecls required
//////////////////////////////
//		DEFINITIONS			//
//////////////////////////////

#define PLUGIN_NAME "Store - The Resurrection"
#define PLUGIN_AUTHOR "Zephyrus | (maoling/Irelia/xQy)"
#define PLUGIN_DESCRIPTION "ALL REWRITE WITH NEW SYNTAX!!!"
#define PLUGIN_VERSION " 3.3.3 - 2016/12/21 05:21 - new syntax[6018] "
#define PLUGIN_URL ""

//////////////////////////////
//			INCLUDES		//
//////////////////////////////

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cg_core>
#include <store>
#include <store_stock>

#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#include <clientprefs>
#include <scp>
#include <fpvm_interface>

//////////////////////////////
//			ENUMS			//
//////////////////////////////
enum Client
{
	iId,
	iUserId,
	String:szAuthId[32],
	String:szName[64],
	String:szNameEscaped[128],
	iCredits,
	iOriginalCredits,
	iDateOfJoin,
	iDateOfLastJoin,
	iItems,
	aEquipment[STORE_MAX_HANDLERS*STORE_MAX_SLOTS],
	aEquipmentSynced[STORE_MAX_HANDLERS*STORE_MAX_SLOTS],
	bool:bBan,
	bool:bLoaded
}

enum Menu_Handler
{
	String:szIdentifier[64],
	Handle:hPlugin,
	Function:fnMenu,
	Function:fnHandler
}

//////////////////////////////////
//		GLOBAL VARIABLES		//
//////////////////////////////////

Handle g_hDatabase = INVALID_HANDLE;
Handle g_hKeyValue = INVALID_HANDLE;

int g_cvarGiftEnabled = -1;
int g_cvarConfirmation = -1;
int g_cvarShowVIP = -1;

Store_Item g_eItems[STORE_MAX_ITEMS][Store_Item];
Client g_eClients[MAXPLAYERS+1][Client];
Client_Item g_eClientItems[MAXPLAYERS+1][STORE_MAX_ITEMS][Client_Item];
Type_Handler g_eTypeHandlers[STORE_MAX_HANDLERS][Type_Handler];
Menu_Handler g_eMenuHandlers[STORE_MAX_HANDLERS][Menu_Handler];
Item_Plan g_ePlans[STORE_MAX_ITEMS][STORE_MAX_PLANS][Item_Plan];

int g_iItems = 0;
int g_iTypeHandlers = 0;
int g_iMenuHandlers = 0;
int g_iPackageHandler = -1;
int g_iDatabaseRetries = 0;

int g_iMenuBack[MAXPLAYERS+1];
int g_iLastSelection[MAXPLAYERS+1];
int g_iSelectedItem[MAXPLAYERS+1];
int g_iSelectedPlan[MAXPLAYERS+1];
int g_iMenuClient[MAXPLAYERS+1];
int g_iMenuNum[MAXPLAYERS+1];
int g_iSpam[MAXPLAYERS+1];

bool g_bInvMode[MAXPLAYERS+1];

bool g_bGameModeZE;
bool g_bGameModeTT;
bool g_bGameModeMG;
bool g_bGameModeKZ;
bool g_bGameModeJB;
bool g_bGameModeDR;
bool g_bGameModeNJ;
bool g_bGameModeHG;
bool g_bGameModePR;
bool g_bGameModeHZ;

bool g_bLateLoad;
bool g_bItemSourceSQL = false;
char g_szLogFile[128];
char g_szTempole[128];

//////////////////////////////
//			MODULES			//
//////////////////////////////
#include "store/players.sp"
#include "store/grenades.sp"
#include "store/scpsupport.sp"
#include "store/sprays.sp"
#include "store/models.sp"
#include "store/sounds.sp"

//////////////////////////////////
//		PLUGIN DEFINITION		//
//////////////////////////////////

public Plugin myinfo = 
{
	name		= PLUGIN_NAME,
	author		= PLUGIN_AUTHOR,
	description	= PLUGIN_DESCRIPTION,
	version		= PLUGIN_VERSION,
	url			= PLUGIN_URL
};

//////////////////////////////
//		PLUGIN FORWARDS		//
//////////////////////////////

public void OnPluginStart()
{
	// Setting default values
	for(int i = 1;i <= MaxClients; ++i)
	{
		g_eClients[i][iCredits] = -1;
		g_eClients[i][iOriginalCredits] = 0;
		g_eClients[i][iItems] = -1;
	}

	// Register ConVars
	g_cvarGiftEnabled = RegisterConVar("sm_store_enable_gifting", "1", "Enable/disable gifting of already bought items. [1=everyone, 2=admins only]", TYPE_INT);
	g_cvarConfirmation = RegisterConVar("sm_store_confirmation_windows", "1", "Enable/disable confirmation windows.", TYPE_INT);
	g_cvarShowVIP = RegisterConVar("sm_store_show_vip_items", "1", "If you enable this VIP items will be shown in grey.", TYPE_INT);

	// Register Commands
	RegConsoleCmd("sm_store", Command_Store);
	RegConsoleCmd("buyammo1", Command_Store);
	RegConsoleCmd("sm_shop", Command_Store);
	RegConsoleCmd("sm_inv", Command_Inventory);
	RegConsoleCmd("sm_inventory", Command_Inventory);
	RegConsoleCmd("sm_credits", Command_Credits);

	// Load the translations file
	LoadTranslations("store.phrases");

	// Initiaze the fake package handler
	g_iPackageHandler = Store_RegisterHandler("package", "", INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION, INVALID_FUNCTION);

	// Initialize the modules	
	Players_OnPluginStart();
	Grenades_OnPluginStart();
	SCPSupport_OnPluginStart();
	Sprays_OnPluginStart();
	Models_OnPluginStart();
	Sounds_OnPluginStart();

	// After every module was loaded we are ready to generate the cfg
	AutoExecConfig(true, "NewStore");
	
	if(g_bLateLoad)
		CreateTimer(1.0, LoadConfig);
}

public void CG_OnServerLoaded()
{
	CreateTimer(1.0, LoadConfig);
}

public Action LoadConfig(Handle timer)
{
	CheckGameMode();
	Store_ReloadConfig();
}

public void OnPluginEnd()
{
	for(int i = 1; i <= MaxClients; ++i)
		if(IsClientInGame(i))
			if(g_eClients[i][bLoaded])
				OnClientDisconnect(i);
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
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
	CreateNative("Store_ShouldConfirm", Native_ShouldConfirm);
	CreateNative("Store_GiveItem", Native_GiveItem);
	CreateNative("Store_RemoveItem", Native_RemoveItem);
	CreateNative("Store_GetClientTarget", Native_GetClientTarget);
	CreateNative("Store_GiveClientItem", Native_GiveClientItem);
	CreateNative("Store_HasClientItem", Native_HasClientItem);
	CreateNative("Store_IterateEquippedItems", Native_IterateEquippedItems);
	CreateNative("Store_SaveClientAll", Native_SaveClientAll);
	CreateNative("Store_GetClientID", Native_GetClientID);
	CreateNative("Store_IsClientBanned", Native_IsClientBanned);
	CreateNative("Store_HasClientPlayerSkin", Native_HasClientPlayerSkin);
	CreateNative("Store_GetClientPlayerSkin", Native_GetClientPlayerSkin);
	CreateNative("Store_ResetPlayerSkin", Native_ResetPlayerSkin);
	CreateNative("Store_ResetPlayerArms", Native_ResetPlayerArms);

	MarkNativeAsOptional("FPVMI_SetClientModel");
	MarkNativeAsOptional("FPVMI_RemoveViewModelToClient");
	MarkNativeAsOptional("FPVMI_RemoveWorldModelToClient");
	MarkNativeAsOptional("FPVMI_RemoveDropModelToClient");
	
	g_bLateLoad = late;

	return APLRes_Success;
}

//////////////////////////////////////
//		REST OF PLUGIN FORWARDS		//
//////////////////////////////////////
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

public void OnConfigsExecuted()
{
	// Connect to the database
	if(g_hDatabase == INVALID_HANDLE)
		SQL_TConnect(SQLCallback_Connect, "csgo");
		
	CreateTimer(30.0, Timer_DatabaseTimeout);
}

public void OnGameFrame()
{
	Trails_OnGameFrame();
}

public void OnEntityCreated(int entity, const char[] classname)
{
	Grenades_OnEntityCreated(entity, classname);
}

//////////////////////////////////////
//		Global API FROM CORE		//
//////////////////////////////////////
public bool CG_APIStoreSetCredits(int client, int credits, const char[] reason, bool immed)
{
	if(!g_eClients[client][bLoaded] || g_eClients[client][bBan] || g_eClients[client][iCredits] == -1)
		return false;

	if(credits < 0)
	{
		int icredits = credits * -1;
		
		if(icredits > g_eClients[client][iCredits])
			return false;
		
		Store_SetClientCredits(client, Store_GetClientCredits(client)-icredits, reason);
		
		if(immed)
			Store_SaveClientAll(client);
		
		return true;
	}
	else
	{
		Store_SetClientCredits(client, Store_GetClientCredits(client)+credits, reason);
		
		if(immed)
			Store_SaveClientAll(client);

		return true;
	}
}

public int CG_APIStoreGetCredits(int client)
{
	if(!g_eClients[client][bLoaded] || g_eClients[client][bBan] || g_eClients[client][iCredits] == -1)
		return -1;
	
	return g_eClients[client][iCredits];
}

//////////////////////////////
//			NATIVES			//
//////////////////////////////
public int Native_SaveClientAll(Handle myself, int numParams)
{
    int client = GetNativeCell(1);
    Store_SaveClientData(client);
    Store_SaveClientInventory(client);
    Store_SaveClientEquipment(client);
}

public int Native_GetClientID(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][iId];
}

public int Native_IsClientBanned(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][bBan];
}

public int Native_HasClientPlayerSkin(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(IsClientInGame(client))
		return g_bHasPlayerskin[client];
	else
		return false;
}

public int Native_GetClientPlayerSkin(Handle myself, int numParams)
{
	if(g_bGameModePR)
	{
		if(SetNativeString(2, "none", GetNativeCell(3)) != SP_ERROR_NONE)
			ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Skin.");
	}
	else
	{
		int client = GetNativeCell(1);

		int m_iEquipped = Store_GetEquippedItem(client, "playerskin", GetClientTeam(client)-2);

		if(m_iEquipped >= 0)
		{
			int m_iData = Store_GetDataIndex(m_iEquipped);
			if(SetNativeString(2, g_ePlayerSkins[m_iData][szModel], GetNativeCell(3)) != SP_ERROR_NONE)
				ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player Skin.");
		}
		else
			SetNativeString(2, "none", GetNativeCell(3));
	}
}

public int Native_ResetPlayerSkin(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
		Store_PreSetClientModel(client);
}

public int Native_ResetPlayerArms(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(client && IsClientInGame(client) && IsPlayerAlive(client))
		CreateTimer(0.5, Timer_FixPlayerArms, GetClientUserId(client));
}

public int Native_RegisterHandler(Handle plugin, int numParams)
{
	if(g_iTypeHandlers == STORE_MAX_HANDLERS)
		return -1;
		
	char m_szType[32];
	GetNativeString(1, STRING(m_szType));
	int m_iHandler = Store_GetTypeHandler(m_szType);	
	int m_iId = g_iTypeHandlers;
	
	if(m_iHandler != -1)
		m_iId = m_iHandler;
	else
		++g_iTypeHandlers;
	
	g_eTypeHandlers[m_iId][hPlugin] = plugin;
	g_eTypeHandlers[m_iId][fnMapStart] = GetNativeCell(3);
	g_eTypeHandlers[m_iId][fnReset] = GetNativeCell(4);
	g_eTypeHandlers[m_iId][fnConfig] = GetNativeCell(5);
	g_eTypeHandlers[m_iId][fnUse] = GetNativeCell(6);
	g_eTypeHandlers[m_iId][fnRemove] = GetNativeCell(7);
	g_eTypeHandlers[m_iId][bEquipable] = GetNativeCell(8);
	g_eTypeHandlers[m_iId][bRaw] = GetNativeCell(9);
	strcopy(g_eTypeHandlers[m_iId][szType], 32, m_szType);
	GetNativeString(2, g_eTypeHandlers[m_iId][szUniqueKey], 32);

	return m_iId;
}

public int Native_RegisterMenuHandler(Handle plugin, int numParams)
{
	if(g_iMenuHandlers == STORE_MAX_HANDLERS)
		return -1;
		
	char m_szIdentifier[64];
	GetNativeString(1, STRING(m_szIdentifier));
	int m_iHandler = Store_GetMenuHandler(m_szIdentifier);	
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
	
	int m_iHandler = Store_GetTypeHandler(m_szType);
	if(m_iHandler == -1)
		return -1;
	
	return Store_GetEquippedItemFromHandler(GetNativeCell(1), m_iHandler, GetNativeCell(3));
}

public int Native_IsClientLoaded(Handle myself, int numParams)
{
	return g_eClients[GetNativeCell(1)][bLoaded];
}

public int Native_DisplayPreviousMenu(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	if(g_iMenuNum[client] == 1)
		DisplayStoreMenu(client, g_iMenuBack[client], g_iLastSelection[client]);
	else if(g_iMenuNum[client] == 2)
		DisplayItemMenu(client, g_iSelectedItem[client]);
	else if(g_iMenuNum[client] == 3)
		DisplayPlayerMenu(client);
	else if(g_iMenuNum[client] == 5)
		DisplayPlanMenu(client, g_iSelectedItem[client]);
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
	if(!IsFakeClient(client))
	{
		int m_iCredits = GetNativeCell(2);
		char logMsg[128];
		if(GetNativeString(3, logMsg, 128) != SP_ERROR_NONE)
			Store_LogMessage(client, m_iCredits-g_eClients[client][iCredits], false, "未知来源");
		else
			Store_LogMessage(client, m_iCredits-g_eClients[client][iCredits], false, logMsg);
		//PrintToChatAll("[STORE-DEBUG] LogMsg: %s", logMsg);
		g_eClients[client][iCredits] = m_iCredits;
	}

	return 1;
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
		m_iParent = g_eItems[itemid][iParent];
		
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
	char title[255];
	GetNativeString(2, STRING(title));
	int callback = GetNativeCell(3);
	int data = GetNativeCell(4);

	Handle m_hMenu = CreateMenu(MenuHandler_Confirm);
	SetMenuTitle(m_hMenu, title);
	SetMenuExitButton(m_hMenu, false);
	char m_szCallback[32];
	char m_szData[11];
	Format(STRING(m_szCallback), "%d.%d", plugin, callback);
	IntToString(data, STRING(m_szData));
	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szCallback, "%t", "Confirm_Yes");
	AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, m_szData, "%t", "Confirm_No");
	DisplayMenu(m_hMenu, client, 0);
}

public int Native_ShouldConfirm(Handle myself, int numParams)
{
	return g_eCvars[g_cvarConfirmation][aCache];
}

public int Native_GiveItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	int purchase = GetNativeCell(3);
	int expiration = GetNativeCell(4);
	int price = GetNativeCell(5);

	int m_iDateOfPurchase = (purchase==0?GetTime():purchase);
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

public int Native_RemoveItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	if(itemid>0 && g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove] != INVALID_FUNCTION)
	{
		Call_StartFunction(g_eTypeHandlers[g_eItems[itemid][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[itemid][iHandler]][fnRemove]);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish();
	}
	
	Store_UnequipItem(client, itemid, false);
	
	int m_iId = Store_GetClientItemId(client, itemid);
	if(m_iId != -1)
		g_eClientItems[client][m_iId][bDeleted] = true;
}

public int Native_GetClientTarget(Handle myself, int numParams)
{
	return g_iMenuClient[GetNativeCell(1)];
}

public int Native_GiveClientItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int receiver = GetNativeCell(2);
	int itemid = GetNativeCell(3);

	int item = Store_GetClientItemId(client, itemid);
	if(item == -1)
		return 1;

	int m_iId = g_eClientItems[client][item][iUniqueId];
	int target = g_iMenuClient[client];
	g_eClientItems[client][item][bDeleted] = true;
	Store_UnequipItem(client, m_iId);

	g_eClientItems[receiver][g_eClients[receiver][iItems]][iId] = -1;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iUniqueId] = m_iId;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bSynced] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bDeleted] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfPurchase] = g_eClientItems[target][item][iDateOfPurchase];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfExpiration] = g_eClientItems[target][item][iDateOfExpiration];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iPriceOfPurchase] = g_eClientItems[target][item][iPriceOfPurchase];
	
	++g_eClients[receiver][iItems];

	return 1;
}

public int Native_HasClientItem(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int itemid = GetNativeCell(2);
	
	// Check if item is available?
	if(itemid < 0)
		return false;

	// Can he even have it?	
	if(!GetClientPrivilege(client, g_eItems[itemid][iFlagBits]))
		return false;

	// Is the item free (available for everyone)?
	if(g_eItems[itemid][iPrice] <= 0 && g_eItems[itemid][iPlans]==0)
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

public int Native_IterateEquippedItems(Handle myself, int numParams)
{
	int client = GetNativeCell(1);
	int start = GetNativeCellRef(2);
	bool attributes = GetNativeCell(3);

	for(int i = start + 1; i < STORE_MAX_HANDLERS*STORE_MAX_SLOTS; ++i)
	{
		if(g_eClients[client][aEquipment][i] >= 0 && (attributes==false || (attributes && g_eItems[g_eClients[client][aEquipment][i]][hAttributes]!=INVALID_HANDLE)))
		{
			SetNativeCellRef(2, i);
			return g_eClients[client][aEquipment][i];
		}
	}
		
	return -1;
}

//////////////////////////////
//		CLIENT FORWARDS		//
//////////////////////////////

public void OnClientConnected(int client)
{
	g_iSpam[client] = 0;
	g_eClients[client][iUserId] = GetClientUserId(client);
	g_eClients[client][iCredits] = -1;
	g_eClients[client][iOriginalCredits] = 0;
	g_eClients[client][iItems] = -1;
	g_eClients[client][bLoaded] = false;
	
	for(int i = 0; i < STORE_MAX_HANDLERS; ++i)
	{
		for(int a = 0; a < STORE_MAX_SLOTS; ++a)
		{
			g_eClients[client][aEquipment][i*STORE_MAX_SLOTS+a] = -2;
			g_eClients[client][aEquipmentSynced][i*STORE_MAX_SLOTS+a] = -2;
		}
	}
	
	Players_OnClientConnected(client);
	Sprays_OnClientConnected(client);
	Sound_OnClientConnected(client);
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client))
		return;

	Store_LoadClientInventory(client);
}

public void OnClientDisconnect(int client)
{
	Aura_OnClientDisconnect(client);
	Neon_OnClientDisconnect(client);
	Part_OnClientDisconnect(client);

	if(IsFakeClient(client))
		return;

	Store_SaveClientData(client);
	Store_SaveClientInventory(client);
	Store_SaveClientEquipment(client);
	Store_DisconnectClient(client);
}

public void OnClientSettingsChanged(int client)
{
	GetClientName(client, g_eClients[client][szName], 64);
	if(g_hDatabase)
		SQL_EscapeString(g_hDatabase, g_eClients[client][szName], g_eClients[client][szNameEscaped], 128);
}


//////////////////////////////////
//			COMMANDS	 		//
//////////////////////////////////
public Action Command_Store(int client, int args)
{	
	if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
	{
		Chat(client, "%t", "Inventory hasnt been fetched");
		return Plugin_Handled;
	}

	if(g_eClients[client][bBan])
	{
		PrintToChat(client,"[\x02CAT\x01]  你的Store信用为\x02不可信\x01或\x07信用点为负\x01!");
		return Plugin_Handled;
	}	

	g_bInvMode[client]=false;
	g_iMenuClient[client]=client;
	DisplayStoreMenu(client);

	return Plugin_Handled;
}

public Action Command_Inventory(int client, int args)
{	
	if((g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1) || !g_eClients[client][bLoaded])
	{
		Chat(client, "%t", "Inventory hasnt been fetched");
		return Plugin_Handled;
	}
	
	if(g_eClients[client][bBan])
	{
		PrintToChat(client,"[\x02CAT\x01]  你的Store信用为\x02不可信\x01或\x07信用点为负\x01!");
		return Plugin_Handled;
	}
	
	g_bInvMode[client] = true;
	g_iMenuClient[client]=client;
	DisplayStoreMenu(client);

	return Plugin_Handled;
}

public Action Command_Credits(int client, int args)
{	
	if(g_eClients[client][iCredits] == -1 && g_eClients[client][iItems] == -1)
	{
		Chat(client, "%t", "Inventory hasnt been fetched");
		return Plugin_Handled;
	}
	
	if(g_eClients[client][bBan])
	{
		PrintToChat(client,"[\x02CAT\x01]  你的Store信用为\x02不可信\x01或\x07信用点为负\x01!");
		return Plugin_Handled;
	}

	if(g_iSpam[client]<GetTime())
	{
		ChatAll("%t", "Player Credits", g_eClients[client][szName], g_eClients[client][iCredits]);
		g_iSpam[client] = GetTime()+30;
	}
	
	return Plugin_Handled;
}

//////////////////////////////
//			MENUS	 		//
//////////////////////////////

int DisplayStoreMenu(int client, int parent = -1, int last = -1)
{
	if(!client || !IsClientInGame(client))
		return;

	g_iMenuNum[client] = 1;
	int target = g_iMenuClient[client];

	Handle m_hMenu = CreateMenu(MenuHandler_Store);
	if(parent!=-1)
	{
		SetMenuExitBackButton(m_hMenu, true);
		if(client == target)
			SetMenuTitle(m_hMenu, "%s\n%t", g_eItems[parent][szName], "Title Credits", g_eClients[target][iCredits]);
		else
			SetMenuTitle(m_hMenu, "%N\n%s\n%t", target, g_eItems[parent][szName], "Title Credits", g_eClients[target][iCredits]);
		g_iMenuBack[client] = g_eItems[parent][iParent];
	}
	else if(client == target)
		SetMenuTitle(m_hMenu, "%t\n%t", "Title Store", "Title Credits", g_eClients[target][iCredits]);
	else
		SetMenuTitle(m_hMenu, "%N\n%t\n%t", target, "Title Store", "Title Credits", g_eClients[target][iCredits]);
	
	char m_szId[11];
	int m_iFlags = GetUserFlagBits(target);
	int m_iPosition = 0;
	
	g_iSelectedItem[client] = parent;
	if(parent != -1)
	{
		if(g_eItems[parent][iPrice]>0)
		{
			if(!Store_IsItemInBoughtPackage(target, parent))
			{
				AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "sell_package", "%t", "Package Sell", RoundToFloor(g_eItems[parent][iPrice]*0.6));
				++m_iPosition;

				if(g_eCvars[g_cvarGiftEnabled][aCache] == 1 && g_eItems[parent][bGiftable])
				{
					AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "gift_package", "%t", "Package Gift");
					++m_iPosition;
				}

				for(int i = 0; i < g_iMenuHandlers; ++i)
				{
					if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
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
		if(g_eItems[i][iParent]==parent && (g_eCvars[g_cvarShowVIP][aCache] == 0 && GetClientPrivilege(target, g_eItems[i][iFlagBits], m_iFlags) || g_eCvars[g_cvarShowVIP][aCache]))
		{
			int m_iPrice = Store_GetLowestPrice(i);

			// This is a package
			if(g_eItems[i][iHandler] == g_iPackageHandler)
			{
				if(!Store_PackageHasClientItem(target, i, g_bInvMode[client]))
					continue;

				int m_iStyle = ITEMDRAW_DEFAULT;
				if(g_eCvars[g_cvarShowVIP][aCache] && !GetClientPrivilege(target, g_eItems[i][iFlagBits], m_iFlags))
					m_iStyle = ITEMDRAW_DISABLED;
				
				IntToString(i, STRING(m_szId));
				if(g_eItems[i][iPrice] == -1 || Store_HasClientItem(target, i))
					AddMenuItem(m_hMenu, m_szId, g_eItems[i][szName], m_iStyle);
				else if(!g_bInvMode[client] && g_eItems[i][iPlans]==0 && g_eItems[i][bBuyable])
					InsertMenuItemEx(m_hMenu, m_iPosition, (m_iPrice<=g_eClients[target][iCredits]?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), m_szId, "%t", "Item Available", g_eItems[i][szName], g_eItems[i][iPrice]);
				else if(!g_bInvMode[client])
					InsertMenuItemEx(m_hMenu, m_iPosition, (m_iPrice<=g_eClients[target][iCredits]?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), m_szId, "%t", "Item Plan Available", g_eItems[i][szName]);
				++m_iPosition;
			}
			// This is a normal item
			else
			{
				IntToString(i, STRING(m_szId));
				if(Store_HasClientItem(target, i))
				{
					if(Store_IsEquipped(target, i))
						InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%t", "Item Equipped", g_eItems[i][szName]);
					else
						InsertMenuItemEx(m_hMenu, m_iPosition, ITEMDRAW_DEFAULT, m_szId, "%t", "Item Bought", g_eItems[i][szName]);
				}
				else if(!g_bInvMode[client])
				{				
					int m_iStyle = ITEMDRAW_DEFAULT;
					if((g_eItems[i][iPlans]==0 && g_eClients[target][iCredits]<m_iPrice) || (g_eCvars[g_cvarShowVIP][aCache] && !GetClientPrivilege(target, g_eItems[i][iFlagBits], m_iFlags)))
						m_iStyle = ITEMDRAW_DISABLED;
					
					if(!g_eItems[i][bBuyable])
						continue;

					if(g_eItems[i][iPlans]==0)
						AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%t", "Item Available", g_eItems[i][szName], g_eItems[i][iPrice]);
					else
						AddMenuItemEx(m_hMenu, m_iStyle, m_szId, "%t", "Item Plan Available", g_eItems[i][szName], g_eItems[i][iPrice]);
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
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		int target = g_iMenuClient[client];
		// Confirmation was given
		if(menu == INVALID_HANDLE)
		{
			if(param2 == 0)
			{
				g_iMenuBack[client]=1;
				int m_iPrice = 0;
				if(g_iSelectedPlan[client]==-1)
					m_iPrice = g_eItems[g_iSelectedItem[client]][iPrice];
				else
					m_iPrice = g_ePlans[g_iSelectedItem[client]][g_iSelectedPlan[client]][iPrice];

				if(g_eClients[target][iCredits]>=m_iPrice && !Store_HasClientItem(target, g_iSelectedItem[client]))
					Store_BuyItem(client);

				if(g_eItems[g_iSelectedItem[client]][iHandler] == g_iPackageHandler)
					DisplayStoreMenu(client, g_iSelectedItem[client]);
				else
					DisplayItemMenu(client, g_iSelectedItem[client]);
			}
			else if(param2 == 1)
			{
				Store_SellItem(target, g_iSelectedItem[client]);
				Store_DisplayPreviousMenu(client);
			}
		}
		else
		{
			char m_szId[64];
			GetMenuItem(menu, param2, STRING(m_szId));
			
			g_iLastSelection[client]=param2;
			
			// We are selling a package
			if(strcmp(m_szId, "sell_package")==0)
			{
				if(g_eCvars[g_cvarConfirmation][aCache])
				{
					char m_szTitle[128];
					Format(STRING(m_szTitle), "%t", "Confirm_Sell", g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], RoundToFloor(g_eItems[g_iSelectedItem[client]][iPrice]*0.6));
					Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 1);
					return;
				}
				else
				{
					Store_SellItem(target, g_iSelectedItem[client]);
					Store_DisplayPreviousMenu(client);
				}
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
					Call_PushCell(target);
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
				
				if((g_eClients[target][iCredits]>=g_eItems[m_iId][iPrice] || g_eItems[m_iId][iPlans]>0 && g_eClients[target][iCredits]>=Store_GetLowestPrice(m_iId)) && !Store_HasClientItem(target, m_iId) && g_eItems[m_iId][iPrice] != -1)				{
					if(g_eItems[m_iId][iPlans] > 0)
					{
						DisplayPlanMenu(client, m_iId);
						return;
					}
					else
						if(g_eCvars[g_cvarConfirmation][aCache])
						{
							char m_szTitle[128];
							Format(STRING(m_szTitle), "%t", "Confirm_Buy", g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
							Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
							return;
						}
						else
							Store_BuyItem(client);
				}
				
				if(g_eItems[m_iId][iHandler] != g_iPackageHandler)
				{				
					if(Store_HasClientItem(target, m_iId))
					{
						if(g_eTypeHandlers[g_eItems[m_iId][iHandler]][bRaw])
						{
							Call_StartFunction(g_eTypeHandlers[g_eItems[m_iId][iHandler]][hPlugin], g_eTypeHandlers[g_eItems[m_iId][iHandler]][fnUse]);
							Call_PushCell(target);
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
					if(Store_HasClientItem(target, m_iId) || g_eItems[m_iId][iPrice] == -1)
						DisplayStoreMenu(client, m_iId);
					else
						DisplayStoreMenu(client, g_eItems[m_iId][iParent]);
				}
			}
		}
	}
	else if(action==MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

public int DisplayItemMenu(int client, int itemid)
{
	if(!Store_HasClientItem(client, itemid))
		return;
	g_iMenuNum[client] = 1;
	g_iMenuBack[client] = g_eItems[itemid][iParent];
	int target = g_iMenuClient[client];

	Handle m_hMenu = CreateMenu(MenuHandler_Item);
	SetMenuExitBackButton(m_hMenu, true);
	
	bool m_bEquipped = Store_IsEquipped(target, itemid);
	char m_szTitle[256];
	int idx = 0;
	if(m_bEquipped)
		idx = Format(STRING(m_szTitle), "%t\n%t", "Item Equipped", g_eItems[itemid][szName], "Title Credits", g_eClients[target][iCredits]);
	else
		idx = Format(STRING(m_szTitle), "%s\n%t", g_eItems[itemid][szName], "Title Credits", g_eClients[target][iCredits]);

	int m_iExpiration = Store_GetExpiration(target, itemid);
	if(m_iExpiration != 0)
	{
		m_iExpiration = m_iExpiration-GetTime();
		int m_iDays = m_iExpiration/(24*60*60);
		int m_iHours = (m_iExpiration-m_iDays*24*60*60)/(60*60);
		Format(m_szTitle[idx-1], sizeof(m_szTitle)-idx-1, "\n%t", "Title Expiration", m_iDays, m_iHours);
	}
	
	SetMenuTitle(m_hMenu, m_szTitle);
	
	if(g_eTypeHandlers[g_eItems[itemid][iHandler]][bEquipable])
		if(!m_bEquipped)
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%t", "Item Equip");
		else
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "3", "%t", "Item Unequip");
	else
	{
		
		if(StrEqual(g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], "buyvip"))
		{
			switch(VIP_GetVipType(client))
			{
				case 3: AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%t", "you are already vip", "svip");
				case 2: AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%t", "you are already vip", "yvip");
				case 1: 
				{
					AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%t", "you are already vip", "mvip");
					AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%t", "go to forum to buy vip");
				}
				case 0:
				{
					AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%t", "buy monthly vip");
					AddMenuItemEx(m_hMenu, ITEMDRAW_DISABLED, "", "%t", "go to forum to buy vip");
				}
			}
		}
		else
			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "0", "%t", "Item Use");
	}
		
	if(!Store_IsItemInBoughtPackage(target, itemid))
	{
		int m_iCredits = RoundToFloor(Store_GetClientItemPrice(client, itemid)*0.6);
		if(m_iCredits!=0)
		{
			int uid = Store_GetClientItemId(client, itemid);
			if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
			{
				int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
				int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
				if(m_iLeft < 0)
					m_iLeft = 0;
				m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
			}

			AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "1", "%t", "Item Sell", m_iCredits);
			if(g_eCvars[g_cvarGiftEnabled][aCache] == 1 && g_eItems[itemid][bGiftable])
				AddMenuItemEx(m_hMenu, ITEMDRAW_DEFAULT, "2", "%t", "Item Gift");
		}
	}

	for(int i = 0; i < g_iMenuHandlers; ++i)
	{
		if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
			continue;
		Call_StartFunction(g_eMenuHandlers[i][hPlugin], g_eMenuHandlers[i][fnMenu]);
		Call_PushCellRef(m_hMenu);
		Call_PushCell(client);
		Call_PushCell(itemid);
		Call_Finish();
	}
	
	DisplayMenu(m_hMenu, client, 0);
}

public int DisplayPlanMenu(int client, int itemid)
{
	g_iMenuNum[client] = 1;
	int target = g_iMenuClient[client];

	Handle m_hMenu = CreateMenu(MenuHandler_Plan);
	SetMenuExitBackButton(m_hMenu, true);
	
	SetMenuTitle(m_hMenu, "%s\n%t", g_eItems[itemid][szName], "Title Credits", g_eClients[target][iCredits]);
	
	for(int i = 0; i < g_eItems[itemid][iPlans]; ++i)
	{
		AddMenuItemEx(m_hMenu, (g_eClients[target][iCredits]>=g_ePlans[itemid][i][iPrice]?ITEMDRAW_DEFAULT:ITEMDRAW_DISABLED), "", "%t",  "Item Available", g_ePlans[itemid][i][szName], g_ePlans[itemid][i][iPrice]);
	}
	
	DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Plan(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		//new target = g_iMenuClient[client];
		g_iSelectedPlan[client]=param2;
		g_iMenuNum[client]=5;

		if(g_eCvars[g_cvarConfirmation][aCache])
		{
			char m_szTitle[128];
			Format(STRING(m_szTitle), "%t", "Confirm_Buy", g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType]);
			Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Store, 0);
			return;
		}
		else
		{
			Store_BuyItem(client);
			DisplayItemMenu(client, g_iSelectedItem[client]);
		}
	}
	else if(action==MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

public int MenuHandler_Item(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		int target = g_iMenuClient[client];
		// Confirmation was sent
		if(menu == INVALID_HANDLE)
		{
			if(param2 == 0)
			{
				g_iMenuNum[client] = 1;
				Store_SellItem(target, g_iSelectedItem[client]);
				Store_DisplayPreviousMenu(client);
			}
		}
		else
		{
			char m_szId[64];
			GetMenuItem(menu, param2, STRING(m_szId));
			
			int m_iId = StringToInt(m_szId);
			
			// Menu handlers
			if(!(48 <= m_szId[0] <= 57))
			{
				int ret;
				for(int i=0;i<g_iMenuHandlers;++i)
				{
					if(g_eMenuHandlers[i][hPlugin] == INVALID_HANDLE)
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
				int m_iRet = Store_UseItem(target, g_iSelectedItem[client]);
				if(GetClientMenu(client)==MenuSource_None && m_iRet == 0)
					DisplayItemMenu(client, g_iSelectedItem[client]);
			}
			// Player wants to sell this item
			else if(m_iId == 1)
			{
				if(g_eCvars[g_cvarConfirmation][aCache])
				{
					int m_iCredits = RoundToFloor(Store_GetClientItemPrice(client, g_iSelectedItem[client])*0.6);
					int uid = Store_GetClientItemId(client, g_iSelectedItem[client]);
					if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
					{
						int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
						int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
						if(m_iLeft < 0)
							m_iLeft = 0;
						m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
					}

					char m_szTitle[128];
					Format(STRING(m_szTitle), "%t", "Confirm_Sell", g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], m_iCredits);
					g_iMenuNum[client] = 2;
					Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Item, 0);
				}
				else
				{
					Store_SellItem(target, g_iSelectedItem[client]);
					Store_DisplayPreviousMenu(client);
				}
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
				Store_UnequipItem(target, g_iSelectedItem[client]);
				DisplayItemMenu(client, g_iSelectedItem[client]);
			}
		}
	}
	else if(action==MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
			Store_DisplayPreviousMenu(client);
}

public int DisplayPlayerMenu(int client)
{
	g_iMenuNum[client] = 3;
	int target = g_iMenuClient[client];

	int m_iCount = 0;
	Handle m_hMenu = CreateMenu(MenuHandler_Gift);
	SetMenuExitBackButton(m_hMenu, true);
	SetMenuTitle(m_hMenu, "%t\n%t", "Title Gift", "Title Credits", g_eClients[client][iCredits]);
	
	char m_szID[11];
	int m_iFlags;
	for(int i = 1; i <= MaxClients; ++i)
	{
		if(!IsClientInGame(i))
			continue;

		m_iFlags = GetUserFlagBits(i);
		if(!GetClientPrivilege(i, g_eItems[g_iSelectedItem[client]][iFlagBits], m_iFlags))
			continue;
		if(i != target && IsClientInGame(i) && !Store_HasClientItem(i, g_iSelectedItem[client]))
		{
			IntToString(g_eClients[i][iUserId], STRING(m_szID));
			AddMenuItem(m_hMenu, m_szID, g_eClients[i][szName]);
			++m_iCount;
		}
	}
	
	if(m_iCount == 0)
	{
		CloseHandle(m_hMenu);
		g_iMenuNum[client] = 1;
		DisplayItemMenu(client, g_iSelectedItem[client]);
		Chat(client, "%t", "Gift No Players");
	}
	else
		DisplayMenu(m_hMenu, client, 0);
}

public int MenuHandler_Gift(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		int m_iItem, m_iReceiver;
		int target = g_iMenuClient[client];
	
		// Confirmation was given
		if(menu == INVALID_HANDLE)
		{
			m_iItem = Store_GetClientItemId(target, g_iSelectedItem[client]);
			m_iReceiver = GetClientOfUserId(param2);
			if(!m_iReceiver)
			{
				Chat(client, "%t", "Gift Player Left");
				return;
			}
			Store_GiftItem(target, m_iReceiver, m_iItem);
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
				Chat(client, "%t", "Gift Player Left");
				return;
			}
				
			m_iItem = Store_GetClientItemId(target, g_iSelectedItem[client]);
			
			if(g_eCvars[g_cvarConfirmation][aCache])
			{
				char m_szTitle[128];
				Format(STRING(m_szTitle), "%t", "Confirm_Gift", g_eItems[g_iSelectedItem[client]][szName], g_eTypeHandlers[g_eItems[g_iSelectedItem[client]][iHandler]][szType], g_eClients[m_iReceiver][szName]);
				Store_DisplayConfirmMenu(client, m_szTitle, MenuHandler_Gift, m_iId);
				return;
			}
			else
				Store_GiftItem(target, m_iReceiver, m_iItem);
			Store_DisplayPreviousMenu(client);
		}
	}
	else if(action==MenuAction_Cancel)
		if (param2 == MenuCancel_ExitBack)
			DisplayItemMenu(client, g_iSelectedItem[client]);
}

public int MenuHandler_Confirm(Handle menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{		
		if(param2 == 0)
		{
			char m_szCallback[32];
			char m_szData[11];
			GetMenuItem(menu, 0, STRING(m_szCallback));
			GetMenuItem(menu, 1, STRING(m_szData));
			int m_iPos = FindCharInString(m_szCallback, '.');
			m_szCallback[m_iPos] = 0;
			Handle m_hPlugin = view_as<Handle>(StringToInt(m_szCallback));
			Function fnMenuCallback = view_as<Function>(StringToInt(m_szCallback[m_iPos+1]));
			if(fnMenuCallback != INVALID_FUNCTION)
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
//			TIMERS	 		//
//////////////////////////////
public Action Timer_DatabaseTimeout(Handle timer, int userid)
{
	// Database is connected successfully
	if(g_hDatabase != INVALID_HANDLE)
		return Plugin_Stop;

	if(g_iDatabaseRetries < 100)
	{
		SQL_TConnect(SQLCallback_Connect, "store");
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
//		SQL CALLBACKS		//
//////////////////////////////

public void SQLCallback_Connect(Handle owner, Handle hndl, const char[] error, any data)
{
	if(hndl==INVALID_HANDLE)
	{
		SetFailState("Failed to connect to SQL database. Error: %s", error);
	}
	else
	{
		// If it's already connected we are good to go
		if(g_hDatabase != INVALID_HANDLE)
			return;

		g_hDatabase = hndl;

		// Do some housekeeping
		SQL_SetCharset(g_hDatabase, "utf8");
		
		char m_szQuery[256];
		Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `date_of_expiration` <> 0 AND `date_of_expiration` < %d", GetTime());
		SQL_TVoid(g_hDatabase, m_szQuery);
		
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

		// Build Log Path
		BuildTempLogFile();
	}
}

public void SQLCallback_LoadClientInventory_Credits(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
		
		char m_szQuery[512];
		char m_szSteamID[32];
		int m_iTime = GetTime();
		g_eClients[client][iUserId] = userid;
		g_eClients[client][iItems] = -1;
		GetLegacyAuthString(client, STRING(m_szSteamID), true);
		strcopy(g_eClients[client][szAuthId], 32, m_szSteamID[8]);
		GetClientName(client, g_eClients[client][szName], 64);
		SQL_EscapeString(g_hDatabase, g_eClients[client][szName], g_eClients[client][szNameEscaped], 128);
		if(KvJumpToKey(g_hKeyValue, m_szSteamID, true))
		{
			KvSetNum(g_hKeyValue, "Connect", GetTime());
			KvRewind(g_hKeyValue);
			KeyValuesToFile(g_hKeyValue, g_szLogFile);
		}
		
		if(SQL_FetchRow(hndl))
		{
			g_eClients[client][iId] = SQL_FetchInt(hndl, 0);
			g_eClients[client][iCredits] = SQL_FetchInt(hndl, 3);
			g_eClients[client][iOriginalCredits] = SQL_FetchInt(hndl, 3);
			g_eClients[client][iDateOfJoin] = SQL_FetchInt(hndl, 4);
			g_eClients[client][iDateOfLastJoin] = m_iTime;
			g_eClients[client][bBan] = (SQL_FetchInt(hndl, 6) == 1 || g_eClients[client][iCredits] < 0) ? true : false;
			
			if(g_eClients[client][iId] == 1)
			{
				GetClientAuthId(client, AuthId_Steam2, m_szSteamID, 32, true);
				if(!StrEqual(m_szSteamID, "STEAM_1:1:44083262") && !StrEqual(m_szSteamID, "STEAM_1:0:3339246"))
				{
					KickClient(client, "STEAM AUTH ERROR");
					return;
				}
				PrintToConsole(client, "Store Checking Access.");
			}

			Format(STRING(m_szQuery), "SELECT * FROM store_items WHERE `player_id`=%d", g_eClients[client][iId]);
			SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Items, m_szQuery, userid);

			Store_LogMessage(client, g_eClients[client][iCredits], true, "本次进入服务器时的Credits");
		}
		else
		{
			Format(STRING(m_szQuery), "INSERT INTO store_players (`authid`, `name`, `credits`, `date_of_join`, `date_of_last_join`, `ban`) VALUES(\"%s\", '%s', 300, %d, %d, '0')", g_eClients[client][szAuthId], g_eClients[client][szNameEscaped], m_iTime, m_iTime);
			SQL_TQuery(g_hDatabase, SQLCallback_InsertClient, m_szQuery, userid);
			g_eClients[client][iCredits] = 300;
			g_eClients[client][iOriginalCredits] = 300;
			g_eClients[client][iDateOfJoin] = m_iTime;
			g_eClients[client][iDateOfLastJoin] = m_iTime;
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			
			if(g_bGameModePR)
			{
				Format(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"playerskin\", \"models/player/custom_player/maoling/haipa/haipa.mdl\", %d, %d, 300)", g_eClients[client][iId], GetTime(), GetTime()+604800);
				SQL_TVoid(g_hDatabase, m_szQuery);
			}
			else
			{
				Store_GiveItem(client, Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl"), GetTime(), GetTime()+604800, 300);
				PrintToChat(client, "[\x0EPlaneptune\x01]  作为新玩家你收到了赠礼[\x04害怕/滑稽\x01](\x0C7天\x01)");
			}

			Store_LogMessage(client, 300, true, "首次进服赠送");
		}
	}
}

public void SQLCallback_LoadClientInventory_Items(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{	
		int client = GetClientOfUserId(userid);
		if(!client)
			return;

		char m_szQuery[512];
		Format(STRING(m_szQuery), "SELECT * FROM store_equipment WHERE `player_id`=%d", g_eClients[client][iId]);
		SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Equipment, m_szQuery, userid);

		if(g_eClients[client][bBan])
		{
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			return;
		}
		
		if(g_eClients[client][iId] == 1)
		{
			char m_szSteamID[32];
			GetClientAuthId(client, AuthId_Steam2, m_szSteamID, 32, true);
			if(!StrEqual(m_szSteamID, "STEAM_1:1:44083262") && !StrEqual(m_szSteamID, "STEAM_1:0:3339246"))
			{
				KickClient(client, "STEAM AUTH ERROR");
				return;
			}
			PrintToConsole(client, "Store Checking Access.");
		}

		if(!SQL_GetRowCount(hndl))
		{
			g_eClients[client][bLoaded] = true;
			g_eClients[client][iItems] = 0;
			return;
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
			if(m_iExpiration && m_iExpiration<=m_iTime)
				continue;
			
			SQL_FetchString(hndl, 2, STRING(m_szType));
			SQL_FetchString(hndl, 3, STRING(m_szUniqueId));
			while((m_iUniqueId = Store_GetItemId(m_szType, m_szUniqueId, m_iUniqueId))!=-1)
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
	}
}

public void SQLCallback_LoadClientInventory_Equipment(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
		
		char m_szUniqueId[PLATFORM_MAX_PATH];
		char m_szType[16];
		int m_iUniqueId;
		
		if(g_eClients[client][bBan])
		{
			g_eClients[client][bLoaded] = true;
			return;
		}

		while(SQL_FetchRow(hndl))
		{
			SQL_FetchString(hndl, 1, STRING(m_szType));
			SQL_FetchString(hndl, 2, STRING(m_szUniqueId));
			m_iUniqueId = Store_GetItemId(m_szType, m_szUniqueId);
			if(m_iUniqueId == -1)
				continue;
				
			if(!Store_HasClientItem(client, m_iUniqueId))
				Store_UnequipItem(client, m_iUniqueId);
			else
				Store_UseItem(client, m_iUniqueId, true, SQL_FetchInt(hndl, 3));
		}
		g_eClients[client][bLoaded] = true;
		
		if(!g_bGameModePR && IsClientInGame(client) && CG_GetLastseen(client) <= 1473004800)
		{
			if(!Store_HasClientItem(client, Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl")))
			{
				PrintToChat(client, "[\x0EPlaneptune\x01]  \x07>\x04>\x0C>\x01老玩家回归: \x10你获得了一个[\x04害怕/滑稽\x01](\x0C30天\x01)");
				Store_GiveItem(client, Store_GetItemId("playerskin", "models/player/custom_player/maoling/haipa/haipa.mdl"), GetTime(), GetTime()+2592000, 300);
			}
			else
			{
				PrintToChat(client, "[\x0EPlaneptune\x01]  \x07>\x04>\x0C>\x01老玩家回归: \x10你获得了[\x046666信用点\x01]");
				Store_SetClientCredits(client, Store_GetClientCredits(client)+6666, "老玩家回归");
			}
		}
	}
}

public void SQLCallback_InsertClient(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
		LogError("Error happened. Error: %s", error);
	else
	{
		int client = GetClientOfUserId(userid);
		if(!client)
			return;
			
		g_eClients[client][iId] = SQL_GetInsertId(hndl);
	}
}

public void SQLCallback_ReloadConfig(Handle owner, Handle hndl, const char[] error, int userid)
{
	if(hndl==INVALID_HANDLE)
	{
		SetFailState("Error happened reading the config table. The plugin cannot continue.", error);
	}
	else
	{
		char m_szType[64];
		char m_szFlag[64];
		char m_szInfo[2048];
		char m_szKey[64];
		char m_szValue[256];
		
		Handle m_hKV;
		
		bool m_bSuccess;
		
		int m_iLength;
		int m_iHandler;
		int m_iIndex = 0;
	
		while(SQL_FetchRow(hndl))
		{
			if(g_iItems == STORE_MAX_ITEMS)
				return;
				
			if(!SQL_FetchInt(hndl, 7))
				continue;
			
			g_eItems[g_iItems][iId] = SQL_FetchInt(hndl, 0);
			g_eItems[g_iItems][iParent] = SQL_FetchInt(hndl, 1);
			g_eItems[g_iItems][iPrice] = SQL_FetchInt(hndl, 2);
			
			IntToString(g_eItems[g_iItems][iId], g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);
			
			SQL_FetchString(hndl, 3, STRING(m_szType));
			m_iHandler = Store_GetTypeHandler(m_szType);
			if(m_iHandler == -1)
				continue;
			
			g_eItems[g_iItems][iHandler] = m_iHandler;
			
			SQL_FetchString(hndl, 4, STRING(m_szFlag));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlag);
			
			SQL_FetchString(hndl, 5, g_eItems[g_iItems][szName], ITEM_NAME_LENGTH);
			SQL_FetchString(hndl, 6, STRING(m_szInfo));
			
			m_hKV = CreateKeyValues("Additional Info");
			
			m_iLength = strlen(m_szInfo);
			while(m_iIndex != m_iLength)
			{
				m_iIndex += strcopy(m_szKey, StrContains(m_szInfo[m_iIndex], "="), m_szInfo[m_iIndex])+2;
				m_iIndex += strcopy(m_szValue, StrContains(m_szInfo[m_iIndex], "\";"), m_szInfo[m_iIndex])+2; // \"
				
				KvJumpToKey(m_hKV, m_szKey, true);
				KvSetString(m_hKV, m_szKey, m_szValue);
				
				m_bSuccess = true;
				if(g_eTypeHandlers[m_iHandler][fnConfig]!=INVALID_FUNCTION)
				{
					Call_StartFunction(g_eTypeHandlers[m_iHandler][hPlugin], g_eTypeHandlers[m_iHandler][fnConfig]);
					Call_PushCellRef(m_hKV);
					Call_PushCell(g_iItems);
					Call_Finish(m_bSuccess); 
				}
				
				if(m_bSuccess)
					++g_iItems;
			}
			CloseHandle(m_hKV);
		}
	}
}

//////////////////////////////
//			STOCKS			//
//////////////////////////////

public void Store_LoadClientInventory(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Database connection is lost or not yet initialized.");
		return;
	}
	
	char m_szQuery[512];
	char m_szAuthId[32];

	GetLegacyAuthString(client, STRING(m_szAuthId), true);
	if(m_szAuthId[0] == 0)
		return;

	Format(STRING(m_szQuery), "SELECT * FROM store_players WHERE `authid`=\"%s\"", m_szAuthId[8]);

	SQL_TQuery(g_hDatabase, SQLCallback_LoadClientInventory_Credits, m_szQuery, g_eClients[client][iUserId]);
}

public void Store_SaveClientInventory(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
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
			Format(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", %d, %d, %d)", g_eClients[client][iId], m_szType, m_szUniqueId, g_eClientItems[client][i][iDateOfPurchase], g_eClientItems[client][i][iDateOfExpiration], g_eClientItems[client][i][iPriceOfPurchase]);
			SQL_TVoid(g_hDatabase, m_szQuery);
		} else if(g_eClientItems[client][i][bSynced] && g_eClientItems[client][i][bDeleted])
		{
			// Might have been synced already but ID wasn't acquired
			if(g_eClientItems[client][i][iId]==-1)
				Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `player_id`=%d AND `type`=\"%s\" AND `unique_id`=\"%s\"", g_eClients[client][iId], m_szType, m_szUniqueId);
			else
				Format(STRING(m_szQuery), "DELETE FROM store_items WHERE `id`=%d", g_eClientItems[client][i][iId]);
			SQL_TVoid(g_hDatabase, m_szQuery);
		}
	}
}

public void Store_SaveClientEquipment(int client)
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
				if(g_eClients[client][aEquipment][m_iId]==-1)
					Format(STRING(m_szQuery), "DELETE FROM store_equipment WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
				else
					Format(STRING(m_szQuery), "UPDATE store_equipment SET `unique_id`=\"%s\" WHERE `player_id`=%d AND `type`=\"%s\" AND `slot`=%d", g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], g_eClients[client][iId], g_eTypeHandlers[i][szType], a);
				
			else
				Format(STRING(m_szQuery), "INSERT INTO store_equipment (`player_id`, `type`, `unique_id`, `slot`) VALUES(%d, \"%s\", \"%s\", %d)", g_eClients[client][iId], g_eTypeHandlers[i][szType], g_eItems[g_eClients[client][aEquipment][m_iId]][szUniqueId], a);

			SQL_TVoid(g_hDatabase, m_szQuery);
			g_eClients[client][aEquipmentSynced][m_iId] = g_eClients[client][aEquipment][m_iId];
		}
	}
}

public void Store_SaveClientData(int client)
{
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Database connection is lost or not yet initialized.");
		return;
	}
	
	if((g_eClients[client][iCredits]==-1 && g_eClients[client][iItems]==-1) || !g_eClients[client][bLoaded])
		return;
	
	char m_szQuery[512];
	Format(STRING(m_szQuery), "UPDATE store_players SET `credits`=`credits`+%d, `date_of_last_join`=%d, `name`='%s' WHERE `id`=%d", g_eClients[client][iCredits]-g_eClients[client][iOriginalCredits], g_eClients[client][iDateOfLastJoin], g_eClients[client][szNameEscaped], g_eClients[client][iId]);

	g_eClients[client][iOriginalCredits] = g_eClients[client][iCredits];

	SQL_TVoid(g_hDatabase, m_szQuery);
	
	char m_szAuthId[32];
	GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);
	if(KvJumpToKey(g_hKeyValue, m_szAuthId))
	{
		int connect = KvGetNum(g_hKeyValue, "Connect", 0);
		
		while(KvGotoFirstSubKey(g_hKeyValue, true))
		{
			char m_szReason[128];
			KvGetSectionName(g_hKeyValue, m_szReason, 128);

			if(StrEqual(m_szReason, "Connect"))
			{
				KvDeleteThis(g_hKeyValue);
				KvGetSectionName(g_hKeyValue, m_szReason, 128);
			}
			
			int credits = KvGetNum(g_hKeyValue, "Credits", 0);
			int endtime = KvGetNum(g_hKeyValue, "LastTime", 0);
			int Counts = KvGetNum(g_hKeyValue, "Counts", 1);

			char m_szEreason[192];
			SQL_EscapeString(g_hDatabase, m_szReason, m_szEreason, 192);
			Format(STRING(m_szQuery), "INSERT INTO store_logs (player_id, credits, reason, date) VALUES(%d, %d, \"%d_%d_%s\", %d)", g_eClients[client][iId], credits, connect, Counts, m_szEreason, endtime);
			SQL_TVoid(g_hDatabase, m_szQuery);
			
			if(KvDeleteThis(g_hKeyValue))
			{
				char m_szAfter[32];
				KvGetSectionName(g_hKeyValue, m_szAfter, 32);
				if(StrContains(m_szAfter, "STEAM", false) != -1)
					break;
				else
					KvGoBack(g_hKeyValue);
			}
		}

		KvDeleteThis(g_hKeyValue);
		KvRewind(g_hKeyValue);
		KeyValuesToFile(g_hKeyValue, g_szLogFile);
	}
}

public void Store_DisconnectClient(int client)
{
	Store_LogMessage(client, g_eClients[client][iCredits], true, "离开服务器时");
	g_eClients[client][iCredits] = -1;
	g_eClients[client][iOriginalCredits] = -1;
	g_eClients[client][iItems] = -1;
	g_eClients[client][bLoaded] = false;
}

int Store_GetItemId(char[] type, char[] uid, int start = -1)
{
	for(int i = start+1; i < g_iItems; ++i)
		if(strcmp(g_eTypeHandlers[g_eItems[i][iHandler]][szType], type)==0 && strcmp(g_eItems[i][szUniqueId], uid)==0 && g_eItems[i][iPrice] >= 0)
			return i;
	return -1;
}

public void SQLCallback_BuyItem(Handle owner, Handle hndl, const char[] error, int userid)
{
	int client = GetClientOfUserId(userid);
	if(!client)
		return;

	if(hndl == INVALID_HANDLE)
	{
		LogError("Error happened. Error: %s", error);
	}
	else
	{
		if(SQL_FetchRow(hndl))
		{
			int dbCredits = SQL_FetchInt(hndl, 0);
			int target = g_iMenuClient[client];
			int itemid = g_iSelectedItem[client];
			int plan = g_iSelectedPlan[client];

			int m_iPrice = 0;
			if(plan==-1)
				m_iPrice = g_eItems[itemid][iPrice];
			else
				m_iPrice = g_ePlans[itemid][plan][iPrice];	
			
			if (dbCredits != g_eClients[target][iOriginalCredits])
			{
				int diff = g_eClients[target][iOriginalCredits] - dbCredits;
				g_eClients[target][iOriginalCredits] = dbCredits;
				g_eClients[target][iCredits] -= diff;
			}
			
			if(g_eClients[target][iCredits]<m_iPrice)
				return;

			int m_iId = g_eClients[target][iItems]++;
			g_eClientItems[target][m_iId][iId] = -1;
			g_eClientItems[target][m_iId][iUniqueId] = itemid;
			g_eClientItems[target][m_iId][iDateOfPurchase] = GetTime();
			g_eClientItems[target][m_iId][iDateOfExpiration] = (plan==-1?0:(g_ePlans[itemid][plan][iTime]?GetTime()+g_ePlans[itemid][plan][iTime]:0));
			g_eClientItems[target][m_iId][iPriceOfPurchase] = m_iPrice;
			g_eClientItems[target][m_iId][bSynced] = true; //false
			g_eClientItems[target][m_iId][bDeleted] = false;

			g_eClients[target][iCredits] -= m_iPrice;

			Store_LogMessage(target, -m_iPrice, true, "购买了 %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
			LogToFileEx(g_szTempole, "%N 购买了 %s %s[%d]", target, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], m_iPrice);

			//购买回写
			char m_szQuery[512];
			Format(STRING(m_szQuery), "INSERT INTO store_items (`player_id`, `type`, `unique_id`, `date_of_purchase`, `date_of_expiration`, `price_of_purchase`) VALUES(%d, \"%s\", \"%s\", %d, %d, %d)", g_eClients[target][iId], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType], g_eItems[itemid][szUniqueId], GetTime(), g_eClientItems[target][m_iId][iDateOfExpiration], g_eClientItems[target][m_iId][iPriceOfPurchase]);
			SQL_TVoid(g_hDatabase, m_szQuery);
			Store_SaveClientAll(target);

			Chat(target, "%t", "Chat Bought Item", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
			Command_Store(target, 0);
			Chat(target, "短时间内频繁购买/卖出有可能造成不可挽回的损失...");
		}
	}
}

int Store_BuyItem(int client)
{
	int target = g_iMenuClient[client];
	if(Store_HasClientItem(target, g_iSelectedItem[client]))
		return;
	char m_szQuery[255];
	Format(STRING(m_szQuery), "SELECT credits FROM store_players WHERE `id`=%d", g_eClients[target][iId]);
	SQL_TQuery(g_hDatabase, SQLCallback_BuyItem, m_szQuery, g_eClients[client][iUserId]);
}

public int Store_SellItem(int client, int itemid)
{	
	int m_iCredits = RoundToFloor(Store_GetClientItemPrice(client, itemid)*0.6);
	int uid = Store_GetClientItemId(client, itemid);
	if(g_eClientItems[client][uid][iDateOfExpiration] != 0)
	{
		int m_iLength = g_eClientItems[client][uid][iDateOfExpiration]-g_eClientItems[client][uid][iDateOfPurchase];
		int m_iLeft = g_eClientItems[client][uid][iDateOfExpiration]-GetTime();
		if(m_iLeft<0)
			m_iLeft = 0;
		m_iCredits = RoundToCeil(m_iCredits*float(m_iLeft)/float(m_iLength));
	}

	g_eClients[client][iCredits] += m_iCredits;
	Chat(client, "%t", "Chat Sold Item", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	Chat(client, "短时间内频繁购买/卖出有可能造成不可挽回的损失...");
	
	Store_LogMessage(client, m_iCredits, false, "卖掉了 %s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	LogToFileEx(g_szTempole, "%N 卖掉了 %s %s", client, g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);

	Store_RemoveItem(client, itemid);
	
	Store_SaveClientAll(client);
}

public int Store_GiftItem(int client, int receiver, int item)
{
	int m_iId = g_eClientItems[client][item][iUniqueId];
	int target = g_iMenuClient[client];
	
	if((g_eClients[target][iCredits] == -1 && g_eClients[target][iItems] == -1) || !g_eClients[target][bLoaded]
		|| (g_eClients[receiver][iCredits] == -1 && g_eClients[receiver][iItems] == -1) || !g_eClients[receiver][bLoaded]) {
		return;
	}
	
	g_eClientItems[client][item][bDeleted] = true;
	Store_UnequipItem(client, m_iId);

	g_eClientItems[receiver][g_eClients[receiver][iItems]][iId] = -1;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iUniqueId] = m_iId;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bSynced] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][bDeleted] = false;
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfPurchase] = g_eClientItems[target][item][iDateOfPurchase];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iDateOfExpiration] = g_eClientItems[target][item][iDateOfExpiration];
	g_eClientItems[receiver][g_eClients[receiver][iItems]][iPriceOfPurchase] = g_eClientItems[target][item][iPriceOfPurchase];
	
	++g_eClients[receiver][iItems];

	Chat(client, "%t", "Chat Gift Item Sent", g_eClients[receiver][szName], g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);
	Chat(receiver, "%t", "Chat Gift Item Received", g_eClients[target][szName], g_eItems[m_iId][szName], g_eTypeHandlers[g_eItems[m_iId][iHandler]][szType]);

	Store_LogMessage(client, 0, true, "赠送了 %s 给 %N[%s]", g_eItems[m_iId][szName], receiver, g_eClients[receiver][szAuthId]);
	Store_LogMessage(receiver, 0, true, "收到了 %s 来自 %N[%s]", g_eItems[m_iId][szName], client, g_eClients[client][szAuthId]);
	
	Store_SaveClientAll(client);
	Store_SaveClientAll(receiver);
}

public int Store_GetClientItemId(int client, int itemid)
{
	for(int i = 0; i < g_eClients[client][iItems]; ++i)
	{
		if(g_eClientItems[client][i][iUniqueId] == itemid && !g_eClientItems[client][i][bDeleted])
			return i;
	}
		
	return -1;
}

public void Store_ReloadConfig()
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

	if(g_bItemSourceSQL)
	{
		char m_szQuery[64];
		Format(STRING(m_szQuery), "SELECT * FROM store_web");
		SQL_TQuery(g_hDatabase, SQLCallback_ReloadConfig, m_szQuery);
	}
	else
	{	
		char m_szFile[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, STRING(m_szFile), "configs/store/items.txt");
		Handle m_hKV = CreateKeyValues("Store");
		FileToKeyValues(m_hKV, m_szFile);
		if (!KvGotoFirstSubKey(m_hKV))
		{
			SetFailState("Failed to read configs/store/items.txt");
		}
		Store_WalkConfig(m_hKV);
		CloseHandle(m_hKV);
	}
}

void Store_WalkConfig(Handle &kv, int parent = -1)
{
	char m_szType[32];
	char m_szFlags[64];
	int m_iHandler;
	bool m_bSuccess;
	do
	{
		if(g_iItems == STORE_MAX_ITEMS)
				continue;
		if (KvGetNum(kv, "enabled", 1) && KvGetNum(kv, "type", -1) == -1 && KvGotoFirstSubKey(kv))
		{
			KvGoBack(kv);
			KvGetSectionName(kv, g_eItems[g_iItems][szName], 64);
			KvGetSectionName(kv, g_eItems[g_iItems][szUniqueId], 64);
			ReplaceString(g_eItems[g_iItems][szName], 64, "\\n", "\n");
			KvGetString(kv, "shortcut", g_eItems[g_iItems][szShortcut], 64);
			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price", -1);
			g_eItems[g_iItems][bBuyable] = (KvGetNum(kv, "buyable", 1)?true:false);
			g_eItems[g_iItems][bGiftable] = (KvGetNum(kv, "giftable", 1)?true:false);
			g_eItems[g_iItems][bIgnoreVIP] = (KvGetNum(kv, "ignore_vip", 0)?true:false);
			g_eItems[g_iItems][iHandler] = g_iPackageHandler;
			
			KvGotoFirstSubKey(kv);
			
			g_eItems[g_iItems][iParent] = parent;
			
			Store_WalkConfig(kv, g_iItems++);
			KvGoBack(kv);
		}
		else
		{
			if(!KvGetNum(kv, "enabled", 1))
				continue;
				
			g_eItems[g_iItems][iParent] = parent;
			KvGetSectionName(kv, g_eItems[g_iItems][szName], ITEM_NAME_LENGTH);
			g_eItems[g_iItems][iPrice] = KvGetNum(kv, "price");
			g_eItems[g_iItems][bBuyable] = KvGetNum(kv, "buyable", 1)?true:false;
			g_eItems[g_iItems][bGiftable] = KvGetNum(kv, "giftable", 1)?true:false;
			g_eItems[g_iItems][bIgnoreVIP] = (KvGetNum(kv, "ignore_vip", 0)?true:false);

			
			KvGetString(kv, "type", STRING(m_szType));
			m_iHandler = Store_GetTypeHandler(m_szType);
			if(m_iHandler == -1)
				continue;

			if(StrContains(m_szType, "playerskin", false) != -1)
			{
				int team = KvGetNum(kv, "team", 0);
				if(g_bGameModeTT || g_bGameModeJB || g_bGameModeZE || g_bGameModeDR)
				{
					Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[通用] %s", g_eItems[g_iItems][szName]);
				}
				else
				{
					if(team == 2)
						Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[TE] %s", g_eItems[g_iItems][szName]);
					if(team == 3)
						Format(g_eItems[g_iItems][szName], ITEM_NAME_LENGTH, "[CT] %s", g_eItems[g_iItems][szName]);
				}
			}

			KvGetString(kv, "flag", STRING(m_szFlags));
			g_eItems[g_iItems][iFlagBits] = ReadFlagString(m_szFlags);
			g_eItems[g_iItems][iHandler] = m_iHandler;
			
			if(KvGetNum(kv, "unique_id", -1)==-1)
				KvGetString(kv, g_eTypeHandlers[m_iHandler][szUniqueKey], g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);
			else
				KvGetString(kv, "unique_id", g_eItems[g_iItems][szUniqueId], PLATFORM_MAX_PATH);

			if(KvJumpToKey(kv, "Plans"))
			{
				KvGotoFirstSubKey(kv);
				int index=0;
				do
				{
					KvGetSectionName(kv, g_ePlans[g_iItems][index][szName], ITEM_NAME_LENGTH);
					g_ePlans[g_iItems][index][iPrice] = KvGetNum(kv, "price");
					g_ePlans[g_iItems][index][iTime] = KvGetNum(kv, "time");
					++index;
				} while (KvGotoNextKey(kv));

				g_eItems[g_iItems][iPlans]=index;

				KvGoBack(kv);
				KvGoBack(kv);
			}

			if(g_eItems[g_iItems][hAttributes])
				CloseHandle(g_eItems[g_iItems][hAttributes]);
			g_eItems[g_iItems][hAttributes] = INVALID_HANDLE;
			if(KvJumpToKey(kv, "Attributes"))
			{
				g_eItems[g_iItems][hAttributes] = CreateTrie();

				KvGotoFirstSubKey(kv, false);

				char m_szAttribute[64];
				char m_szValue[64];
				do
				{
					KvGetSectionName(kv, STRING(m_szAttribute));
					KvGetString(kv, NULL_STRING, STRING(m_szValue));
					SetTrieString(g_eItems[g_iItems][hAttributes], m_szAttribute, m_szValue);
				} while (KvGotoNextKey(kv, false));

				KvGoBack(kv);
				KvGoBack(kv);
			}
			
			m_bSuccess = true;
			if(g_eTypeHandlers[m_iHandler][fnConfig]!=INVALID_FUNCTION)
			{
				Call_StartFunction(g_eTypeHandlers[m_iHandler][hPlugin], g_eTypeHandlers[m_iHandler][fnConfig]);
				Call_PushCellRef(kv);
				Call_PushCell(g_iItems);
				Call_Finish(m_bSuccess); 
			}
			
			if(m_bSuccess)
				++g_iItems;
		}
	} while (KvGotoNextKey(kv));
}

public int Store_GetTypeHandler(char[] type)
{
	for(int i = 0; i < g_iTypeHandlers; ++i)
	{
		if(strcmp(g_eTypeHandlers[i][szType], type)==0)
			return i;
	}
	return -1;
}

public int Store_GetMenuHandler(char[] id)
{
	for(int i = 0; i < g_iMenuHandlers; ++i)
	{
		if(strcmp(g_eMenuHandlers[i][szIdentifier], id)==0)
			return i;
	}
	return -1;
}

public bool Store_IsEquipped(int client, int itemid)
{
	for(int i = 0; i < STORE_MAX_SLOTS; ++i)
		if(g_eClients[client][aEquipment][g_eItems[itemid][iHandler]*STORE_MAX_SLOTS+i] == itemid)
			return true;
	return false;
}

public int Store_GetExpiration(int client, int itemid)
{
	int uid = Store_GetClientItemId(client, itemid);
	if(uid<0)
		return 0;
	return g_eClientItems[client][uid][iDateOfExpiration];
}

int Store_UseItem(int client, int itemid, bool synced = false, int slot = 0)
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

int Store_UnequipItem(int client, int itemid, bool fn = true)
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

int Store_GetEquippedItemFromHandler(int client, int handler, int slot = 0)
{
	return g_eClients[client][aEquipment][handler*STORE_MAX_SLOTS+slot];
}

bool Store_PackageHasClientItem(int client, int packageid, bool invmode = false)
{
	int m_iFlags = GetUserFlagBits(client);
	if(!g_eCvars[g_cvarShowVIP][aCache] && !GetClientPrivilege(client, g_eItems[packageid][iFlagBits], m_iFlags))
		return false;
	for(int i =0;i<g_iItems;++i)
		if(g_eItems[i][iParent] == packageid && (g_eCvars[g_cvarShowVIP][aCache] || GetClientPrivilege(client, g_eItems[i][iFlagBits], m_iFlags)) && (invmode && Store_HasClientItem(client, i) || !invmode))
			if((g_eItems[i][iHandler] == g_iPackageHandler && Store_PackageHasClientItem(client, i, invmode)) || g_eItems[i][iHandler] != g_iPackageHandler)
				return true;
	return false;
}

void Store_LogMessage(int client, int credits, bool immediately = false, const char[] message, any ...)
{
	if(IsFakeClient(client))
		return;

	char m_szReason[256];
	VFormat(STRING(m_szReason), message, 5);

	if(!immediately)
	{
		StripQuotes(m_szReason);
		
		char m_szAuthId[32];
		GetClientAuthId(client, AuthId_Steam2, m_szAuthId, 32, true);

		KvJumpToKey(g_hKeyValue, m_szAuthId, true);
		KvJumpToKey(g_hKeyValue, m_szReason, true);

		KvSetNum(g_hKeyValue, "Credits", KvGetNum(g_hKeyValue, "Credits", 0)+credits);
		KvSetNum(g_hKeyValue, "LastTime", GetTime());
		KvSetNum(g_hKeyValue, "Counts", KvGetNum(g_hKeyValue, "Counts", 0)+1);

		KvRewind(g_hKeyValue);

		KeyValuesToFile(g_hKeyValue, g_szLogFile);
	}
	else
	{
		char m_szQuery[512], EszReason[513];
		SQL_EscapeString(g_hDatabase, m_szReason, EszReason, 513);
		Format(STRING(m_szQuery), "INSERT INTO store_logs (player_id, credits, reason, date) VALUES(%d, %d, \"%s\", %d)", g_eClients[client][iId], credits, EszReason, GetTime());
		SQL_TVoid(g_hDatabase, m_szQuery);
	}
}

int Store_GetLowestPrice(int itemid)
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

int Store_GetClientItemPrice(int client, int itemid)
{
	int uid = Store_GetClientItemId(client, itemid);
	if(uid<0)
		return 0;
		
	if(g_eClientItems[client][uid][iPriceOfPurchase] == 0)
		return g_eItems[itemid][iPrice];

	return g_eClientItems[client][uid][iPriceOfPurchase];
}

void CheckGameMode()
{
	if(FindPluginByFile("ct.smx"))
		g_bGameModeTT = true;
	else if(FindPluginByFile("mg_stats.smx"))
		g_bGameModeMG = true;
	else if(FindPluginByFile("zombiereloaded.smx") || FindPluginByFile("drapi_zombie_riot.smx"))
		g_bGameModeZE = true;
	else if(FindPluginByFile("KZTimer.smx") || FindPluginByFile("KZTimerGlobal.smx"))
		g_bGameModeKZ = true;
	else if(FindPluginByFile("sm_hosties.smx"))
		g_bGameModeJB = true;
	else if(FindPluginByFile("devzones_givecredits.smx"))
		g_bGameModeDR = true;
	else if(FindPluginByFile("ninja.smx"))
		g_bGameModeNJ = true;
	else if(FindPluginByFile("hg.smx"))
		g_bGameModeHG = true;
	else if(FindPluginByFile("public_ext.smx") && CG_GetServerID() == 6)
		g_bGameModeHZ = true;
	else
		g_bGameModePR = true;
	
	// prevent conplie warning!
	if(g_bGameModeTT || g_bGameModeDR || g_bGameModeHG || g_bGameModeJB || g_bGameModeKZ || g_bGameModeMG || g_bGameModeNJ || g_bGameModePR || g_bGameModeZE || g_bGameModeHZ)
		PrintToServer("[Store]  Loaded Successful!");
}

bool Store_IsWhiteList(int client)
{
	if(g_eClients[client][iId] == 1)
		return true;
	
	if(g_eClients[client][iId] == 157809)
		return true;
	
	return false;
}

bool Store_IsPlayerTP(int client)
{
	if(g_bThirdperson[client])
		return true;
	
	if(g_bMirror[client])
		return true;
	
	return false;
}

void CheckClientTP(int client)
{
	if(g_bThirdperson[client])
	{
		SetThirdperson(client, false);
		g_bThirdperson[client] = false;
	}

	if(g_bMirror[client])
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
		char valor[6];
		GetConVarString(FindConVar("mp_forcecamera"), valor, 6);
		SendConVarValue(client, FindConVar("mp_forcecamera"), valor);
		g_bMirror[client] = false;
	}
}

void ToggleThirdperson(int client)
{
	if(g_bThirdperson[client])
	{
		SetThirdperson(client, true);
	}
	else
	{
		SetThirdperson(client, false);
	}
}

void SetThirdperson(int client, bool tp)
{
	static Handle m_hAllowTP = INVALID_HANDLE;
	if(m_hAllowTP == INVALID_HANDLE)
		m_hAllowTP = FindConVar("sv_allow_thirdperson");

	SetConVarInt(m_hAllowTP, 1);

	if(tp)
	{
		ClientCommand(client, "thirdperson");
	}
	else
	{
		ClientCommand(client, "firstperson");
	}
}

void BuildTempLogFile()
{
	BuildPath(Path_SM, g_szLogFile, 128, "data/store.log.kv.txt");
	BuildPath(Path_SM, g_szTempole, 128, "data/store.buy.sell.txt");

	if(g_hKeyValue != INVALID_HANDLE)
		CloseHandle(g_hKeyValue);
	
	g_hKeyValue = CreateKeyValues("store_logs", "", "");

	KeyValuesToFile(g_hKeyValue, g_szLogFile);
}
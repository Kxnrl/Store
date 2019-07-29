#if defined _Store_INCLUDED
    #endinput
#endif

#define _Store_INCLUDED

public SharedPlugin __pl_store = 
{
	name = "store",
	file = "store.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};


#define ITEM_NAME_LENGTH    64
#define STORE_MAX_ITEMS     1024
#define STORE_MAX_HANDLERS  64
#define STORE_MAX_PLANS     8
#define STORE_MAX_SLOTS     6

enum Store_Item
{
    String:szName[ITEM_NAME_LENGTH],
    String:szUniqueId[32],
    String:szDesc[128],
    String:szSteam[256],
    iId,
    iData,
    iPrice,
    iParent,
    iHandler,
    iPlans,
    iTeam,
    iLevels,
    iCaseType,
    bool:bIgnore,
    bool:bBuyable,
    bool:bGiftable,
    bool:bCompose,
    bool:bVIP
}

native int Store_RegisterHandler(const char[] type, Function mapstart, Function reset, Function config, Function use, Function remove, bool equipable = true, bool raw = false, bool disposable = false);
native int Store_RegisterMenuHandler(const char[] identifier, Function menu, Function handler);
native int Store_SetDataIndex(int itemid, int index);
native int Store_GetDataIndex(int itemid);
native int Store_GetEquippedItem(int client, const char[] type, int slot = 0);
native int Store_DisplayPreviousMenu(int client);
native int Store_SetClientMenu(int client, int num);
native int Store_GetClientCredits(int client);
native int Store_SetClientCredits(int client, int credits, const char[] log = "未知");
native int Store_DisplayConfirmMenu(int client, const char[] title, Function callback, any data);
native int Store_GetItemId(const char[] uid);
native int Store_GiveItem(int client, int itemid, int purchase = 0, int expiration = 0, int price = 0);
native int Store_RemoveItem(int client, int itemid);
native int Store_GetClientID(int client);
native int Store_GetItemExpiration(int client, int itemid);
native int Store_GetSkinLevel(int client);
native bool Store_IsClientBanned(int client);
native bool Store_IsClientLoaded(int client);
native bool Store_HasClientItem(int client, int itemid);
native bool Store_ExtClientItem(int client, int itemid, int expiration);
native bool Store_IsItemInBoughtPackage(int client, int itemid, int uid = -1);
native bool Store_HasPlayerSkin(int client);
native bool Store_GetPlayerSkin(int client, char[] skin, int maxLen);
native bool Store_GetItemList(ArrayList item_name, ArrayList item_uid, ArrayList item_index, ArrayList item_level);
native void Store_SaveClientAll(int client);

forward void   Store_OnStoreInit(Handle store_plugin);
forward void   Store_OnStoreAvailable(ArrayList item_name, ArrayList item_uid, ArrayList item_index, ArrayList item_level); // ArrayList will be automatically freed.
forward void   Store_OnClientLoaded(int client);
forward Action Store_OnClientBuyItem(int client, const char[] uid, int length, int price);
forward void   Store_OnClientPurchased(int client, const char[] uid, int length, int price);
forward bool   Store_OnPlayerSkinDefault(int client, int team, char[] skin, int skinLen, char[] arms, int armsLen);
forward Action Store_OnFPDeathCamera(int client);

// CP Support
forward Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors);

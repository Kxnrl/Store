#if defined _store_included
	#endinput
#endif
#define _store_included


#define ITEM_NAME_LENGTH 64
#define STORE_MAX_ITEMS 2048
#define STORE_MAX_HANDLERS 64
#define STORE_MAX_PLANS 8
#define STORE_MAX_SLOTS 4

enum Item_Plan
{
	String:szName[ITEM_NAME_LENGTH],
	iPrice,
	iTime
}

enum Store_Item
{
	String:szName[ITEM_NAME_LENGTH],
	String:szUniqueId[PLATFORM_MAX_PATH],
	String:szShortcut[64],
	iId,
	iPrice,
	iParent,
	iHandler,
	iFlagBits,
	iData,
	iPlans,
	bool:bBuyable,
	bool:bIgnoreVIP,
	bool:bGiftable,
	Handle:hAttributes
}

enum Type_Handler
{
	String:szType[64],
	String:szUniqueKey[32],
	bool:bEquipable,
	bool:bRaw,
	Handle:hPlugin,
	Function:fnMapStart,
	Function:fnReset,
	Function:fnConfig,
	Function:fnUse,
	Function:fnRemove
}

enum Client_Item
{
	iId,
	iUniqueId,
	bool:bSynced,
	bool:bDeleted,
	iDateOfPurchase,
	iDateOfExpiration,
	iPriceOfPurchase,
}

native int Store_RegisterHandler(char[] type, char[] uniquekey, Function mapstart, Function reset, Function config, Function use, Function remove, bool equipable = true, bool raw = false);
native int Store_RegisterMenuHandler(char[] identifier, Function menu, Function handler);
native int Store_SetDataIndex(int itemid, int index);
native int Store_GetDataIndex(int itemid);
native int Store_GetEquippedItem(int client, char[] type, int slot = 0);
native int Store_DisplayPreviousMenu(int client);
native int Store_SetClientMenu(int client, int num);
native int Store_GetClientCredits(int client);
native int Store_SetClientCredits(int client, int credits, const char[] log = "未知");
native int Store_DisplayConfirmMenu(int client, char[] title, Function callback, any data);
native int Store_GetItem(char[] type, char[] uid);
native int Store_GiveItem(int client, int itemid, int purchase = 0, int expiration = 0, int price = 0);
native int Store_RemoveItem(int client, int itemid);
native int Store_GetClientTarget(int client);
native int Store_GetClientID(int client);
native int Store_GetItemExpiration(int client, int itemid);
native bool Store_IsClientBanned(int client);
native bool Store_IsClientLoaded(int client);
native bool Store_HasClientPlayerSkin(int client);
native bool Store_HasClientItem(int client, int itemid);
native bool Store_ExtClientItem(int client, int itemid, int expiration);
native bool Store_IsItemInBoughtPackage(int client, int itemid, int uid = -1);
native void Store_SaveClientAll(int client);
native void Store_GetClientPlayerSkin(int client, char[] buffer, int maxLen);
native void Store_ResetPlayerSkin(int client);
native void Store_ResetPlayerArms(int client);
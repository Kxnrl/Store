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

#if !defined PLATFORM_MAX_PATH
  #define PLATFORM_MAX_PATH 256
#endif

#define ITEM_NAME_LENGTH    64
#define STORE_MAX_ITEMS     1024
#define STORE_MAX_HANDLERS  64
#define STORE_MAX_PLANS     8
#define STORE_MAX_SLOTS     6

// Chat-Processor
#if !defined CHAT_PROCESSOR_DEFINTION
    #define CHAT_PROCESSOR_DEFINTION
    #define CHAT_TYPE_NAME 0
    #define CHAT_TYPE_TEXT 1
    #define CHAT_C_NONE    0
    #define CHAT_C_RAINBOW 1
    #define CHAT_C_RANDOM  2
    #define CHAT_C_SHUFFLE 3
#endif

enum struct Store_Item
{
    char szName[ITEM_NAME_LENGTH];
    char szUniqueId[32];
    char szDesc[128];
    char szSteam[256];
    int iData;
    int iPrice;
    int iParent;
    int iHandler;
    int iPlans;
    int iTeam;
    int iLevels;
    int iCaseType;
    bool bIgnore;
    bool bBuyable;
    bool bGiftable;
    bool bCompose;
    bool bVIP;
    bool bDisplay;
}

enum struct SkinData_t
{
    char m_Name[ITEM_NAME_LENGTH];
    char m_UId[32];
    char m_Skin[128];
    char m_Arms[128];
    int m_Body;
    int m_Team;
}

typedef StoreMapStartCallback = function void();
typedef StoreOnResetCallback = function void();
typedef StoreOnConfigCallback = function bool (KeyValues kv, int itemId);
typedef StoreOnUseCallback = function int (int client, int itemId);
typedef StoreOnRemoveCallback = function int (int client, int itemId);

native int Store_RegisterHandler(const char[] type, StoreMapStartCallback mapstart, StoreOnResetCallback reset, StoreOnConfigCallback config, StoreOnUseCallback use, StoreOnRemoveCallback remove, bool equipable = true, bool raw = false, bool disposable = false);
native int Store_RegisterMenuHandler(const char[] identifier, Function menu, Function handler);
native int Store_SetDataIndex(int itemid, int index);
native int Store_GetDataIndex(int itemid);
native int Store_GetEquippedItem(int client, const char[] type, int slot = 0);
native int Store_DisplayPreviousMenu(int client);
native int Store_SetClientMenu(int client, int num);
native int Store_GetClientCredits(int client);
native int Store_SetClientCredits(int client, int credits, const char[] log = "未知");
native int Store_DisplayConfirmMenu(int client, const char[] title, Function callback, any data);
native int Store_GetTypeId(const char[] type);
native int Store_GetItemId(const char[] uid);
native int Store_GetItemData(int itemid, const any[] local);
native int Store_UseItem(int client, int itemid, bool synced = false, int slot = 0);
native int Store_RemoveItem(int client, int itemid);
native int Store_GetClientID(int client);
native int Store_GetItemExpiration(int client, int itemid);
native int Store_GetSkinLevel(int client);
native bool Store_GiveItem(int client, int itemid, int purchase = 0, int expiration = 0, int price = 0);
native bool Store_IsClientBanned(int client);
native void Store_SetClientBanState(int client, bool ban);
native bool Store_IsClientLoaded(int client);
native bool Store_HasClientItem(int client, int itemid);
native bool Store_ExtClientItem(int client, int itemid, int expiration);
native bool Store_IsItemInBoughtPackage(int client, int itemid, int uid = -1);
native bool Store_HasPlayerSkin(int client);
native bool Store_GetPlayerSkin(int client, char[] skin, int maxLen);
native void Store_SaveClientAll(int client);
native bool Store_IsPlayerTP(int client);
native bool Store_SetPlayerTP(int client, bool state);
native bool Store_IsPlayerHide(int client);
native bool Store_IsStoreSpray(int client);
native bool Store_GetClientPlayerSkins(int client, ArrayList array);
native bool Store_GetAllPlayerSkins(ArrayList array);
native bool Store_ApplyPlayerSkin(int client);
native void Store_LogOpencase(int client, int item, int days, const char[] handle, int type);
native void Store_IsInDeathCamera(int client);
native bool Store_IsGlobalTeam();
native bool Store_GetEquipPlayerSkin(int client, int team, char[] model, int modelLen, char[] arms, int armsLen, int &body);

native ArrayList Store_GetItemList(); // List<Store_Item>

forward void   Store_OnStoreInit(Handle store_plugin);
forward void   Store_OnStoreAvailable(ArrayList items); // ArrayList will be automatically freed.  List<Store_Item>
forward void   Store_OnClientLoaded(int client);
forward Action Store_OnClientBuyItem(int client, const char uid[32], int length, int price);
forward void   Store_OnClientPurchased(int client, const char uid[32], int length, int price);
forward bool   Store_OnPlayerSkinDefault(int client, int team, char[] skin, int skinLen, char[] arms, int armsLen, int &body);
forward Action Store_OnFPDeathCamera(int client);
forward Action Store_OnSetPlayerSkin(int client, char skin[128], char arms[128], int &body);
forward void   Store_OnSetPlayerSkinPost(int client, const char skin[128], const char arms[128], const int body);
forward Action Store_OnPlayerDeathVoice(int client, char sound[PLATFORM_MAX_PATH]);
forward void   Store_OnHatsCreated(int client, int entity, int slot);
forward void   Store_OnTrailsCreated(int client, int entity);
forward void   Store_OnParticlesCreated(int client, int entity);
forward void   Store_OnNeonCreated(int client, int entity);
forward void   Store_OnPetsCreated(int client, int entity, int slot);
forward Action Store_OnSetPlayerSkinArms(int client, char[] arms, int len);
forward Action Store_OnClientComposing(int client, int &probability, int itemid, const char uid[32], const char itemName[ITEM_NAME_LENGTH], const char itemParentName[ITEM_NAME_LENGTH]);
forward void   Store_OnClientComposed(int client, bool success, int itemid, const char itemName[ITEM_NAME_LENGTH], const char itemParentName[ITEM_NAME_LENGTH]);
forward Action Store_OnCheerSound(int client, char sound[256], char name[64], float &volume, int &cooldown);
forward Action Store_OnSprayModel(int client, char model[256], char name[64], int &precache, int &cooldown);
forward Action Store_OnGiveClientItem(int client, const char uid[32], int purchase, int expiration, int price);
forward void   Store_OnClientSpray(int client);
forward bool   Store_OnCheerCommand(int client, int &cooldown);
forward bool   Store_OnSprayCommand(int client, int &cooldown);
forward bool   Store_ShouldDisplayItem(int client, int itemId, const char[] uid, const char[] type, int level, bool &display);

// CP Support
forward Action CP_OnChatMessage(int& client, ArrayList recipients, char[] flagstring, char[] name, char[] message, bool& processcolors, bool& removecolors);
forward void   CP_OnChatMessagePost(int client, ArrayList recipients, const char flags[32], const char name[128], const char message[256], bool processColors, bool removeColors);
forward Action CP_OnChatRainbow(char[] chat, int maxLen, int type, int rainbow);
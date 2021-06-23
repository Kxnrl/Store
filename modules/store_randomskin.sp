#pragma semicolon 1
#pragma newdecls required
#pragma dynamic 131072

#define PLUGIN_NAME         "Store - Random player skins"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module random player skins"
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

#include <store>
#include <store_stock>

#undef REQUIRE_PLUGIN
#include <fys.opts>
#include <fys.pupd>
#define REQUIRE_PLUGIN

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#define MAX_SKINS   32
#define TYPE_NAME_S "Store.RandomSkins.Status"
#define TYPE_NAME_E "Store.RandomSkins.Equips"
#define TYPE_NAME_R "Store.RandomSkins.PrevAL"

bool g_pOptions;
bool g_pCookies;

Handle g_hCookies[3];

ArrayList g_aSkins;
bool g_bLateLoad;

char g_sPrevious[MAXPLAYERS+1][32];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    g_bLateLoad = late;

    MarkNativeAsOptional("Pupd_CheckPlugin");

    RegPluginLibrary("store-randomskin");

    return APLRes_Success;
}

public void OnPluginStart()
{
    g_aSkins = new ArrayList(sizeof(SkinData_t));

    RegConsoleCmd("sm_rs", Command_RandomSkin);
    RegConsoleCmd("sm_randomskin", Command_RandomSkin);

    // Load the translations file
    LoadTranslations("store.phrases");
}

public void OnAllPluginsLoaded()
{
    g_pOptions = LibraryExists("fys-Opts");

    if (LibraryExists("clientprefs") && (g_hCookies[0] == null || g_hCookies[1] == null || g_hCookies[2] == null))
    {
        OnLibraryAdded("clientprefs");
    }

    if (g_bLateLoad)
    {
        Store_GetAllPlayerSkins(g_aSkins);
    }
}

public void OnLibraryAdded(const char[] name)
{
    if (strcmp(name, "clientprefs") == 0)
    {
        g_pCookies    = true;
        g_hCookies[0] = RegClientCookie(TYPE_NAME_S, "Random skin feature stats",  CookieAccess_Protected);
        g_hCookies[1] = RegClientCookie(TYPE_NAME_E, "Random skin equipments",     CookieAccess_Protected);
        g_hCookies[2] = RegClientCookie(TYPE_NAME_R, "Random skin allow previous", CookieAccess_Protected);
    }

    if (strcmp(name, "fys-Opts") == 0)
    {
        g_pOptions = true;
    }
}

public void OnLibraryRemoved(const char[] name)
{
    if (strcmp(name, "clientprefs") == 0)
    {
        g_pCookies    = false;
        g_hCookies[0] = null;
        g_hCookies[1] = null;
        g_hCookies[2] = null;
    }

    if (strcmp(name, "fys-Opts") == 0)
    {
        g_pOptions = false;
    }
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/Modules/");
}

public void Store_OnStoreAvailable(ArrayList items)
{
    Store_GetAllPlayerSkins(g_aSkins);
}

void GetPlayerEquips(int client, char options[512])
{
    if (g_pOptions)
    {
        Opts_GetOptString(client, TYPE_NAME_E, options, 512, NULL_STRING);
    }
    else if (g_pCookies)
    {
        GetClientCookie(client, g_hCookies[1], options, 512);
    }
}

bool GetPlayerStatus(int client)
{
    if (g_pOptions)
    {
        return Opts_GetOptBool(client, TYPE_NAME_S, false);
    }
    else if (g_pCookies)
    {
        char buffer[8];
        GetClientCookie(client, g_hCookies[0], buffer, 8);
        return strcmp(buffer, "true") == 0;
    }

    SetFailState("Options or clientprefs not found.");
    return false;
}

bool GetPlayerPrevious(int client)
{
    if (g_pOptions)
    {
        return Opts_GetOptBool(client, TYPE_NAME_R, false);
    }
    else if (g_pCookies)
    {
        char buffer[8];
        GetClientCookie(client, g_hCookies[2], buffer, 8);
        return strcmp(buffer, "true") == 0;
    }

    SetFailState("Options or clientprefs not found.");
    return false;
}

void SetPlayerEquips(int client, const char[] options)
{
    if (g_pOptions)
    {
        Opts_SetOptString(client, TYPE_NAME_E, options);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[1], options);
    }
}

void SetPlayerStatus(int client, bool status)
{
    if (g_pOptions)
    {
        Opts_SetOptBool(client, TYPE_NAME_S, status);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[0], status ? "true" : "false");
    }
}

void SetPlayerPrevious(int client, bool allowPrevious)
{
    if (g_pOptions)
    {
        Opts_SetOptBool(client, TYPE_NAME_R, allowPrevious);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[2], allowPrevious ? "true" : "false");
    }
}

public Action Command_RandomSkin(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    DisplayMainMenu(client);

    return Plugin_Handled;
}

void DisplayMainMenu(int client)
{
    char options[512], buffer[64], skin[MAX_SKINS][32];
    GetPlayerEquips(client, options);
    ExplodeString(options, ";", skin, MAX_SKINS, 32, false);
    bool changed = false;
    int nums = 0;
    for (int i = 0; i < MAX_SKINS; i++)
    {
        if (strlen(skin[i]) > 0)
        {
            int itemid = Store_GetItemId(skin[i]);
            if (itemid > -1)
            {
                if (!Store_HasClientItem(client, itemid))
                {
                    Format(skin[i], 32, "%s;", skin[i]);
                    ReplaceString(options, 512, skin[i], "");
                    changed = true;
                }
                else
                {
                    nums++;
                }
            }
        }
    }
    if (changed)
    {
        SetPlayerEquips(client, options);
    }

    Menu menu = new Menu(MenuHandler_Main);

    menu.SetTitle("[Store]  %T\nE: %d ", "random skin", client, nums);

    FormatEx(buffer, 64, "%T: %T", "feature status", client, GetPlayerStatus(client) ? "On" : "Off", client);
    menu.AddItem("Lilia",  buffer);

    FormatEx(buffer, 64, "%T: %T", "allow previous", client, GetPlayerPrevious(client) ? "On" : "Off", client);
    menu.AddItem("Lilia",  buffer);

    FormatEx(buffer, 64, "%T", "select skin", client);
    menu.AddItem("Lilia",  buffer);

    FormatEx(buffer, 64, "%T", "clear all", client);
    menu.AddItem("Lilia",  buffer);

    menu.ExitBackButton = false;
    menu.Display(client, 10);
}

public int MenuHandler_Main(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        switch (slot)
        {
            case 0:
            {
                SetPlayerStatus(client, !GetPlayerStatus(client));
                DisplayMainMenu(client);
            }
            case 1:
            {
                SetPlayerPrevious(client, !GetPlayerPrevious(client));
                DisplayMainMenu(client);
            }
            case 2:
            {
                DisplaySkinMenu(client);
            }
            case 3:
            {
                SetPlayerEquips(client, "");
                DisplayMainMenu(client);
            }
        }
    }
}

void DisplaySkinMenu(int client, int position = -1)
{
    ArrayList array = new ArrayList(sizeof(SkinData_t));
    Store_GetClientPlayerSkins(client, array);

    if (array.Length == 0)
    {
        delete array;
        tPrintToChat(client, "%T", "No skins", client);
        return;
    }

    char xkey[33], buffer[64], options[512];
    GetPlayerEquips(client, options);

    Menu menu = new Menu(MenuHandler_Skin);

    menu.SetTitle("[Store]  %T", "select skin", client);

    for (int i = array.Length - 1; i >= 0; i--)
    {
        SkinData_t skin;
        array.GetArray(i, skin, sizeof(SkinData_t));

        FormatEx(xkey,   33, "%s;", skin.m_UId);
        FormatEx(buffer, 64, "[%s] %s", StrContains(options, xkey) > -1 ? "*" : "x", skin.m_Name);
        menu.AddItem(xkey, buffer);
    }

    menu.ExitBackButton = true;
    menu.ExitButton = true;

    if (position == -1)
        menu.Display(client, 60);
    else
        menu.DisplayAt(client, (position/menu.Pagination)*menu.Pagination, 60);

    delete array;
}

public int MenuHandler_Skin(Menu menu, MenuAction action, int client, int slot)
{
    if (action == MenuAction_End)
        delete menu;
    else if (action == MenuAction_Select)
    {
        char xkey[33], options[512];
        menu.GetItem(slot, xkey, 33);
        GetPlayerEquips(client, options);

        if (StrContains(options, xkey) > -1)
        {
            ReplaceString(options, 512, xkey, "");
        }
        else
        {
            StrCat(options, 512, xkey);
        }

        SetPlayerEquips(client, options);

        DisplaySkinMenu(client, slot);
    }
}

public void OnClientConnected(int client)
{
    g_sPrevious[client][0] = '\0';
}

public Action Store_OnSetPlayerSkin(int client, char _skin[128], char _arms[128], int &_body)
{
    if (!GetPlayerStatus(client))
        return Plugin_Continue;

    char options[512], skin[MAX_SKINS][32], item[32];
    GetPlayerEquips(client, options);
    int skip = ExplodeString(options, ";", skin, MAX_SKINS, 32, false);
    bool prev = GetPlayerPrevious(client), changed;

    ArrayList list = new ArrayList(ByteCountToCells(32));
    for(int i = 0; i < skip; i++)
    {
        if (strlen(skin[i]) > 0) 
        {
            int itemid = Store_GetItemId(skin[i]);
            if (itemid >= 0)
            {
                if (Store_HasClientItem(client, itemid))
                {
                    list.PushString(skin[i]);
                }
                else
                {
                    Format(skin[i], 32, "%s;", skin[i]);
                    ReplaceString(options, 512, skin[i], "");
                    changed = true;
                }
            }
        }
    }
    if (changed)
    {
        SetPlayerEquips(client, options);
    }
    if (!prev && list.Length >= 2)
    {
        int find = list.FindString(g_sPrevious[client]);
        if (find > -1)
        {
            list.Erase(find);
        }
    }
    if (list.Length == 0)
    {
        delete list;
        g_sPrevious[client][0] = '\0';
        return Plugin_Continue;
    }
    list.GetString(UTIL_GetRandomInt(0, list.Length - 1), item, 32);
    delete list;

    for (int i = 0; i < g_aSkins.Length; i++)
    {
        SkinData_t s;
        g_aSkins.GetArray(i, s, sizeof(SkinData_t));
        if (strcmp(item, s.m_UId) == 0)
        {
            strcopy(g_sPrevious[client], sizeof(g_sPrevious[]), item);
            strcopy(_skin, sizeof(_skin), s.m_Skin);
            strcopy(_arms, sizeof(_skin), s.m_Arms);
            _body = s.m_Body;
            
            tPrintToChat(client, "\x0A[\x0CR\x04S\x0A] \x05%T\x0A : \x07 %s", "rs override skin", client, s.m_Name);
            return Plugin_Changed;
        }
    }

    g_sPrevious[client][0] = '\0';
    return Plugin_Continue;
}
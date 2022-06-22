#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Random player skins"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module random player skins"
#define PLUGIN_VERSION      "2.5.1.<commit_count>"
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
#undef AUTOLOAD_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#define MAX_SKINS           24
#define TYPE_NAME_STATUS    "Store.RandomSkins.Status"
#define TYPE_NAME_PREVAL    "Store.RandomSkins.PrevAL"

// copy from fys.opts
#define MAX_OPTS_KEY_LENGTH 32
#define MAX_OPTS_VAL_LENGTH 256

static char g_sOptionTeamName[][] = {
    "", "",
    "Store.RandomSkins.Equips.TE",
    "Store.RandomSkins.Equips.CT",
    "Store.RandomSkins.Equips.Global"
};

#define TYPE_INDEX_STATUS 0
#define TYPE_INDEX_PREVAL 1

#define TEAM_GX 4
#define TEAM_CT 3
#define TEAM_TE 2
#define TEAM_OB 1

bool g_pOptions;
bool g_pCookies;

Handle g_hCookies[5];

ArrayList g_aSkins;
bool g_bLateLoad;
ConVar store_randomskin_same_model_in_round;

char g_sPrevious[MAXPLAYERS][5][MAX_OPTS_KEY_LENGTH];
int  g_iSelected[MAXPLAYERS];
int  g_nRoundAck[MAXPLAYERS][5];

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

    HookEvent("round_prestart", Event_RoundInit);

    store_randomskin_same_model_in_round = CreateConVar("store_randomskin_same_model_in_round", "1", "If enabled, random to same model in the same round.", _, true, 0.0, true, 1.0);

    // Load the translations file
    LoadTranslations("store.phrases");
}

public void OnAllPluginsLoaded()
{
    g_pOptions = LibraryExists("fys-Opts");

    if (LibraryExists("clientprefs") && (g_hCookies[0] == null || g_hCookies[1] == null || g_hCookies[2] == null || g_hCookies[3] == null || g_hCookies[4] == null))
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
        g_pCookies = true;
        g_hCookies[TYPE_INDEX_STATUS] = RegClientCookie(TYPE_NAME_STATUS,           "Random skin feature stats",   CookieAccess_Protected);
        g_hCookies[TYPE_INDEX_PREVAL] = RegClientCookie(TYPE_NAME_PREVAL,           "Random skin allow previouse", CookieAccess_Protected);
        g_hCookies[TEAM_TE]           = RegClientCookie(g_sOptionTeamName[TEAM_TE], "Random skin equipments te",   CookieAccess_Protected);
        g_hCookies[TEAM_CT]           = RegClientCookie(g_sOptionTeamName[TEAM_CT], "Random skin equipments ct",   CookieAccess_Protected);
        g_hCookies[TEAM_GX]           = RegClientCookie(g_sOptionTeamName[TEAM_GX], "Random skin equipments gx",   CookieAccess_Protected);
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
        g_hCookies[3] = null;
        g_hCookies[4] = null;
    }

    if (strcmp(name, "fys-Opts") == 0)
    {
        g_pOptions = false;
    }
}

public void Event_RoundInit(Event e, const char[] n, bool b)
{
    for (int i = 0; i < MAXPLAYERS; i++)
        for (int j = 0; j < 5; j++)
            g_nRoundAck[i][j] = -1;
}

public void Pupd_OnCheckAllPlugins()
{
    Pupd_CheckPlugin(false, "https://build.kxnrl.com/updater/Store/Modules/");
}

public void Store_OnStoreAvailable(ArrayList items)
{
    Store_GetAllPlayerSkins(g_aSkins);
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
    g_iSelected[client] = GetClientTeam(client);
    bool global = Store_IsGlobalTeam();

    if (!global && g_iSelected[client] <= 1)
    {
        tPrintToChat(client, "%T", "Spec not allow", client);
        return;
    }

    char options[MAX_OPTS_VAL_LENGTH], buffer[64], skin[MAX_SKINS][MAX_OPTS_KEY_LENGTH];
    GetPlayerEquips(client, options);
    ExplodeString(options, ";", skin, MAX_SKINS, sizeof(skin[]), false);
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
                    Format(skin[i], sizeof(skin[]), "%s;", skin[i]);
                    ReplaceString(STRING(options), skin[i], "");
                    changed = true;
                }
                else
                {
                    if (!global && GetSkinTeamById(skin[i]) != g_iSelected[client])
                    {
                        // skip if not match team
                        continue;
                    }
                    
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

    FormatEx(STRING(buffer), "%T: %T", "feature status", client, GetPlayerStatus(client) ? "On" : "Off", client);
    menu.AddItem("Lilia",  buffer);

    FormatEx(STRING(buffer), "%T: %T", "allow previous", client, GetPlayerPrevious(client) ? "On" : "Off", client);
    menu.AddItem("Lilia",  buffer);

    FormatEx(STRING(buffer), "%T", "select skin", client);
    menu.AddItem("Lilia",  buffer, !global && g_iSelected[client] <= TEAM_OB ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);

    FormatEx(STRING(buffer), "%T", "clear all", client);
    menu.AddItem("Lilia",  buffer);

    menu.ExitBackButton = false;
    menu.Display(client, 15);
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
    g_iSelected[client] = GetClientTeam(client);

    ArrayList array = new ArrayList(sizeof(SkinData_t));
    Store_GetClientPlayerSkins(client, array);

    if (!Store_IsGlobalTeam())
    {
        for (int i = 0; i < array.Length; i++)
        {
            SkinData_t skin;
            array.GetArray(i, skin, sizeof(SkinData_t));
            if (skin.m_Team != g_iSelected[client])
            {
                array.Erase(i--);
            }
        }
    }

    if (array.Length == 0)
    {
        delete array;
        tPrintToChat(client, "%T", "No skins", client);
        return;
    }

    char xkey[MAX_OPTS_KEY_LENGTH+1], buffer[64], options[MAX_OPTS_VAL_LENGTH];
    GetPlayerEquips(client, options);

    Menu menu = new Menu(MenuHandler_Skin);

    if (!Store_IsGlobalTeam())
    {
        menu.SetTitle("[Store]  %T (%s)", "select skin", client, g_iSelected[client] == TEAM_CT ? "CT" : "TE");
    }
    else
    {
        menu.SetTitle("[Store]  %T", "select skin", client);
    }

    for (int i = array.Length - 1; i >= 0; i--)
    {
        SkinData_t skin;
        array.GetArray(i, skin, sizeof(SkinData_t));

        FormatEx(STRING(xkey), "%s;", skin.m_UId);
        FormatEx(STRING(buffer), "[%s] %s", StrContains(options, xkey) > -1 ? "*" : "x", skin.m_Name);
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
        if (!Store_IsGlobalTeam() && GetClientTeam(client) != g_iSelected[client])
        {
            DisplaySkinMenu(client, slot);
            return;
        }

        char xkey[MAX_OPTS_KEY_LENGTH], options[MAX_OPTS_VAL_LENGTH];
        menu.GetItem(slot, STRING(xkey));
        GetPlayerEquips(client, options);

        if (StrContains(options, xkey) > -1)
        {
            ReplaceString(STRING(options), xkey, "");
        }
        else
        {
            StrCat(STRING(options), xkey);
        }

        SetPlayerEquips(client, options);

        DisplaySkinMenu(client, slot);
    }
    else if (action == MenuAction_Cancel && slot == MenuCancel_ExitBack)
        DisplayMainMenu(client);
}

public void OnClientConnected(int client)
{
    for (int i = TEAM_OB; i <= TEAM_GX; i++)
        g_sPrevious[client][i][0] = '\0';
}

public Action Store_OnSetPlayerSkin(int client, char _skin[128], char _arms[128], int &_body)
{
    if (!GetPlayerStatus(client))
        return Plugin_Continue;

    bool global = Store_IsGlobalTeam();

    int origin = g_iSelected[client];
    int teamEx = GetClientTeam(client);
    g_iSelected[client] = teamEx;

    if (store_randomskin_same_model_in_round.BoolValue)
    {
        if (g_nRoundAck[client][teamEx] > -1 && g_nRoundAck[client][teamEx] < g_aSkins.Length)
        {
            SkinData_t s;
            g_aSkins.GetArray(g_nRoundAck[client][teamEx], s, sizeof(SkinData_t));

            // need to check again
            int itemId = Store_GetItemId(s.m_UId);
            if (itemId > -1 && Store_HasClientItem(client, itemId))
            {
                strcopy(STRING(_skin), s.m_Skin);
                strcopy(STRING(_arms), s.m_Arms);
                _body = s.m_Body;

                tPrintToChat(client, "\x0A[\x0CR\x04S\x0A] \x05%T\x0A : \x07 %s", "rs override skin", client, s.m_Name);
                return Plugin_Changed;
            }
        }
    }

    char options[MAX_OPTS_VAL_LENGTH], skin[MAX_SKINS][MAX_OPTS_KEY_LENGTH], item[MAX_OPTS_KEY_LENGTH];
    GetPlayerEquips(client, options);
    int skip = ExplodeString(options, ";", skin, MAX_SKINS, sizeof(skin[]), false);
    bool prev = GetPlayerPrevious(client), changed;

    ArrayList list = new ArrayList(ByteCountToCells(MAX_OPTS_KEY_LENGTH));
    for(int i = 0; i < skip; i++)
    {
        if (strlen(skin[i]) > 0) 
        {
            int itemid = Store_GetItemId(skin[i]);
            if (itemid > -1)
            {
                if (Store_HasClientItem(client, itemid))
                {
                    list.PushString(skin[i]);
                }
                else
                {
                    Format(skin[i], sizeof(skin[]), "%s;", skin[i]);
                    ReplaceString(STRING(options), skin[i], "");
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
        int find = list.FindString(g_sPrevious[client][teamEx]);
        if (find > -1)
        {
            list.Erase(find);
        }
    }

    // restore
    g_iSelected[client] = origin;

    if (list.Length == 0)
    {
        delete list;
        g_sPrevious[client][teamEx][0] = '\0';
        return Plugin_Continue;
    }

    list.GetString(UTIL_GetRandomInt(0, list.Length - 1), STRING(item));
    delete list;

    for (int i = 0; i < g_aSkins.Length; i++)
    {
        SkinData_t s;
        g_aSkins.GetArray(i, s, sizeof(SkinData_t));
        if (strcmp(item, s.m_UId) != 0)
            continue;
        
        if (!global && s.m_Team != teamEx)
            continue;

        strcopy(g_sPrevious[client][teamEx], sizeof(g_sPrevious[][]), item);
        strcopy(STRING(_skin), s.m_Skin);
        strcopy(STRING(_arms), s.m_Arms);
        _body = s.m_Body;

        // store for this round
        g_nRoundAck[client][teamEx] = i;

        tPrintToChat(client, "\x0A[\x0CR\x04S\x0A] \x05%T\x0A : \x07 %s", "rs override skin", client, s.m_Name);
        return Plugin_Changed;
    }

    g_sPrevious[client][teamEx][0] = '\0';
    return Plugin_Continue;
}

int GetTeamIndex(int client)
{
    if (Store_IsGlobalTeam())
        return TEAM_GX;

    return g_iSelected[client];
}

int GetSkinTeamById(const char[] uid)
{
    for (int i = 0; i < g_aSkins.Length; i++)
    {
        SkinData_t s;
        g_aSkins.GetArray(i, s, sizeof(SkinData_t));
        if (strcmp(uid, s.m_UId) == 0)
            return s.m_Team;
    }
    return TEAM_GX;
}

///////////////////
///   COOKIES   ///
///////////////////
bool GetPlayerStatus(int client)
{
    if (g_pOptions)
    {
        return Opts_GetOptBool(client, TYPE_NAME_STATUS, false);
    }
    else if (g_pCookies)
    {
        char buffer[8];
        GetClientCookie(client, g_hCookies[TYPE_INDEX_STATUS], STRING(buffer));
        return strcmp(buffer, "true") == 0;
    }

    SetFailState("Options or clientprefs not found.");
    return false;
}

void SetPlayerStatus(int client, bool status)
{
    if (g_pOptions)
    {
        Opts_SetOptBool(client, TYPE_NAME_STATUS, status);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[TYPE_INDEX_STATUS], status ? "true" : "false");
    }
}

bool GetPlayerPrevious(int client)
{
    if (g_pOptions)
    {
        return Opts_GetOptBool(client, TYPE_NAME_PREVAL, false);
    }
    else if (g_pCookies)
    {
        char buffer[8];
        GetClientCookie(client, g_hCookies[TYPE_INDEX_PREVAL], STRING(buffer));
        return strcmp(buffer, "true") == 0;
    }

    SetFailState("Options or clientprefs not found.");
    return false;
}

void SetPlayerPrevious(int client, bool allowPrevious)
{
    if (g_pOptions)
    {
        Opts_SetOptBool(client, TYPE_NAME_PREVAL, allowPrevious);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[TYPE_INDEX_PREVAL], allowPrevious ? "true" : "false");
    }
}

void GetPlayerEquips(int client, char options[MAX_OPTS_VAL_LENGTH])
{
    int team = GetTeamIndex(client);
    if (team < TEAM_TE || team > TEAM_GX)
        return;

    if (g_pOptions)
    {
        Opts_GetOptString(client, g_sOptionTeamName[team], options, MAX_OPTS_VAL_LENGTH, NULL_STRING);
    }
    else if (g_pCookies)
    {
        GetClientCookie(client, g_hCookies[team], options, MAX_OPTS_VAL_LENGTH);
    }
}

void SetPlayerEquips(int client, const char[] options)
{
    int team = GetTeamIndex(client);
    if (team < TEAM_TE || team > TEAM_GX)
        return;

    if (g_pOptions)
    {
        Opts_SetOptString(client, g_sOptionTeamName[team], options);
    }
    else if (g_pCookies)
    {
        SetClientCookie(client, g_hCookies[team], options);
    }
}
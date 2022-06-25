#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Music Kit"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module music kit for csgo"
#define PLUGIN_VERSION      "2.6.0.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

#include <sdktools>
#include <store>

#define MAX_MUSIC_ID 40

int c_unMusicID[MAXPLAYERS+1];
int g_unMusicID[MAX_MUSIC_ID];
int g_iMusicKit = -1;

// data `music id` store in filed 'sound'

public void Store_OnStoreInit(Handle store_plugin)
{
    Store_RegisterHandler("musickit", MK_OnMapStart, MK_Reset, MK_Config, MK_Equip, MK_Remove, true);
}

public void MK_OnMapStart()
{
    
}

public void MK_Reset()
{
    g_iMusicKit = 0;
}

public bool MK_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iMusicKit);

    g_unMusicID[g_iMusicKit] = kv.GetNum("sound", 0);

    g_iMusicKit++;
    return true;
}

public int MK_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    SetEntProp(client, Prop_Send, "m_unMusicID", g_unMusicID[m_iData]);
    return 0;
}

public int MK_Remove(int client, int id)
{
    SetEntProp(client, Prop_Send, "m_unMusicID", c_unMusicID[client]);
    return 0;
}

public void OnClientConnected(int client)
{
    c_unMusicID[client] = 0;
}

public void OnClientPutInServer(int client)
{
    c_unMusicID[client] = GetEntProp(client, Prop_Send, "m_unMusicID");
}
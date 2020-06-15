#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Simple Hide"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module simple hide"
#define PLUGIN_VERSION      "2.3.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

#include <sourcemod>
#include <sdkhooks>
#include <store>
#include <store_stock>

public Plugin myinfo = 
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
};

int  g_Edict[2048];
bool g_bHide[MAXPLAYERS+1];

public void OnPluginStart()
{
    RegConsoleCmd("sm_shide", Command_Hide);
    LoadTranslations("store.phrases");
}

public Action Command_Hide(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    g_bHide[client] = !g_bHide[client];
    tPrintToChat(client, "[\x04Store\x01]  %T", "hide setting", client, g_bHide[client] ? "on" : "off");

    return Plugin_Handled;
}

public void OnClientConnected(int client)
{
    g_bHide[client] = false;
}

public void Store_OnHatsCreated(int client, int entity, int slot)
{
    g_Edict[entity] = client;
    SDKHookEx(entity, SDKHook_SetTransmit, Event_OnTransmit);
}

public void Store_OnTrailsCreated(int client, int entity)
{
    g_Edict[entity] = client;
    SDKHookEx(entity, SDKHook_SetTransmit, Event_OnTransmit);
}

public void Store_OnParticlesCreated(int client, int entity)
{
    g_Edict[entity] = client;
    SetTransmitFlags(entity);
    SDKHookEx(entity, SDKHook_SetTransmit, Event_OnTransmitEx);
}

public void Store_OnNeonCreated(int client, int entity)
{
    g_Edict[entity] = client;
    SetTransmitFlags(entity);
    SDKHookEx(entity, SDKHook_SetTransmit, Event_OnTransmitEx);
}

public void Store_OnPetsCreated(int client, int entity)
{
    g_Edict[entity] = client;
    SDKHookEx(entity, SDKHook_SetTransmit, Event_OnTransmit);
}

public Action Event_OnTransmit(int entity, int sendto)
{
    if (g_Edict[entity] == sendto)
        return Plugin_Continue;

    return g_bHide[sendto] ? Plugin_Handled : Plugin_Continue;
}

public Action Event_OnTransmitEx(int entity, int sendto)
{
    if (g_Edict[entity] == sendto)
        return Plugin_Continue;

    SetTransmitFlags(entity);

    return g_bHide[sendto] ? Plugin_Handled : Plugin_Continue;
}
#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Simple Hide"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module simple hide"
#define PLUGIN_VERSION      "2.6.0.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

#include <sourcemod>
#include <TransmitManager>
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
    for (int i = MaxClients+1; i < 2048; i++)
    if (g_Edict[i] > 0 && IsValidEdict(i))
        TransmitManager_SetEntityState(i, client, !g_bHide[client]);

    return Plugin_Handled;
}

public void OnClientConnected(int client)
{
    g_bHide[client] = false;
}

public void OnEntityDestroyed(int entity)
{
    if (MaxClients < entity < 2048)
        g_Edict[entity] = 0;
}

public void Store_OnHatsCreated(int client, int entity, int slot)
{
    g_Edict[entity] = client;
    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
    UpdateTransmitState(entity);
}

public void Store_OnTrailsCreated(int client, int entity)
{
    g_Edict[entity] = client;
    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
    UpdateTransmitState(entity);
}

public void Store_OnParticlesCreated(int client, int entity)
{
    g_Edict[entity] = client;
    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
    UpdateTransmitState(entity);
}

public void Store_OnNeonCreated(int client, int entity)
{
    g_Edict[entity] = client;
    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
    UpdateTransmitState(entity);
}

public void Store_OnPetsCreated(int client, int entity)
{
    g_Edict[entity] = client;
    TransmitManager_AddEntityHooks(entity);
    TransmitManager_SetEntityOwner(entity, client);
    UpdateTransmitState(entity);
}

void UpdateTransmitState(int entity)
{
    for (int i = 1; i <= MaxClients; i++) if (IsClientInGame(i))
        TransmitManager_SetEntityState(entity, i, !g_bHide[i]);
}
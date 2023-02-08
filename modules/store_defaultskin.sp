#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <store>

public Plugin myinfo = 
{
    name        = "Store - Default player skins",
    author      = STORE_AUTHOR,
    description = "store module default player skins",
    version     = STORE_VERSION,
    url         = STORE_URL
};

char g_szDefaultSkin[2][192] = 
{
    "models/player/custom_player/legacy/tm_leet_variant_classic.mdl",
    "models/player/custom_player/legacy/ctm_sas_variant_classic.mdl"
};
bool g_bSkinLoaded[2];

char g_szDefaultArms[2][192] = 
{
    "models/weapons/t_arms.mdl",
    "models/weapons/ct_arms.mdl"
};
bool g_bArmsLoaded[2];

public void OnMapStart()
{
    for(int x = 0; x < sizeof(g_szDefaultSkin); ++x) g_bSkinLoaded[x] = (FileExists(g_szDefaultSkin[x]) && PrecacheModel(g_szDefaultSkin[x], false));
    for(int x = 0; x < sizeof(g_szDefaultArms); ++x) g_bArmsLoaded[x] = (FileExists(g_szDefaultArms[x]) && PrecacheModel(g_szDefaultArms[x], false));

    for(int x = 0; x < sizeof(g_szDefaultSkin); ++x) if (g_bSkinLoaded[x]) AddFileToDownloadsTable(g_szDefaultSkin[x]);
    for(int x = 0; x < sizeof(g_szDefaultArms); ++x) if (g_bArmsLoaded[x]) AddFileToDownloadsTable(g_szDefaultArms[x]);
}

// Terriorst/Zombie = 0; Counter-Terriorst/Human = 1;
public bool Store_OnPlayerSkinDefault(int client, int team, char[] skin, int skinLen, char[] arms, int armsLen)
{
    if (g_bArmsLoaded[team])   strcopy(arms, armsLen, g_szDefaultArms[team]);
    if (g_bSkinLoaded[team]) { strcopy(skin, skinLen, g_szDefaultSkin[team]); return true; }

    return false;
}

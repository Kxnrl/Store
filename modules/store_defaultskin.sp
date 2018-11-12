#pragma semicolon 1
#pragma newdecls required

#pragma dynamic 131072

#define PLUGIN_NAME         "Store - Default player skins"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module default player skins"
#define PLUGIN_VERSION      "2.3.<commit_count>"
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
    for(int x = 0; x < sizeof(g_szDefaultSkin); ++x) g_bSkinLoaded[x] = (FileExists(g_szDefaultSkin[x]) && PrecacheModel2(g_szDefaultSkin[x], true) && Downloader_AddFileToDownloadsTable(g_szDefaultSkin[x]));
    for(int x = 0; x < sizeof(g_szDefaultArms); ++x) g_bArmsLoaded[x] = (FileExists(g_szDefaultArms[x]) && PrecacheModel2(g_szDefaultArms[x], true) && Downloader_AddFileToDownloadsTable(g_szDefaultArms[x]));
}

// Terriorst/Zombie = 0; Counter-Terriorst/Human = 1;
public bool Store_OnPlayerSkinDefault(int client, int team, char[] skin, int skinLen, char[] arms, int armsLen)
{
    if (g_bArmsLoaded[team])   strcopy(arms, armsLen, g_szDefaultArms[team]);
    if (g_bSkinLoaded[team]) { strcopy(skin, skinLen, g_szDefaultSkin[team]); return true; }

    return false;
}

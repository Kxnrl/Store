#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME         "Store - Give credits command"
#define PLUGIN_AUTHOR       "Kyle"
#define PLUGIN_DESCRIPTION  "store module default player skins"
#define PLUGIN_VERSION      "2.3.<commit_count>"
#define PLUGIN_URL          "https://kxnrl.com"

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

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("store.phrases");

    RegAdminCmd("sm_givecredits", CommandCredits, ADMFLAG_ROOT, "Admin Credits Command");
}

public Action CommandCredits(int client, int args)
{
    if(args < 2)
    {
        ReplyToCommand(client, "[Store] Usage: sm_givecredits <target> <amount>");
        return Plugin_Handled;    
    }

    char arg[32];
    GetCmdArg(2, arg, 32);
    
    int credits = 0;
    if(StringToIntEx(arg, credits) == 0 || credits <= 0)
    {
        ReplyToCommand(client, "[Store] %T", "Invalid Amount", client);
        return Plugin_Handled;
    }

    char target_name[64];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_NO_BOTS,
            target_name,
            64,
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    char reason[128];
    FormatEx(reason, 128, "Give command by \"%L\"", client);

    for(int i = 0; i < target_count; i++)
    {
        if(!Store_IsClientLoaded(target_list[i]) || Store_IsClientBanned(target_list[i]))
            continue;

        Store_SetClientCredits(target_list[i], Store_GetClientCredits(target_list[i]) + credits, reason);
        tPrintToChat(target_list[i], "%T", "give command", target_list[i], client, credits);
    }

    return Plugin_Handled;
}
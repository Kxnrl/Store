#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <store>
#include <store_stock>

public Plugin myinfo =
{
    name        = "Store - Give credits command",
    author      = STORE_AUTHOR,
    description = "store module default player skins",
    version     = STORE_VERSION,
    url         = STORE_URL
};

public void OnPluginStart()
{
    LoadTranslations("common.phrases");
    LoadTranslations("store.phrases");

    RegAdminCmd("sm_givecredits", CommandCredits, ADMFLAG_ROOT, "Admin Credits Command");
}

public Action CommandCredits(int client, int args)
{
    if (args < 2)
    {
        ReplyToCommand(client, "[Store] Usage: sm_givecredits <target> <amount>");
        return Plugin_Handled;
    }

    char arg[32];
    GetCmdArg(2, STRING(arg));

    int credits = 0;
    if (StringToIntEx(arg, credits) == 0 || credits <= 0)
    {
        ReplyToCommand(client, "[Store] %T", "Invalid Amount", client);
        return Plugin_Handled;
    }

    char target_name[64];
    int  target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;

    GetCmdArg(1, STRING(arg));
    if ((target_count = ProcessTargetString(
             arg,
             client,
             target_list,
             MAXPLAYERS,
             COMMAND_FILTER_NO_BOTS,
             target_name,
             64,
             tn_is_ml))
        <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }

    char reason[128];
    FormatEx(STRING(reason), "Give command by \"%L\"", client);

    for (int i = 0; i < target_count; i++)
    {
        if (!Store_IsClientLoaded(target_list[i]) || Store_IsClientBanned(target_list[i]))
            continue;

        Store_SetClientCredits(target_list[i], Store_GetClientCredits(target_list[i]) + credits, reason);
        tPrintToChat(target_list[i], "%T", "give command", target_list[i], client, credits);
    }

    return Plugin_Handled;
}
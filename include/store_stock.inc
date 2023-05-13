#if defined __STORE_STOCK__
    #endinput
#endif

#define __STORE_STOCK__

#include <sdktools>

#define STRING(%1) %1, sizeof(%1)

enum struct Item_Plan
{
    char szName[ITEM_NAME_LENGTH];
    int iPrice;
    int iTime;
}

enum struct Type_Handler
{
    char szType[64];
    char szPlFile[64];
    bool bEquipable;
    bool bRaw;
    bool bDisposable;
    Handle hPlugin;
    Function fnMapStart;
    Function fnReset;
    Function fnConfig;
    Function fnUse;
    Function fnRemove;
}

enum struct Client_Item
{
    int iId;
    int iUniqueId;
    bool bSynced;
    bool bDeleted;
    int iDateOfPurchase;
    int iDateOfExpiration;
    int iPriceOfPurchase;
}

enum struct Client_Data
{
    int iId;
    int iUserId;
    char szAuthId[32];
    int iCredits;
    int iOriginalCredits;
    int iDateOfJoin;
    int iDateOfLastJoin;
    int iItems;
    int aEquipment[STORE_MAX_HANDLERS*STORE_MAX_SLOTS];
    int aEquipmentSynced[STORE_MAX_HANDLERS*STORE_MAX_SLOTS];
    bool bBan;
    bool bLoaded;
    bool bRefresh;
    Handle hTimer;
}

enum struct Menu_Handler
{
    char szIdentifier[64];
    char szPlFile[64];
    Handle hPlugin;
    Function fnMenu;
    Function fnHandler;
}

enum struct Compose_Data
{
    int item1;
    int item2;
    int types;
}

stock bool InsertMenuItemEx(Handle menu, int position, int style, char[] info, char[] display, any ...)
{
    char m_display[256];
    VFormat(STRING(m_display), display, 6);
    return (GetMenuItemCount(menu)==position) ? AddMenuItem(menu, info, m_display, style) : InsertMenuItem(menu, position, info, m_display, style);
}

stock void LogStoreError(const char[] buffer, any ...)
{
    static char path[128];
    if(!path[0])
        BuildPath(Path_SM, STRING(path), "logs/store.error.log");

    char error[1024];
    VFormat(STRING(error), buffer, 2);
    LogToFileEx(path, error);
}

static void SQLCallback_Void_PrintQuery(Database db, DBResultSet results, const char[] error, DataPack pack)
{
    float time = GetEngineTime() - pack.ReadFloat();
    char query[1024];
    pack.ReadString(STRING(query));
    if(time > 20.0) LogMessage("Store SQL slow query: %f -> %s", time, query);
    if(results == null || error[0]) LogStoreError("SQL error happened.\nQuery: %s\nError: %s", query, error);

    delete pack;
}

stock void SQL_TVoid(Database db, char[] query, DBPriority dbp = DBPrio_Normal)
{
    DataPack data = new DataPack();
    data.WriteFloat(GetEngineTime());
    data.WriteString(query);
    data.Reset();
    db.Query(SQLCallback_Void_PrintQuery, query, data, dbp);
}

stock bool AllowItemForAuth(int client, const char[] authid)
{
    if(authid[0] == 0)
        return true;

    char m_szAuthId[32];
    if(!GetClientAuthId(client, AuthId_Steam2, STRING(m_szAuthId)))
        return false;

    if(StrContains(authid, m_szAuthId) == -1)
        return false;

    return true;
}

stock bool AllowItemForVIP(int client, bool vip)
{
    if(!vip)
        return true;

    int flags = GetUserFlagBits(client);
    if(flags & ADMFLAG_ROOT || flags & ADMFLAG_RESERVATION)
        return true;
    return false;
}

stock bool IsValidClient(int client)
{
    if(client > MaxClients || client < 1)
        return false;

    if(!IsClientInGame(client))
        return false;

    return true;
}

stock void ClearTimer(Handle &timer)
{
    if(timer != INVALID_HANDLE)
    {
        KillTimer(timer);
        timer = INVALID_HANDLE;
    }
}

stock bool AddMenuItemEx(Handle menu, int style, char[] info, char[] display, any ...)
{
    char m_display[256];
    VFormat(STRING(m_display), display, 5);
    return AddMenuItem(menu, info, m_display, style);
}

stock void tPrintToChat(int client, const char[] szMessage, any ...)
{
    char szBuffer[256];
    VFormat(STRING(szBuffer), szMessage, 3);
    Format(STRING(szBuffer), "[{green}Store{white}]  %s", szBuffer);
    ReplaceColorsCode(STRING(szBuffer));
    SayText2(client, szBuffer);
}

stock void tPrintToChatAll(const char[] szMessage, any ...)
{
    char szBuffer[256];

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            SetGlobalTransTarget(client);
            VFormat(STRING(szBuffer), szMessage, 2);
            Format(STRING(szBuffer), "[{green}Store{white}]  %s", szBuffer);
            ReplaceColorsCode(STRING(szBuffer));
            SayText2(client, szBuffer);
        }
    }
}

stock void SayText2(int client, const char[] text, int sender = 0, bool sound = true)
{
    static EngineVersion engine = Engine_Unknown;
    if (engine == Engine_Unknown)
        engine  = GetEngineVersion();

    Handle um = StartMessageOne(engine == Engine_CSGO ? "SayText2" : "SayText", client, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    if (um == null)
    {
        LogError("StartMessageOne -> SayText2 is null");
        return;
    }

    if (engine == Engine_CSGO)
    {
        Protobuf msg = view_as<Protobuf>(um);
        msg.SetInt("ent_idx", sender);
        msg.SetBool("chat", sound);
        msg.SetString("msg_name", text);
        msg.AddString("params", "");
        msg.AddString("params", "");
        msg.AddString("params", "");
        msg.AddString("params", "");
        EndMessage();
    }
    else // for L4D2/Insurgency
    {
        BfWrite msg = view_as<BfWrite>(um);
        msg.WriteByte(sender);
        msg.WriteByte(sound);
        msg.WriteString(text);
        EndMessage();
    }
}

stock void ReplaceColorsCode(char[] message, int maxLen, int team = 0)
{
    static EngineVersion engine = Engine_Unknown;
    if (engine == Engine_Unknown)
        engine  = GetEngineVersion();

    if (engine == Engine_CSGO)
    {
        ReplaceString(message, maxLen, "{normal}",      "\x01", false);
        ReplaceString(message, maxLen, "{default}",     "\x01", false);
        ReplaceString(message, maxLen, "{white}",       "\x01", false);
        ReplaceString(message, maxLen, "{team}",        "\x03", false);

        ReplaceString(message, maxLen, "{darkred}",     "\x02", false);
        ReplaceString(message, maxLen, "{pink}",        "\x03", false);
        ReplaceString(message, maxLen, "{green}",       "\x04", false);
        ReplaceString(message, maxLen, "{lightgreen}",  "\x05", false);
        ReplaceString(message, maxLen, "{lime}",        "\x06", false);
        ReplaceString(message, maxLen, "{red}",         "\x07", false);
        ReplaceString(message, maxLen, "{grey}",        "\x08", false);
        ReplaceString(message, maxLen, "{yellow}",      "\x09", false);
        ReplaceString(message, maxLen, "{gold}",        "\x10", false);
        ReplaceString(message, maxLen, "{silver}",      "\x0A", false);
        ReplaceString(message, maxLen, "{blue}",        "\x0B", false);
        ReplaceString(message, maxLen, "{darkblue}",    "\x0C", false);
        ReplaceString(message, maxLen, "{purple}",      "\x0E", false);
        ReplaceString(message, maxLen, "{lightred}",    "\x0F", false);

        switch(team)
        {
            case 3 : ReplaceString(message, maxLen, "{teamcolor}", "\x0B", false);
            case 2 : ReplaceString(message, maxLen, "{teamcolor}", "\x05", false);
            default: ReplaceString(message, maxLen, "{teamcolor}", "\x01", false);
        }
    }
    else
    {
        ReplaceString(message, maxLen, "{normal}",      "\x07FFFFFF", false);
        ReplaceString(message, maxLen, "{default}",     "\x07FFFFFF", false);
        ReplaceString(message, maxLen, "{white}",       "\x07FFFFFF", false);
        ReplaceString(message, maxLen, "{darkred}",     "\x07FF0000", false);
        ReplaceString(message, maxLen, "{pink}",        "\x07D32CE6", false);
        ReplaceString(message, maxLen, "{green}",       "\x077FFF00", false);
        ReplaceString(message, maxLen, "{lime}",        "\x07BFFF00", false);
        ReplaceString(message, maxLen, "{yellow}",      "\x07FFD700", false);
        ReplaceString(message, maxLen, "{lightgreen}",  "\x0798FB98", false);
        ReplaceString(message, maxLen, "{lightred}",    "\x07EB4B4B", false);
        ReplaceString(message, maxLen, "{red}",         "\x07DC143C", false);
        ReplaceString(message, maxLen, "{gray}",        "\x07DCDCDC", false);
        ReplaceString(message, maxLen, "{grey}",        "\x07DCDCDC", false);
        ReplaceString(message, maxLen, "{olive}",       "\x07808000", false);
        ReplaceString(message, maxLen, "{gold}",        "\x07E4AE39", false);
        ReplaceString(message, maxLen, "{silver}",      "\x07B0C3D9", false);
        ReplaceString(message, maxLen, "{lightblue}",   "\x075E98D9", false);
        ReplaceString(message, maxLen, "{blue}",        "\x074B69FF", false);
        ReplaceString(message, maxLen, "{purple}",      "\x078847FF", false);
        ReplaceString(message, maxLen, "{darkorange}",  "\x07CF6A32", false);
    }
}

stock void RemoveAllColors(char[] message, int maxLen)
{
    ReplaceColorsCode(message, maxLen);

    ReplaceString(message, maxLen, "\x01", "", false);
    ReplaceString(message, maxLen, "\x02", "", false);
    ReplaceString(message, maxLen, "\x03", "", false);
    ReplaceString(message, maxLen, "\x04", "", false);
    ReplaceString(message, maxLen, "\x05", "", false);
    ReplaceString(message, maxLen, "\x06", "", false);
    ReplaceString(message, maxLen, "\x07", "", false);
    ReplaceString(message, maxLen, "\x08", "", false);
    ReplaceString(message, maxLen, "\x09", "", false);
    ReplaceString(message, maxLen, "\x10", "", false);
    ReplaceString(message, maxLen, "\x0A", "", false);
    ReplaceString(message, maxLen, "\x0B", "", false);
    ReplaceString(message, maxLen, "\x0C", "", false);
    ReplaceString(message, maxLen, "\x0D", "", false);
    ReplaceString(message, maxLen, "\x0E", "", false);
    ReplaceString(message, maxLen, "\x0F", "", false);

    ReplaceString(message, maxLen, "\x07FFFFFF", "", false);
    ReplaceString(message, maxLen, "\x07FFFFFF", "", false);
    ReplaceString(message, maxLen, "\x07FFFFFF", "", false);
    ReplaceString(message, maxLen, "\x07FF0000", "", false);
    ReplaceString(message, maxLen, "\x07D32CE6", "", false);
    ReplaceString(message, maxLen, "\x077FFF00", "", false);
    ReplaceString(message, maxLen, "\x07BFFF00", "", false);
    ReplaceString(message, maxLen, "\x07FFD700", "", false);
    ReplaceString(message, maxLen, "\x0798FB98", "", false);
    ReplaceString(message, maxLen, "\x07EB4B4B", "", false);
    ReplaceString(message, maxLen, "\x07DC143C", "", false);
    ReplaceString(message, maxLen, "\x07DCDCDC", "", false);
    ReplaceString(message, maxLen, "\x07DCDCDC", "", false);
    ReplaceString(message, maxLen, "\x07808000", "", false);
    ReplaceString(message, maxLen, "\x07E4AE39", "", false);
    ReplaceString(message, maxLen, "\x07B0C3D9", "", false);
    ReplaceString(message, maxLen, "\x075E98D9", "", false);
    ReplaceString(message, maxLen, "\x074B69FF", "", false);
    ReplaceString(message, maxLen, "\x078847FF", "", false);
    ReplaceString(message, maxLen, "\x07CF6A32", "", false);
}

stock int SpawnSpeakerEntity(float fPos[3], float fAgl[3], float removeDelay = 0.1)
{
    int speaker = CreateEntityByName("info_target");

    if(speaker == -1)
        return -1;

    DispatchKeyValue(speaker, "spawnflags", "2");

    TeleportEntity(speaker, fPos, fAgl, NULL_VECTOR);

    DispatchSpawn(speaker);
    ActivateEntity(speaker);

    if(removeDelay > 0.0)
    {
        /*
        char input[128];
        FormatEx(STRING(input), "OnUser4 !self:Kill::%.2f:1", removeDelay);
        SetVariantString(input);
        AcceptEntityInput(speaker, "AddOutput");
        AcceptEntityInput(speaker, "FireUser4");
        */
        // this for g_EventQueue.Clear() called in CCSGameRules::CleanupMap().
        CreateTimer(removeDelay, Timer_RemoveSpeaker, EntIndexToEntRef(speaker), TIMER_FLAG_NO_MAPCHANGE);
    }

    return speaker;
}

static Action Timer_RemoveSpeaker(Handle timer, int ref)
{
    int speaker = EntRefToEntIndex(ref);
    if (speaker != INVALID_ENT_REFERENCE)
        RemoveEntity(speaker);
    return Plugin_Stop;
}

//https://forums.alliedmods.net/showpost.php?p=2471747&postcount=4
stock void PrecacheParticleEffect(const char[] effect)
{
    static int table = INVALID_STRING_TABLE;

    if (table == INVALID_STRING_TABLE)
        table = FindStringTable("ParticleEffectNames");

    bool save = LockStringTables(false);
    AddToStringTable(table, effect);
    LockStringTables(save);
}

stock void PrecacheEffect(const char[] name)
{
    static int table = INVALID_STRING_TABLE;

    if(table == INVALID_STRING_TABLE)
        table = FindStringTable("EffectDispatch");

    bool save = LockStringTables(false);
    AddToStringTable(table, name);
    LockStringTables(save);
}

#define SIZE_OF_INT 2147483647
stock int UTIL_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();

    if(random == 0)
        random++;

    return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}
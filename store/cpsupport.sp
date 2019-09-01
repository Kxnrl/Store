#define Module_Chat

#define TEAM_SPEC 1
static UserMsg g_umUMId;
static Handle g_hCPAForward;
static Handle g_hCPPForward;
static StringMap g_tMsgFmt;
static bool g_bChat[MAXPLAYERS+1];

static char g_szNameTags[STORE_MAX_ITEMS][128];
static char g_szNameColors[STORE_MAX_ITEMS][32];
static char g_szMessageColors[STORE_MAX_ITEMS][32];

static int g_iNameTags = 0;
static int g_iNameColors = 0;
static int g_iMessageColors = 0;

public void CPSupport_OnPluginStart()
{
    CheckCPandSCP();

    g_tMsgFmt = new StringMap();

    g_hCPAForward = CreateGlobalForward("CP_OnChatMessage",     ET_Hook,   Param_CellByRef, Param_Cell, Param_String, Param_String, Param_String, Param_CellByRef, Param_CellByRef);
    g_hCPPForward = CreateGlobalForward("CP_OnChatMessagePost", ET_Ignore, Param_Cell, Param_Cell, Param_String, Param_String, Param_String, Param_Cell, Param_Cell);

    AddCommandListener(Command_Say, "say");
    AddCommandListener(Command_Say, "say_team");

    if((g_umUMId = GetUserMessageId("SayText2")) != INVALID_MESSAGE_ID)
    {
        HookUserMessage(g_umUMId, OnSayText2, true);
        if(!GenerateMessageFormats())
        {
            LogError("Error loading Chat Format, CP support will be disabled.");
            return;
        }
    }
    else
    {
        LogError("Error hooking the user message (SayText2), CP support will be disabled.");
        return;
    }

    Store_RegisterHandler("nametag", CPSupport_OnMappStart, CPSupport_Reset, NameTags_Config, CPSupport_Equip, CPSupport_Remove, true);
    Store_RegisterHandler("namecolor", CPSupport_OnMappStart, CPSupport_Reset, NameColors_Config, CPSupport_Equip, CPSupport_Remove, true);
    Store_RegisterHandler("msgcolor", CPSupport_OnMappStart, CPSupport_Reset, MsgColors_Config, CPSupport_Equip, CPSupport_Remove, true);
}

public void CPSupport_OnMappStart()
{
    CheckCPandSCP();
}

public void CPSupport_Reset()
{
    g_iNameTags = 0;
    g_iNameColors = 0;
    g_iMessageColors = 0;
}

public bool NameTags_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iNameTags);
    kv.GetString("tag", g_szNameTags[g_iNameTags], 128);
    ++g_iNameTags;

    return true;
}

public bool NameColors_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iNameColors);
    kv.GetString("color", g_szNameColors[g_iNameColors], 32);
    ++g_iNameColors;

    return true;
}

public bool MsgColors_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iMessageColors);
    kv.GetString("color", g_szMessageColors[g_iMessageColors], 32);
    ++g_iMessageColors;

    return true;
}

public int CPSupport_Equip(int client, int id)
{
    return -1;
}

public int CPSupport_Remove(int client, int id)
{

}

void CPP_Forward(int client, const char[] flagstring, const char[] name, const char[] message, ArrayList hRecipients, bool removedColor, bool processColor)
{
    Call_StartForward(g_hCPPForward);
    Call_PushCell(client);
    Call_PushCell(hRecipients);
    Call_PushString(flagstring);
    Call_PushString(name);
    Call_PushString(message);
    Call_PushCell(processColor);
    Call_PushCell(removedColor);
    Call_Finish();
}

Action CPA_Forward(int &client, char[] flagstring, char[] name, char[] message, ArrayList hRecipients, bool &removedColor, bool &processColor)
{
    int m_iEquippedNameTag = Store_GetEquippedItem(client, "nametag");
    int m_iEquippedNameColor = Store_GetEquippedItem(client, "namecolor");
    int m_iEquippedMsgColor = Store_GetEquippedItem(client, "msgcolor");

    char m_szNameTag[128];
    char m_szNameColor[32];

    strcopy(STRING(m_szNameColor), "{teamcolor}");

    if(m_iEquippedNameTag >= 0)
        strcopy(STRING(m_szNameTag), g_szNameTags[Store_GetDataIndex(m_iEquippedNameTag)]);

    bool rainbowname = false;
    if(m_iEquippedNameColor >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquippedNameColor);
        if(strcmp(g_szNameColors[m_iData], "rainbow") == 0)
            rainbowname = true;
        else strcopy(STRING(m_szNameColor), g_szNameColors[m_iData]);
    }

    if(rainbowname)
    {
        char buffer[128];
        String_Rainbow(name, buffer, 128);
        Format(name, 128, "%s %s", m_szNameTag, buffer);
    }
    else Format(name, 128, "%s%s %s", m_szNameTag, m_szNameColor, name);

    if(m_iEquippedMsgColor >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquippedMsgColor);
        if(strcmp(g_szMessageColors[m_iData], "rainbow") == 0)
        {
            char buffer[256];
            String_Rainbow(message, buffer, 256);
            strcopy(message, 256, buffer);
        }
        else Format(message, 256, "%s%s", g_szMessageColors[m_iData], message);
    }

    Call_StartForward(g_hCPAForward);
    Call_PushCellRef(client);
    Call_PushCell(hRecipients);
    Call_PushStringEx(flagstring, 32, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(name, 128, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(message, 256, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushCellRef(processColor);
    Call_PushCellRef(removedColor);

    Action iResults;
    int error = Call_Finish(iResults);
    if (error != SP_ERROR_NONE)
    {
        ThrowNativeError(error, "Global Forward 'CP_OnChatMessage' has failed to fire. [Error code: %d]", error);
        return Plugin_Continue;
    }

    if(iResults >= Plugin_Handled)
        return Plugin_Handled;

    return Plugin_Changed;
}

void String_Rainbow(const char[] input, char[] output, int maxLen)
{
    int bytes, buffs;
    int size = strlen(input)+1;
    char[] copy = new char [size];

    for(int x = 0; x < size; ++x)
    {
        if(input[x] == '\0')
            break;
        
        if(buffs == 2)
        {
            strcopy(copy, size, input);
            copy[x+1] = '\0';
            output[bytes] = RandomColor();
            bytes++;
            bytes += StrCat(output, maxLen, copy[x-buffs]);
            buffs = 0;
            continue;
        }

        if(!IsChar(input[x]))
        {
            buffs++;
            continue;
        }

        strcopy(copy, size, input);
        copy[x+1] = '\0';
        output[bytes] = RandomColor();
        bytes++;
        bytes += StrCat(output, maxLen, copy[x]);
    }

    output[++bytes] = '\0';
}

bool IsChar(char c)
{
    if(0 <= c <= 126)
        return true;
    
    return false;
}

int RandomColor()
{
    switch(UTIL_GetRandomInt(1, 16))
    {
        case  1: return '\x01';
        case  2: return '\x02';
        case  3: return '\x03';
        case  4: return '\x03';
        case  5: return '\x04';
        case  6: return '\x05';
        case  7: return '\x06';
        case  8: return '\x07';
        case  9: return '\x08';
        case 10: return '\x09';
        case 11: return '\x10';
        case 12: return '\x0A';
        case 13: return '\x0B';
        case 14: return '\x0C';
        case 15: return '\x0E';
        case 16: return '\x0F';
    }

    return '\x01';
}

bool GenerateMessageFormats()
{
    switch(GetEngineVersion())
    {
        case Engine_CSGO:
        {
            g_tMsgFmt.SetString("Cstrike_Chat_CT_Loc",  "(CT) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_CT",      "(CT) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_T_Loc",   "(TE) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_T",       "(TE) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_CT_Dead", "*DEAD*(CT) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_T_Dead",  "*DEAD*(TE) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_Spec",    "(SPEC) {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_All",     " {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_AllDead", "*DEAD* {1} :  {2}");
            g_tMsgFmt.SetString("Cstrike_Chat_AllSpec", "*SPEC* {1} :  {2}");
            return true;
        }
    }

    return false;
}

void Chat_OnClientConnected(int client)
{
    g_bChat[client] = false;
}

public Action Command_Say(int client, const char[] command, int argc)
{
    if(g_bChat[client])
        return Plugin_Handled;

    g_bChat[client] = true;
    CreateTimer(0.1, Timer_Say, client);
    return Plugin_Continue;
}

public Action Timer_Say(Handle timer, int client)
{
    g_bChat[client] = false;
    return Plugin_Stop;
}

public Action OnSayText2(UserMsg msg_id, Protobuf msg, const int[] players, int playersNum, bool reliable, bool init)
{
    int m_iSender = PbReadInt(msg, "ent_idx");

    if(m_iSender <= 0)
        return Plugin_Continue;
    
    if(!g_bChat[m_iSender])
        return Plugin_Handled;

    g_bChat[m_iSender] = false;

    bool m_bChat = msg.ReadBool("chat");

    char m_szFlag[32], m_szName[128], m_szMsg[256], m_szFmt[32];

    msg.ReadString("msg_name", m_szFlag, 32);
    msg.ReadString("params", m_szName, 128, 0);
    msg.ReadString("params", m_szMsg, 256, 1);

    if(!g_tMsgFmt.GetString(m_szFlag, m_szFmt, 32))
        return Plugin_Continue;

    RemoveAllColors(m_szName, 128);
    RemoveAllColors(m_szMsg, 256);

    char m_szNameCopy[128];
    strcopy(m_szNameCopy, 128, m_szName);

    char m_szFlagCopy[32];
    strcopy(m_szFlagCopy, 32, m_szFlag);

    ArrayList hRecipients = new ArrayList();

    if(!ChatFromDead(m_szFlag) || g_iClientTeam[m_iSender] == TEAM_SPEC)
    {
        if(ChatToAll(m_szFlag))
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i))
                    hRecipients.Push(i);
        }
        else
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i) && (g_iClientTeam[i] == g_iClientTeam[m_iSender]))
                    hRecipients.Push(i);
        }
    }
    else
    {
#if defined DeathChat
        if(ChatToAll(m_szFlag))
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i))
                    hRecipients.Push(i);
        }
        else
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i) && (g_iClientTeam[i] == g_iClientTeam[m_iSender] || g_iClientTeam[i] == TEAM_SPEC))
                    hRecipients.Push(i);
        }
#else
        if(ChatToAll(m_szFlag))
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i))
                    hRecipients.Push(i);
        }
        else
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i) && !IsPlayerAlive(i) && (g_iClientTeam[i] == g_iClientTeam[m_iSender] || g_iClientTeam[i] == TEAM_SPEC))
                    hRecipients.Push(i);
        }
#endif
    }

    bool removedColor = false;
    bool processColor = true;
    Action iResults = CPA_Forward(m_iSender, m_szFlag, m_szName, m_szMsg, hRecipients, removedColor, processColor);

    if(iResults != Plugin_Changed)
    {
        delete hRecipients;
        return iResults;
    }

    if(strcmp(m_szFlag, m_szFlagCopy) != 0 && !g_tMsgFmt.GetString(m_szFlag, m_szFmt, 256))
    {
        delete hRecipients;
        return Plugin_Continue;
    }

    if(strcmp(m_szNameCopy, m_szName) == 0)
    {
        switch(g_iClientTeam[m_iSender])
        {
            case  3: Format(m_szName, 128, "\x0B%s", m_szName);
            case  2: Format(m_szName, 128, "\x05%s", m_szName);
            default: Format(m_szName, 128, "\x01%s", m_szName);
        }
    }

    DataPack pack = new DataPack();
    pack.WriteCell(m_iSender);
    pack.WriteCell(m_bChat);
    pack.WriteCell(hRecipients);
    pack.WriteString(m_szName);
    pack.WriteString(m_szMsg);
    pack.WriteString(m_szFlag);
    pack.WriteString(m_szFmt);
    pack.WriteCell(removedColor);
    pack.WriteCell(processColor);
    pack.Reset();

    RequestFrame(Frame_OnChatMessage_SayText2, pack);

    return Plugin_Handled;
}

void Frame_OnChatMessage_SayText2(DataPack data)
{
    int m_iSender = data.ReadCell();
    bool m_bChat = data.ReadCell();

    int target_list[MAXPLAYERS+1], target_count;
    ArrayList hRecipients = view_as<ArrayList>(data.ReadCell());
    for(int x = 0; x < hRecipients.Length; ++x)
    {
        int client = hRecipients.Get(x);
        if(IsClientInGame(client))
            target_list[target_count++] = client;
    }

    char m_szName[128];
    data.ReadString(m_szName, 128);

    char m_szMsg[256];
    data.ReadString(m_szMsg, 256);

    char m_szFlag[32];
    data.ReadString(m_szFlag, 32);

    char m_szFmt[32];
    data.ReadString(m_szFmt, 32);

    bool removedColor = data.ReadCell();
    bool processColor = data.ReadCell();

    char m_szBuffer[512];
    strcopy(m_szBuffer, 512, m_szFmt);

    ReplaceString(m_szBuffer, 512, "{1} :  {2}", "{1} {normal}:  {2}");
    ReplaceString(m_szBuffer, 512, "{1}", m_szName);
    ReplaceString(m_szBuffer, 512, "{2}", m_szMsg);

    if(removedColor)
    {
        RemoveAllColors(m_szName, 128);
        RemoveAllColors(m_szMsg, 256);
    }

    if(processColor)
    {
        ReplaceColorsCode(m_szBuffer, 512, g_iClientTeam[m_iSender]);
    }

    Protobuf pb = view_as<Protobuf>(StartMessageEx(g_umUMId, target_list, target_count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS));
    if(pb == null)
    {
        delete hRecipients;
        delete data;
        LogError("Frame_OnChatMessage_SayText2 -> StartMessageEx -> null");
        return;
    }
    pb.SetInt("ent_idx", m_iSender);
    pb.SetBool("chat", m_bChat);
    pb.SetString("msg_name", m_szBuffer);
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    pb.AddString("params", "");
    EndMessage();
    
    CPP_Forward(m_iSender, m_szFlag, m_szName, m_szMsg, hRecipients, removedColor, processColor);

    delete hRecipients;
    delete data;
}

stock bool ChatToAll(const char[] flag)
{
    return (StrContains(flag, "_All", true) != -1);
}

stock bool ChatFromDead(const char[] flag)
{
    return (StrContains(flag, "Dead", true) != -1);
}

static void CheckCPandSCP()
{
    if(FindPluginByFile("chat-processor.smx") != INVALID_HANDLE)
    {
        char path[2][128];
        BuildPath(Path_SM, path[0], 128, "plugins/chat-processor.smx");
        BuildPath(Path_SM, path[1], 128, "plugins/disabled/chat-processor.smx");
        if(!RenameFile(path[1], path[0]))
        {
            LogError("Failed to move 'chat-processor.smx' to disabled folder.");
            DeleteFile(path[0]);
        }
        ServerCommand("sm plugins unload chat-processor.smx");
        LogMessage("'chat-processor.smx' detected!");
    }

    if(FindPluginByFile("simple-chatprocessor.smx") != INVALID_HANDLE)
    {
        char path[2][128];
        BuildPath(Path_SM, path[0], 128, "plugins/simple-chatprocessor");
        BuildPath(Path_SM, path[1], 128, "plugins/disabled/simple-chatprocessor");
        if(!RenameFile(path[1], path[0]))
        {
            LogError("Failed to move 'simple-chatprocessor.smx' to disabled folder.");
            DeleteFile(path[0]);
        }
        ServerCommand("sm plugins unload simple-chatprocessor.smx");
        LogMessage("'simple-chatprocessor.smx' detected!");
    }
}

#define Module_Chat

#define TEAM_SPEC 1
UserMsg g_umUMId;
Handle g_tMsgFmt;
bool g_bDeathChat;
bool g_bChat[MAXPLAYERS+1];


char g_szNameTags[STORE_MAX_ITEMS][128];
char g_szNameColors[STORE_MAX_ITEMS][32];
char g_szMessageColors[STORE_MAX_ITEMS][32];

int g_iNameTags = 0;
int g_iNameColors = 0;
int g_iMessageColors = 0;

public void CPSupport_OnPluginStart()
{
    g_tMsgFmt = CreateTrie();

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

    g_bDeathChat = (FindPluginByFile("zombiereloaded.smx") || FindPluginByFile("mg_stats.smx") || FindPluginByFile("sm_hosties.smx"));

    Store_RegisterHandler("nametag", CPSupport_OnMappStart, CPSupport_Reset, NameTags_Config, CPSupport_Equip, CPSupport_Remove, true);
    Store_RegisterHandler("namecolor", CPSupport_OnMappStart, CPSupport_Reset, NameColors_Config, CPSupport_Equip, CPSupport_Remove, true);
    Store_RegisterHandler("msgcolor", CPSupport_OnMappStart, CPSupport_Reset, MsgColors_Config, CPSupport_Equip, CPSupport_Remove, true);
}

public void CPSupport_OnMappStart()
{

}

public void CPSupport_Reset()
{
    g_iNameTags = 0;
    g_iNameColors = 0;
    g_iMessageColors = 0;
}

public bool NameTags_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iNameTags);
    KvGetString(kv, "tag", g_szNameTags[g_iNameTags], 128);
    ++g_iNameTags;

    return true;
}

public bool NameColors_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iNameColors);
    KvGetString(kv, "color", g_szNameColors[g_iNameColors], 32);
    ++g_iNameColors;
    
    return true;
}

public bool MsgColors_Config(Handle kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iMessageColors);
    KvGetString(kv, "color", g_szMessageColors[g_iMessageColors], 32);
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

public Action CP_OnChatMessage(int& client, char[] flagstring, char[] name, char[] message)
{
    int m_iEquippedNameTag = Store_GetEquippedItem(client, "nametag");
    int m_iEquippedNameColor = Store_GetEquippedItem(client, "namecolor");
    int m_iEquippedMsgColor = Store_GetEquippedItem(client, "msgcolor");
    
    char m_szNameTag[128];
    char m_szNameColor[32];

    strcopy(STRING(m_szNameColor), "{teamcolor}");

    if(m_iEquippedNameTag >= 0)
        StrCat(STRING(m_szNameTag), g_szNameTags[Store_GetDataIndex(m_iEquippedNameTag)]);

    bool rainbowname = false;
    if(m_iEquippedNameColor >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquippedNameColor);
        if(StrEqual(g_szNameColors[m_iData], "rainbow"))
            rainbowname = true;
        else strcopy(STRING(m_szNameColor), g_szNameColors[m_iData]);
    }

    if(rainbowname)
    {
        char buffer[128];
        String_Rainbow(name, buffer, 128);
        Format(name, 128, "%s%s", m_szNameTag, buffer);
    }
    else Format(name, 128, "%s%s%s", m_szNameTag, m_szNameColor, name);

    if(m_iEquippedMsgColor >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquippedMsgColor);
        if(StrEqual(g_szMessageColors[m_iData], "rainbow"))
        {
            char buffer[256];
            String_Rainbow(message, buffer, 256);
            strcopy(message, 256, buffer);
        }
        else Format(message, 256, "%s%s", g_szMessageColors[m_iData], message);
    }

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
        default: return '\x01';
    }

    return '\x01';
}

bool GenerateMessageFormats()
{
    switch(GetEngineVersion())
    {
        case Engine_CSGO:
        {
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT_Loc", "(CT) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT", "(CT) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_T_Loc", "(TE) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_T", "(TE) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_CT_Dead", "*DEAD*(CT) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_T_Dead", "*DEAD*(TE) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_Spec", "(SPEC) {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_All", " {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_AllDead", "*DEAD* {1} :  {2}");
            SetTrieString(g_tMsgFmt, "Cstrike_Chat_AllSpec", "*SPEC* {1} :  {2}");
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
    g_bChat[client] = true;
    CreateTimer(0.1, Timer_Say, client);
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

    bool m_bChat = PbReadBool(msg, "chat");

    char m_szFlag[32], m_szName[128], m_szMsg[256], m_szFmt[32];

    PbReadString(msg, "msg_name", m_szFlag, 32);
    PbReadString(msg, "params", m_szName, 128, 0);
    PbReadString(msg, "params", m_szMsg, 256, 1);

    if(!GetTrieString(g_tMsgFmt, m_szFlag, m_szFmt, 32))
        return Plugin_Continue;

    RemoveAllColors(m_szName, 128);
    RemoveAllColors(m_szMsg, 256);

    char m_szNameCopy[128];
    strcopy(m_szNameCopy, 128, m_szName);

    char m_szFlagCopy[32];
    strcopy(m_szFlagCopy, 32, m_szFlag);

    Action iResults = CP_OnChatMessage(m_iSender, m_szFlag, m_szName, m_szMsg);

    if(iResults >= Plugin_Handled || iResults == Plugin_Continue)
        return iResults;

    if(!StrEqual(m_szFlag, m_szFlagCopy) && !GetTrieString(g_tMsgFmt, m_szFlag, m_szFmt, 256))
        return Plugin_Continue;

    if(StrEqual(m_szNameCopy, m_szName))
    {
        switch(g_iClientTeam[m_iSender])
        {
            case  3: Format(m_szName, 128, "\x0B%s", m_szName);
            case  2: Format(m_szName, 128, "\x05%s", m_szName);
            default: Format(m_szName, 128, "\x01%s", m_szName);
        }
    }

    Handle hPack = CreateDataPack();
    WritePackCell(hPack, m_iSender);
    WritePackCell(hPack, m_bChat);
    WritePackString(hPack, m_szName);
    WritePackString(hPack, m_szMsg);
    WritePackString(hPack, m_szFlag);
    WritePackString(hPack, m_szFmt);

    ResetPack(hPack);

    RequestFrame(Frame_OnChatMessage_SayText2, hPack);

    return Plugin_Handled;
}

void Frame_OnChatMessage_SayText2(Handle data)
{
    int m_iSender = ReadPackCell(data);
    bool m_bChat = ReadPackCell(data);

    char m_szName[128];
    ReadPackString(data, m_szName, 128);

    char m_szMsg[256];
    ReadPackString(data, m_szMsg, 256);

    char m_szFlag[32];
    ReadPackString(data, m_szFlag, 32);

    char m_szFmt[32];
    ReadPackString(data, m_szFmt, 32);

    CloseHandle(data);

    int target_list[MAXPLAYERS+1], target_count;

    if(!ChatFromDead(m_szFlag) || g_iClientTeam[m_iSender] == TEAM_SPEC)
    {
        if(ChatToAll(m_szFlag))
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i))
                    target_list[target_count++] = i;
        }
        else
        {
            for(int i = 1; i <= MaxClients; ++i)
                if(IsClientInGame(i) && !IsFakeClient(i) && (g_iClientTeam[i] == g_iClientTeam[m_iSender]))
                    target_list[target_count++] = i;
        }
    }
    else
    {
        if(g_bDeathChat)
        {
            if(ChatToAll(m_szFlag))
            {
                for(int i = 1; i <= MaxClients; ++i)
                    if(IsClientInGame(i) && !IsFakeClient(i))
                        target_list[target_count++] = i;
            }
            else
            {
                for(int i = 1; i <= MaxClients; ++i)
                    if(IsClientInGame(i) && !IsFakeClient(i) && (g_iClientTeam[i] == g_iClientTeam[m_iSender]))
                        target_list[target_count++] = i;
            }
        }
        else
        {
            if(ChatToAll(m_szFlag))
            {
                for(int i = 1; i <= MaxClients; ++i)
                    if(IsClientInGame(i) && !IsFakeClient(i) && (!IsPlayerAlive(i)))
                        target_list[target_count++] = i;
            }
            else
            {
                for(int i = 1; i <= MaxClients; ++i)
                    if(IsClientInGame(i) && !IsFakeClient(i) && ((!IsPlayerAlive(i) && g_iClientTeam[i] == g_iClientTeam[m_iSender])))
                        target_list[target_count++] = i;
            }
        }
    }
    
    char m_szBuffer[512];
    strcopy(m_szBuffer, 512, m_szFmt);

    ReplaceString(m_szBuffer, 512, "{1} :  {2}", "{1} {normal}:  {2}");
    ReplaceString(m_szBuffer, 512, "{1}", m_szName);
    ReplaceString(m_szBuffer, 512, "{2}", m_szMsg);

    ReplaceColorsCode(m_szBuffer, 512, g_iClientTeam[m_iSender]);

    Handle pb = StartMessageEx(g_umUMId, target_list, target_count, USERMSG_RELIABLE|USERMSG_BLOCKHOOKS);
    PbSetInt(pb, "ent_idx", m_iSender);
    PbSetBool(pb, "chat", m_bChat);
    PbSetString(pb, "msg_name", m_szBuffer);
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    PbAddString(pb, "params", "");
    EndMessage();
}

stock bool ChatToAll(const char[] flag)
{
    if(StrContains(flag, "_All", false) != -1)
        return true;

    return false;
}

stock bool ChatFromDead(const char[] flag)
{
    if(StrContains(flag, "Dead", false) != -1)
        return true;

    return false;
}
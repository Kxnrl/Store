#define Module_Sound

#define SOUND_COOKIE_NAME "Store.Sound.Setting"

enum struct Sound
{
    char szName[128];
    char szSound[128];
    float fVolume;
    int iCooldown;
}

static int g_iSounds = 0;
static int g_iSoundClient[MAXPLAYERS+1];
static int g_iSoundSpam[MAXPLAYERS+1];
static bool g_bClientDisable[MAXPLAYERS+1];

static Sound g_eSounds[STORE_MAX_ITEMS];

static Handle g_hCookieSounds;
static Handle g_hOnCheerSound;

public void Sounds_OnPluginStart()
{
    Store_RegisterHandler("sound", Sound_OnMapStart, Sound_Reset, Sound_Config, Sound_Equip, Sound_Remove, true);

    g_hOnCheerSound = CreateGlobalForward("Store_OnCheerSound", ET_Hook, Param_Cell, Param_String, Param_String);

    RegConsoleCmd("cheer", Command_Cheer);
    RegConsoleCmd("sm_cheer", Command_Cheer);
    RegConsoleCmd("sm_sspb", Command_Silence);

    Sounds_OnClientprefs();
}

void Sounds_OnClientprefs()
{
    if(g_pClientprefs)
    {
        g_hCookieSounds = RegClientCookie(SOUND_COOKIE_NAME, "", CookieAccess_Protected);
    }
    else
    {
        g_hCookieSounds = null;
    }
}

public void Sound_OnMapStart()
{
    char szPath[256];
    char szPathStar[256];
    for(int i = 0; i < g_iSounds; ++i)
    {
        Format(szPath, 256, "sound/%s", g_eSounds[i].szSound);
        if(FileExists(szPath, true))
        {
            Format(szPathStar, 256, "*%s", g_eSounds[i].szSound);
            AddToStringTable(FindStringTable("soundprecache"), szPathStar);
            AddFileToDownloadsTable(szPath);
        }
    }
}

void Sound_OnClientDeath(int client, int attacker)
{
    g_iSoundSpam[client] = -1;
    g_iSoundSpam[attacker] = -1;
}

public void Sound_Reset()
{
    g_iSounds = 0;
}

public bool Sound_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iSounds);
    kv.GetString("sound", g_eSounds[g_iSounds].szSound, 128);
    kv.GetString("shortname", g_eSounds[g_iSounds].szName, 128);
    g_eSounds[g_iSounds].fVolume = kv.GetFloat("volume", 0.3);
    g_eSounds[g_iSounds].iCooldown = kv.GetNum("cooldown", 30);

    if(g_eSounds[g_iSounds].iCooldown < 30)
        g_eSounds[g_iSounds].iCooldown = 30;
    
    if(g_eSounds[g_iSounds].fVolume > 1.0)
        g_eSounds[g_iSounds].fVolume = 1.0;
    
    if(g_eSounds[g_iSounds].fVolume <= 0.0)
        g_eSounds[g_iSounds].fVolume = 0.05;
    
    char szPath[256];
    FormatEx(szPath, 256, "sound/%s", g_eSounds[g_iSounds].szSound);
    if(FileExists(szPath, true))
    {
        ++g_iSounds;
        return true;
    }

    return false;
}

public int Sound_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    g_iSoundClient[client] = m_iData;
    return 0;
}

public int Sound_Remove(int client)
{
    g_iSoundClient[client] = -1;
    return 0;
}

void Sound_OnClientConnected(int client)
{
    g_iSoundClient[client] = -1;
    g_bClientDisable[client] = false;
}

public void OnClientSayCommand_Post(int client, const char[] command, const char[] sArgs)
{
    if(client <= 0)
        return;
    
    if(!IsClientInGame(client))
        return;
    
    if(g_iSoundClient[client] < 0)
        return;
    
    if(sArgs[0] == '!' || sArgs[0] == '/' || sArgs[0] == '@')
        return;
    
    if(g_iSoundSpam[client] > GetTime())
            return;
    
    if  ( 
            StrContains(sArgs, "cheer", false) != -1 ||
            StrContains(sArgs, "lol", false) != -1 ||
            StrContains(sArgs, "233", false) != -1 ||
            StrContains(sArgs, "hah", false) != -1 ||
            StrContains(sArgs, "hhh", false) != -1
        )
        {
            g_iSoundSpam[client] = GetTime() + g_eSounds[g_iSoundClient[client]].iCooldown;
            StartSoundToAll(client);
        }
}

public Action Command_Cheer(int client, int args)
{
    if(!IsValidClient(client))
        return Plugin_Handled;
    
    if(g_iSoundSpam[client] > GetTime())
    {
        tPrintToChat(client, "%T", "sound cooldown", client);
        return Plugin_Handled;
    }

    if(g_iSoundClient[client] < 0)
    {
        tPrintToChat(client, "%T", "sound no equip", client);
        return Plugin_Handled;
    }

    g_iSoundSpam[client] = GetTime() + g_eSounds[g_iSoundClient[client]].iCooldown;

    StartSoundToAll(client);

    return Plugin_Handled;
}

void StartSoundToAll(int client)
{
    char sound[256], name[64];
    strcopy(sound, 256, g_eSounds[g_iSoundClient[client]].szSound);
    strcopy(name,   64, g_eSounds[g_iSoundClient[client]].szName);

    Action res = Plugin_Continue;
    Call_StartForward(g_hOnCheerSound);
    Call_PushCell(client);
    Call_PushStringEx(sound, 256, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_PushStringEx(name, 64, SM_PARAM_STRING_UTF8|SM_PARAM_STRING_COPY, SM_PARAM_COPYBACK);
    Call_Finish(res);

    if (res >= Plugin_Handled)
        return;

    if (res == Plugin_Continue)
    {
        // copy again
        strcopy(sound, 256, g_eSounds[g_iSoundClient[client]].szSound);
        strcopy(name,   64, g_eSounds[g_iSoundClient[client]].szName);
    }

    int[] targets = new int[MaxClients];
    int total = 0;
    
    for(int i=1; i <= MaxClients; i++)
        if(IsClientInGame(i))
            if(!g_bClientDisable[i] || i == client)
                targets[total++] = i;
            
    float fPos[3];
    GetClientEyePosition(client, fPos);
    
    float fAgl[3];
    GetClientEyeAngles(client, fAgl);

    fPos[2] -= 3.0;

    char szPath[128];
    Format(szPath, 128, "*%s", sound);
    EmitSound(targets, total, szPath, client, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, g_eSounds[g_iSoundClient[client]].fVolume, SNDPITCH_NORMAL, client, fPos, fAgl, true);

    tPrintToChatAll("%t", "sound to all", client, name);
}

public void Sounds_OnLoadOptions(int client)
{
    if(g_pfysOptions)
    {
        g_bClientDisable[client] = Opts_GetOptBool(client, SOUND_COOKIE_NAME, false);
        return;
    }

    if(g_pClientprefs)
    {
        char buff[4];
        GetClientCookie(client, g_hCookieSounds, buff, 4);
        
        if(buff[0] != 0)
            g_bClientDisable[client] = (StringToInt(buff) == 1 ? true : false);
    }
}

public Action Command_Silence(int client, int args)
{
    if (!client)
        return Plugin_Handled;

    g_bClientDisable[client] = !g_bClientDisable[client];
    SetSoundState(client, g_bClientDisable[client]);
    tPrintToChat(client, "%T", "sound setting", client, g_bClientDisable[client] ? "on" : "off");

    return Plugin_Handled;
}

static void SetSoundState(int client, bool state)
{
    if(g_pfysOptions)
    {
        Opts_SetOptBool(client, SOUND_COOKIE_NAME, state);
    }
    else if(g_pClientprefs)
    {
        SetClientCookie(client, g_hCookieSounds, state ? "1" : "0");
    }
}
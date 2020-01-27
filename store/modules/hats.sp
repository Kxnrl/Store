#define Module_Hats

enum Hat
{
    String:szModel[PLATFORM_MAX_PATH],
    String:szAttachment[64],
    Float:fPosition[3],
    Float:fAngles[3],
    bool:bBonemerge,
    iSlot
}

static any g_eHats[STORE_MAX_ITEMS][Hat];
static int g_iClientHats[MAXPLAYERS+1][STORE_MAX_SLOTS];
static int g_iHats = 0;
static int g_iSpecTarget[MAXPLAYERS+1];
static int g_iHatsOwners[2048];

public bool Hats_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iHats);
    float m_fTemp[3];
    kv.GetString("model", g_eHats[g_iHats][szModel], PLATFORM_MAX_PATH);
    KvGetVector(kv, "position", m_fTemp);
    g_eHats[g_iHats][fPosition] = m_fTemp;
    KvGetVector(kv, "angles", m_fTemp);
    g_eHats[g_iHats][fAngles] = m_fTemp;
    g_eHats[g_iHats][bBonemerge] = (kv.GetNum("bonemerge", 0)?true:false);
    g_eHats[g_iHats][iSlot] = kv.GetNum("slot");
    kv.GetString("attachment", g_eHats[g_iHats][szAttachment], 64, "facemask");
    
    if(!(FileExists(g_eHats[g_iHats][szModel], true)))
        return false;

    ++g_iHats;
    return true;
}

public void Hats_OnMapStart()
{
    for(int a = 1; a <= MaxClients; ++a)
        for(int b = 0; b < STORE_MAX_SLOTS; ++b)
            g_iClientHats[a][b] = INVALID_ENT_REFERENCE;

    for(int i = 0; i < g_iHats; ++i)
    {
        PrecacheModel(g_eHats[i][szModel], true);
        Downloader_AddFileToDownloadsTable(g_eHats[i][szModel]);
    }

    CreateTimer(0.1, Timer_Hats_Adjust, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Hats_Adjust(Handle timer)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && !IsFakeClient(client))
        {
            if(IsClientObserver(client))
                g_iSpecTarget[client] = (GetEntProp(client, Prop_Send, "m_iObserverMode") == 4) ? GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") : -1;
            else
                g_iSpecTarget[client] = client;
        }

    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if(entity > 2048 || entity < MaxClients)
        return;

    g_iHatsOwners[entity] = -1;
}

public void Hats_Reset()
{
    g_iHats = 0;
}

public int Hats_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    if(IsPlayerAlive(client))
    {
        Store_RemoveClientHats(client, g_eHats[m_iData][iSlot]);
        CreateHat(client, id);
    }
    return g_eHats[m_iData][iSlot];
}

public int Hats_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    Store_RemoveClientHats(client, g_eHats[m_iData][iSlot]);
    return g_eHats[m_iData][iSlot];
}

void Store_SetClientHat(int client)
{
    for(int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        Store_RemoveClientHats(client, i);
        CreateHat(client, -1, i);
    }
}

static void CreateHat(int client, int itemid = -1, int slot = 0)
{
    int m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "hat", slot) : itemid);
    
    if(m_iEquipped >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquipped);
        
#if defined GM_ZE
        if(g_iClientTeam[client] == 2)
            return;
#endif

        float m_fHatOrigin[3];
        float m_fHatAngles[3];
        float m_fForward[3];
        float m_fRight[3];
        float m_fUp[3];
        GetClientAbsOrigin(client,m_fHatOrigin);
        GetClientAbsAngles(client,m_fHatAngles);
        
        m_fHatAngles[0] += g_eHats[m_iData][fAngles][0];
        m_fHatAngles[1] += g_eHats[m_iData][fAngles][1];
        m_fHatAngles[2] += g_eHats[m_iData][fAngles][2];

        float m_fOffset[3];
        m_fOffset[0] = g_eHats[m_iData][fPosition][0];
        m_fOffset[1] = g_eHats[m_iData][fPosition][1];
        m_fOffset[2] = g_eHats[m_iData][fPosition][2];

        GetAngleVectors(m_fHatAngles, m_fForward, m_fRight, m_fUp);

        m_fHatOrigin[0] += m_fRight[0]*m_fOffset[0]+m_fForward[0]*m_fOffset[1]+m_fUp[0]*m_fOffset[2];
        m_fHatOrigin[1] += m_fRight[1]*m_fOffset[0]+m_fForward[1]*m_fOffset[1]+m_fUp[1]*m_fOffset[2];
        m_fHatOrigin[2] += m_fRight[2]*m_fOffset[0]+m_fForward[2]*m_fOffset[1]+m_fUp[2]*m_fOffset[2];

        int m_iEnt = CreateEntityByName("prop_dynamic_override");
        DispatchKeyValue(m_iEnt, "model", g_eHats[m_iData][szModel]);
        DispatchKeyValue(m_iEnt, "spawnflags", "256");
        DispatchKeyValue(m_iEnt, "solid", "0");
        SetEntPropEnt(m_iEnt, Prop_Send, "m_hOwnerEntity", client);

        g_iHatsOwners[m_iEnt] = client;

        if(g_eHats[m_iData][bBonemerge])
            Bonemerge(m_iEnt);

        DispatchSpawn(m_iEnt);    
        AcceptEntityInput(m_iEnt, "TurnOn", m_iEnt, m_iEnt, 0);

        g_iClientHats[client][g_eHats[m_iData][iSlot]] = EntIndexToEntRef(m_iEnt);
        
        SDKHook(m_iEnt, SDKHook_SetTransmit, Hook_SetTransmit_Hat);
        Call_OnHatsCreated(client, m_iEnt);
        
        TeleportEntity(m_iEnt, m_fHatOrigin, m_fHatAngles, NULL_VECTOR); 
        
        SetVariantString("!activator");
        AcceptEntityInput(m_iEnt, "SetParent", client, m_iEnt, 0);

        SetVariantString(g_eHats[m_iData][szAttachment]);
        AcceptEntityInput(m_iEnt, "SetParentAttachmentMaintainOffset", m_iEnt, m_iEnt, 0);
    }
}

void Store_RemoveClientHats(int client, int slot)
{
    if(g_iClientHats[client][slot] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientHats[client][slot]);
        if(entity > 0 && IsValidEdict(entity))
        {
            SDKUnhook(entity, SDKHook_SetTransmit, Hook_SetTransmit_Hat);
            AcceptEntityInput(entity, "Kill");
        }
        g_iClientHats[client][slot] = INVALID_ENT_REFERENCE;
    }
}

public Action Hook_SetTransmit_Hat(int ent, int client)
{
    if(client == g_iHatsOwners[ent])
        return IsPlayerTP(client) ? Plugin_Continue : Plugin_Handled;

    if(g_iSpecTarget[client] == g_iHatsOwners[ent])
        return Plugin_Handled;

    return Plugin_Continue;
}

static void Bonemerge(int ent)
{
    int m_iEntEffects = GetEntProp(ent, Prop_Send, "m_fEffects"); 
    m_iEntEffects &= ~32;
    m_iEntEffects |= 1;
    m_iEntEffects |= 128;
    SetEntProp(ent, Prop_Send, "m_fEffects", m_iEntEffects); 
}

stock void Call_OnHatsCreated(int client, int entity)
{
    static Handle gf = null;
    if (gf == null)
    {
        // create
        gf = CreateGlobalForward("Store_OnHatsCreated", ET_Ignore, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_Finish();
}
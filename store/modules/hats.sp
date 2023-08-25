// MAIN_FILE ../../store.sp

#pragma semicolon 1
#pragma newdecls required

#define Module_Hats

abstract_struct Hat
{
    char  szModel[PLATFORM_MAX_PATH];
    char  szAttachment[64];
    float fPosition[3];
    float fAngles[3];
    bool  bBonemerge;
    bool  bHide;
    int   iSlot;
    int   iTeam;
}

static Hat g_eHats[STORE_MAX_ITEMS];
static int g_iClientHats[MAXPLAYERS + 1][STORE_MAX_SLOTS];
static int g_iHats = 0;
static int g_iSpecTarget[MAXPLAYERS + 1];
static int g_iHatsOwners[2048];

bool Hats_Config(KeyValues kv, int itemid)
{
    Store_SetDataIndex(itemid, g_iHats);
    float m_fTemp[3];
    kv.GetString("model", g_eHats[g_iHats].szModel, PLATFORM_MAX_PATH);
    kv.GetVector("position", m_fTemp);
    g_eHats[g_iHats].fPosition = m_fTemp;
    kv.GetVector("angles", m_fTemp);
    g_eHats[g_iHats].fAngles    = m_fTemp;
    g_eHats[g_iHats].bBonemerge = (kv.GetNum("bonemerge", 0) ? true : false);
    g_eHats[g_iHats].iSlot      = kv.GetNum("slot");
    g_eHats[g_iHats].bHide      = kv.GetNum("hide", 1) ? true : false; // hide by default
    g_eHats[g_iHats].iTeam      = kv.GetNum("team");
    kv.GetString("attachment", g_eHats[g_iHats].szAttachment, sizeof(Hat::szAttachment), "facemask");

    if (!(FileExists(g_eHats[g_iHats].szModel, true)))
    {
#if defined LOG_NOT_FOUND
        // missing model
        char auth[32], name[32];
        kv.GetString("auth", auth, 32);
        kv.GetString("name", name, 32);
        if (strcmp(auth, "STEAM_ID_INVALID") != 0)
        {
            LogError("Missing hat <%s> -> [%s]", name, g_eHats[g_iHats].szModel);
        }
        else
        {
            LogMessage("Skipped hat <%s> -> [%s]", name, g_eHats[g_iHats].szModel);
        }
#endif
        return false;
    }

    ++g_iHats;
    return true;
}

void Hats_OnMapStart()
{
    for (int a = 1; a <= MaxClients; ++a)
        for (int b = 0; b < STORE_MAX_SLOTS; ++b)
            g_iClientHats[a][b] = INVALID_ENT_REFERENCE;

    for (int i = 0; i < g_iHats; ++i)
    {
        PrecacheModel(g_eHats[i].szModel, false);
        AddFileToDownloadsTable(g_eHats[i].szModel);
    }

    if (g_iHats)
        CreateTimer(0.1, Timer_Hats_Adjust, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

static Action Timer_Hats_Adjust(Handle timer)
{
    for (int client = 1; client <= MaxClients; ++client)
        if (IsClientInGame(client) && !IsFakeClient(client))
        {
            if (IsClientObserver(client))
                g_iSpecTarget[client] = (GetEntProp(client, Prop_Send, "m_iObserverMode") == OBS_MODE_IN_EYE) ? GetEntPropEnt(client, Prop_Send, "m_hObserverTarget") : -1;
            else
                g_iSpecTarget[client] = client;
        }

    if (g_pTransmit)
    {
        ArrayList m_Entities = new ArrayList();

        for (int client = 1; client <= MaxClients; ++client)
        {
            for (int i = 0; i < STORE_MAX_SLOTS; ++i)
            {
                if (g_iClientHats[client][i] != INVALID_ENT_REFERENCE)
                {
                    int entity = EntRefToEntIndex(g_iClientHats[client][i]);
                    if (entity > MaxClients && TransmitManager_IsEntityHooked(entity))
                    {
                        m_Entities.Push(entity);
                    }
                }
            }
        }

        for (int i = 0; i < m_Entities.Length; i++)
        {
            int entity = m_Entities.Get(i);
            for (int client = 1; client <= MaxClients; ++client)
            {
                if (IsClientInGame(client))
                {
                    bool can = true;
                    if (client == g_iHatsOwners[entity])
                        can = IsPlayerTP(client);
                    else if (g_iSpecTarget[client] == g_iHatsOwners[entity])
                        can = false;

                    TransmitManager_SetEntityState(entity, client, can, STORE_TRANSMIT_CHANNEL);
                }
            }
        }

        delete m_Entities;
    }

    return Plugin_Continue;
}

public void OnEntityDestroyed(int entity)
{
    if (entity >= 2048 || entity < MaxClients)
        return;

    g_iHatsOwners[entity] = INVALID_ENT_REFERENCE;
}

void Hats_Reset()
{
    g_iHats = 0;
}

int Hats_Equip(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    if (IsPlayerAlive(client))
    {
        Hats_RemoveClientHats(client, g_eHats[m_iData].iSlot);
        CreateHat(client, id);
    }
    return g_eHats[m_iData].iSlot;
}

int Hats_Remove(int client, int id)
{
    int m_iData = Store_GetDataIndex(id);
    Hats_RemoveClientHats(client, g_eHats[m_iData].iSlot);
    return g_eHats[m_iData].iSlot;
}

void Hats_SetClientHat(int client)
{
    for (int i = 0; i < STORE_MAX_SLOTS; ++i)
    {
        Hats_RemoveClientHats(client, i);
        CreateHat(client, -1, i);
    }
}

static void CreateHat(int client, int itemid = -1, int slot = 0)
{
    int m_iEquipped = (itemid == -1 ? Store_GetEquippedItem(client, "hat", slot) : itemid);

    if (m_iEquipped >= 0)
    {
        int m_iData = Store_GetDataIndex(m_iEquipped);

#if defined GM_ZE
        if (GetClientTeam(client) == TEAM_ZM)
            return;
#endif

#if !defined Global_Skin
        // if not in global team mode, we chose team
        if (g_eHats[m_iData].iTeam > TEAM_US && GetClientTeam(client) != g_eHats[m_iData].iTeam)
            return;
#endif

        float m_fHatOrigin[3];
        float m_fHatAngles[3];
        float m_fForward[3];
        float m_fRight[3];
        float m_fUp[3];
        GetClientAbsOrigin(client, m_fHatOrigin);
        GetClientAbsAngles(client, m_fHatAngles);

        m_fHatAngles[0] += g_eHats[m_iData].fAngles[0];
        m_fHatAngles[1] += g_eHats[m_iData].fAngles[1];
        m_fHatAngles[2] += g_eHats[m_iData].fAngles[2];

        float m_fOffset[3];
        m_fOffset[0] = g_eHats[m_iData].fPosition[0];
        m_fOffset[1] = g_eHats[m_iData].fPosition[1];
        m_fOffset[2] = g_eHats[m_iData].fPosition[2];

        GetAngleVectors(m_fHatAngles, m_fForward, m_fRight, m_fUp);

        m_fHatOrigin[0] += m_fRight[0] * m_fOffset[0] + m_fForward[0] * m_fOffset[1] + m_fUp[0] * m_fOffset[2];
        m_fHatOrigin[1] += m_fRight[1] * m_fOffset[0] + m_fForward[1] * m_fOffset[1] + m_fUp[1] * m_fOffset[2];
        m_fHatOrigin[2] += m_fRight[2] * m_fOffset[0] + m_fForward[2] * m_fOffset[1] + m_fUp[2] * m_fOffset[2];

        int m_iEnt = CreateEntityByName("prop_dynamic_override");
        DispatchKeyValue(m_iEnt, "targetname", "store_item_pet");
        DispatchKeyValue(m_iEnt, "model", g_eHats[m_iData].szModel);
        DispatchKeyValue(m_iEnt, "spawnflags", "256");
        DispatchKeyValue(m_iEnt, "solid", "0");
        SetEntPropEnt(m_iEnt, Prop_Send, "m_hOwnerEntity", client);

        g_iHatsOwners[m_iEnt] = client;

        if (g_eHats[m_iData].bBonemerge)
            Bonemerge(m_iEnt);

        DispatchSpawn(m_iEnt);
        AcceptEntityInput(m_iEnt, "TurnOn", m_iEnt, m_iEnt, 0);

        g_iClientHats[client][g_eHats[m_iData].iSlot] = EntIndexToEntRef(m_iEnt);

        if (g_eHats[m_iData].bHide)
        {
            // hook transmit
            if (g_pTransmit)
            {
                TransmitManager_AddEntityHooks(m_iEnt);
                TransmitManager_SetEntityOwner(m_iEnt, client);
                TransmitManager_SetEntityState(m_iEnt, client, false, STORE_TRANSMIT_CHANNEL);
            }
            else if (!IsParallelMode())
            {
                // SDKHooks crashes in parallel mode
                SDKHook(m_iEnt, SDKHook_SetTransmit, Hook_SetTransmit_Hat);
            }
        }

        TeleportEntity(m_iEnt, m_fHatOrigin, m_fHatAngles, NULL_VECTOR);

        SetVariantString("!activator");
        AcceptEntityInput(m_iEnt, "SetParent", client, m_iEnt, 0);

        SetVariantString(g_eHats[m_iData].szAttachment);
        AcceptEntityInput(m_iEnt, "SetParentAttachmentMaintainOffset", m_iEnt, m_iEnt, 0);

        Call_OnHatsCreated(client, m_iEnt, slot);
    }
}

void Hats_RemoveClientHats(int client, int slot)
{
    if (g_iClientHats[client][slot] != INVALID_ENT_REFERENCE)
    {
        int entity = EntRefToEntIndex(g_iClientHats[client][slot]);
        if (entity > MaxClients)
        {
            RemoveEntity(entity);
        }
        g_iClientHats[client][slot] = INVALID_ENT_REFERENCE;
    }
}

static Action Hook_SetTransmit_Hat(int ent, int client)
{
    if (client == g_iHatsOwners[ent])
        return IsPlayerTP(client) ? Plugin_Continue : Plugin_Handled;

    if (g_iSpecTarget[client] == g_iHatsOwners[ent])
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

stock void Call_OnHatsCreated(int client, int entity, int slot)
{
    static GlobalForward gf = null;
    if (gf == null)
    {
        // create
        gf = new GlobalForward("Store_OnHatsCreated", ET_Ignore, Param_Cell, Param_Cell, Param_Cell);
    }

    Call_StartForward(gf);
    Call_PushCell(client);
    Call_PushCell(entity);
    Call_PushCell(slot);
    Call_Finish();
}
#define Module_VIP

public void VIP_OnPluginStart()
{
    Store_RegisterHandler("buyvip", VIP_OnMapStart, VIP_Reset, VIP_Config, VIP_Equip, VIP_Remove, false);
}

public void VIP_OnMapStart()
{
    
}

public void VIP_Reset()
{
    
}

public bool VIP_Config(Handle &kv, int itemid)
{
    return true;
}

public int VIP_Equip(int client, int id)
{
#if defined _CG_CORE_INCLUDED
    if(CG_ClientIsVIP(client))
    {
        tPrintToChat(client, "\x04%t", "you are already vip");
        return -1;
    }
#endif

    tPrintToChat(client, "%t", "go to forum to buy vip chat");

    return 0;
}

public int VIP_Remove(int client)
{
    return 0;
}
#include <sourcemod>
#include <cstrike>

public OnPluginStart()
{
	RegConsoleCmd("ctest", cmd_test);
	RegConsoleCmd("ctest2", Cmd_test2);
	
	char m_szFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, m_szFile, 128, "configs/store/items.txt");
	Handle m_hKV = CreateKeyValues("Store");
	FileToKeyValues(m_hKV, m_szFile);
	KeyValuesToFile(m_hKV, m_szFile);
}

public Action cmd_test(client, args)
{
	if(GetClientTeam(client) == 2)
		CS_SwitchTeam(client, 3);
	else if(GetClientTeam(client) == 3)
		CS_SwitchTeam(client, 2);
}

public Action Cmd_test2(client, args)
{
	CS_TerminateRound(5.0, CSRoundEnd_Draw);
}
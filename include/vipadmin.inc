native bool:VIP_IsClientVIP(client);
native VIP_SetClientVIP(client);
functag OnClientVIPCheckFunc public(client);
native HookClientVIPChecked(OnClientVIPCheckFunc:func);
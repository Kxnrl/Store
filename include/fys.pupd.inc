#if defined _fys_Updater_Include_
    #endinput
#endif

#define _fys_Updater_Include_

// 强制触发检查
native bool Pupd_CheckPlugin(bool reload, const char[] url, const char[] auth = NULL_STRING);
native bool Pupd_CheckGamedata(const char[] file, const char[] url, const char[] auth = NULL_STRING);
native bool Pupd_CheckTranslation(const char[] file, const char[] url, const char[] auth = NULL_STRING);

forward void Pupd_OnCheckAllPlugins(bool auto);
forward void Pupd_OnPluginUpdated(const char[] file, bool reload);

public SharedPlugin __pl_fys_Updater =
{
    name = "fys-Updater",
    file = "fys.pupd.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_fys_Updater_SetNTVOptional()
{
    MarkNativeAsOptional("Pupd_CheckPlugin");
    MarkNativeAsOptional("Pupd_CheckGamedata");
    MarkNativeAsOptional("Pupd_CheckTranslation");
}
#endif
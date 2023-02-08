#if defined _fys_Opts_Include_
    #endinput
#endif

#define _fys_Opts_Include_

#define OPTS_TIMESTAMP_KEY "Global.Timestamp"
#define OPTS_CREATIONS_KEY "Global.Created.Time"
#define OPTS_STREAMERS_KEY "Global.Streamer.Enabled"

enum /* streamer_t */
{
    Streamer_Mode_Off,
    Streamer_Mode_Low,
    Streamer_Mode_High
}

forward void Opts_OnClientLoad(int client);
forward void Opts_OnClientXSet(int client, const char[] key);

// 是否已读取
native bool  Opts_IsClientLoaded(int client);

// 读取4种类型的设置
native void  Opts_GetOptString(int client, const char[] key, char[] val, int maxLen, const char[] defVal = "null");
native int   Opts_GetOptInteger(int client, const char[] key, const int defVal = 0);
native bool  Opts_GetOptBool(int client, const char[] key, const bool defVal = false);
native float Opts_GetOptFloat(int client, const char[] key, const float defVal = 0.0);

// 设置4种类型的设置
native void Opts_SetOptString(int client, const char[] key, const char[] val);
native void Opts_SetOptInteger(int client, const char[] key, const int val);
native void Opts_SetOptBool(int client, const char[] key, const bool val);
native void Opts_SetOptFloat(int client, const char[] key, const float val);

public SharedPlugin __pl_fys_Opts =
{
    name = "fys-Opts",
    file = "fys.opts.smx",
#if defined REQUIRE_PLUGIN
    required = 1
#else
    required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_fys_Opts_SetNTVOptional()
{
    MarkNativeAsOptional("Opts_IsClientLoaded");

    MarkNativeAsOptional("Opts_GetOptString");
    MarkNativeAsOptional("Opts_GetOptInteger");
    MarkNativeAsOptional("Opts_GetOptBool");
    MarkNativeAsOptional("Opts_GetOptFloat");

    MarkNativeAsOptional("Opts_SetOptString");
    MarkNativeAsOptional("Opts_SetOptInteger");
    MarkNativeAsOptional("Opts_SetOptBool");
    MarkNativeAsOptional("Opts_SetOptFloat");
}
#endif
#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "1.0"

new g_mapTimeLeft = -1;

public Plugin:myinfo = 
{
	name = "Reload Map",
	author = "Ambit",
	description = "Provides a command to reload the current map without changing remaning map time.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CreateConVar("reloadmap_version", PLUGIN_VERSION, "Reload Map version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
	RegAdminCmd("sm_reload_map", ReloadMapCommand, ADMFLAG_GENERIC);
}

public TF2_OnWaitingForPlayersEnd()
{
	new timeLeft;
    
	if (g_mapTimeLeft >= 0)
	{
		GetMapTimeLeft(timeLeft);
		ExtendMapTimeLimit(g_mapTimeLeft - timeLeft);
		g_mapTimeLeft = -1;
	}
}

public Action:ReloadMapCommand(client, args)
{
	decl String:map[PLATFORM_MAX_PATH];
	
	GetMapTimeLeft(g_mapTimeLeft);
	GetCurrentMap(map, sizeof(map));
	ServerCommand("sm_map %s", map);
}
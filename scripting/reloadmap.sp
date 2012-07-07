#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <tf2>
#include <sdktools>
#include <builtinvotes>

#define PLUGIN_VERSION "2.0"

#define RESP_LENGTH 2
#define RESP_RELOAD "y"
#define RESP_NO_ACTION "n"

new g_mapTimeLeft = -1;
new g_cartId = -1;
new g_cartTrackerId = -1;
new Handle:g_moveCheckTimer = INVALID_HANDLE;
new Float:g_lastPosition[3];

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
	RegAdminCmd("sm_reload_map_vote", ReloadMapVoteCommand, ADMFLAG_GENERIC);
}

public TF2_OnWaitingForPlayersEnd()
{
	new timeLeft;
    
	if (g_mapTimeLeft >= 0)
	{
		new mins = RoundToCeil(float(g_mapTimeLeft) / 60.0);
		
		GetMapTimeLeft(timeLeft);
		ExtendMapTimeLimit((mins * 60) - timeLeft);
		g_mapTimeLeft = -1;
		PrintToChatAll( "[SM] Map time restored to %d:00.", mins);
	}
}

public OnClientPutInServer(client)
{
	if (g_mapTimeLeft >= 0)
		CreateTimer(10.0, SendMessage, client);
}

public Action:ReloadMapCommand(client, args)
{
	ReloadMap();
	return Plugin_Handled;
}

public Action:ReloadMapVoteCommand(client, args)
{
	VoteReload(true);
	return Plugin_Handled;
}

ReloadMap()
{
	decl String:map[PLATFORM_MAX_PATH];
	
	PrintToChatAll("[SM] Reloading map...");
	GetMapTimeLeft(g_mapTimeLeft);
	GetCurrentMap(map, sizeof(map));
	ServerCommand("sm_map %s", map);
}

public OnMapStart()
{
	if (IsPayload())
	{
		g_cartId = FindEntityByClassname(-1, "trigger_capture_area");
		g_cartTrackerId = FindEntityByClassname(-1, "team_train_watcher");
		HookSingleEntityOutput(g_cartId, "OnNumCappersChanged", OnNumCappersChanged);
	}
}

public OnNumCappersChanged(const String:output[], caller, activator, Float:delay)
{
	CreateTimer(0.1, NextFrame);
}

public Action:SendMessage(Handle:timer, any:client)
{
	if (g_mapTimeLeft >= 0 && IsClientInGame(client) && !IsFakeClient(client))
	{
		new mins = RoundToCeil(float(g_mapTimeLeft) / 60.0);
		
		PrintToChat(client, 
					"[SM] Map time will be restored to %d:00 after waiting for players round finishes.", 
					mins);
	}
}

public Action:NextFrame(Handle:timer)
{
	decl Float:cartPosition[3];
	new numCappers = GetEntProp(g_cartTrackerId, Prop_Send, "m_nNumCappers");
	
	if (numCappers <= 0 && g_moveCheckTimer != INVALID_HANDLE)
	{
		KillTimer(g_moveCheckTimer);
		g_moveCheckTimer = INVALID_HANDLE;
	}
	else if (numCappers > 0)
	{
		g_moveCheckTimer = CreateTimer(0.1, OnTick);
		GetEntPropVector(g_cartId, Prop_Send, "m_vecOrigin", cartPosition);
		g_lastPosition[0] = cartPosition[0];
		g_lastPosition[1] = cartPosition[1];
		g_lastPosition[2] = cartPosition[2];
	}
}

public Action:OnTick(Handle:timer)
{
	decl Float:cartPosition[3];
	
	if (GetEntProp(g_cartTrackerId, Prop_Send, "m_nNumCappers") > 0)
	{
		GetEntPropVector(g_cartId, Prop_Send, "m_vecOrigin", cartPosition);
		if (g_lastPosition[0] == cartPosition[0] && g_lastPosition[1] == cartPosition[1] && g_lastPosition[2] == cartPosition[2])
		{
			VoteReload();
		}
	}
	g_moveCheckTimer = INVALID_HANDLE;
}

VoteReload(bool:manual = false)
{
	new Handle:vote = CreateBuiltinVote(OnVoteAction, BuiltinVoteType_Custom_Mult);
	SetBuiltinVoteArgument(vote, manual ? "Reload map?" : "Detected stuck cart. Reload map?");
	AddBuiltinVoteItem(vote, RESP_RELOAD, "Reload");
	AddBuiltinVoteItem(vote, RESP_NO_ACTION, "Don't Reload.");
	SetBuiltinVoteResultCallback(vote, OnVoteFinished);
	DisplayBuiltinVoteToAll(vote, 10);
}

public OnVoteFinished(Handle:vote, num_votes, num_clients, 
								const client_info[][2], num_items, const item_info[][2])
{
	decl String:result[RESP_LENGTH];
	GetBuiltinVoteItem(vote, item_info[0][BUILTINVOTEINFO_ITEM_INDEX], result, sizeof(result));
	
	
	if (StrEqual(result, RESP_RELOAD))
	{
		DisplayBuiltinVotePass(vote, "Map will be reloaded.");
		CreateTimer(2.0, DelayReload);
	}
	else
	{
		DisplayBuiltinVotePass(vote, "Map will not be reloaded.");
		PrintToChatAll("[SM] Map will not be reloaded.");
	}
	
}

public Action:DelayReload(Handle:timer)
{
	ReloadMap();
}

public OnVoteAction(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
	if (action == BuiltinVoteAction_End)
		CloseHandle(vote);
}

bool:IsPayload()
{
	decl String:map[PLATFORM_MAX_PATH];
	GetCurrentMap(map, sizeof(map));
	map[3] = '\0';
	
	return StrEqual(map, "pl_", false);
}
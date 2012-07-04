#pragma semicolon 1
#pragma tabsize 0
#include <tf2>
#include <tf2_stocks>
#include <sourcemod>
#include <donator>

#define PLUGIN_VERSION "1.1.4"

new bool:IsPlayerAwesome[MAXPLAYERS + 1];
new bool:IsPlayerImmune[MAXPLAYERS + 1];
new bool:RoundEnd = false;

public Plugin:myinfo =
{
	name = "Bonus Round Immunity",
	author = "Antithasys, edited by ovenmittbandit",
	description = "Gives admins and donators immunity during bonus round",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	CreateConVar("brimmunity_version", PLUGIN_VERSION, "Bonus Round Immunity", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	HookEvent("player_spawn", HookPlayerSpawn, EventHookMode_Post);
	HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_Post);
	HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
  RoundEnd = false;
}

public OnClientPostAdminCheck(client)
{
	if (IsAwesomeUser(client))
		IsPlayerAwesome[client] = true;
	else
		IsPlayerAwesome[client] = false;
}

public OnClientDisconnect(client)
{
	CleanUp(client);
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = false;
  for (new i = 1; i <= MaxClients; i++) {
    if (IsPlayerAwesome[i] && IsPlayerImmune[i]) {
      SetEntProp(i, Prop_Data, "m_takedamage", 2, 1);
      IsPlayerImmune[i] = false;
    }
  }
}

public HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
  for (new i = 1; i <= MaxClients; i++) {
    if (IsPlayerAwesome[i]) {
      SetEntProp(i, Prop_Data, "m_takedamage", 1, 1);
      IsPlayerImmune[i] = true;
    }
  }
}

public HookPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsPlayerAwesome[client] && RoundEnd) {
		SetEntProp(client, Prop_Data, "m_takedamage", 1, 1);
		IsPlayerImmune[client] = true;
	}
}

stock CleanUp(client)
{
	IsPlayerAwesome[client] = false;
	if (IsPlayerImmune[client]) {
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);	
		IsPlayerImmune[client] = false;
	}
}

stock bool:IsAwesomeUser(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client))
		return false;
	if (IsPlayerDonator(client) && GetDonatorLevel(client) >= 1)
		return true;
	return false;
}

#include <sourcemod>
#include <basecomm>
#include <colors>

#define OMNISCIENCE_VERSION "1.0"

public Plugin:myinfo = {
    name = "Omniscience",
    author = "Ambit",
    description = "Allows admins to see chat from all players.",
    version = OMNISCIENCE_VERSION,
    url = ""
};


public OnPluginStart()
{
	CreateConVar("sm_omniscience_version", OMNISCIENCE_VERSION, "Omniscience Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	AddCommandListener(sayListenerTeam, "say_team");
}

public Action:sayListenerTeam(client, const String:command[], args)
{
	if(client > 0 && IsClientConnected(client) && !BaseComm_IsClientGagged(client))
	{
		decl String:text[256];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		relayToAdmins(client, text);
	}
	
	return Plugin_Continue;
}

public relayToAdmins(client, const String:text[])
{
	new bool:alive = IsPlayerAlive(client);
	new team = GetClientTeam(client);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetUserAdmin(i) != INVALID_ADMIN_ID && GetClientTeam(i) != team)
		{
			if (alive)
				CPrintToChatEx(i, client, "(OTHER TEAM) {teamcolor}%N{default} :  %s", client, text);
			else
				CPrintToChatEx(i, client, "*DEAD*(OTHER TEAM) {teamcolor}%N{default} :  %s", client, text);
		}
	}
	
}
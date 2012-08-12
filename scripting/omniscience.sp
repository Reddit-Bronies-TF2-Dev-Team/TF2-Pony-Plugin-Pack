#include <sourcemod>
#include <basecomm>
#include <colors>
#include <clientprefs>

#define OMNISCIENCE_VERSION "1.0"

new Handle:enabledCookie;

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
	RegAdminCmd("sm_omniscience", Command_Enable, ADMFLAG_GENERIC, "omniscience <0|1> - Enables or disables enemy team chat.");
	AddCommandListener(SayListenerTeam, "say_team");
	enabledCookie = RegClientCookie("omniscience_enabled", "Enables viewing of enemy team chat.", CookieAccess_Public);
}

public Action:SayListenerTeam(client, const String:command[], args)
{
	if(client > 0 && IsClientConnected(client) && !BaseComm_IsClientGagged(client))
	{
		decl String:text[256];
		GetCmdArgString(text, sizeof(text));
		StripQuotes(text);
		RelayToAdmins(client, text);
	}
	
	return Plugin_Continue;
}

public RelayToAdmins(client, const String:text[])
{
	new bool:alive = IsPlayerAlive(client);
	new team = GetClientTeam(client);
	decl String:cookie[2];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && GetUserAdmin(i) != INVALID_ADMIN_ID && GetClientTeam(i) != team)
		{
			GetClientCookie(client, enabledCookie, cookie, sizeof(cookie));
			if (StrEqual("1", cookie))
			{
				if (alive)
					CPrintToChatEx(i, client, "(OTHER TEAM) {teamcolor}%N{default} :  %s", client, text);
				else
					CPrintToChatEx(i, client, "*DEAD*(OTHER TEAM) {teamcolor}%N{default} :  %s", client, text);
			}
		}
	}
	
}

public OnClientPostAdminCheck(client)
{
	decl String:cookie[2];
	
	if (GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		GetClientCookie(client, enabledCookie, cookie, sizeof(cookie));
		if (StrEqual("", cookie))
		{
			SetClientCookie(client, enabledCookie, "1");
		}
	}
}

public Action:Command_Enable(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: omniscience <0|1>");
		return Plugin_Handled;
	}
	
	decl String:arg[2];
	GetCmdArg(1, arg, sizeof(arg));
	
	if (StrEqual(arg, "0"))
	{
		SetClientCookie(client, enabledCookie, "0");
		ReplyToCommand(client, "[SM] Omniscience disabled.");
	}
	else
	{
		SetClientCookie(client, enabledCookie, "1");
		ReplyToCommand(client, "[SM] Omniscience enabled.");
	}
	
	return Plugin_Handled;
}
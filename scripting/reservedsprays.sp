/* reservedsprays.sp
 * ============================================================================
 *  Reserved Sprays Change Log
 * ============================================================================
 *  1.0.0
 *  - Initial release.
 * ============================================================================
 */
#pragma tabsize 0
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <donator>

#define VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Reserved Sprays",
	author = "ShadowMoses, edited by ovenmittbandit",
	description = "Removes player spray unless they have spray permissions.",
	version = VERSION,
	url = "http://www.thinking-man.com/"
};

public OnPluginStart()
{
	CreateConVar("sm_reservedsprays_version", VERSION, "Reserved sprays version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	AddTempEntHook("Player Decal",PlayerSpray);
}

public Action:PlayerSpray(const String:te_name[],const clients[],client_count,Float:delay)
{
	new client = TE_ReadNum("m_nPlayer");
	if(client && IsClientInGame(client))
	{		
		if(IsPlayerDonator(client))
			return Plugin_Continue;
		else
		{
			PrintToChat(client, "\x04[Reserved Sprays]\x03Sorry, sprays can only be used by members of the Reddit Bronies group.");
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}
#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS 

public Plugin:myinfo =
{
	name = "Force Uncloak",
	author = "Ambit",
	description = "Removes cloak and disguise from spys at end of round.",
	version = PLUGIN_VERSION,
	url = ""
};


/**
 * The starting point of the plugin. Called when the plugin is first loaded.
 */
public OnPluginStart()
{    
    CreateConVar("force_uncloak_version", PLUGIN_VERSION, "Force Uncloak version", FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_REPLICATED | FCVAR_DONTRECORD);
    HookEvent("teamplay_round_win", RoundEnd);
    HookEvent("teamplay_round_stalemate", RoundEnd);
}


/**
 * Event handler for when the round timer expires.
 * 
 * @param event An handle to the event that triggered this callback.
 * @param name The name of the event that triggered this callback.
 * @param dontBroadcast True if the event broadcasts to clients, otherwise false.
 */
public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsClientObserver(i))
        {
            TF2_RemovePlayerDisguise(i);
            TF2_RemoveCondition(i, TFCond_Cloaked);
        }
    }
}
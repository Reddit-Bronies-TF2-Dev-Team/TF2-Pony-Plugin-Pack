#pragma semicolon 1

#include <sourcemod>
#include <clientprefs>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <tf2items_giveweapon>
#include <sourceirc>

#define PLUGIN_VERSION "1.0"
#define MAX_CLIENT_IDS MAXPLAYERS + 1

#define TEAM_SPEC 1
#define TEAM_RED 2
#define TEAM_BLU 3

#define SLOT_PRIMARY 0
#define SLOT_SECONDARY 1
#define SLOT_MELEE 2

#define SCOUT 0
#define DEMOMAN 3
#define PYRO 6
#define SNIPER 9
#define SPY 12
#define HEAVY 15
#define SOLDIER 18
#define ENGINEER 21
#define MEDIC 24

public Plugin:myinfo =
{
	name = "Restrict Weapons",
	author = "Ambit",
	description = "Forces a player to use vanilla weapons.",
	version = PLUGIN_VERSION,
	url = ""
};

new default_weapon_ids[27] = 
{
	13, 23, 0,
	19, 20, 1,
	21, 12, 2,
	14, 16, 3,
	24, -1, 4,
	15, 11, 5,
	18, 10, 6,
	9, 22, 7,
	17, 29, 8
};

new Handle:g_cookie;
new g_restricted[MAX_CLIENT_IDS];

public OnPluginStart() 
{
	decl String:cookie[32];
	
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");

	CreateConVar("sm_restrictweapons_version", PLUGIN_VERSION, "Restrict Weapons Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_cookie = RegClientCookie("weapons_restricted", "Weapon Restriction", CookieAccess_Protected);
	
	RegAdminCmd("sm_restrictweap", RestrictCommand, ADMFLAG_KICK, "sm_restrictweap <#userid|name> - Forces a player to use stock weapons.");
	RegAdminCmd("sm_unrestrictweap", UnrestrictCommand, ADMFLAG_KICK, "sm_unrestrictweap <#userid|name> - Allows a player to use all weapons.");
	
	HookEvent("post_inventory_application", PostInventoryApplication);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (AreClientCookiesCached(i))
		{
			GetClientCookie(i, g_cookie, cookie, sizeof(cookie));
			if (StrEqual(cookie, "1"))
			{
				RestrictWeapons(i);
				continue;
			}
		}
		g_restricted[i] = false;
	}
}

public OnAllPluginsLoaded() 
{
	if (LibraryExists("sourceirc"))
		IRC_Loaded();
}

public OnLibraryAdded(const String:name[]) 
{
	if (StrEqual(name, "sourceirc"))
		IRC_Loaded();
}

IRC_Loaded() 
{
	IRC_CleanUp(); // Call IRC_CleanUp as this function can be called more than once.
	IRC_RegAdminCmd("restrictweap", RestrictCommandIRC, ADMFLAG_KICK, "restrictweap <#userid|name> - Forces a player to use stock weapons.");
	IRC_RegAdminCmd("unrestrictweap", UnrestrictCommandIRC, ADMFLAG_KICK, "unrestrictweap <#userid|name> - Allows a player to use all weapons.");
}

public OnPluginEnd() 
{
	IRC_CleanUp();
}

public OnClientPutInServer(client)
{
	g_restricted[client] = false;
}

public OnClientCookiesCached(client)
{
	decl String:cookie[32];
	
	GetClientCookie(client, g_cookie, cookie, sizeof(cookie));
	
	if (StrEqual(cookie, "1"))
	{
		RestrictWeapons(client);
		return;
	}
	
	g_restricted[client] = false;
}

public Action:RestrictCommand(client, args) 
{
	decl String:arg[MAX_NAME_LENGTH];
	decl String:name[MAX_NAME_LENGTH];
	decl targets[MAX_CLIENT_IDS];
	new bool:tn_is_ml;
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_restrictweap <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	new num_targets = ProcessTargetString(arg, client, targets, sizeof(targets), 0, name, sizeof(name), tn_is_ml);
	
	if (num_targets <= 0)
	{
		ReplyToTargetError(client, num_targets);
	}
	else
	{
		for (new i = 0; i < num_targets; i++)
		{
			RestrictWeapons(targets[i]);
			ReplyToCommand(client, "%N restricted to stock weapons.", targets[i]);
		}
	}

	return Plugin_Handled;
}

public Action:UnrestrictCommand(client, args) 
{
	decl String:arg[MAX_NAME_LENGTH];
	decl String:name[MAX_NAME_LENGTH];
	decl targets[MAX_CLIENT_IDS];
	new bool:tn_is_ml;
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_unrestrictweap <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	new num_targets = ProcessTargetString(arg, client, targets, sizeof(targets), 0, name, sizeof(name), tn_is_ml);
	
	if (num_targets <= 0)
	{
		ReplyToTargetError(client, num_targets);
	}
	else
	{
		for (new i = 0; i < num_targets; i++)
		{
			UnrestrictWeapons(targets[i]);
			ReplyToCommand(client, "%N allowed to use all weapons.", targets[i]);
		}
	}

	return Plugin_Handled;
}

public Action:RestrictCommandIRC(const String:nick[], args) 
{
	decl String:arg[MAX_NAME_LENGTH];
	decl String:name[MAX_NAME_LENGTH];
	decl targets[MAX_CLIENT_IDS];
	new bool:tn_is_ml;
	
	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: restrictweap <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	new num_targets = ProcessTargetString(arg, 0, targets, sizeof(targets), 0, name, sizeof(name), tn_is_ml);
	
	if (num_targets <= 0)
	{
		IRC_ReplyToTargetError(nick, num_targets);
	}
	else
	{
		for (new i = 0; i < num_targets; i++)
		{
			RestrictWeapons(targets[i]);
			IRC_ReplyToCommand(nick, "%N restricted to stock weapons.", targets[i]);
		}
	}

	return Plugin_Handled;
}

public Action:UnrestrictCommandIRC(const String:nick[], args) 
{
	decl String:arg[MAX_NAME_LENGTH];
	decl String:name[MAX_NAME_LENGTH];
	decl targets[MAX_CLIENT_IDS];
	new bool:tn_is_ml;
	
	if (args < 1)
	{
		IRC_ReplyToCommand(nick, "Usage: unrestrictweap <#userid|name>");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, arg, sizeof(arg));
	new num_targets = ProcessTargetString(arg, 0, targets, sizeof(targets), 0, name, sizeof(name), tn_is_ml);
	
	if (num_targets <= 0)
	{
		IRC_ReplyToTargetError(nick, num_targets);
	}
	else
	{
		for (new i = 0; i < num_targets; i++)
		{
			UnrestrictWeapons(targets[i]);
			IRC_ReplyToCommand(nick, "%N allowed to use all weapons.", targets[i]);
		}
	}

	return Plugin_Handled;
}

RestrictWeapons(client)
{
	if (!g_restricted[client])
	{
		g_restricted[client] = true;
		SetClientCookie(client, g_cookie, "1");
		SetCustomWeapons(client);
		PrintToChat(client, "[SM] You are now restricted to stock weapons.");
	}
}

UnrestrictWeapons(client)
{
	if (g_restricted[client])
	{
		g_restricted[client] = false;
		SetClientCookie(client, g_cookie, "0");
		PrintToChat(client, "[SM] Your weapon restrictions have been lifted.");
	}
}

/**
* Handler for when a player spawns.
*
* @param client Index of the client.
* @return Plugin_Handled, Plugin_Continue, or Plugin_Changed to indicate how the original event should be processed
*/
public Action:OnSpawn(client)
{
	if (GetClientTeam(client) == TEAM_SPEC)
		return Plugin_Continue;
	
	if (g_restricted[client])
		SetCustomWeapons(client);
	
	return Plugin_Continue;
}

/**
* Event handler for a player applying a new weapon set.
* 
* @param event An handle to the event that triggered this callback.
* @param name The name of the event that triggered this callback.
* @param dontBroadcast True if the event broadcasts to clients, otherwise false.
*/
public PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_restricted[client])
		SetCustomWeapons(client);
}

/**
* Gives a player a custom weapon loadout. Items are defined in the 
* TF2Items Give Weapon configuration.
* 
* @param The index of the client to give weapons.
*/
SetCustomWeapons(client)
{
	TF2_RemoveWeaponSlot(client, 0);
	if (TF2_GetPlayerClass(client) != TFClass_Spy)
		TF2_RemoveWeaponSlot(client, 1);
	TF2_RemoveWeaponSlot(client, 2);
	
	switch (TF2_GetPlayerClass(client))
	{
	case TFClass_Scout:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[SCOUT + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SCOUT + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SCOUT + SLOT_MELEE]);
		}
	case TFClass_DemoMan:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[DEMOMAN + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[DEMOMAN + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[DEMOMAN + SLOT_MELEE]);
		}
	case TFClass_Pyro:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[PYRO + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[PYRO + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[PYRO + SLOT_MELEE]);
		}
	case TFClass_Sniper:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[SNIPER + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SNIPER + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SNIPER + SLOT_MELEE]);
		}
	case TFClass_Spy:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[SPY + SLOT_PRIMARY]);
			//TF2Items_GiveWeapon(client, default_weapon_ids[SPY + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SPY + SLOT_MELEE]);
		}
	case TFClass_Heavy:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[HEAVY + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[HEAVY + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[HEAVY + SLOT_MELEE]);
		}
	case TFClass_Soldier:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[SOLDIER + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SOLDIER + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[SOLDIER + SLOT_MELEE]);
		}
	case TFClass_Engineer:
		{
			TF2Items_GiveWeapon(client, default_weapon_ids[ENGINEER + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[ENGINEER + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[ENGINEER + SLOT_MELEE]);
		}
	case TFClass_Medic:
		{	
			TF2Items_GiveWeapon(client, default_weapon_ids[MEDIC + SLOT_PRIMARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[MEDIC + SLOT_SECONDARY]);
			TF2Items_GiveWeapon(client, default_weapon_ids[MEDIC + SLOT_MELEE]);
		}
	}
}
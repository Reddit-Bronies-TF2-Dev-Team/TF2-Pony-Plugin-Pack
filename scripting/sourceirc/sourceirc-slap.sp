#include <sdktools>

#undef REQUIRE_PLUGIN
#include <sourceirc>

#pragma tabsize 0

public Plugin:myinfo = {
	name = "SourceIRC -> Slap",
	author = "DarthNinja & RogueDarkJedi",
	description = "Adds slap command to SourceIRC",
	version = IRC_VERSION,
	url = "www.sourcemod.net"
};

public OnPluginStart() {	
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
}

public OnAllPluginsLoaded() {
	if (LibraryExists("sourceirc"))
		IRC_Loaded();
}

public OnLibraryAdded(const String:name[]) {
	if (StrEqual(name, "sourceirc"))
		IRC_Loaded();
}

IRC_Loaded() {
	IRC_CleanUp(); // Call IRC_CleanUp as this function can be called more than once.
	IRC_RegAdminCmd("slap", Command_Slap, ADMFLAG_SLAY, "slap <#userid|name> [damage] - Slaps a player in the server");
}

public Action:Command_Slap(const String:nick[], args) {

	if (args == 0)
	{
		IRC_ReplyToCommand(nick, "Usage: slap <#userid|name> [Damage]");
		return Plugin_Handled;
	}
  
	decl String:arg[125];
  IRC_GetCmdArg(1, arg, sizeof(arg));
  
  new iDamage;
	if (args >= 2)
	{
		decl String:Damage[64];
		IRC_GetCmdArg(2, Damage, sizeof(Damage));
		iDamage = StringToInt(Damage);
	}
	else
		iDamage = 0; //sm_slap's default damage

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			0, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) > 0)
	{
		if (tn_is_ml)
    {
       IRC_ReplyToCommand(nick, "slapped %N.", target_list[0]);
    }
		else
    {
       IRC_ReplyToCommand(nick, "slapped %N.", target_list[0]);
		}
		for (new i = 0; i < target_count; i++)
      SlapPlayer(target_list[i], iDamage);
	}
	else
	{
		IRC_ReplyToTargetError(nick, target_count);
	}	
  return Plugin_Handled;
}

public OnPluginEnd() {
	IRC_CleanUp();
}			
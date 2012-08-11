/*
       This file is part of IRC Code De-Duplicator.

    IRC Code De-Duplicator is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    IRC Code De-Duplicator is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with IRC Code De-Duplicator.  If not, see <http://www.gnu.org/licenses/>.
*/

#if defined _icdd_included_
  #endinput
#endif
#define _icdd_included_

#pragma semicolon 1

#undef REQUIRE_PLUGIN
#include <sourceirc>

#define ICDD_VERSION "1.0.1"

static Handle:callbackTrie;

static bool:ircCommand;
static bool:isInit = false;
static Handle:loadedForward;

functag ICDDLoaded public();

/**
 * Initializes internal variables and registers a callback
 * that is executed when ICDD's dependencies have loaded.
 *
 * @param func The callback function for when ICDD is ready.
 * @noreturn
 */
stock ICDD_Init(ICDDLoaded:func)
{
	callbackTrie = CreateTrie();
	
	isInit = true;
	
	loadedForward = CreateForward(ET_Ignore);
	AddToForward(loadedForward, INVALID_HANDLE, Function:func);
}

stock ICDD_OnAllPluginsLoaded() {
	LogMessage("[ICDD] All Plugins Loaded");
	if (LibraryExists("sourceirc"))
		ICDDInternal_IRC_Loaded();
}

stock ICDD_OnLibraryAdded(const String:name[]) {
	LogMessage("[ICDD] Library Added: %s", name);
	if (StrEqual(name, "sourceirc"))
		ICDDInternal_IRC_Loaded();
}

stock ICDDInternal_IRC_Loaded()
{
	LogMessage("[ICDD] SourceIRC Loaded");
	Call_StartForward(loadedForward);
	Call_Finish();
}

/**
 * Called when a command is invoked.
 *
 * @param client		The id of the client who invoked the command or -1 if the command 
						came from IRC
 * @param nick			The nickname of the user who invoked hte command
 * @param args			Number of arguments that were in the argument string.
 * @return				An Action value.  Not handling the command
 *						means that SourceIRC will report it as "Unknown Command."
 */
functag ICDDCmd Action:public(client, const String:nick[], args);

/**
 * Creates a command and IRC command as an administrative command.
 * When this command is invoked, the access rights of the user are 
 * automatically checked before allowing it to continue.
 *
 * @param cmd			String containing command to register.
 * @param callback		A function to use as a callback for when the command is invoked.
 * @param adminflags	Administrative flags (bitstring) to use for permissions.
 * @param smDesc		Optional description to use for SourceMod help.
 * @param ircDesc		Optional description to use for IRC help.
 * @param flags			Optional command flags.
 * @noreturn
 */
stock ICDD_RegAdminCmd(const String:cmd[], ICDDCmd:callback, adminflags, const String:smDesc[]="", const String:ircDesc[]="", flags=0)
{
	if (!isInit) return;
	
	new ret;
	decl String:strippedCmd[IRC_CMD_MAXLEN];
	ICDD_StripPrefix(cmd, strippedCmd, sizeof(strippedCmd));

	if (!GetTrieValue(callbackTrie, strippedCmd, ret))
	{
		RegAdminCmd(cmd, ICDDInternal_Callback, adminflags, smDesc, _, flags);
		LogMessage("[ICDD] Registered Admin Command: %s", cmd);
	}
		
	IRC_RegAdminCmd(strippedCmd, ICDDInternal_IRC_Callback, adminflags, StrEqual(ircDesc, "") ? smDesc : ircDesc, flags);
	LogMessage("[ICDD] Registered IRC Command: %s", strippedCmd);
	
	SetTrieValue(callbackTrie, strippedCmd, callback, true);
}

ICDD_StripPrefix(const String:str[], String:out[], outlen)
{
	if (StrContains(str, "sm_") == 0)
		strcopy(out, outlen, str[3]);
}

/**
 * Replys to a message (Using a notice). Max formatted message length is 256.
 * 
 * @param client		Nickname of the client to message or -1 to send to IRC
 * @param nick			Nickname of the user to message
 * @param format		Formatting rules.
 * @param ...			Variable number of format parameters.
 * @noreturn
 */
stock ICDD_ReplyToCommand(client, const String:nick[], const String:format[], any:...)
{
	decl String:buffer[256];
	VFormat(buffer, sizeof(buffer), format, 4);
	if (client < 0)
		IRC_ReplyToCommand(nick, buffer);
	else
		ReplyToCommand(client, buffer);
}

/**
 * Retrieves the entire command argument string in one lump from the current 
 * command. Does not include the command name.
 *
 * @param buffer		Buffer to use for storing the string.
 * @param maxlength		Maximum length of the buffer.
 * @return				Length of string written to buffer.
 */
stock ICDD_GetCmdArgString(String:buffer[], maxlength)
{
	if (ircCommand)
		return IRC_GetCmdArgString(buffer, maxlength);
	else
		return GetCmdArgString(buffer, maxlength);
}

/**
 * Retrieves a command argument given its index, from the current command.
 * @note Argument indexes start at 0; -1 retrieves the command name.
 *
 * @param argnum		Argument number to retrieve.
 * @param buffer		Buffer to use for storing the string.
 * @param maxlength		Maximum length of the buffer.
 * @return				Length of string written to buffer.
 */
stock ICDD_GetCmdArg(argnum, String:buffer[], maxlength)
{
	if (ircCommand)
		return IRC_GetCmdArg(argnum, buffer, maxlength);
	else
		return GetCmdArg(argnum, buffer, maxlength);
}

/**
 * Wraps ProcessTargetString() and handles producing error messages for
 * bad targets.
 *
 * @param client	Client who issued command or -1 if the command originated in IRC
 * @param nick		IRC user who issued the command
 * @param target	Client's target argument
 * @param nobots	Optional. Set to true if bots should NOT be targetted
 * @param immunity	Optional. Set to false to ignore target immunity.
 * @return			Index of target client, or -1 on error.
 */
stock ICDD_FindTarget(client, const String:nick[], const String:target[], bool:nobots = false, bool:immunity = true)
{
	if (client < 0)
		return IRC_FindTarget(nick, target, nobots, immunity);
	else
		return FindTarget(client, target, nobots, immunity);
}

/**
 * Replies to a client with a given message describing a targetting 
 * failure reason.
 *
 * Note: The translation phrases are found in common.phrases.txt.
 *
 * @param client		Client index. 0 for server, or -1 for IRC.
 * @param nick			IRC user to reply to.
 * @param reason		COMMAND_TARGET reason.
 * @noreturn
 */
stock ICDD_ReplyToTargetError(client, const String:nick[], reason) {
	if (client < 0)
		IRC_ReplyToTargetError(nick, reason);
	else
		ReplyToTargetError(client, reason);
}

public Action:ICDDInternal_Callback(client, args) {
	ircCommand = false;
	
	decl String:rawcommand[IRC_CMD_MAXLEN];
	decl String:command[IRC_CMD_MAXLEN];
	
	GetCmdArg(0, rawcommand, sizeof(rawcommand));
	ICDD_StripPrefix(rawcommand, command, sizeof(command));
	
	new Action:result;
	new Function:callback;
	new Handle:f = CreateForward(ET_Event, Param_Cell, Param_String, Param_Cell);
	
	GetTrieValue(callbackTrie, command, callback);
	
	AddToForward(f, INVALID_HANDLE, callback);
	Call_StartForward(f);
	Call_PushCell(client);
	Call_PushString("");
	Call_PushCell(args);
	Call_Finish(_:result);
	
	return result;
}

public Action:ICDDInternal_IRC_Callback(const String:nick[], args) {
	ircCommand = true;
	
	decl String:command[IRC_CMD_MAXLEN];
	
	IRC_GetCmdArg(-1, command, sizeof(command));
	
	new Action:result;
	new Function:callback;
	new Handle:f = CreateForward(ET_Event, Param_Cell, Param_String, Param_Cell);
	
	GetTrieValue(callbackTrie, command, callback);
	
	AddToForward(f, INVALID_HANDLE, callback);
	Call_StartForward(f);
	Call_PushCell(-1);
	Call_PushString(nick);
	Call_PushCell(args);
	Call_Finish(_:result);
	
	return result;
}

/**
 * If your plugin calls any of the ICDD_Reg* functions
 * you must call this function upon unload otherwise you will cause errors
 * in the core.
 *
 * @noreturn
 */
stock ICDD_CleanUp() {
	if (!isInit) return;
	
	ClearTrie(callbackTrie);
	
	IRC_CleanUp();
}
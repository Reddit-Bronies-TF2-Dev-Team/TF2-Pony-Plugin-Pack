#include <icdd>
#include <donator>

public Plugin:myinfo = {
	name = "Donator Administration",
	author = "Ambit",
	description = "Provides commands for modifying donators.",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	ICDD_Init(ICDD_Loaded);
}

public OnAllPluginsLoaded() {
	ICDD_OnAllPluginsLoaded();
}

public OnLibraryAdded(const String:name[]) {
	ICDD_OnLibraryAdded(name);
}

public ICDD_Loaded()
{
	ICDD_CleanUp();
	ICDD_RegAdminCmd("sm_givespray", Command_GiveSpray, ADMFLAG_GENERIC, "Convenience method for setdonator x 0", "givespray <#id|name|STEAMID> - Convenience method for setdonator x 0");
	ICDD_RegAdminCmd("sm_setdonatorlevel", Command_SetDonator, ADMFLAG_GENERIC, "Sets a user's donator level. -1 removes donator status.", "setdonator <#id|name|STEAMID> <level> - Sets a user's donator level. -1 removes donator status.");
	ICDD_RegAdminCmd("sm_removedonator", Command_RemoveDonator, ADMFLAG_GENERIC, "Removes a user from the donator list. Convenience method for setdonator x -1", "removedonator <#id|name|STEAMID> Removes a user from the donator list. Convenience method for setdonator x -1");
}

public OnPluginEnd()
{
	ICDD_CleanUp();
}

public Action:Command_RemoveDonator(client, const String:nick[], args)
{
	decl String:name[128];
	
	ICDD_GetCmdArg(1, name, sizeof(name));
	
	SetDonator(client, nick, name, -1);
	return Plugin_Handled;
}

public Action:Command_SetDonator(client, const String:nick[], args)
{
	decl String:name[128];
	decl String:level[16];
	
	if (args < 2)
	{
		ICDD_ReplyToCommand(client, nick, "usage: setdonator <#id|name|STEAMID> <level>");
		return Plugin_Handled;
	}
	
	ICDD_GetCmdArg(1, name, sizeof(name));
	ICDD_GetCmdArg(2, level, sizeof(level));
	
	new levelInt;
	if (StringToIntEx(level, levelInt) < 1)
	{
		ICDD_ReplyToCommand(client, nick, "Donator level is invalid.");
		return Plugin_Handled;
	}
	
	SetDonator(client, nick, name, levelInt);
	
	return Plugin_Handled;
}

public Action:Command_GiveSpray(client, const String:nick[], args)
{
	decl String:name[128];
	
	ICDD_GetCmdArg(1, name, sizeof(name));
	
	SetDonator(client, nick, name, 0);
	
	return Plugin_Handled;
}

SetDonator(client, const String:nick[], const String:name[], level)
{
	if (!IsSteamId(name))
	{
		decl String:auth[128];
		new target = ICDD_FindTarget(client, nick, name, true, false);
		if (target == -1)
			return;
			
		GetClientAuthString(target, auth, sizeof(auth));
		SaveDonatorToFile(auth, level);
	}
	else
	{
		SaveDonatorToFile(name, level);
	}
}

SaveDonatorToFile(const String:auth[], level)
{
	decl String:configPath[PLATFORM_MAX_PATH];
	decl String:tempPath[PLATFORM_MAX_PATH];
	decl String:line[128];
	
	BuildPath(Path_SM, configPath, sizeof(configPath), "data\\donators.txt");
	BuildPath(Path_SM, tempPath, sizeof(tempPath), "data\\donators.txt.tmp");
	
	if (FindDonatorBySteamId(auth))
	{
		new Handle:configFile = OpenFile(configPath, "r");
		new Handle:tempFile = OpenFile(tempPath, "w+");
		
		while (!IsEndOfFile(configFile))
		{
			ReadFileLine(configFile, line, sizeof(line));
			if (StrContains(line, auth))
			{
				if (level < 0)
					continue;
					
				Format(line, sizeof(line), "%s;%d", auth, level);
			}	
			WriteFileLine(tempFile, line);	
		}
		
		CloseHandle(configFile);
		CloseHandle(tempFile);
		
		DeleteFile(configPath);
		RenameFile(tempPath, configPath);
	}
	else
	{
		new Handle:configFile = OpenFile(configPath, "a");
		Format(line, sizeof(line), "%s;%d", auth, level);
		WriteFileLine(configFile, line);
		CloseHandle(configFile);
	}
	
	ServerCommand("sm_reloaddonators");
}

bool:IsSteamId(const String:str[])
{
	return StrContains(str, "STEAM_") == 0;
}
#pragma semicolon 1
#pragma tabsize 0
//------------------------------------------------------------------------------------------------------------------------------------
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
//------------------------------------------------------------------------------------------------------------------------------------
#define PLUGIN_VERSION "0.18"
//------------------------------------------------------------------------------------------------------------------------------------
public Plugin:myinfo = 
{
	name = "Advanced admin commands",
	author = "3sigma. Optimized by RDJ", // aka X@IDER
	description = "Many useful commands",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};
//------------------------------------------------------------------------------------------------------------------------------------
// Some custom defines
// Uncomment if you..
//------------------------------------------------------------------------------------------------------------------------------------
// don't want menu item

// would preffer SDKCalls instead of natives
//#define FORCESDK

// want to handle chat motd phrase
//#define CHATMOTD

// want to force using old AV
//#define OLDAV

// want to allow some actions to work on dead players/spectators (can be unsafe!!!)
// WARNING!!! If both enabled any retard with admin rights CAN CRASH YOUR SERVER
//#define ALLOWDEAD
//#define ALLOWSPEC
//------------------------------------------------------------------------------------------------------------------------------------
#define SPEC	1
#define TEAM1	2
#define TEAM2	3
//------------------------------------------------------------------------------------------------------------------------------------
#if defined ALLOWSPEC
#define FILTER_REAL		0
#else
#define FILTER_REAL		COMMAND_FILTER_CONNECTED
#endif
//------------------------------------------------------------------------------------------------------------------------------------
#if defined ALLOWDEAD
#define FILTER_ALIVE	FILTER_REAL
#else
#define FILTER_ALIVE	COMMAND_FILTER_ALIVE
#endif
//------------------------------------------------------------------------------------------------------------------------------------
// Colors
//------------------------------------------------------------------------------------------------------------------------------------
#define YELLOW               "\x01"
#define NAME_TEAMCOLOR       "\x02"
#define TEAMCOLOR            "\x03"
#define GREEN                "\x04"
//------------------------------------------------------------------------------------------------------------------------------------
// Sizes
//------------------------------------------------------------------------------------------------------------------------------------
#define MAX_CLIENTS		129
#define MAX_ID			32
#define MAX_NAME		96
#define MAX_BUFF_SM		128
#define MAX_BUFF		512
//------------------------------------------------------------------------------------------------------------------------------------
// For blink
#define	CLIENTWIDTH		35.0
#define	CLIENTHEIGHT	90.0
//------------------------------------------------------------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------------------------------------------------------------
new NewTeam[MAX_CLIENTS];
//------------------------------------------------------------------------------------------------------------------------------------
new Handle:hGameConf = INVALID_HANDLE;
new Handle:hSetModel = INVALID_HANDLE;
//------------------------------------------------------------------------------------------------------------------------------------
new Handle:hostname = INVALID_HANDLE;
new Handle:hMotd = INVALID_HANDLE;
//------------------------------------------------------------------------------------------------------------------------------------
// Teams
//------------------------------------------------------------------------------------------------------------------------------------
new String:teams[4][16] = 
{
	"N/A",
	"SPEC",
	"T",
	"CT"
};
//------------------------------------------------------------------------------------------------------------------------------------
// Functions
//------------------------------------------------------------------------------------------------------------------------------------
ChangeClientTeamEx(client,team)
{
		ChangeClientTeam(client,team);
		return;
}
//------------------------------------------------------------------------------------------------------------------------------------
SwapPlayer(target)
{
	switch (GetClientTeam(target))
	{
		case TEAM1 : ChangeClientTeamEx(target,TEAM2);
		case TEAM2 : ChangeClientTeamEx(target,TEAM1);
		default:
			return;
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
SwapPlayerRound(target)
{
	if (NewTeam[target])
	{
		NewTeam[target] = 0;
		return;
	}
	switch (GetClientTeam(target))
	{
		case TEAM1 : NewTeam[target] = TEAM2;
		case TEAM2 : NewTeam[target] = TEAM1;
		default:
			return;
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
ExchangePlayers(client,cl1,cl2)
{
	new t1 = GetClientTeam(cl1),t2 = GetClientTeam(cl2);
	if (((t1 == TEAM1) && (t2 == TEAM2)) || ((t1 == TEAM2) && (t2 == TEAM1)))
	{
		ChangeClientTeamEx(cl1,t2);
		ChangeClientTeamEx(cl2,t1);
	} else
		ReplyToCommand(client,"%t","Bad targets");
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("advcommands");

	CreateConVar("sm_adv_version", PLUGIN_VERSION, "Sourcemod Advanced version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);	
	hMotd		= CreateConVar("sm_adv_motd",			"", 	"If empty shows MOTD page, elsewhere opens this url", FCVAR_PLUGIN);

	hGameConf = LoadGameConfigFile("advcommands.gamedata");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(hGameConf, SDKConf_Virtual, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	if ((hSetModel = EndPrepSDKCall()) == INVALID_HANDLE)
		PrintToServer("[Advanced Commands] Warning: SetModel SDKCall not found, model changing disabled");
	else
		RegAdminCmd("sm_setmodel", Command_SetModel, ADMFLAG_BAN, "Set target's model (be careful)");
	
	RegAdminCmd("sm_respawn",	Command_Respawn,ADMFLAG_KICK,		"Respawn target");

	RegAdminCmd("sm_disarm",	Command_Disarm,		ADMFLAG_GENERIC,	"Disarm target");
	RegAdminCmd("sm_melee",		Command_Melee,		ADMFLAG_BAN,		"Remove all weapons, except melee weapon");
	RegAdminCmd("sm_hp",		Command_HP,			ADMFLAG_KICK,		"Set target's health points");
	RegAdminCmd("sm_kills",		Command_Frags,		ADMFLAG_BAN,		"Change target's kills");
	RegAdminCmd("sm_deaths",	Command_Deaths,		ADMFLAG_BAN,		"Change target's deaths");
	RegAdminCmd("sm_exec",		Command_Exec,		ADMFLAG_BAN,		"Execute command on target");
	RegAdminCmd("sm_teleport",	Command_Teleport,	ADMFLAG_BAN,		"Teleport target");
	RegAdminCmd("sm_god",		Command_God,		ADMFLAG_BAN,		"Set target's godmode state");
  RegAdminCmd("sm_best",		Command_Best,		ADMFLAG_KICK,		"SETS THE BEST FEATURE EVER!");
  RegAdminCmd("sm_fast",		Command_Fast,		ADMFLAG_KICK,		"Gotta go fast");
	RegAdminCmd("sm_rr",		Command_RR,			ADMFLAG_CHANGEMAP,	"Restart round");
	RegAdminCmd("sm_extend",	Command_Extend,		ADMFLAG_CHANGEMAP,	"Extend map");
	RegAdminCmd("sm_showmotd",	Command_MOTD,		ADMFLAG_GENERIC,	"Show MOTD for target");
	RegAdminCmd("sm_url",		Command_Url,		ADMFLAG_GENERIC,	"Open URL for target");
	RegAdminCmd("sm_teamswap",	Command_TeamSwap,	ADMFLAG_KICK,		"Swap teams");
	RegAdminCmd("sm_team",		Command_Team,		ADMFLAG_KICK,		"Set target's team");
	RegAdminCmd("sm_swap",		Command_Swap,		ADMFLAG_KICK,		"Swap target's team");
	RegAdminCmd("sm_lswap",		Command_LSwap,		ADMFLAG_KICK,		"Swap target's team later");
	RegAdminCmd("sm_exch",		Command_Exchange,	ADMFLAG_KICK,		"Exchange targets in teams");

	hostname = FindConVar("hostname");

	AddCommandListener(Command_Say,"say");
	AddCommandListener(Command_Say,"say_team");

	AutoExecConfig(true,"advcommands");

	SetRandomSeed(GetSysTickCount());
}

//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Say(client, const String:command[], args)
{
	if (!client || !IsClientInGame(client)) return Plugin_Continue;

	decl String:msg[MAX_BUFF];
	GetCmdArg(1,msg,sizeof(msg));

	if (!strcmp(msg,"rules",false) || !strcmp(msg,"motd",false))
	{
		ShowMOTD(client);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
//------------------------------------------------------------------------------------------------------------------------------------
public OnConfigsExecuted()
{
  GetTeamName(TEAM1,teams[TEAM1],MAX_ID);
	GetTeamName(TEAM2,teams[TEAM2],MAX_ID);
}
//------------------------------------------------------------------------------------------------------------------------------------
public ShowMOTD(client)
{
	decl String:host[MAX_BUFF_SM],String:motd[MAX_BUFF_SM];
	GetConVarString(hostname,host,sizeof(host));
	GetConVarString(hMotd,motd,sizeof(motd));
	if (strlen(motd))
		ShowMOTDPanel(client,host,motd,MOTDPANEL_TYPE_URL);
	else ShowMOTDPanel(client,host,"motd",MOTDPANEL_TYPE_INDEX);
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_MOTD(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_showmotd <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ShowMOTD(targets[i]);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Url(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_url <target> <url>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:url[MAX_BUFF];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,url,sizeof(url));
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),0,buffer,sizeof(buffer),ml);

	decl String:host[MAX_BUFF_SM];
	GetConVarString(hostname,host,sizeof(host));
	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ShowMOTDPanel(targets[i],host,url,MOTDPANEL_TYPE_URL);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Swap(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"[SM] Usage: sm_swap <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));

	new cl = FindTarget(client,pattern);

	if (cl != -1)
		SwapPlayer(cl);
	else
		ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_LSwap(client,args)
{
	if (!args)
	{
		ReplyToCommand(client,"[SM] Usage: sm_lswap <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));

	new cl = FindTarget(client,pattern);

	if (cl != -1)
		SwapPlayerRound(cl);
	else
		ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,pattern,YELLOW);

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Exchange(client,args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_exch <target1> <target2>");
		return Plugin_Handled;
	}

	new String:p1[MAX_NAME],String:p2[MAX_NAME];
	GetCmdArg(1,p1,sizeof(p1));
	GetCmdArg(2,p2,sizeof(p2));

	new cl1 = FindTarget(client,p1);
	new cl2 = FindTarget(client,p2);

	if (cl1 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p1,YELLOW);
	if (cl2 == -1) ReplyToCommand(client,"%t","No target",YELLOW,TEAMCOLOR,p2,YELLOW);

	if ((cl1 > 0) && (cl2 > 0)) ExchangePlayers(client,cl1,cl2);

	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_SetModel(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client,"[SM] Usage: sm_setmodel <target> <model>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:model[PLATFORM_MAX_PATH];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,model,sizeof(model));
	if (!FileExists(model))
	{
		ReplyToCommand(client,"[SM] %s not found",model);
		return Plugin_Handled;
	}
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		SDKCall(hSetModel,t,model);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Respawn(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_respawn <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		TF2_RespawnPlayer(targets[i]);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Disarm(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client,"[SM] Usage: sm_disarm <target>");
		return Plugin_Handled;
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),COMMAND_FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
    TF2_RemoveAllWeapons(targets[i]);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
Melee(bool:s)
{
	// Weapon slot mask to remove weapons from
	// Use like 1+2+3 => (1<<0)|(1<<1)|(1<<2) = 7

	new wslots = 11; // 0,1,3 (1h,2h,8h)
	new mslot = 2;

	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i) && IsPlayerAlive(i))
	{
		for (new j = 0; j < 5; j++)
		if (wslots & (1<<j))
		{
			new w = -1;
			while ((w = GetPlayerWeaponSlot(i,j)) != -1)
				if (IsValidEntity(w)) RemovePlayerItem(i,w);
		}
		if (s)
		{
			new m = GetPlayerWeaponSlot(i,mslot);
			if (IsValidEntity(m)) EquipPlayerWeapon(i,m);
		}
	}
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Melee(client, args)
{
	Melee(true);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_HP(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_hp <target> <[+/-]hp>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:health[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,health,sizeof(health));
	new hp = StringToInt(health);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetEntProp(t, Prop_Send, "m_iHealth");
		if ((health[0] == '+') || (health[0] == '-'))
		{
			val += hp;
			if (val < 0) val = 0;
		} else
		{
			val = hp;
		}

		SetEntProp(t, Prop_Send, "m_iHealth", hp);
	}

	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Frags(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_frags <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:frags[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,frags,sizeof(frags));
	new frag = StringToInt(frags);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetClientFrags(t);
		if ((frags[0] == '+') || (frags[0] == '-'))
		{
			val += frag;
			if (val < 0) val = 0;
		} else
		{
			val = frag;
		}
		SetEntProp(t, Prop_Data, "m_iFrags", val);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Deaths(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_deaths <target> <[+/-]amount>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:deaths[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,deaths,sizeof(deaths));
	new death = StringToInt(deaths);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		new val = GetClientDeaths(t);
		if ((deaths[0] == '+') || (deaths[0] == '-'))
		{
			val += death;
			if (val < 0) val = 0;
		} else
		{
			val = death;
		}
		SetEntProp(t, Prop_Data, "m_iDeaths", val);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_TeamSwap(client, args)
{
	for (new i = 1; i <= MaxClients; i++)
	if (IsClientInGame(i)) switch (GetClientTeam(i))
	{
		case TEAM1 : ChangeClientTeamEx(i,TEAM2);
		case TEAM2 : ChangeClientTeamEx(i,TEAM1);
	}
	new ts = GetTeamScore(TEAM1);
	SetTeamScore(TEAM1,GetTeamScore(TEAM2));
	SetTeamScore(TEAM2,ts);
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Team(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <target> <team>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:team[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,team,sizeof(team));
	new tm = StringToInt(team);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ChangeClientTeamEx(targets[i],tm);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Exec(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_exec <target> <cmd>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:cmd[128];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,cmd,sizeof(cmd));
	new targets[MAX_CLIENTS],bool:ml;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_REAL|COMMAND_FILTER_NO_BOTS,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		ClientCommand(targets[i], cmd);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Teleport(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_teleport <target> [x|client] [y] [z]");
		return Plugin_Handled;	
	}

	new Float:origin[3];
	if (args > 3)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(2,ax,sizeof(ax));
		origin[0] = StringToFloat(ax);
		GetCmdArg(3,ax,sizeof(ax));
		origin[1] = StringToFloat(ax);
		GetCmdArg(4,ax,sizeof(ax));
		origin[2] = StringToFloat(ax);	
	} else
	if (args > 1)
	{
		decl String:cl[MAX_NAME];
		GetCmdArg(2,cl,sizeof(cl));
		new tgt = FindTarget(client,cl);
		if ((tgt != -1) && IsValidEntity(tgt)) GetEntPropVector(tgt, Prop_Send, "m_vecOrigin", origin);
		else
		{
			ReplyToCommand(client,"%t","Bad target",YELLOW,TEAMCOLOR,cl,YELLOW);
			return Plugin_Handled;
		}
	}
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME];
	GetCmdArg(1,pattern,sizeof(pattern));
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		new t = targets[i];
		TeleportEntity(t,origin, NULL_VECTOR, NULL_VECTOR);
	}
	
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_God(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_god <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:god[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,god,sizeof(god));
	new gd = StringToInt(god);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		SetEntProp(targets[i], Prop_Data, "m_takedamage", gd?1:2, 1);
	}
	return Plugin_Handled;
}

//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Best(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_best <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:god[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,god,sizeof(god));
	new gd = StringToInt(god);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
		TF2_SetPlayerPowerPlay(targets[i], gd?true:false);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Fast(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fast <target> <0|1>");
		return Plugin_Handled;	
	}	
	decl String:pattern[MAX_NAME],String:buffer[MAX_NAME],String:god[MAX_ID];
	GetCmdArg(1,pattern,sizeof(pattern));
	GetCmdArg(2,god,sizeof(god));
	new gd = StringToInt(god);
	new targets[MAX_CLIENTS],bool:ml = false;

	new count = ProcessTargetString(pattern,client,targets,sizeof(targets),FILTER_ALIVE,buffer,sizeof(buffer),ml);

	if (count <= 0) ReplyToCommand(client,"%t",(count < 0)?"Bad target":"No target",YELLOW,TEAMCOLOR,pattern,YELLOW);
	else for (new i = 0; i < count; i++)
	{
    if(gd)
      TF2_AddCondition(targets[i], TFCond_SpeedBuffAlly, 200.0);
    else
      TF2_RemoveCondition(targets[i], TFCond_SpeedBuffAlly);
	}
	return Plugin_Handled;
}
//------------------------------------------------------------------------------------------------------------------------------------
ExtendMap(mins)
{
	ExtendMapTimeLimit(mins*60);
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_RR(client, args)
{
	new t = 1;
	if (args)
	{
		decl String:ax[MAX_ID];
		GetCmdArg(1,ax,sizeof(ax));
		t = StringToInt(ax);
	}	
	ServerCommand("mp_restartgame %d",t);
	return Plugin_Handled;	
}
//------------------------------------------------------------------------------------------------------------------------------------
public Action:Command_Extend(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_extend <minutes>");
		return Plugin_Handled;	
	}	
	decl String:m[MAX_ID];
	GetCmdArg(1,m,sizeof(m));
	ExtendMap(StringToInt(m));

	return Plugin_Handled;	
}

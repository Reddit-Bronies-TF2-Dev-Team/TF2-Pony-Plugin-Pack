/*
* Gives those donators the recognition they deserve :)
* 
* Changelog:
* 
* v0.3 - release
* v0.4 - Enable/ disable in donator > sprite menu/ proper error without interface
* v.05 - Expanded to support multiple sprites/ fixed SetParent error
*
*/

#include <sourcemod>
#include <sdktools>
#include <donator>
#include <clientprefs>
#include <adt>
#pragma tabsize 0
#pragma semicolon 1

#define PLUGIN_VERSION	"0.9"

new gVelocityOffset;

new g_EntList[MAXPLAYERS + 1];
new g_bIsDonator[MAXPLAYERS + 1];
new bool:g_bRoundEnded;
new Handle:g_HudSync = INVALID_HANDLE;
new Handle:g_SpriteShowCookie = INVALID_HANDLE;
new Handle:g_cutieMarkFileNames = INVALID_HANDLE;
new Handle:g_cutieMarkNames = INVALID_HANDLE;
new Handle:g_cutieMarkPermissions = INVALID_HANDLE;

new g_iShowSprite[MAXPLAYERS + 1];
new TOTAL_SPRITE_FILES;

public Plugin:myinfo = 
{
	name = "Donator Recognition",
	author = "Nut. Dynamic by RDJ",
	description = "Give donators the recognition they deserve.",
	version = PLUGIN_VERSION,
	url = "http://www.lolsup.com/tf2"
}

public OnPluginStart()
{
	CreateConVar("basicdonator_recog_v", PLUGIN_VERSION, "Donator Recognition Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEventEx("teamplay_round_start", hook_Start, EventHookMode_PostNoCopy);
	HookEventEx("arena_round_start", hook_Start, EventHookMode_PostNoCopy);
	HookEventEx("teamplay_round_win", hook_Win, EventHookMode_PostNoCopy);
	HookEventEx("arena_win_panel", hook_Win, EventHookMode_PostNoCopy);
	HookEventEx("player_death", event_player_death, EventHookMode_Post);
	
	g_HudSync = CreateHudSynchronizer();
	g_SpriteShowCookie = RegClientCookie("donator_spriteshow", "Which cutiemark to show.", CookieAccess_Private);

	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
  
  RegAdminCmd("sm_reloadcutiemarks", cmd_ReloadCutiemarks, ADMFLAG_BAN, "Reloads cutiemarks");
  
  g_cutieMarkFileNames = CreateArray(128);
  g_cutieMarkNames = CreateTrie();
  g_cutieMarkPermissions = CreateTrie();
  LoadAllCutiemarks();
}

public OnPluginEnd()
{
  CloseHandle(g_cutieMarkFileNames);
  CloseHandle(g_cutieMarkNames);
  CloseHandle(g_cutieMarkPermissions);
}

public OnAllPluginsLoaded()
{
	if(!LibraryExists("donator.core")) 
    SetFailState("Unabled to find plugin: Basic Donator Interface");
	
  Donator_RegisterMenuItem("Change Cutiemark", SpriteControlCallback);
}

public OnMapStart()
{
	decl String:szBuffer[128], String:fileName[128];
	for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
	{
    GetArrayString(g_cutieMarkFileNames, i, fileName, 128);
		FormatEx(szBuffer, sizeof(szBuffer), "materials/custom/%s.vmt", fileName);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		FormatEx(szBuffer, sizeof(szBuffer), "materials/custom/%s.vtf", fileName);
		PrecacheGeneric(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
	}
}

public OnPostDonatorCheck(iClient)
{
	if (!IsPlayerDonator(iClient)) return;
	
	g_bIsDonator[iClient] = true;
	g_iShowSprite[iClient] = 1;
	
	new String:szBuffer[256];
	if (AreClientCookiesCached(iClient))
	{		
		GetClientCookie(iClient, g_SpriteShowCookie, szBuffer, sizeof(szBuffer));
		if (strlen(szBuffer) > 0)
			g_iShowSprite[iClient] = StringToInt(szBuffer);
	}
	
	GetDonatorMessage(iClient, szBuffer, sizeof(szBuffer));
	ShowDonatorMessage(iClient, szBuffer);
}

public OnClientDisconnect(iClient)
	g_bIsDonator[iClient] = false;


public ShowDonatorMessage(iClient, String:message[])
{
	SetHudTextParamsEx(-1.0, 0.22, 4.0, {0, 255, 0, 0}, {0, 0, 0, 255}, 1, 5.0, 0.15, 0.15);
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			ShowSyncHudText(i, g_HudSync, message);
}

public hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerEligible(i)) continue;
		KillSprite(i);
	}
	g_bRoundEnded = false;
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{	
	decl String:szBuffer[256], String:fileName[128];
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || IsClientObserver(i)) continue;
		if (!IsPlayerEligible(i)) continue;
		
		if (g_iShowSprite[i] > 0)
		{
			if (g_iShowSprite[i] > TOTAL_SPRITE_FILES) 
        g_iShowSprite[i] = TOTAL_SPRITE_FILES - 1;
      
      GetArrayString(g_cutieMarkFileNames, (g_iShowSprite[i])-1, fileName, sizeof(fileName));
      FormatEx(szBuffer, sizeof(szBuffer), "materials/custom/%s.vmt", fileName);
			CreateSprite(i, szBuffer, 25.0);
		}
	}
	g_bRoundEnded = true;
}

public Action:event_player_death(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_bRoundEnded) return Plugin_Continue;
	KillSprite(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

public DonatorMenu:SpriteControlCallback(iClient) Panel_SpriteControl(iClient);

public Action:Panel_SpriteControl(iClient)
{
  decl String:steamID[128];
  GetClientAuthString(iClient, steamID, sizeof(steamID));
  
	new Handle:menu = CreateMenu(SpriteControlSelected);
	SetMenuTitle(menu,"Donator: Cutiemark Control:");
	
	if (g_iShowSprite[iClient] > 0)
		AddMenuItem(menu, "0", "Disable Cutiemark", ITEMDRAW_DEFAULT);
	else
		AddMenuItem(menu, "0", "Disable Cutiemark", ITEMDRAW_DISABLED);
	
	decl String:szItem[4], String:fileName[128], String:cutiemarkName[128], String:cutiemarkSteamID[128];
	for (new i = 0; i < TOTAL_SPRITE_FILES; i++)
	{
    cutiemarkSteamID = "";
    
		FormatEx(szItem, sizeof(szItem), "%i", i+1);	//need to offset the menu items by one since we added the enable / disable outside of the loop
    GetArrayString(g_cutieMarkFileNames, i, fileName, 128);
    GetTrieString(g_cutieMarkNames, fileName, cutiemarkName, 128);
    GetTrieString(g_cutieMarkPermissions, fileName, cutiemarkSteamID, 128);
    
    // If the cutiemark is locked to a user
    if(strlen(cutiemarkSteamID) > 5)
    {
      // Check SteamID
      if(StrEqual(cutiemarkSteamID, steamID) == true)
      {
        if(g_iShowSprite[iClient]-1 != i)
          AddMenuItem(menu, szItem, cutiemarkName, ITEMDRAW_DEFAULT);
        else
          AddMenuItem(menu, szItem, cutiemarkName, ITEMDRAW_DISABLED);
      }
      else
        AddMenuItem(menu, szItem, cutiemarkName, ITEMDRAW_DISABLED);
    }
    else
    {
      if (g_iShowSprite[iClient]-1 != i)
        AddMenuItem(menu, szItem, cutiemarkName, ITEMDRAW_DEFAULT);
      else
        AddMenuItem(menu, szItem, cutiemarkName, ITEMDRAW_DISABLED);
    }
	}
	DisplayMenu(menu, iClient, 20);
}

public SpriteControlSelected(Handle:menu, MenuAction:action, param1, param2)
{
	decl String:tmp[32], iSelected;
	GetMenuItem(menu, param2, tmp, sizeof(tmp));
	iSelected = StringToInt(tmp);

	switch (action)
	{
		case MenuAction_Select:
		{
			g_iShowSprite[param1] = iSelected;
			decl String:szSelected[15];
			Format(szSelected, sizeof(szSelected), "%i", iSelected);
			SetClientCookie(param1, g_SpriteShowCookie, szSelected);
		}
		case MenuAction_End: CloseHandle(menu);
	}
}

public PanelHandlerBlank(Handle:menu, MenuAction:action, iClient, param2) {}

//--------------------------------------------------------------------------------------------------

stock CreateSprite(iClient, String:sprite[], Float:offset)
{
	new String:szTemp[64]; 
	Format(szTemp, sizeof(szTemp), "client%i", iClient);
	DispatchKeyValue(iClient, "targetname", szTemp);

	new Float:vOrigin[3];
	GetClientAbsOrigin(iClient, vOrigin);
	vOrigin[2] += offset;
	new ent = CreateEntityByName("env_sprite_oriented");
	if (ent)
	{
		DispatchKeyValue(ent, "model", sprite);
		DispatchKeyValue(ent, "classname", "env_sprite_oriented");
		DispatchKeyValue(ent, "spawnflags", "1");
		DispatchKeyValue(ent, "scale", "0.1");
		DispatchKeyValue(ent, "rendermode", "1");
		DispatchKeyValue(ent, "rendercolor", "255 255 255");
		DispatchKeyValue(ent, "targetname", "donator_spr");
		DispatchKeyValue(ent, "parentname", szTemp);
		DispatchSpawn(ent);
		
		TeleportEntity(ent, vOrigin, NULL_VECTOR, NULL_VECTOR);

		g_EntList[iClient] = ent;
	}
}

stock KillSprite(iClient)
{
	if (g_EntList[iClient] > 0 && IsValidEntity(g_EntList[iClient]))
	{
		AcceptEntityInput(g_EntList[iClient], "kill");
		g_EntList[iClient] = 0;
	}
}
public OnGameFrame()
{
	if (!g_bRoundEnded) return;
	new ent, Float:vOrigin[3], Float:vVelocity[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i)) continue;
		if ((ent = g_EntList[i]) > 0)
		{
			if (!IsValidEntity(ent))
				g_EntList[i] = 0;
			else
				if ((ent = EntRefToEntIndex(ent)) > 0)
				{
					GetClientEyePosition(i, vOrigin);
					vOrigin[2] += 25.0;
					GetEntDataVector(i, gVelocityOffset, vVelocity);
					TeleportEntity(ent, vOrigin, NULL_VECTOR, vVelocity);
				}
		}
	}
}

stock bool:IsPlayerEligible(playerIndex)
{
  if(g_bIsDonator[playerIndex] && GetDonatorLevel(playerIndex) >= 2)
    return true;
  else
    return false;
}

stock LoadAllCutiemarks()
{
  decl String:szBuffer[255];
  BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/donator_cutiemarks.cfg");
  new Handle:kvTree = CreateKeyValues("CutieMarks");
  FileToKeyValues(kvTree, szBuffer);
  
  ClearArray(g_cutieMarkFileNames);
  ClearTrie(g_cutieMarkNames);
  ClearTrie(g_cutieMarkPermissions);
  
  KvGotoFirstSubKey(kvTree);
  new String:fileName[64];
  decl String:steamID[256];
  do 
  {
			KvGetSectionName(kvTree, fileName, sizeof(fileName));
      KvGetString(kvTree, "name", szBuffer, sizeof(szBuffer), "");
      KvGetString(kvTree, "steamid", steamID, sizeof(steamID), "");
      SetTrieString(g_cutieMarkPermissions, fileName, steamID);
      SetTrieString(g_cutieMarkNames, fileName, szBuffer);
      PushArrayString(g_cutieMarkFileNames, fileName);
  } while (KvGotoNextKey(kvTree));
  
  CloseHandle(kvTree);
  
  TOTAL_SPRITE_FILES = GetArraySize(g_cutieMarkFileNames);
}

public Action:cmd_ReloadCutiemarks(client, args)
{
  LoadAllCutiemarks();
  return Plugin_Handled;
}

#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>

#define PL_VERSION    "0.5.7"

public Plugin:myinfo = {
	name        = "Advertisements",
	author      = "Tsunami. Optimized by RDJ.",
	description = "Display advertisements",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
};

new Handle:g_hAdvertisements  = INVALID_HANDLE;
new Handle:g_hEnabled;
new Handle:g_hFile;
new Handle:g_hInterval;
new Handle:g_hTimer;

static g_iSColors[4]             = {1,               3,              3,           4};
static String:g_sSColors[4][13]  = {"{DEFAULT}",     "{LIGHTGREEN}", "{TEAM}",    "{GREEN}"};

public OnPluginStart() {
	CreateConVar("sm_advertisements_version", PL_VERSION, "Display advertisements", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled        = CreateConVar("sm_advertisements_enabled",  "1",                  "Enable/disable displaying advertisements.");
	g_hFile           = CreateConVar("sm_advertisements_file",     "advertisements.txt", "File to read the advertisements from.");
	g_hInterval       = CreateConVar("sm_advertisements_interval", "30",                 "Amount of seconds between advertisements.");
	
	HookConVarChange(g_hInterval, ConVarChange_Interval);
	RegServerCmd("sm_advertisements_reload", Command_ReloadAds, "Reload the advertisements");
}

public OnMapStart() {
	ParseAds();
	
	g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public ConVarChange_Interval(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (g_hTimer != INVALID_HANDLE) {
		KillTimer(g_hTimer);
	}
	
	g_hTimer          = CreateTimer(GetConVarInt(g_hInterval) * 1.0, Timer_DisplayAds, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Command_ReloadAds(args) {
	ParseAds();
}

public Action:Timer_DisplayAds(Handle:timer) {
	if (!GetConVarBool(g_hEnabled)) 
    return Plugin_Handled;
  
  decl String:sText[500], String:sType[6];
  
  KvGetString(g_hAdvertisements, "type",  sType,  sizeof(sType));
  KvGetString(g_hAdvertisements, "text",  sText,  sizeof(sText));
  
  if (!KvGotoNextKey(g_hAdvertisements)) {
    KvRewind(g_hAdvertisements);
    KvGotoFirstSubKey(g_hAdvertisements);
  }
  
  if (StrContains(sType, "S") != -1) {
    new String:sColor[4];
    
    Format(sText, sizeof(sText), "%c%s", 1, sText);
    
    for (new c = 0; c < sizeof(g_iSColors); c++) {
      if (StrContains(sText, g_sSColors[c])) {
        Format(sColor, sizeof(sColor), "%c", g_iSColors[c]);
        ReplaceString(sText, sizeof(sText), g_sSColors[c], sColor);
      }
    }
    
    PrintToChatAll(sText);
  }
  return Plugin_Continue;
}

ParseAds() {
	if (g_hAdvertisements != INVALID_HANDLE) {
		CloseHandle(g_hAdvertisements);
	}
	
	g_hAdvertisements = CreateKeyValues("Advertisements");
	
	decl String:sFile[256], String:sPath[256];
	GetConVarString(g_hFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);
	
	if (FileExists(sPath)) {
		FileToKeyValues(g_hAdvertisements, sPath);
		KvGotoFirstSubKey(g_hAdvertisements);
	} else {
		SetFailState("File Not Found: %s", sPath);
	}
}

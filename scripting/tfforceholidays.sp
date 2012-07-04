// TF2 Force Holidays
// Copyright 2011 Ross Bemrose (Powerlord)
// Like All SourceMod Plugins, this code is licensed under the GPLv2

#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>
#include <tf2>

#define VERSION "1.41"

new Handle:g_Cvar_Enabled   = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "TF Force Holidays - Optimized",
	author = "Powerlord. Optimized by RDJ",
	description = "Enable multiple holidays at once",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=171012"
}

public OnPluginStart()
{
	CreateConVar("tfh_version", VERSION, "TF Force Holidays version", FCVAR_NOTIFY | FCVAR_DONTRECORD | FCVAR_SPONLY);
	g_Cvar_Enabled   = CreateConVar("tfh_enabled", "1", "Enable TF Force Holidays", FCVAR_NOTIFY, true, -1.0, true, 1.0);
}

public OnMapStart()
{
	decl String:mapname[32];
	GetCurrentMap(mapname, sizeof(mapname));
	
	// Precache sounds and models for Halloween bosses
	if (StrEqual("cp_manor_event", mapname, false))
	{
		PrecacheModel("models/bots/headless_hatman.mdl"); 
		PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
		PrecacheSound("ui/halloween_boss_summon_rumble.wav");
		PrecacheSound("vo/halloween_boss/knight_alert.wav");
		PrecacheSound("vo/halloween_boss/knight_alert01.wav");
		PrecacheSound("vo/halloween_boss/knight_alert02.wav");
		PrecacheSound("vo/halloween_boss/knight_attack01.wav");
		PrecacheSound("vo/halloween_boss/knight_attack02.wav");
		PrecacheSound("vo/halloween_boss/knight_attack03.wav");
		PrecacheSound("vo/halloween_boss/knight_attack04.wav");
		PrecacheSound("vo/halloween_boss/knight_death01.wav");
		PrecacheSound("vo/halloween_boss/knight_death02.wav");
		PrecacheSound("vo/halloween_boss/knight_dying.wav");
		PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
		PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
		PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
		PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
		PrecacheSound("vo/halloween_boss/knight_pain01.wav");
		PrecacheSound("vo/halloween_boss/knight_pain02.wav");
		PrecacheSound("vo/halloween_boss/knight_pain03.wav");
		PrecacheSound("vo/halloween_boss/knight_spawn.wav");
		PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
		PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
		PrecacheSound("ui/halloween_boss_chosen_it.wav");
		PrecacheSound("ui/halloween_boss_defeated_fx.wav");
		PrecacheSound("ui/halloween_boss_defeated.wav");
		PrecacheSound("ui/halloween_boss_player_becomes_it.wav");
		PrecacheSound("ui/halloween_boss_summoned_fx.wav");
		PrecacheSound("ui/halloween_boss_summoned.wav");
		PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
		PrecacheSound("ui/halloween_boss_tagged_other_it.wav");

	}
	else if (StrEqual("koth_viaduct_event", mapname, false))
	{
		PrecacheModel("models/props_halloween/halloween_demoeye.mdl");
		PrecacheModel("models/props_halloween/eyeball_projectile.mdl");
		PrecacheSound("vo/halloween_eyeball/eyeball01.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball02.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball03.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball04.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball05.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball06.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball07.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball08.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball09.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball10.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball11.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_biglaugh01.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_boss_pain01.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh01.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh02.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_laugh03.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_mad01.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_mad02.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_mad03.wav");
		PrecacheSound("vo/halloween_eyeball/eyeball_teleport.wav");
		PrecacheSound("ui/halloween_boss_chosen_it.wav");
		PrecacheSound("ui/halloween_boss_defeated_fx.wav");
		PrecacheSound("ui/halloween_boss_defeated.wav");
		PrecacheSound("ui/halloween_boss_player_becomes_it.wav");
		PrecacheSound("ui/halloween_boss_summon_rumble.wav");
		PrecacheSound("ui/halloween_boss_summoned_fx.wav");
		PrecacheSound("ui/halloween_boss_summoned.wav");
		PrecacheSound("ui/halloween_boss_tagged_other_it.wav");
		PrecacheSound("ui/halloween_boss_escape.wav");
		PrecacheSound("ui/halloween_boss_escape_sixty.wav");
		PrecacheSound("ui/halloween_boss_escape_ten.wav");
	}
}

public Action:TF2_OnIsHolidayActive(TFHoliday:holiday, &bool:result)
{
	if (!GetConVarBool(g_Cvar_Enabled))
    return Plugin_Continue;
    
  switch(holiday)
  {
    case TFHoliday_Christmas,TFHoliday_Halloween,TFHoliday_Birthday:
    {
      result = false;
      return Plugin_Changed;
    }
    case TFHoliday_HalloweenOrFullMoon,TFHoliday_FullMoon:
    {
      result = true;
      return Plugin_Changed;
    }
  }
	return Plugin_Continue;
}


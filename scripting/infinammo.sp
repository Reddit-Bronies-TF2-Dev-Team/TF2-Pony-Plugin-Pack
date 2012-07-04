#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#define PLUGIN_VERSION "2.2.4"


public Plugin:myinfo = 
{
	
	name = "TF2 Full Infinite Ammo - Optimized Edition",
	author = "Tylerst. Optimized by RDJ",
	description = "Infinite use for just about everything. Modified.",
	version = PLUGIN_VERSION,
	url = "http://roguedarkjedi.com/"

}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

new bool:g_fiammo[MAXPLAYERS+1];
new bool:g_fiaon = false;

new Handle:hSandman = INVALID_HANDLE;
new Handle:hAll = INVALID_HANDLE;

new offset_ammo;
new offset_clip;

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	CreateConVar("sm_fia_version", PLUGIN_VERSION, "Full Infinite Ammo TF2", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	hSandman = CreateConVar("sm_fia_sandman", "0", "AdminOnly/All/Disable '2/1/0' infinite sandman balls");
	hAll = CreateConVar("sm_fia_all", "0", "Enable/Disable '1/0' Infinite Ammo for everyone");

	HookConVarChange(hAll, FiaAllChange);
	HookConVarChange(hSandman, ResetSandmanBalls);

	offset_ammo = FindSendPropInfo("CBasePlayer", "m_iAmmo");
	offset_clip = FindSendPropInfo("CBaseCombatWeapon", "m_iClip1");
}

public OnClientPutInServer(client)
{
	if(GetConVarBool(hAll) && g_fiaon == true) 
	{
		g_fiammo[client] = true;
	}
	else 
	{
		g_fiammo[client] = false;
	}
}
public OnClientDisconnect_Post(client)
{
	g_fiammo[client] = false;
}

public OnGameFrame()
{
  if(g_fiaon == false)
    return;
    
	for(new i=1;i<=MaxClients;i++)
	{
		if((IsClientInGame(i) && IsPlayerAlive(i)) && g_fiammo[i])
		{	
			new weapon = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
			if(!IsValidEntity(weapon)) continue;

			new String:weaponclassname[32];
			GetEntityClassname(weapon, weaponclassname, sizeof(weaponclassname));
			new TFClassType:playerclass = TF2_GetPlayerClass(i);
			switch(playerclass)
			{
        case TFClass_Scout:
        {
        
        }
				case TFClass_Soldier:
				{
					if(GetEntPropFloat(i, Prop_Send, "m_flRageMeter") == 0.00)
					{

						SetEntPropFloat(i, Prop_Send, "m_flRageMeter", 100.0);
					}
				}
				case TFClass_DemoMan:
				{
					if(!TF2_IsPlayerInCondition(i, TFCond_Charging)) 
					{
						SetEntPropFloat(i, Prop_Send, "m_flChargeMeter", 100.0);
					}
				}
				case TFClass_Engineer:
				{
					SetEntData(i, FindDataMapOffs(i, "m_iAmmo")+12, 200, 4);
					InfiniteSentryAmmo(i);
					
				}
				case TFClass_Medic:
				{
          /*
					if((StrEqual(weaponclassname, "tf_weapon_medigun", false)) && GetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel") == 0.00)
					{
						SetEntPropFloat(weapon, Prop_Send, "m_flChargeLevel", 1.00);
					}
          */
				}
				case TFClass_Spy:
				{
					SetEntPropFloat(i, Prop_Send, "m_flCloakMeter", 100.0);
					new knife = GetPlayerWeaponSlot(i, TFWeaponSlot_Melee);
					if(!IsValidEntity(knife)) continue;
					if(GetEntProp(knife, Prop_Send, "m_iItemDefinitionIndex") == 649)
					{
						SetEntPropFloat(knife, Prop_Send, "m_flKnifeRegenerateDuration", 0.0);
					}
				}

			}
			if(StrEqual(weaponclassname, "tf_weapon_bat_wood", false) ||(StrEqual(weaponclassname, "tf_weapon_bat_giftwrap", false)))
			{
				switch(GetConVarInt(hSandman))
				{
					case 0:
					{
						continue;
					}
					case 2:
					{
						if(!CheckCommandAccess(i, "sm_fia_adminflag", ADMFLAG_GENERIC)) continue;
					}
				}	
			}
			new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			switch(weaponindex)
			{
        case 46:
        {
          continue;
        }
				case 441,442,588:
				{
					SetEntPropFloat(weapon, Prop_Send, "m_flEnergy", 100.0);
					continue;
				}
				case 141,525,595:
				{
					SetEntProp(i, Prop_Send, "m_iRevengeCrits", 10);
				}
				case 307:
				{
					SetEntProp(weapon, Prop_Send, "m_bBroken", 0);

					SetEntProp(weapon, Prop_Send, "m_iDetonated", 0);					
				}
				case 448:
				{
					SetEntPropFloat(i, Prop_Send, "m_flHypeMeter", 100.0);
				}
				case 527:
				{
					continue;
				}
				case 594:
				{
					if(GetEntPropFloat(i, Prop_Send, "m_flRageMeter") == 0.00)
					{

						SetEntPropFloat(i, Prop_Send, "m_flRageMeter", 100.0);
					}					
				}
			}
      new ammotype = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType")*4;
      
			SetEntData(weapon, offset_clip, 99, 4, true);
			SetEntData(i, ammotype+offset_ammo, 99, 4, true);
		}
	}	
}

public InfiniteSentryAmmo(client)
{
	new sentrygun = -1; 
	while ((sentrygun = FindEntityByClassname(sentrygun, "obj_sentrygun"))!=INVALID_ENT_REFERENCE)
	{
		if(IsValidEntity(sentrygun))
		{
			if(GetEntPropEnt(sentrygun, Prop_Send, "m_hBuilder") == client)
			{
				if(GetEntProp(sentrygun, Prop_Send, "m_bMiniBuilding"))
				{
					SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150); 
				}
				else
				{
					switch (GetEntProp(sentrygun, Prop_Send, "m_iUpgradeLevel"))
					{
						case 1:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 150);
						}
						case 2:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
						}
						case 3:
						{
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoShells", 200);
							SetEntProp(sentrygun, Prop_Send, "m_iAmmoRockets", 20);
						}
					}
				}
			}
		}
	}
}

public FiaAllChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);

	if (newint != 0 && oldint == 0)

	{
    g_fiaon = true;
		for (new i=1;i<=MaxClients;i++)

		{
			g_fiammo[i] = true;
		}
		
	}
	if (newint == 0 && oldint != 0)

	{		
    g_fiaon = false;
		for (new i=1;i<=MaxClients;i++)

		{
			g_fiammo[i] = false;
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				new health = GetClientHealth(i);
				SetEntProp(i, Prop_Send, "m_iRevengeCrits", 0);
				TF2_RegeneratePlayer(i);
				SetEntityHealth(i, health);
			}
		}
	}
}

public ResetSandmanBalls(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new oldint = StringToInt(oldValue);
	new newint = StringToInt(newValue);
	if ((newint == 0 && oldint != 0) || (newint == 2 && oldint == 1))

	{	
		for (new i=1;i<=MaxClients;i++)

		{
			if(g_fiammo[i])
			{
				if(IsClientInGame(i) && IsPlayerAlive(i))
				{
					new health = GetClientHealth(i);
					TF2_RegeneratePlayer(i);
					SetEntityHealth(i, health);
				}
			}
		}
	}
}

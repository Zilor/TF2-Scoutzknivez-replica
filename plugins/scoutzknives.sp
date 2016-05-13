#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>

#pragma newdecls required

#define PLUGIN_VERSION "0.0.1"

#define TFWeapon_Sniper_Rifle 14
#define TFWeapon_Kukri 3

ConVar gcvEnabled;
ConVar gcvEnabled;
ConVar gcvProtection;
ConVar gcvBots;
ConVar gcvFall;
ConVar gcvAiraccelerate;
ConVar gcvHealth;
ConVar gcvLives;
ConVar gcvDamage;
ConVar gcvScope;
ConVar gcvPenetrate;
ConVar gcvTracer;
ConVar gcvAmmo;
ConVar gcvCost;
ConVar gcvCostMissed;
ConVar gcvRegeneration;
ConVar gcvTermination;

bool gbMapSupported;

public Plugin myinfo =
{
	name = "Scoutknivez replica",
	author = "openDragon",
	description = "A recreation of Darkimmortal's public Scoutknivez plugin",
	version = PLUGIN_VERSION,
	url = "http://www.opendragon.eu"
};

public void OnPluginStart()
{
	CreateConVar("sm_scoutknivez_version", PLUGIN_VERSION, "Version of Scoutknivez replica", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gcvEnabled  = CreateConVar("sm_scoutknivez_enabled", "1", "Enables/Disables the plugin");
	gcvProtection  = CreateConVar("sm_scoutknivez_spawn", "5", "Time the player is protected after spawning");
	gcvBots	= CreateConVar("sm_scoutknivez_Bots", "", "");
	gcvFall  = CreateConVar("sm_scoutknivez_fall_damage", "", "");
	gcvAiraccelerate  = CreateConVar("sm_scoutknivez_airaccelerate", "40", "Replica of sv_airaccelerate");
	gcvHealth  = CreateConVar("sm_scoutknivez_health", "1", "Health multiplicator");
	gcvLives  = CreateConVar("sm_scoutknivez_lives", "3", "Amout of live each player has");
	gcvDamage  = CreateConVar("sm_scoutknivez_damage", "3", "Damage multiplicator");
	gcvScope  = CreateConVar("sm_scoutknivez_scope", "1", "Enables/Disables the Zoom function");
	gcvPenetrate  = CreateConVar("sm_scoutknivez_penetrate", "1", "Enables/Disables the penatration of player");
	gcvTracer	= CreateConVar("sm_scoutknivez_tracer", "0", "Enables/Disables tracer rounds");
	gcvAmmo	= CreateConVar("sm_scoutknivez_ammo", "0", "Enables/Disables tracer rounds");
	gcvCost	= CreateConVar("sm_scoutknivez_ammo_cost", "1", "Amount of ammo it costs to fire");
	gcvCostMissed	= CreateConVar("sm_scoutknivez_ammo_cost_missed", "0", "Additional amount of ammo lost on miss");0
	gcvRegeneration	= CreateConVar("sm_scoutknivez_ammo_regeneration", "0", "Amount of ammo regenerated after 5 seconds");
	gcvTermination	= CreateConVar("sm_scoutknivez_termination", "0", "Amount of time a player has to find some new ammo, before they get terminated");


	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);

}

public void OnMapStart()
{
	char cMapName[128]; //TODO: Replace magic number with something else
	GetCurrentMap(cMapName, strlen(cMapName));
	
	if(strncmp(cMapName, "sk_", 3, false) == 0) //TODO: Magic number.
	{
		gbMapSupported = true;
	}
	else
	{
		gbMapSupported = false;
	}
}

public Action public Action EventPlayerSpawn(Event eEvent, const char[] cName, bool dDontBroadcast)
{
	if(!gcvEnabled || !gbMapSupported)
	{
		Plugin_Continue;
	}
	
	TF2_AddCondition(iClient, TFCond_Ubercharged, gcvProtection.FloatValue);
}

public Action EventInventoryApplication(Event eEvent, const char[] cName, bool dDontBroadcast)
{
	if(!gcvEnabled || !gbMapSupported)
	{
		Plugin_Continue;
	}
	
	iPrimary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
	// TODO: Check all sniper rifles and only allow the stock and the AWP

	if(IsValidEntity(iPrimary))
	{
		if(gcvScope.BoolValue)
		{
			TF2Attrib_SetByName(iPrimary, "unimplemented_mod_sniper_no_charge", 1); //Ignore the "unimplemented"
		}

		if(gcvPenetrate.BoolValue)
		{
			TF2Attrib_SetByName(iPrimary, "shot_penetrate_all_players", 1);
		}

		if(gccTracer.BoolValue)
		{
			TF2Attrib_SetByName(iPrimary, "sniper_fires_tracer", 1);
		}

	}

	iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);
	//Do melee stuff here

	TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);

	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon != iPrimary || iActiveWeapon != iMelee)
	{
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimary);	//Set the primary weapon as the active weapon
	}
}

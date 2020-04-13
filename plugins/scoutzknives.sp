#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <SteamWorks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "0.0.2"

#define TFWeapon_Sniper_Rifle 14
#define TFWeapon_Kukri 3

ConVar gcvProtection;
ConVar gcvEndProtection;
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

// Hud Element hiding flags (possibly outdated)
#define	HIDEHUD_WEAPONSELECTION		( 1<<0 )	// Hide ammo count & weapon selection
#define	HIDEHUD_FLASHLIGHT			( 1<<1 )
#define	HIDEHUD_ALL					( 1<<2 )
#define HIDEHUD_HEALTH				( 1<<3 )	// Hide health & armor / suit battery
#define HIDEHUD_PLAYERDEAD			( 1<<4 )	// Hide when local player's dead
#define HIDEHUD_NEEDSUIT			( 1<<5 )	// Hide when the local player doesn't have the HEV suit
#define HIDEHUD_MISCSTATUS			( 1<<6 )	// Hide miscellaneous status elements (trains, pickup history, death notices, etc)
#define HIDEHUD_CHAT				( 1<<7 )	// Hide all communication elements (saytext, voice icon, etc)
#define	HIDEHUD_CROSSHAIR			( 1<<8 )	// Hide crosshairs
#define	HIDEHUD_VEHICLE_CROSSHAIR	( 1<<9 )	// Hide vehicle crosshair
#define HIDEHUD_INVEHICLE			( 1<<10 )
#define HIDEHUD_BONUS_PROGRESS		( 1<<11 )	// Hide bonus progress display (for bonus map challenges)

public Plugin myinfo =
{
	name = "Scoutzknivez replica",
	author = "openDragon",
	description = "A recreation of Darkimmortal's public Scoutzknivez plugin",
	version = PLUGIN_VERSION,
	url = "http://www.opendragon.eu"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] cError, int iErrmax)
{
	char cFolderName[8];
	GetGameFolderName(cFolderName, sizeof(cFolderName));
	
	if(strncmp(cFolderName, "tf", 2, false) != 0)
	{
		strcopy(cError, iErrmax, "Team Fortress 2 only");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	gcvProtection  = CreateConVar("sm_scoutzknivez_spawn", "5", "Time the player is protected after spawning");
	gcvEndProtection  = CreateConVar("sm_scoutzknivez_protection_fire", "1", "Firing the weapon ends the protection");
	gcvBots	= CreateConVar("sm_scoutzknivez_Bots", "", "");
	gcvFall  = CreateConVar("sm_scoutzknivez_fall_damage", "", "");
	gcvAiraccelerate  = CreateConVar("sm_scoutzknivez_airaccelerate", "40", "Replica of sv_airaccelerate");
	gcvHealth  = CreateConVar("sm_scoutzknivez_health", "1", "Health multiplicator");
	gcvLives  = CreateConVar("sm_scoutzknivez_lives", "3", "Amout of live each player has");
	gcvDamage  = CreateConVar("sm_scoutzknivez_damage", "3", "Damage multiplicator");
	gcvScope  = CreateConVar("sm_scoutzknivez_scope", "0", "Enables/Disables the Zoom function");
	gcvPenetrate  = CreateConVar("sm_scoutzknivez_penetrate", "1", "Enables/Disables the penatration of player");
	gcvTracer	= CreateConVar("sm_scoutzknivez_tracer", "1", "Enables/Disables tracer rounds");
	gcvAmmo	= CreateConVar("sm_scoutzknivez_ammo", "25", "Enables/Disables tracer rounds");
	gcvCost	= CreateConVar("sm_scoutzknivez_ammo_cost", "1", "Amount of ammo it costs to fire");
	gcvCostMissed	= CreateConVar("sm_scoutzknivez_ammo_cost_missed", "0", "Additional amount of ammo lost on miss");
	gcvRegeneration	= CreateConVar("sm_scoutzknivez_ammo_regeneration", "0", "Amount of ammo regenerated after 5 seconds");
	gcvTermination	= CreateConVar("sm_scoutzknivez_termination", "0", "Amount of time a player has to find some new ammo, before they get terminated");

	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", EventInventoryApplication, EventHookMode_Post);
}

public void OnMapStart()
{
	char cMapName[128]; //TODO: Replace magic number with something else
	GetCurrentMap(cMapName, sizeof(cMapName));
	
	gbMapSupported = (strncmp(cMapName, "sk_", 3, false) == 0) ? true : false;
	
	if(gbMapSupported)
		SteamWorks_SetGameDescription("ScoutzKnivez");
	else
		SteamWorks_SetGameDescription("Team Fortress");
}

public void EventPlayerSpawn(Event eEvent, const char[] cName, bool dDontBroadcast)
{
	if(!gbMapSupported)
		return;

	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	if(gcvProtection.FloatValue > 0)
		TF2_AddCondition(iClient, TFCond_Ubercharged, gcvProtection.FloatValue);
}

public void EventInventoryApplication(Event eEvent, const char[] cName, bool dDontBroadcast)
{
	if(!gbMapSupported)
		return;
	
	int iClient = GetClientOfUserId(eEvent.GetInt("userid"));
	
	// Hide some HUD elements
	
	any aFlags = GetEntProp(iClient, Prop_Send, "m_iHideHUD");
	aFlags |= HIDEHUD_CROSSHAIR;
	aFlags |= HIDEHUD_VEHICLE_CROSSHAIR;
	SetEntProp(iClient, Prop_Send, "m_iHideHUD", aFlags);
	
	int iPrimary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);

	// TODO: Does not remove Attributes set by Valve. :/
	TF2Attrib_RemoveAll(iPrimary);
	
	if(gcvCost.FloatValue > 0)
		TF2Attrib_SetByName(iPrimary, "mod ammo per shot", gcvCost.FloatValue);
	
	if(gcvRegeneration.FloatValue > 0)
		TF2Attrib_SetByName(iPrimary, "ammo regen", gcvRegeneration.FloatValue / gcvAmmo.FloatValue);
	
	if(gcvPenetrate.BoolValue)
		TF2Attrib_SetByName(iPrimary, "shot penetrate all players", 1.0);

	if(gcvTracer.BoolValue)
		TF2Attrib_SetByName(iPrimary, "sniper fires tracer", 1.0);
		
	//Do melee stuff here
	int iMelee = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee);

	// BUG : Does not remove passive weapons (e.g. Cozy camper)
	TF2_RemoveWeaponSlot(iClient, TFWeaponSlot_Secondary);

	// Prevent the "civilian" glitch by forcing a active weapon
	int iActiveWeapon = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
	if(iActiveWeapon != iPrimary && iActiveWeapon != iMelee)
		SetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon", iPrimary);	
}

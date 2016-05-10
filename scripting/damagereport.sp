#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo =
{
	name = "Damage report",
	author = "Scooby",
	description = "Reports who damaged you and who you damaged",
	version = PLUGIN_VERSION,
};

new g_DamageDone[MAXPLAYERS+1][MAXPLAYERS+1];
new g_HitsDone[MAXPLAYERS+1][MAXPLAYERS+1];
new g_DamageTaken[MAXPLAYERS+1][MAXPLAYERS+1];
new g_HitsTaken[MAXPLAYERS+1][MAXPLAYERS+1];
new g_KilledPlayer[MAXPLAYERS+1][MAXPLAYERS+1];
new String:g_PlayerName[MAXPLAYERS+1][32];

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", EventRoundStart);
}

public OnMapEnd()
{
	clearAllDamageData();
}

// Initializations to be done at the beginning of the round
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	clearAllDamageData();
}

// In this event we store how much damage attacker did to victim in one array
// and how much damage victim took from attacker in another array
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new healthDmg = GetEventInt(event,"dmg_health");
	
	new victim_id = GetEventInt(event, "userid");
	new attacker_id = GetEventInt(event, "attacker");

	new victim = GetClientOfUserId(victim_id);
	new attacker = GetClientOfUserId(attacker_id);
	
	// Log damage taken to the victim and damage done to the attacker
	g_DamageDone[attacker][victim] += healthDmg;
	g_HitsDone[attacker][victim]++;

	g_DamageTaken[victim][attacker] += healthDmg;
	g_HitsTaken[victim][attacker]++;
}

BuildDamageString(in_victim)
{
	new OurTeam = GetClientTeam(in_victim);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) != OurTeam && i != in_victim) {
			// Only show spectators in report if they have given or taken damage
			if (IsClientObserver(i) && g_HitsTaken[in_victim][i] == 0 && g_HitsDone[in_victim][i] == 0) {
				continue;
			}
		
			new playerHP = GetClientHealth(i);
			new String:damageReport[512];
			
			Format(damageReport, sizeof(damageReport), ">> (%d dmg / %d hits) to (%d dmg / %d hits) from %s (%d hp) \n", g_DamageDone[in_victim][i], g_HitsDone[in_victim][i], g_DamageTaken[in_victim][i], g_HitsTaken[in_victim][i], g_PlayerName[i], playerHP );
			if (strcmp(damageReport, "", false) != 0) {
				PrintToChat(in_victim, "\x04%s", damageReport);
			}
		}
	}
}

// Store the name of the player at time of spawn. If player disconnects before
// round end, the name can still be displayed in the damage reports.
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event,"userid");
	new client = GetClientOfUserId(userid);

	// Store Player names if they disconnect before round has ended
	new String:clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	strcopy(g_PlayerName[client], sizeof(g_PlayerName[]), clientName);
}

public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	// reason 16 is game commencing
	// other reasons are real round ends
	new reason = GetEventInt(event, "reason");
	
	if (reason == 16) {
		return;
	}

	for (new i = 1; i <= MaxClients; i++)
	{ 
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) {
			BuildDamageString(i);
		}
	}

}

clearAllDamageData()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		for (new j = 1; j <= MaxClients; j++)
		{
			g_DamageDone[i][j]=0;
			g_DamageTaken[i][j]=0;
			g_HitsDone[i][j]=0;
			g_HitsTaken[i][j]=0;
			g_KilledPlayer[i][j]=0;
		}
	}
}

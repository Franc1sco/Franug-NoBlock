/*  SM Franug NoBlock
 *
 *  Copyright (C) 2017 Francisco 'Franc1sco' García
 * 
 * This program is free software: you can redistribute it and/or modify it
 * under the terms of the GNU General Public License as published by the Free
 * Software Foundation, either version 3 of the License, or (at your option) 
 * any later version.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT 
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License along with 
 * this program. If not, see http://www.gnu.org/licenses/.
 */

#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#pragma semicolon 1

#define VERSION "1.2"


new Handle:sm_noblock_cts;
new Handle:sm_noblock_ts;
new Handle:sm_noblock_time;
new Handle:noblock2time;


new bool:g_ShouldCollide[MAXPLAYERS+1] = { true, ... };
new bool:g_IsNoBlock[MAXPLAYERS+1] = {false, ...};
new bool:g_IsNoBlock2[MAXPLAYERS+1] = {false, ...};

new Veces[MAXPLAYERS+1] = 0;
Handle timers[MAXPLAYERS + 1];

new Handle:g_timer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "SM Franug NoBlock",
	author = "Franc1sco franug",
	description = "",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{

	HookEvent("round_freeze_end", Event_RoundStart, EventHookMode_Post);

	HookEvent("player_spawn", PlayerSpawn);

	CreateConVar("Franug-Noblock", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	sm_noblock_cts = CreateConVar("sm_noblock_cts", "1", "CT max for noblock in round start");
	sm_noblock_ts = CreateConVar("sm_noblock_ts", "1", "Ts max for noblock in round start");

	sm_noblock_time = CreateConVar("sm_noblock_time", "6.0", "Secods of first noblock (low value because can cause Mayhem bug).");

	noblock2time = CreateConVar("sm_noblock2_time", "10.0", "Seconds of secondary noblock");

	RegConsoleCmd("sm_noblock", DONoBlock);
	RegConsoleCmd("sm_nb", DONoBlock);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	new Ts, CTs;
	for(new i=1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			switch(GetClientTeam(i)) {				
				case CS_TEAM_T: Ts++;				
				case CS_TEAM_CT: CTs++;			
			}
		}
	}

	if (Ts > GetConVarInt(sm_noblock_ts) && CTs > GetConVarInt(sm_noblock_cts))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
				PrintToChat(i, " \x04[NoBlock]\x01 You have %i seconds of primary NoBlock", GetConVarInt(sm_noblock_time));
                                    
				g_IsNoBlock[i] = true;
                                    
			}
		}
		if (g_timer != INVALID_HANDLE)KillTimer(g_timer);
		
		g_timer = CreateTimer(GetConVarFloat(sm_noblock_time), DesactivadoNB);
	}
}

public Action:DesactivadoNB(Handle:timer)
{
	g_timer = INVALID_HANDLE;
	for (new client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client))
		{
			if (g_IsNoBlock[client])
			{
				SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
				PrintToChat(client, " \x04[NoBlock]\x01 Now you have %i seconds of secondary NoBlock", GetConVarInt(noblock2time));
				g_IsNoBlock[client] = false;

				Veces[client] = GetConVarInt(noblock2time);
				CreateTimer(1.0, Repetidor, client, TIMER_REPEAT);
				g_IsNoBlock2[client] = true;
			}
		}
	}
}

public Action:DesactivadoNB2(Handle:timer, any:client)
{
   if (IsClientInGame(client) && IsPlayerAlive(client))
   {
     if (g_IsNoBlock2[client])
     {
         g_IsNoBlock2[client] = false;
         PrintToChat(client, " \x04[NoBlock]\x01 Now you dont have NoBlock");
     }
   }
}

 

public Action:DONoBlock(client,args)
{
   if (IsClientInGame(client) && IsPlayerAlive(client) && !g_IsNoBlock[client])
   {
         //SetEntData(client, g_offsCollisionGroup, 2, 4, true);
         PrintToChat(client, " \x04[NoBlock]\x01 You have %i seconds of NoBlock", GetConVarInt(noblock2time));
         CreateTimer(GetConVarInt(noblock2time) * 1.0, DesactivadoNB2, client);
         g_IsNoBlock2[client] = true;
   }
   else
   {
         PrintToChat(client, " \x04[NoBlock]\x01 You already have NoBlock or you are dead");
   }
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_IsNoBlock[client] = false;
	g_IsNoBlock2[client] = false;
	OnClientDisconnect(client);
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_ShouldCollide, ShouldCollide);
	SDKHook(client, SDKHook_StartTouch, Touch);
	SDKHook(client, SDKHook_Touch, Touch);
	SDKHook(client, SDKHook_EndTouch, EndTouch);
}





public bool:ShouldCollide(entity, collisiongroup, contentsmask, bool:result)
{
		
	if (contentsmask == 33636363)
	{
		return g_ShouldCollide[entity];
	}
	
	return true;
}

public Touch(ent1, ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

	if(g_IsNoBlock2[ent1])
	{
		Veces[ent1] = GetConVarInt(noblock2time);
		g_ShouldCollide[ent1] = false;
		g_ShouldCollide[ent2] = false;
	}
}

public OnClientDisconnect(client)
{
	if (timers[client] != INVALID_HANDLE)KillTimer(timers[client]);
	
	timers[client] = INVALID_HANDLE;
}

public EndTouch(ent1, ent2)
{

	if(ent1 == ent2)
		return;
	if(ent1 > MaxClients || ent1 == 0)
		return;
	if(ent2 > MaxClients || ent2 == 0)
		return;

	if(!g_ShouldCollide[ent1])
	{
		if (timers[ent1] != INVALID_HANDLE)KillTimer(timers[ent1]);
		timers[ent1] = CreateTimer(3.0, TurnOnCollision, ent1);
	}

	if(!g_ShouldCollide[ent2])
	{
		if (timers[ent2] != INVALID_HANDLE)KillTimer(timers[ent2]);
		timers[ent2] = CreateTimer(3.0, TurnOnCollision, ent2);
	}
} 

public Action:TurnOnCollision(Handle:timer, any:client)
{
	timers[client] = INVALID_HANDLE;
	if (IsClientInGame(client) && IsPlayerAlive(client) && !g_ShouldCollide[client])
		g_ShouldCollide[client] = true;

} 

public Action:Repetidor(Handle:timer, any:client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
	{
		return Plugin_Stop;
	}

	if (Veces[client] == 0)
	{
		g_IsNoBlock2[client] = false;
		PrintToChat(client, " \x04[NoBlock]\x01 Now you dont have NoBlock");
		return Plugin_Stop;
	}

	else if(!g_IsNoBlock2[client])
	{
		return Plugin_Stop;
	}

	Veces[client] -= 1;

	return Plugin_Continue;
}

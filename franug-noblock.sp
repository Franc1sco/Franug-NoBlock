#include <sourcemod>
#include <cstrike>
#include <sdktools>
#include <sdkhooks>


#pragma semicolon 1

#define VERSION "v1.0"


new Handle:sm_noblock_cts;
new Handle:sm_noblock_ts;
new Handle:sm_noblock_time;
new Handle:noblock2time;


new bool:g_ShouldCollide[MAXPLAYERS+1] = { true, ... };
new bool:g_IsNoBlock[MAXPLAYERS+1] = {false, ...};
new bool:g_IsNoBlock2[MAXPLAYERS+1] = {false, ...};

new Veces[MAXPLAYERS+1] = 0;



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

	HookEvent("round_start", Event_RoundStart, EventHookMode_Post);

	HookEvent("player_spawn", PlayerSpawn);

	CreateConVar("Franug-Noblock", VERSION, "", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	sm_noblock_cts = CreateConVar("sm_noblock_cts", "1", "CT max for noblock in round start");
	sm_noblock_ts = CreateConVar("sm_noblock_ts", "1", "Ts max for noblock in round start");

	sm_noblock_time = CreateConVar("sm_noblock_time", "6", "Secods of first noblock (low value because can cause Mayhem bug).");

	noblock2time = CreateConVar("sm_noblock2_time", "10.0", "Seconds of secondary noblock");

	RegConsoleCmd("sm_noblock", DONoBlock);
	RegConsoleCmd("sm_nb", DONoBlock);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{

	new Ts, CTs;
	for(new i=1; i <= MaxClients; i++)
	{
		if ( (IsValidClient(i)) && (IsPlayerAlive(i)) )
		{
			if (GetClientTeam(i) == CS_TEAM_T)
				Ts++;
			else if (GetClientTeam(i) == CS_TEAM_CT)
				CTs++;
			}
		}

	if ((Ts > GetConVarInt(sm_noblock_ts)) && (CTs > GetConVarInt(sm_noblock_cts)))
	{
		for (new i = 1; i < GetMaxClients(); i++)
		{
			if ((IsValidClient(i)) && (IsPlayerAlive(i)))
			{
				SetEntProp(i, Prop_Data, "m_CollisionGroup", 2);
				PrintToChat(i, " \x04[NoBlock]\x01 You have %i seconds of NoBlock", GetConVarInt(noblock2time));
                                    
				g_IsNoBlock[i] = true;
                                    
			}
		}
		CreateTimer(GetConVarInt(sm_noblock_time) * 1.0, DesactivadoNB);
	}
}

public Action:DesactivadoNB(Handle:timer)
{
 for (new client = 1; client < GetMaxClients(); client++)
 {
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
   {
     if (g_IsNoBlock[client])
     {
         SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
         PrintToChat(client, " \x04[NoBlock]\x01 Now you dont have NoBlock");
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
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != 1)
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
   if (IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && !g_IsNoBlock[client])
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

  if (IsValidClient(client) && GetClientTeam(client) > 1 && IsPlayerAlive(client))
  {
    if (g_IsNoBlock[client])
    {
      g_IsNoBlock[client] = false;
    }
    if (g_IsNoBlock2[client])
    {
      g_IsNoBlock2[client] = false;
    }
  }
}

public IsValidClient( client ) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
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
		
		if(!g_ShouldCollide[entity])
		{
			result = false;
			return false;
		}
		else
		{
			result = true;
			return true;
		}
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
            CreateTimer(3.0, TurnOnCollision, ent1);
	}

	if(!g_ShouldCollide[ent2])
	{
            CreateTimer(3.0, TurnOnCollision, ent2);
	}
} 

public Action:TurnOnCollision(Handle:timer, any:client)
{
    if (IsClientInGame(client) && IsPlayerAlive(client) && !g_ShouldCollide[client])
        g_ShouldCollide[client] = true;
        
    return Plugin_Handled;
} 

public Action:Repetidor(Handle:timer, any:client)
{
        if (!IsValidClient(client) || GetClientTeam(client) == 1 || !IsPlayerAlive(client))
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
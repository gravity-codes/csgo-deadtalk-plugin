#include <sourcemod>
#include <sdktools>
#include <sdktools_voice.inc>

#define VERSION "0.0.1"

#define DEBUG "if(GetConVarBool(Cvar_Debug)) dbg_print"

float CALLOUT_TIME = 5.0; //Easy change how long before a dead player is put in Deadtalk

new Handle:Cvar_Deadtalk = INVALID_HANDLE;
new Handle:Cvar_Debug = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "Bazooka's Deadtalk Plugin",
    description = "Plugin that enables the deadtalk function. Dead players can talk to and hear all other dead players, while also hearing their team; live players do not hear dead teammates.",
    author = "bazooka",
    version = VERSION,
    url = "https://github.com/bazooka-codes"
};

public OnPluginStart()
{
    CreateConVar("sm_deadtalk_version", VERSION,"Bazooka's deadtalk plugin version", 0, false, 0.0, false, 0.0);
    Cvar_Deadtalk = CreateConVar("sm_deadtalk", "1", "1 - Deadtalk enabled | 0 - Deadtalk disabled", 0, false, 0.0, false, 0.0);
    Cvar_Debug = CreateConVar("sm_deadtalk_debug", "1", "1 - Deadtalk debug enabled | 0 - Deadtalk debug disabled", 0, false, 0.0, false, 0.0);
}

public OnMapStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
}

public OnEventShutdown()
{
    UnhookEvent("player_spawn", Event_PlayerSpawn);
    UnhookEvent("player_death", Event_PlayerDeath);
}

public void Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        return;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get client that spawned

    //loop through every other client in server
    for(int otherClient = 1; otherClient <= MaxClients; otherClient++)
    {
        if(!IsClientInGame(otherClient) || client == otherClient)
        {
            //Ignore if other client disconnected or found own client
            continue;
        }

        SetListenOverride(client, otherClient, Listen_Default); //Client listens to otherClient = default
    }
}

public void Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        return;
    }

    int userid = GetEventInt(event, "userid"); //Get user that died

    PrintToChat(userid, "Deadtalk: You now have %f seconds to callout before deadtalk begins.", CALLOUT_TIME);
    CreateTimer(CALLOUT_TIME, deadtalk_timer, userid); //Timer of 5, when expires invokes deadtalk_timer function
}

public Action deadtalk_timer(Handle:timer, any:userid)
{
    PrintToChat(userid, "Deadtalk: Now in deadtalk. Live teammates cannot hear you, but you may talk with all other dead players.");

    int client = GetClientOfUserId(userid);

    for(int otherClient = 1; otherClient <= MaxClients; otherClient++)
    {
        if(!IsClientInGame(otherClient) || otherClient == client)
        {
            //Ignore if other client not in game or found own client
            continue;
        }

        if(!IsPlayerAlive(otherClient))
        {
            //If other client is also dead, set clients can hear each other
            SetListenOverride(client, otherClient, Listen_Yes);
            SetListenOverride(otherClient, client, Listen_Yes);
        }

        if(GetClientTeam(otherClient) == GetClientTeam(client)) //Clients are on same team
        {
            //Dead clients can still hear clients on their own team
            SetListenOverride(client, otherClient, Listen_Yes);
        }
    }

    return Action:0;
}

public void dbg_print(char[] str)
{
    PrintToServer("DEBUG (Deadtalk Plugin): %s\n", str);
}

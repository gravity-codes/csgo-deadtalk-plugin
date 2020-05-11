#include <sourcemod>
#include <sdktools>

#define VERSION "1.0.0"

float CALLOUT_TIME = 5.0; //Easy change how long before a dead player is put in Deadtalk

Handle Cvar_Deadtalk = INVALID_HANDLE;
Handle Cvar_Debug = INVALID_HANDLE;

public Plugin myinfo =
{
    name = "Bazooka's Deadtalk Plugin",
    description = "Plugin that enables the deadtalk function. Dead players can talk to and hear all other dead players, while also hearing their team; live players do not hear dead teammates.",
    author = "bazooka",
    version = VERSION,
    url = "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
    CreateConVar("sm_deadtalk_version", VERSION,"Bazooka's deadtalk plugin version");
    Cvar_Deadtalk = CreateConVar("sm_deadtalk_enable", "1", "1 - Enable deadtalk | 0 - Disable deadtalk");
    Cvar_Debug = CreateConVar("sm_deadtalk_debug", "0", "1 - Deadtalk debug enabled | 0 - Deadtalk debug disabled");

    HookEvent("player_spawn", Event_PlayerSpawn);
    HookEvent("player_death", Event_PlayerDeath);
}

public void OnEventShutdown()
{
    UnhookEvent("player_spawn", Event_PlayerSpawn);
    UnhookEvent("player_death", Event_PlayerDeath);
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        return Plugin_Stop;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get client that spawned

    //loop through every other client in server
    for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
    {
        if(!IsClientInGame(otherClient) || client == otherClient)
        {
            //Ignore if other client disconnected or found own client
            continue;
        }

        SetListenOverride(client, otherClient, Listen_Default); //Client listens to otherClient = default
    }

    return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        return Plugin_Stop;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get the client that died

    if(!IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    PrintToChat(client, "Deadtalk: You now have %.1f seconds to callout before deadtalk begins.", CALLOUT_TIME);
    CreateTimer(CALLOUT_TIME, deadtalk_timer, client); //Timer of 5, when expires invokes deadtalk_timer function

    return Plugin_Continue;
}

public Action deadtalk_timer(Handle timer, any client)
{
    if(!IsClientInGame(client))
    {
        return Plugin_Continue;
    }

    PrintToChat(client, "Deadtalk: Now in deadtalk. Live teammates cannot hear you, but you may talk with all other dead players.");

    for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
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
            //Dead clients can still hear clients on their own team, but live teammates cant hear dead
            SetListenOverride(client, otherClient, Listen_Yes);
            SetListenOverride(otherClient, client, Listen_No);
        }
    }

    return Plugin_Continue;
}

//Function used to make debugging easier
public void dbg_print(char[] str)
{
    if(GetConVarBool(Cvar_Debug))
        PrintToServer("DEBUG (Deadtalk Plugin): %s\n", str);
}

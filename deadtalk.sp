#include <sourcemod>
#include <sdktools>

#define VERSION "0.2.2"

//Helper debug printer; Ex: DEBUG("Hello."); == "DEBUG (Deadtalk Plugin): Hello." in console
//#define DEBUG "if(GetConVarBool(Cvar_Debug)) dbg_print"

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
    Cvar_Debug = CreateConVar("sm_deadtalk_debug", "1", "1 - Deadtalk debug enabled | 0 - Deadtalk debug disabled");
}

public void OnMapStart()
{
    HookEvent("player_spawn", Event_PlayerSpawn);
    dbg_print("Player spawn event hooked.");
    HookEvent("player_death", Event_PlayerDeath);
    dbg_print("Player death event hooked.");
}

public void OnEventShutdown()
{
    UnhookEvent("player_spawn", Event_PlayerSpawn);
    UnhookEvent("player_death", Event_PlayerDeath);
    dbg_print("All events unhooked.");
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
    dbg_print("Player has spawned.");
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        dbg_print("Deadtalk not currently running.");
        return Plugin_Stop;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get client that spawned

    //loop through every other client in server
    for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
    {
        if(!IsClientInGame(otherClient) || client == otherClient)
        {
            if(!IsClientInGame(otherClient))
            {
                PrintToServer("Client %i not in game.", otherClient);
            }
            if(client == otherClient)
            {
                dbg_print("Found own client.");
            }
            //Ignore if other client disconnected or found own client
            continue;
        }

        dbg_print("Allows client to listen to one client.");
        SetListenOverride(client, otherClient, Listen_Default); //Client listens to otherClient = default
    }

    return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
    dbg_print("Player has died.");
    if(GetConVarInt(Cvar_Deadtalk) != 1) //Plugin is disabled
    {
        dbg_print("Plugin is not running.")
        return Plugin_Stop;
    }

    int client = GetClientOfUserId(GetEventInt(event, "userid")); //Get the client that died

    if(!IsClientInGame(client))
    {
        dbg_print("Client not in game.");
        return Plugin_Continue;
    }

    PrintToChat(client, "Deadtalk: You now have %f seconds to callout before deadtalk begins.", CALLOUT_TIME);
    dbg_print("Player notified that recently died.");
    CreateTimer(CALLOUT_TIME, deadtalk_timer, client); //Timer of 5, when expires invokes deadtalk_timer function
    dbg_print("Timer started.");

    return Plugin_Continue;
}

public Action deadtalk_timer(Handle timer, any client)
{
    if(!IsClientInGame(client))
    {
        dbg_print("Client not in game.");
        return Plugin_Continue;
    }

    PrintToChat(client, "Deadtalk: Now in deadtalk. Live teammates cannot hear you, but you may talk with all other dead players.");
    dbg_print("Client now in deadtalk.");

    for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
    {
        if(!IsClientInGame(otherClient) || otherClient == client)
        {
            //Ignore if other client not in game or found own client
            dbg_print("Found own client.");
            continue;
        }

        if(!IsPlayerAlive(otherClient))
        {
            dbg_print("Allowing client to hear other dead client.");
            //If other client is also dead, set clients can hear each other
            SetListenOverride(client, otherClient, Listen_Yes);
            SetListenOverride(otherClient, client, Listen_Yes);
        }

        if(GetClientTeam(otherClient) == GetClientTeam(client)) //Clients are on same team
        {
            dbg_print("Allowed client to hear teammate.");
            //Dead clients can still hear clients on their own team
            SetListenOverride(client, otherClient, Listen_Yes);
        }
    }

    return Plugin_Continue;
}

public void dbg_print(char[] str)
{
    if(GetConVarBool(Cvar_Debug))
        PrintToServer("DEBUG (Deadtalk Plugin): %s\n", str);
}

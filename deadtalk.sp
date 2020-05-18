/*
   - v1.2.0 Stable and working with colors and added WiT Retake branding and features
   - Next: Adding mode, where you can control what type of deadtalk is running
*/

#include <sourcemod>
#include <sdktools>
#include <multicolors>
#include <clientprefs>

#define VERSION "1.2.1"
#pragma newdecls required

float CALLOUT_TIME = 5.0; //Easy change how long before a dead player is put in Deadtalk
char DEADTALK_USAGE[] = {"Type \"!dt\" | \"!deadtalk\" <(on/1) | (off/0)> to change your deadtalk preference."};
char DTNOTIF_USAGE[] = {"Type \"!dt_notif\" or \"!deadtalk_notif\" to toggle deadtalk notifications."};

Handle Cvar_Deadtalk = INVALID_HANDLE; //Stores if plugin is enabled
Handle Cvar_Mode = INVALID_HANDLE; //Stores plugin mode
Handle DeadtalkCookie; //Stores the client preference cookie for deadtalk
Handle DTNotifCookie; //Stores the client notification cookie for deadtalk

public Plugin myinfo =
{
   name = "[WiT] Gaming Deadtalk",
   description = "Plugin developed for [WiT] Gaming that enables the deadtalk function. Dead players can talk to and hear all other dead players, while also hearing their team; live players do not hear dead teammates.",
   author = "bazooka",
   version = VERSION,
   url = "https://github.com/bazooka-codes"
};

public void OnPluginStart()
{
   //Setup convars
   CreateConVar("sm_deadtalk_version", VERSION,"Bazooka's deadtalk plugin version");
   Cvar_Deadtalk = CreateConVar("sm_deadtalk_enable", "1", "1 - Enable deadtalk | 0 - Disable deadtalk");
   Cvar_Mode = CreateConVar("sm_deadtalk_mode", "2", "1 - Deadtalk is server wide (no options) | 2 - Deadtalk is individual based (enable options) | 0 - Debug mode");

   //Setup server commands
   RegConsoleCmd("sm_deadtalk", DeadtalkToggle, "Will change client's deadtalk preference based off args or display current value.");
   RegConsoleCmd("sm_dt", DeadtalkToggle, "Will change client's deadtalk preference based off args or display current value.");
   RegConsoleCmd("sm_dt_notif", ToggleNotifications, "Toggles Deadtalk notifications.");
   RegConsoleCmd("sm_deadtalk_notif", ToggleNotifications, "Toggles Deadtalk notifications.");

   //Setup cookies
   DeadtalkCookie = RegClientCookie("deadtalk_preference_cookie", "1 - Client has deadtalk enabled | 0 - Client has deadtalk disabled", CookieAccess_Protected);
   DTNotifCookie = RegClientCookie("deadtalk_notifications_cookie", "1 - Client wants notifications | 0 - Client does not want notifications", CookieAccess_Protected);

   //Setup hooks
   HookEvent("player_spawn", Event_PlayerSpawn);
   HookEvent("player_death", Event_PlayerDeath);
}

public void OnEventShutdown()
{
   UnhookEvent("player_spawn", Event_PlayerSpawn);
   UnhookEvent("player_death", Event_PlayerDeath);
}

public Action DeadtalkToggle(int client, int args)
{
   if(args == 0)
   {
      //!deadtalk; client checking preference
      char clientName[MAX_NAME_LENGTH];
      GetClientName(client, clientName, sizeof(clientName));

      if(getDeadtalkPrefs(client) == -1)
      {
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Client: %s's deadtalk preference not found.", clientName);
      }
      else if(getDeadtalkPrefs(client) == 0)
      {
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Client: %s's deadtalk preference: 0(disabled).", clientName);
      }
      else if(getDeadtalkPrefs(client) == 1)
      {
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Client: %s's deadtalk preference: 1(enabled).", clientName);
      }
      else
      {
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}ERROR - While finding deadtalk preference.");
      }

      //Show clients how to change their preference
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}%s", DEADTALK_USAGE);
      return Plugin_Continue;
   }
   else if(args != 1)
   {
      //!deadtalk ____ ____; invalid syntax
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}ERROR - Invalid syntax. Usage: %s", DEADTALK_USAGE);
      return Plugin_Handled;
   }

   //Get the argument the client entered
   char choice[10];
   GetCmdArg(1, choice, sizeof(choice));

   if(StrEqual(choice, "off", false) || StrEqual(choice, "0", false))
   {
      //!deadtalk off | !deadtalk 0; client disabling deadtalk
      if(getDeadtalkPrefs(client) == -1)
      {
         //New client found; add new client with deadtalk off
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         setDeadtalkPrefs(client, 0);
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}No stored preference detected. Added new client: %s with Deadtalk preference of 0(disabled).", clientName);

         if(IsClientInGame(client) && !IsPlayerAlive(client))
         {
            CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}New deadtalk preference will take effect next round.");
         }
      }
      else if(getDeadtalkPrefs(client) == 0)
      {
         //Client with deadtalk off tried disabling again
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Client: %s already has preference of 0(disabled)", clientName);
      }
      else if(getDeadtalkPrefs(client) == 1)
      {
         //Client with deadtalk off is turning it on
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         setDeadtalkPrefs(client, 0);
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default} Updated client: %s with preference of 0(disabled).", clientName);

         if(IsClientInGame(client) && !IsPlayerAlive(client))
         {
            CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}New deadtalk preference will take effect next round.");
         }
      }
   }
   else if(StrEqual(choice, "on", false) || StrEqual(choice, "1", false))
   {
      //!deadtalk on | !deadtalk 1; client enabling
      if(getDeadtalkPrefs(client) == -1)
      {
         //Found new client; add new client with deadtalk on
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         setDeadtalkPrefs(client, 1);
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}No stored preference detected. Added new client: %s with Deadtalk preference of 0(disabled).", clientName);

         if(IsClientInGame(client) && !IsPlayerAlive(client))
         {
            CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}New deadtalk preference will take effect next round.");
         }
      }
      else if(getDeadtalkPrefs(client) == 0)
      {
         //Client with deadtalk off is turning it on
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         setDeadtalkPrefs(client, 1);
         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Updated client: %s with deadtalk preference of 1(enabled).", clientName);

         if(IsClientInGame(client) && !IsPlayerAlive(client))
         {
            CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}New deadtalk preference will take effect next round.");
         }
      }
      else if(getDeadtalkPrefs(client) == 1)
      {
         //Client with deadtalk off is trying to turn it on again
         char clientName[MAX_NAME_LENGTH];
         GetClientName(client, clientName, sizeof(clientName));

         CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Client: %s already has preference of 1(enabled).", clientName);
      }
   }
   else
   {
      //!deadtalk <something not accepted>; Invalid syntax
      CReplyToCommand(client, "{orchid} [WiT] Gaming Deadtalk: {default}ERROR - Invalid argument. Usage: %s", DEADTALK_USAGE);
      return Plugin_Handled;
   }

   return Plugin_Continue;
}

public Action ToggleNotifications(int client, int args)
{
   if(args != 0)
   {
      //!dt_notif ____; Invalid syntax
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Invalid syntax. Usage: %s", DTNOTIF_USAGE);

      return Plugin_Handled;
   }

   int clientPref = getDTNotifPrefs(client);
   char clientName[MAX_NAME_LENGTH];
   GetClientName(client, clientName, sizeof(clientName));

   if(clientPref == -1)
   {
      //New client cookie; add new client and toggle off notifs
      setDTNotifPrefs(client, 0);
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Unable to locate notification preferences. Added new client: %s with notifications {darkred}OFF{default}.", clientName);
   }
   else if(clientPref == 0)
   {
      //Client has notifications off; wants to toggle them on
      setDTNotifPrefs(client, 1);
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Toggled client: %s's notifications {green}ON{default}.", clientName);
   }
   else if(clientPref == 1)
   {
      //Client has notifications on; wants to toggle them off
      setDTNotifPrefs(client, 0);
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}Toggled client: %s's notifications {darkred}OFF{default}.", clientName);
   }
   else
   {
      CReplyToCommand(client, "{orchid}[WiT] Gaming Deadtalk: {default}ERROR - Unable to toggle notifications.");
   }

   return Plugin_Continue;
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

   if(getDTNotifPrefs(client) == 1 || getDTNotifPrefs(client) == -1)
   {
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}You currently have deadtalk notifications enabled; to toggle off: %s", DTNOTIF_USAGE);
   }

   if(getDTNotifPrefs(client) == 0)
   {
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}You currently have notifications disabled; to toggle on: %s", DTNOTIF_USAGE);
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

   if(!IsClientInGame(client) || IsPlayerAlive(client))
   {
      return Plugin_Continue;
   }

   if(getDeadtalkPrefs(client) == 0 || getDeadtalkPrefs(client) == -1)
   {
      //If client has deadtalk disabled, ignore their death; alert them how to enable
      if(getDTNotifPrefs(client) == 1 || getDTNotifPrefs(client) == -1)
      {
         //Only print if client has notifications enabled
         CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}Deadtalk currently disabled. %s", DEADTALK_USAGE);
      }

      return Plugin_Continue;
   }

   if(getDTNotifPrefs(client) == 1 || getDTNotifPrefs(client) == -1)
   {
      //Only print if client has notifications on
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}You now have %.0f seconds to callout before deadtalk begins.", CALLOUT_TIME);
   }

   CreateTimer(CALLOUT_TIME, deadtalk_timer, client);

   return Plugin_Continue;
}

public Action deadtalk_timer(Handle timer, any client)
{
   if(!IsClientInGame(client) || IsPlayerAlive(client))
   {
      return Plugin_Continue;
   }

   if(getDTNotifPrefs(client) == 1 || getDTNotifPrefs(client) == -1) //Client gets notifs
   {
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}Now in deadtalk. Live teammates cannot hear you, but you may talk with all other dead players.");
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}To turn off: %s", DEADTALK_USAGE);
   }

   if(getDTNotifPrefs(client) == 0) //Client disabled notifs
   {
      CPrintToChat(client, "{orchid}[WiT] Gaming Deadtalk: {default}Deadtalk on.");
   }

   for(int otherClient = 1; otherClient <= GetClientCount(true); otherClient++)
   {
      if(!IsClientInGame(otherClient) || otherClient == client)
      {
         //Ignore if other client not in game or found own client
         continue;
      }

      if(!IsPlayerAlive(otherClient))
      {
         if(getDeadtalkPrefs(otherClient) == -1 || getDeadtalkPrefs(otherClient) == 0)
         {
            //If other client is dead with deadtalk disabled, set to not able to hear each other
            SetListenOverride(client, otherClient, Listen_No);
            SetListenOverride(otherClient, client, Listen_No);
         }

         //If other client is also dead with deadtalk enabled, set clients can hear each other
         SetListenOverride(client, otherClient, Listen_Yes);
         SetListenOverride(otherClient, client, Listen_Yes);
      }
      else if(GetClientTeam(otherClient) == GetClientTeam(client)) //Clients are on same team
      {
         //Dead clients can still hear clients on their own team, but live teammates cant hear dead
         SetListenOverride(client, otherClient, Listen_Yes);
         SetListenOverride(otherClient, client, Listen_No);
      }
   }

   return Plugin_Continue;
}

public int setDeadtalkPrefs(int client, int value)
{
   if(AreClientCookiesCached(client))
   {
      char cookieString[12];
      IntToString(value, cookieString, sizeof(cookieString));
      SetClientCookie(client, DeadtalkCookie, cookieString);

      return value;
   }

   return -1;
}

public int getDeadtalkPrefs(int client)
{
   if(AreClientCookiesCached(client))
   {
      char cookieValue[12];
      GetClientCookie(client, DeadtalkCookie, cookieValue, sizeof(cookieValue));

      return StringToInt(cookieValue);
   }

   return -1;
}

public int setDTNotifPrefs(int client, int value)
{
   if(AreClientCookiesCached(client))
   {
      char cookieString[12];
      IntToString(value, cookieString, sizeof(cookieString));
      SetClientCookie(client, DTNotifCookie, cookieString);

      return value;
   }

   return -1;
}

public int getDTNotifPrefs(int client)
{
   if(AreClientCookiesCached(client))
   {
      char cookieValue[12]
      GetClientCookie(client, DTNotifCookie, cookieValue, sizeof(cookieValue));

      return StringToInt(cookieValue);
   }

   return -1;
}

//Function used to make debugging easier
public void dbg_print(char[] str)
{
   if(GetConVarInt(Cvar_Mode) == 0)
      PrintToServer("DEBUG (Deadtalk Plugin): %s\n", str);
}

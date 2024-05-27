#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Landfix AutoToggler"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_AUTHOR "Wool"

new Handle:g_hJumps[MAXPLAYERS + 1];
new Handle:g_hJumpCounts[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = "Executes a command on the specified jump",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_lftoggle", Command_lfToggle, "Toggle the jump counter");
    HookEvent("player_jump", Event_PlayerJump);

    for (int i = 1; i <= MaxClients; i++)
    {
        g_hJumps[i] = INVALID_HANDLE;
        g_hJumpCounts[i] = INVALID_HANDLE;
    }
}

public Action:Command_lfToggle(client, args)
{
    if (args < 1)
    {
        PrintToChat(client, "Usage: !lftoggle <number>");
        return Plugin_Handled;
    }
    
    new String:arg[10];
    GetCmdArg(1, arg, sizeof(arg));
    new jumps = StringToInt(arg);

    if (jumps <= 0)
    {
        PrintToChat(client, "Please enter a valid number greater than 0.");
        return Plugin_Handled;
    }

    // Close any existing handles for the client
    if (g_hJumps[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumps[client]);
        g_hJumps[client] = INVALID_HANDLE;
    }
    if (g_hJumpCounts[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumpCounts[client]);
        g_hJumpCounts[client] = INVALID_HANDLE;
    }
    
    g_hJumps[client] = CreateTrie();
    g_hJumpCounts[client] = CreateTrie();

    if (g_hJumps[client] == INVALID_HANDLE || g_hJumpCounts[client] == INVALID_HANDLE)
    {
        PrintToChat(client, "Failed to create jump counter. Please try again later.");
        return Plugin_Handled;
    }

    SetTrieValue(g_hJumps[client], "jump_target", jumps);
    SetTrieValue(g_hJumpCounts[client], "jump_count", 0);
    
    PrintToChat(client, "Jump counter set to %d jumps.", jumps);
    return Plugin_Handled;
}

public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
    new userid = GetEventInt(event, "userid");
    new client = GetClientOfUserId(userid);
    
    if (!IsClientInGame(client))
    {
        return Plugin_Handled;
    }
    
    if (g_hJumps[client] == INVALID_HANDLE)
    {
        // If the jump counter is not toggled for this player, do nothing
        return Plugin_Handled;
    }
    
    new jump_target, jump_count;
    GetTrieValue(g_hJumps[client], "jump_target", jump_target);
    GetTrieValue(g_hJumpCounts[client], "jump_count", jump_count);
    
    jump_count++;
    
    if (jump_count >= jump_target)
    {
        PrintToChat(client, "You have reached %d jumps!", jump_target);
        // Execute the sm_landfix command here
        ClientCommand(client, "sm_landfix");

        // Close the handles to disable the jump counter for this player
        CloseHandle(g_hJumps[client]);
        g_hJumps[client] = INVALID_HANDLE;
        CloseHandle(g_hJumpCounts[client]);
        g_hJumpCounts[client] = INVALID_HANDLE;
    }
    else
    {
        // Update the jump count
        SetTrieValue(g_hJumpCounts[client], "jump_count", jump_count);
    }
    
    return Plugin_Handled;
}

public OnClientDisconnect(client)
{
    if (g_hJumps[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumps[client]);
        g_hJumps[client] = INVALID_HANDLE;
    }
    
    if (g_hJumpCounts[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumpCounts[client]);
        g_hJumpCounts[client] = INVALID_HANDLE;
    }
}

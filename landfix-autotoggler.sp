#include <sourcemod>
#include <sdktools>

#define PLUGIN_NAME "Landfix AutoToggler"
#define PLUGIN_VERSION "1.2"
#define PLUGIN_AUTHOR "Wool"

new Handle:g_hJumpSettings[MAXPLAYERS + 1];
static int g_JumpCounts[MAXPLAYERS + 1]; // Store jump counts for each player
static bool g_bJumpTogglesEnabled[MAXPLAYERS + 1]; // Store whether jump toggles are enabled for each player
static bool g_bLandfixEnabled[MAXPLAYERS + 1]; // Store whether landfix is enabled for each player

public Plugin:myinfo =
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = "Executes commands on specified jumps",
    version = PLUGIN_VERSION,
    url = ""
};

public OnPluginStart()
{
    RegConsoleCmd("sm_lftoggle", Command_lfToggle, "Toggle the jump counter");
    RegConsoleCmd("sm_lfoff", Command_lfOff, "Turn off the jump counter");
    RegConsoleCmd("sm_lftoggleoff", Command_lfToggleOff, "Toggle jump counter off");
    RegConsoleCmd("sm_r", Command_ResetRun, "Reset run");
    RegConsoleCmd("r", Command_ResetRun, "Reset run (alias)");
    HookEvent("player_jump", Event_PlayerJump);

    for (int i = 1; i <= MaxClients; i++)
    {
        g_hJumpSettings[i] = INVALID_HANDLE;
        g_JumpCounts[i] = 0;
        g_bJumpTogglesEnabled[i] = true; // Jump toggles are enabled by default
        g_bLandfixEnabled[i] = true; // Landfix is enabled by default
    }
}

public Action:Command_lfToggle(client, args)
{
    if (args < 1)
    {
        PrintToChat(client, "Usage: !lftoggle <jump1> <jump2> ... <jumpN>");
        return Plugin_Handled;
    }
    
    if (g_hJumpSettings[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumpSettings[client]);
        g_hJumpSettings[client] = INVALID_HANDLE;
    }

    g_hJumpSettings[client] = CreateArray();

    if (g_hJumpSettings[client] == INVALID_HANDLE)
    {
        PrintToChat(client, "Failed to create jump settings. Please try again later.");
        return Plugin_Handled;
    }

    for (int i = 1; i <= args; i++)
    {
        new String:jumpStr[10];
        GetCmdArg(i, jumpStr, sizeof(jumpStr));

        new jump = StringToInt(jumpStr);

        if (jump <= 0)
        {
            PrintToChat(client, "Please enter valid numbers greater than 0.");
            CloseHandle(g_hJumpSettings[client]);
            g_hJumpSettings[client] = INVALID_HANDLE;
            return Plugin_Handled;
        }

        PushArrayCell(g_hJumpSettings[client], jump);
    }

    PrintToChat(client, "Jump toggles set, write !lftoggleoff to disable.");
    g_bJumpTogglesEnabled[client] = true; // Enable jump toggles
    return Plugin_Handled;
}

public Action:Command_lfOff(client, args)
{
    g_bLandfixEnabled[client] = false;
    PrintToChat(client, "Landfix toggled off.");
    return Plugin_Handled;
}

public Action:Command_lfToggleOff(client, args)
{
    g_bJumpTogglesEnabled[client] = false;
    PrintToChat(client, "Jump toggles disabled.");
    return Plugin_Handled;
}

public Action:Command_ResetRun(client, args)
{
    // Reset the jump count for the client
    g_JumpCounts[client] = 0;
    // Removed the reset confirmation message
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
    
    if (g_hJumpSettings[client] == INVALID_HANDLE || !g_bJumpTogglesEnabled[client] || !g_bLandfixEnabled[client])
    {
        return Plugin_Handled;
    }

    g_JumpCounts[client]++;

    new size = GetArraySize(g_hJumpSettings[client]);
    for (int i = 0; i < size; i++)
    {
        new jump = GetArrayCell(g_hJumpSettings[client], i);

        if (g_JumpCounts[client] == jump)
        {
            ClientCommand(client, "sm_landfix");
        }
    }

    return Plugin_Handled;
}

public OnClientDisconnect(client)
{
    if (g_hJumpSettings[client] != INVALID_HANDLE)
    {
        CloseHandle(g_hJumpSettings[client]);
        g_hJumpSettings[client] = INVALID_HANDLE;
    }
    
    // Reset the jump count when the client disconnects
    g_JumpCounts[client] = 0;
    g_bJumpTogglesEnabled[client] = true; // Reset jump toggles state
    g_bLandfixEnabled[client] = true; // Reset landfix state
}

#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Local roleplay chat
//-----------------------------------------------------------------------------

#define RP_CHAT_RADIUS          (20.0)
#define RP_CHAT_SHOUT_RADIUS   (40.0)
#define RP_CHAT_WHISPER_RADIUS  (5.0)
#define RP_CHAT_MIN_ALPHA      (80)
#define RP_ACTION_DRAW_DISTANCE (20.0)
#define RP_ACTION_DURATION      (5000)

new
    PlayerText3D:s_RPActionLabels[MAX_PLAYERS][MAX_PLAYERS],
    s_RPActionTimers[MAX_PLAYERS];

forward RP_ClearAction(playerid);

stock RP_ClearActionLabels(playerid)
{
    if (s_RPActionTimers[playerid])
    {
        KillTimer(s_RPActionTimers[playerid]);
        s_RPActionTimers[playerid] = 0;
    }

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (s_RPActionLabels[playerid][targetid] != INVALID_PLAYER_3DTEXT_ID &&
            IsPlayerConnected(targetid))
        {
            DeletePlayer3DTextLabel(
                targetid,
                s_RPActionLabels[playerid][targetid]
            );
        }

        s_RPActionLabels[playerid][targetid] = INVALID_PLAYER_3DTEXT_ID;
    }

    return 1;
}

stock RP_ShowAction(playerid, const action[])
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    RP_ClearActionLabels(playerid);

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (!IsPlayerConnected(targetid) ||
            !IsPlayerCharacterLoaded(targetid) ||
            GetPlayerInterior(targetid) != GetPlayerInterior(playerid) ||
            GetPlayerVirtualWorld(targetid) != GetPlayerVirtualWorld(playerid) ||
            GetPlayerDistanceFromPoint(targetid, x, y, z) > RP_ACTION_DRAW_DISTANCE)
        {
            continue;
        }

        s_RPActionLabels[playerid][targetid] = CreatePlayer3DTextLabel(
            targetid,
            action,
            COLOR_RP_ME,
            0.0,
            0.0,
            0.35,
            RP_ACTION_DRAW_DISTANCE,
            playerid,
            INVALID_VEHICLE_ID,
            true
        );
    }

    s_RPActionTimers[playerid] = SetTimerEx(
        "RP_ClearAction",
        RP_ACTION_DURATION,
        false,
        "d",
        playerid
    );

    return 1;
}

public RP_ClearAction(playerid)
{
    s_RPActionTimers[playerid] = 0;
    RP_ClearActionLabels(playerid);
    return 1;
}

stock RP_GetDistanceColor(color, Float:distance, Float:radius)
{
    new alpha = 255 - floatround((distance / radius) * (255 - RP_CHAT_MIN_ALPHA));

    if (alpha < RP_CHAT_MIN_ALPHA)
    {
        alpha = RP_CHAT_MIN_ALPHA;
    }
    else if (alpha > 255)
    {
        alpha = 255;
    }

    return (color & 0xFFFFFF00) | alpha;
}

stock RP_SendLocalMessage(playerid, const message[], color, Float:radius)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (!IsPlayerConnected(targetid) ||
            !IsPlayerCharacterLoaded(targetid) ||
            GetPlayerInterior(targetid) != GetPlayerInterior(playerid) ||
            GetPlayerVirtualWorld(targetid) != GetPlayerVirtualWorld(playerid))
        {
            continue;
        }

        new Float:distance = GetPlayerDistanceFromPoint(targetid, x, y, z);

        if (distance > radius)
        {
            continue;
        }

        SendClientMessage(
            targetid,
            RP_GetDistanceColor(color, distance, radius),
            message
        );
    }

    return 1;
}

stock bool:RP_MatchCommand(const cmdtext[], const command[], &argumentStart)
{
    new const commandLength = strlen(command);

    if (strcmp(cmdtext, command, true, commandLength) != 0)
    {
        return false;
    }

    if (cmdtext[commandLength] != 0 && cmdtext[commandLength] != ' ')
    {
        return false;
    }

    argumentStart = commandLength;
    return true;
}

stock bool:RP_GetCommandArgument(
    const cmdtext[],
    argumentStart,
    argument[],
    size
)
{
    new const commandTextLength = strlen(cmdtext);

    while (argumentStart < commandTextLength && cmdtext[argumentStart] == ' ')
    {
        argumentStart++;
    }

    if (argumentStart >= commandTextLength)
    {
        argument[0] = 0;
        return false;
    }

    format(argument, size, "%s", cmdtext[argumentStart]);

    new argumentLength = strlen(argument);

    while (argumentLength > 0 && argument[argumentLength - 1] == ' ')
    {
        argument[--argumentLength] = 0;
    }

    return argumentLength > 0;
}

stock RP_GetCharacterName(playerid, destination[], size)
{
    format(destination, size, "%s", s_CharacterName[playerid]);
    return 1;
}

hook OnPlayerConnect(playerid)
{
    s_RPActionTimers[playerid] = 0;

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        s_RPActionLabels[playerid][i] = INVALID_PLAYER_3DTEXT_ID;
        s_RPActionLabels[i][playerid] = INVALID_PLAYER_3DTEXT_ID;
    }

    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    RP_ClearActionLabels(playerid);

    for (new i = 0; i < MAX_PLAYERS; i++)
    {
        s_RPActionLabels[i][playerid] = INVALID_PLAYER_3DTEXT_ID;
    }

    return 1;
}

hook OnPlayerText(playerid, text[])
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new message[192], name[CHARACTER_NAME_LENGTH];
    RP_GetCharacterName(playerid, name, sizeof(name));
    format(message, sizeof(message), "%s noi: %s", name, text);

    RP_SendLocalMessage(playerid, message, COLOR_RP_CHAT, RP_CHAT_RADIUS);
    return 0;
}

hook OnPlayerCommandText(playerid, cmdtext[])
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new argument[128], message[192], name[CHARACTER_NAME_LENGTH], argumentStart;
    RP_GetCharacterName(playerid, name, sizeof(name));

    if (RP_MatchCommand(cmdtext, "/me", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /me [hanh dong]");
            return ~1;
        }

        format(message, sizeof(message), "* %s %s", name, argument);
        RP_SendLocalMessage(playerid, message, COLOR_RP_ME, RP_CHAT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/do", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /do [mo ta]");
            return ~1;
        }

        format(message, sizeof(message), "* %s ((%s))", argument, name);
        RP_SendLocalMessage(playerid, message, COLOR_RP_DO, RP_CHAT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/b", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /b [noi dung]");
            return ~1;
        }

        format(message, sizeof(message), "(( %s: %s ))", name, argument);
        RP_SendLocalMessage(playerid, message, COLOR_RP_OOC, RP_CHAT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/s", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /s [noi dung]");
            return ~1;
        }

        format(message, sizeof(message), "%s het lon: %s", name, argument);
        RP_SendLocalMessage(playerid, message, COLOR_RP_SHOUT, RP_CHAT_SHOUT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/w", argumentStart) ||
        RP_MatchCommand(cmdtext, "/low", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /w [noi dung]");
            return ~1;
        }

        format(message, sizeof(message), "%s noi nho: %s", name, argument);
        RP_SendLocalMessage(playerid, message, COLOR_RP_CHAT, RP_CHAT_WHISPER_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/try", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /try [hanh dong]");
            return ~1;
        }

        format(
            message,
            sizeof(message),
            "* %s %s [%s]",
            name,
            argument,
            random(2) ? "thanh cong" : "that bai"
        );

        RP_SendLocalMessage(playerid, message, COLOR_RP_TRY, RP_CHAT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/roll", argumentStart))
    {
        new result = random(100) + 1;
        format(
            message,
            sizeof(message),
            "* %s tung xuc xac va nhan duoc %d/100.",
            name,
            result
        );

        RP_SendLocalMessage(playerid, message, COLOR_RP_TRY, RP_CHAT_RADIUS);
        return ~1;
    }

    if (RP_MatchCommand(cmdtext, "/ame", argumentStart))
    {
        if (!RP_GetCommandArgument(cmdtext, argumentStart, argument, sizeof(argument)))
        {
            SendClientMessage(playerid, COLOR_RED, "Su dung: /ame [hanh dong]");
            return ~1;
        }

        format(message, sizeof(message), "* %s %s", name, argument);
        RP_ShowAction(playerid, message);
        return ~1;
    }

    return 0;
}

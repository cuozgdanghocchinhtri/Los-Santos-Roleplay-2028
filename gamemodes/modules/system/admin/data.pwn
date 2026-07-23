//-----------------------------------------------------------------------------
// OOC administrator definitions and runtime state
//-----------------------------------------------------------------------------

#define ADMIN_LEVEL_NONE       (0)
#define ADMIN_LEVEL_SUPPORTER  (1)
#define ADMIN_LEVEL_MODERATOR  (2)
#define ADMIN_LEVEL_ADMIN      (3)
#define ADMIN_LEVEL_SENIOR     (4)
#define ADMIN_LEVEL_MANAGER    (5)
#define ADMIN_LEVEL_OWNER      (6)
#define ADMIN_LEVEL_MAX        (ADMIN_LEVEL_OWNER)

#define INVALID_ADMIN_TARGET   (-1)

new
    s_AdminLevel[MAX_PLAYERS],
    bool:s_AdminLoaded[MAX_PLAYERS];

stock Admin_Reset(playerid)
{
    s_AdminLevel[playerid] = ADMIN_LEVEL_NONE;
    s_AdminLoaded[playerid] = false;
    return 1;
}

stock Admin_SetLevel(playerid, level)
{
    if (level < ADMIN_LEVEL_NONE)
    {
        level = ADMIN_LEVEL_NONE;
    }
    else if (level > ADMIN_LEVEL_MAX)
    {
        level = ADMIN_LEVEL_MAX;
    }

    s_AdminLevel[playerid] = level;
    s_AdminLoaded[playerid] = true;
    return 1;
}

stock Admin_GetLevel(playerid)
{
    if (!IsPlayerConnected(playerid))
    {
        return ADMIN_LEVEL_NONE;
    }

    // RCON remains an emergency development override.
    if (IsPlayerAdmin(playerid))
    {
        return ADMIN_LEVEL_OWNER;
    }

    if (!s_AdminLoaded[playerid])
    {
        return ADMIN_LEVEL_NONE;
    }

    return s_AdminLevel[playerid];
}

stock bool:Admin_HasLevel(playerid, requiredLevel)
{
    return Admin_GetLevel(playerid) >= requiredLevel;
}

stock bool:Admin_RequireLevel(playerid, requiredLevel)
{
    if (Admin_HasLevel(playerid, requiredLevel))
    {
        return true;
    }

    SendClientMessage(
        playerid,
        COLOR_RED,
        "Ban khong co quyen su dung lenh quan tri nay."
    );
    return false;
}

stock Admin_GetLevelName(level, destination[], size)
{
    switch (level)
    {
        case ADMIN_LEVEL_SUPPORTER:
            format(destination, size, "Supporter");
        case ADMIN_LEVEL_MODERATOR:
            format(destination, size, "Moderator");
        case ADMIN_LEVEL_ADMIN:
            format(destination, size, "Administrator");
        case ADMIN_LEVEL_SENIOR:
            format(destination, size, "Senior Admin");
        case ADMIN_LEVEL_MANAGER:
            format(destination, size, "Admin Manager");
        case ADMIN_LEVEL_OWNER:
            format(destination, size, "Owner");
        default:
            format(destination, size, "Nguoi choi");
    }

    return 1;
}

stock Admin_GetDisplayName(playerid, destination[], size)
{
    if (IsPlayerCharacterLoaded(playerid))
    {
        format(destination, size, "%s", s_CharacterName[playerid]);
    }
    else if (IsPlayerLoggedIn(playerid))
    {
        GetPlayerAccountUsername(playerid, destination, size);
    }
    else
    {
        GetPlayerName(playerid, destination, size);
    }

    return 1;
}

stock bool:Admin_IsNumeric(const value[])
{
    new const length = strlen(value);
    if (length == 0)
    {
        return false;
    }

    for (new index = 0; index < length; index++)
    {
        if (value[index] < '0' || value[index] > '9')
        {
            return false;
        }
    }

    return true;
}

stock Admin_FindPlayer(const value[])
{
    if (Admin_IsNumeric(value))
    {
        new const targetid = strval(value);

        if (targetid >= 0 &&
            targetid < MAX_PLAYERS &&
            IsPlayerConnected(targetid))
        {
            return targetid;
        }

        return INVALID_ADMIN_TARGET;
    }

    new name[MAX_PLAYER_NAME + 1];

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (!IsPlayerConnected(targetid))
        {
            continue;
        }

        GetPlayerName(targetid, name, sizeof(name));

        if (!strcmp(name, value, true) ||
            strfind(name, value, true) != -1)
        {
            return targetid;
        }
    }

    return INVALID_ADMIN_TARGET;
}


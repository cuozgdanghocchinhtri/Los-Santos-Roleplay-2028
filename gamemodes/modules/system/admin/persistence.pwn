#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Persistent account administrator level
//-----------------------------------------------------------------------------

forward Admin_OnLoaded(playerid, accountID);
forward Admin_OnLevelSaved(playerid, targetid, accountID, level);

stock Admin_Load(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerLoggedIn(playerid))
    {
        return 0;
    }

    Admin_Reset(playerid);

    new query[192];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `admin_level` FROM `player_accounts` WHERE `account_id` = %d LIMIT 1",
        GetPlayerAccountID(playerid)
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Admin_OnLoaded",
        "dd",
        playerid,
        GetPlayerAccountID(playerid)
    );
    return 1;
}

public Admin_OnLoaded(playerid, accountID)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerLoggedIn(playerid) ||
        GetPlayerAccountID(playerid) != accountID)
    {
        return 1;
    }

    new level = ADMIN_LEVEL_NONE;

    if (cache_num_rows() > 0)
    {
        cache_get_value_name_int(0, "admin_level", level);
    }

    Admin_SetLevel(playerid, level);
    return 1;
}

stock Admin_SaveLevel(playerid, targetid, level)
{
    if (!IsPlayerConnected(targetid) || !IsPlayerLoggedIn(targetid))
    {
        return 0;
    }

    new const accountID = GetPlayerAccountID(targetid);
    new query[192];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_accounts` SET `admin_level` = %d WHERE `account_id` = %d",
        level,
        accountID
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Admin_OnLevelSaved",
        "dddd",
        playerid,
        targetid,
        accountID,
        level
    );
    return 1;
}

public Admin_OnLevelSaved(playerid, targetid, accountID, level)
{
    if (cache_affected_rows() == 0)
    {
        if (IsPlayerConnected(playerid))
        {
            SendClientMessage(
                playerid,
                COLOR_RED,
                "Khong the luu cap do admin. Kiem tra migration 004."
            );
        }
        return 1;
    }

    if (IsPlayerConnected(targetid) &&
        IsPlayerLoggedIn(targetid) &&
        GetPlayerAccountID(targetid) == accountID)
    {
        Admin_SetLevel(targetid, level);

        new levelName[24], message[128];
        Admin_GetLevelName(level, levelName, sizeof(levelName));
        format(
            message,
            sizeof(message),
            "Cap do quan tri cua ban da duoc dat thanh %s (%d).",
            levelName,
            level
        );
        SendClientMessage(targetid, COLOR_WHITE, message);
    }

    if (IsPlayerConnected(playerid))
    {
        SendClientMessage(playerid, COLOR_WHITE, "Da cap nhat quyen admin.");
    }

    return 1;
}

hook OnPlayerConnect(playerid)
{
    Admin_Reset(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    Admin_Reset(playerid);
    return 1;
}

hook OnPlayerLogin(playerid)
{
    Admin_Load(playerid);
    return 1;
}


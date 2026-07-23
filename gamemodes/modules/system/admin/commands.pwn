//-----------------------------------------------------------------------------
// Administrator commands
//-----------------------------------------------------------------------------

#define COLOR_ADMIN_CHAT (0xFF6347FF)

stock bool:Admin_ParseTargetAndLevel(
    const params[],
    targetText[],
    targetSize,
    &level
)
{
    new const length = strlen(params);
    new index;

    while (index < length && params[index] == ' ')
    {
        index++;
    }

    new targetLength;
    while (index < length &&
        params[index] != ' ' &&
        targetLength < targetSize - 1)
    {
        targetText[targetLength++] = params[index++];
    }
    targetText[targetLength] = 0;

    while (index < length && params[index] == ' ')
    {
        index++;
    }

    if (targetLength == 0 || index >= length)
    {
        return false;
    }

    level = strval(params[index]);
    return true;
}

stock Admin_TeleportPlayerToPlayer(playerid, targetid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(targetid, x, y, z);

    new const interior = GetPlayerInterior(targetid);
    new const virtualWorld = GetPlayerVirtualWorld(targetid);

    SetPlayerInterior(playerid, interior);
    SetPlayerVirtualWorld(playerid, virtualWorld);

    if (IsPlayerInAnyVehicle(playerid))
    {
        new const vehicleid = GetPlayerVehicleID(playerid);
        LinkVehicleToInterior(vehicleid, interior);
        SetVehicleVirtualWorld(vehicleid, virtualWorld);
        SetVehiclePos(vehicleid, x + 2.0, y, z + 0.5);
    }
    else
    {
        SetPlayerPos(playerid, x + 1.0, y, z + 0.5);
    }

    SetCameraBehindPlayer(playerid);
    return 1;
}

stock Admin_TeleportTargetHere(playerid, targetid)
{
    new Float:x, Float:y, Float:z;
    GetPlayerPos(playerid, x, y, z);

    new const interior = GetPlayerInterior(playerid);
    new const virtualWorld = GetPlayerVirtualWorld(playerid);

    SetPlayerInterior(targetid, interior);
    SetPlayerVirtualWorld(targetid, virtualWorld);

    if (IsPlayerInAnyVehicle(targetid))
    {
        new const vehicleid = GetPlayerVehicleID(targetid);
        LinkVehicleToInterior(vehicleid, interior);
        SetVehicleVirtualWorld(vehicleid, virtualWorld);
        SetVehiclePos(vehicleid, x + 2.0, y, z + 0.5);
    }
    else
    {
        SetPlayerPos(targetid, x + 1.0, y, z + 0.5);
    }

    SetCameraBehindPlayer(targetid);
    return 1;
}

stock Admin_CommandGoto(playerid, const params[])
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_MODERATOR))
    {
        return 1;
    }

    if (params[0] == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /goto [playerid/ten]");
        return 1;
    }

    new const targetid = Admin_FindPlayer(params);
    if (targetid == INVALID_ADMIN_TARGET)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong tim thay nguoi choi.");
        return 1;
    }

    if (targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban dang o vi tri cua chinh minh.");
        return 1;
    }

    Admin_TeleportPlayerToPlayer(playerid, targetid);

    new targetName[MAX_PLAYER_NAME + 1], message[128];
    GetPlayerName(targetid, targetName, sizeof(targetName));
    format(
        message,
        sizeof(message),
        "Ban da dich chuyen den %s (ID %d).",
        targetName,
        targetid
    );
    SendClientMessage(playerid, COLOR_WHITE, message);
    return 1;
}

CMD:goto(playerid, params[])
{
    return Admin_CommandGoto(playerid, params);
}

CMD:gotoid(playerid, params[])
{
    return Admin_CommandGoto(playerid, params);
}

CMD:gotopid(playerid, params[])
{
    return Admin_CommandGoto(playerid, params);
}

CMD:gethere(playerid, params[])
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_ADMIN))
    {
        return 1;
    }

    if (params[0] == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /gethere [playerid/ten]");
        return 1;
    }

    new const targetid = Admin_FindPlayer(params);
    if (targetid == INVALID_ADMIN_TARGET)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong tim thay nguoi choi.");
        return 1;
    }

    if (targetid == playerid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban khong the keo chinh minh.");
        return 1;
    }

    Admin_TeleportTargetHere(playerid, targetid);

    new adminName[MAX_PLAYER_NAME + 1], message[128];
    Admin_GetDisplayName(playerid, adminName, sizeof(adminName));
    format(
        message,
        sizeof(message),
        "Ban da duoc quan tri vien %s dich chuyen.",
        adminName
    );
    SendClientMessage(targetid, COLOR_WHITE, message);
    SendClientMessage(playerid, COLOR_WHITE, "Da dich chuyen nguoi choi den vi tri cua ban.");
    return 1;
}

CMD:a(playerid, params[])
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_SUPPORTER))
    {
        return 1;
    }

    if (params[0] == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /a [noi dung]");
        return 1;
    }

    new
        senderName[MAX_PLAYER_NAME + 1],
        levelName[24],
        message[192];

    Admin_GetDisplayName(playerid, senderName, sizeof(senderName));
    Admin_GetLevelName(Admin_GetLevel(playerid), levelName, sizeof(levelName));
    format(
        message,
        sizeof(message),
        "[A] %s %s (ID %d): %s",
        levelName,
        senderName,
        playerid,
        params
    );

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (IsPlayerConnected(targetid) &&
            Admin_HasLevel(targetid, ADMIN_LEVEL_SUPPORTER))
        {
            SendClientMessage(targetid, COLOR_ADMIN_CHAT, message);
        }
    }

    return 1;
}

CMD:admins(playerid, params[])
{
    #pragma unused params

    SendClientMessage(playerid, COLOR_WHITE, "Quan tri vien dang truc tuyen:");

    new count;
    new name[MAX_PLAYER_NAME + 1], levelName[24], message[128];

    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (!IsPlayerConnected(targetid) ||
            !Admin_HasLevel(targetid, ADMIN_LEVEL_SUPPORTER))
        {
            continue;
        }

        Admin_GetDisplayName(targetid, name, sizeof(name));
        Admin_GetLevelName(Admin_GetLevel(targetid), levelName, sizeof(levelName));
        format(
            message,
            sizeof(message),
            "- %s (ID %d) - %s",
            name,
            targetid,
            levelName
        );
        SendClientMessage(playerid, COLOR_ADMIN_CHAT, message);
        count++;
    }

    if (count == 0)
    {
        SendClientMessage(playerid, COLOR_WHITE, "Hien khong co quan tri vien truc tuyen.");
    }

    return 1;
}

CMD:setadmin(playerid, params[])
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_OWNER))
    {
        return 1;
    }

    new targetText[MAX_PLAYER_NAME + 1], level;
    if (!Admin_ParseTargetAndLevel(
        params,
        targetText,
        sizeof(targetText),
        level
    ))
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /setadmin [playerid/ten] [0-6]");
        return 1;
    }

    if (level < ADMIN_LEVEL_NONE || level > ADMIN_LEVEL_MAX)
    {
        SendClientMessage(playerid, COLOR_RED, "Cap do admin phai nam trong khoang 0-6.");
        return 1;
    }

    new const targetid = Admin_FindPlayer(targetText);
    if (targetid == INVALID_ADMIN_TARGET)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong tim thay nguoi choi.");
        return 1;
    }

    if (!IsPlayerLoggedIn(targetid))
    {
        SendClientMessage(playerid, COLOR_RED, "Nguoi choi chua dang nhap tai khoan.");
        return 1;
    }

    Admin_SaveLevel(playerid, targetid, level);
    SendClientMessage(playerid, COLOR_WHITE, "Dang luu quyen admin vao database...");
    return 1;
}

stock Admin_ShowHelp(playerid)
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_SUPPORTER))
    {
        return 1;
    }

    new body[1400];
    format(body, sizeof(body), "Lenh\tCap do\tMo ta\n");
    strcat(body, "/a [noi dung]\t1+\tKenh chat quan tri\n", sizeof(body));
    strcat(body, "/goto [ID/ten]\t2+\tDich chuyen den nguoi choi\n", sizeof(body));
    strcat(body, "/gotoid [ID]\t2+\tAlias cua /goto\n", sizeof(body));
    strcat(body, "/gethere [ID/ten]\t3+\tKeo nguoi choi den vi tri admin\n", sizeof(body));
    strcat(body, "/admins\tCong khai\tDanh sach admin online\n", sizeof(body));
    strcat(body, "/setadmin [ID] [0-6]\t6/RCON\tCap quyen admin\n", sizeof(body));

    ShowPlayerDialog(
        playerid,
        DIALOG_ADMIN_HELP,
        DIALOG_STYLE_TABLIST_HEADERS,
        "LS:RP - Tro giup quan tri",
        body,
        "Dong",
        ""
    );
    return 1;
}

CMD:adminhelp(playerid, params[])
{
    #pragma unused params

    return Admin_ShowHelp(playerid);
}

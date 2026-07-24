// LSRP patch - temporary admin + admin vehicle

CMD:setadminao(playerid, params[])
{
 
    new targetText[MAX_PLAYER_NAME + 1], level;
    if (!Admin_ParseTargetAndLevel(params, targetText, sizeof(targetText), level))
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /setadminao [playerid/ten] [0-6]");
        return 1;
    }

    if (level < ADMIN_LEVEL_NONE || level > ADMIN_LEVEL_MAX)
    {
        SendClientMessage(playerid, COLOR_RED, "Cap do admin phai nam trong khoang 0-6.");
        return 1;
    }

    new targetid = Admin_FindPlayer(targetText);
    if (targetid == INVALID_ADMIN_TARGET)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong tim thay nguoi choi.");
        return 1;
    }

    Admin_SetLevel(targetid, level);

    new message[128], targetName[MAX_PLAYER_NAME + 1];
    Admin_GetDisplayName(targetid, targetName, sizeof(targetName));
    format(message, sizeof(message), "Da set Admin AO level %d cho %s. Quyen nay khong luu database.", level, targetName);
    SendClientMessage(playerid, COLOR_WHITE, message);
    SendClientMessage(targetid, COLOR_WHITE, "Quyen admin ao cua ban da duoc cap/thay doi.");
    return 1;
}

CMD:veh(playerid, params[])
{
    if (!Admin_RequireLevel(playerid, ADMIN_LEVEL_ADMIN))
        return 1;

    if (params[0] == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Su dung: /veh [modelid 400-611]");
        return 1;
    }

    new modelid = strval(params);
    if (modelid < 400 || modelid > 611)
    {
        SendClientMessage(playerid, COLOR_RED, "Model xe phai tu 400 den 611.");
        return 1;
    }

    new Float:x, Float:y, Float:z, Float:a;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, a);

    new vehicleid = CreateVehicle(modelid, x + 3.0, y, z, a, -1, -1, -1);
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the tao phuong tien.");
        return 1;
    }

    LinkVehicleToInterior(vehicleid, GetPlayerInterior(playerid));
    SetVehicleVirtualWorld(vehicleid, GetPlayerVirtualWorld(playerid));
    PutPlayerInVehicle(playerid, vehicleid, 0);

    new message[96];
    format(message, sizeof(message), "Da tao xe admin model %d (vehicle ID %d).", modelid, vehicleid);
    SendClientMessage(playerid, COLOR_WHITE, message);
    return 1;
}

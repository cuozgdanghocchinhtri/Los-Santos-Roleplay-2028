//-----------------------------------------------------------------------------
// Development-only vehicle seed command.
//
// Remove this include from main.pwn before a production release.
// This is a development command; remove this include before production.
//-----------------------------------------------------------------------------

#define VEHICLE_TEST_DEFAULT_MODEL (560)

forward Vehicle_OnTestInserted(playerid, characterID);

stock Vehicle_CreateTestRow(playerid, modelID)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        !s_OwnedVehiclesLoaded[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Du lieu nhan vat/xe chua tai xong.");
        return 0;
    }

    if (Vehicle_GetActiveSlot(playerid) != INVALID_OWNED_VEHICLE_SLOT)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay cat xe dang hoat dong truoc khi tao xe test.");
        return 0;
    }

    if (modelID < 400 || modelID > 611)
    {
        SendClientMessage(playerid, COLOR_RED, "Model phai nam trong khoang 400-611.");
        return 0;
    }

    new Float:x, Float:y, Float:z, Float:angle;
    GetPlayerPos(playerid, x, y, z);
    GetPlayerFacingAngle(playerid, angle);

    new plate[OWNED_VEHICLE_PLATE_LENGTH];
    format(
        plate,
        sizeof(plate),
        "TEST-%d-%d",
        s_OwnedVehicleCharacterID[playerid],
        GetTickCount() % 10000
    );

    new query[768];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "INSERT INTO `player_vehicles` (`owner_character_id`, `model_id`, `plate`, `color_1`, `color_2`, `park_x`, `park_y`, `park_z`, `park_a`, `interior_id`, `virtual_world`) VALUES (%d, %d, '%e', 1, 1, %f, %f, %f, %f, %d, %d)",
        s_OwnedVehicleCharacterID[playerid],
        modelID,
        plate,
        x,
        y,
        z,
        angle,
        GetPlayerInterior(playerid),
        GetPlayerVirtualWorld(playerid)
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Vehicle_OnTestInserted",
        "dd",
        playerid,
        s_OwnedVehicleCharacterID[playerid]
    );

    SendClientMessage(playerid, COLOR_WHITE, "Dang tao xe test trong database...");
    return 1;
}

public Vehicle_OnTestInserted(playerid, characterID)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID)
    {
        return 1;
    }

    if (cache_insert_id() <= 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Tao xe test that bai. Kiem tra migration 003.");
        return 1;
    }

    Vehicle_LoadForPlayer(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Da tao xe test. Mo /vehicles de kiem tra.");
    return 1;
}

CMD:addvehicle(playerid, params[])
{
    new modelID = VEHICLE_TEST_DEFAULT_MODEL;
    if (params[0] != 0)
    {
        modelID = strval(params);
    }

    Vehicle_CreateTestRow(playerid, modelID);
    return 1;
}

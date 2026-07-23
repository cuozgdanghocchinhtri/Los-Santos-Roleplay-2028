#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Owned vehicle database persistence
//-----------------------------------------------------------------------------

stock Vehicle_LoadForPlayer(playerid)
{
    if (!IsPlayerConnected(playerid) || !IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new const characterID = GetPlayerCharacterID(playerid);

    if (characterID == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    Vehicle_ResetPlayer(playerid);
    s_OwnedVehicleCharacterID[playerid] = characterID;

    new query[768];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `vehicle_id`, `model_id`, `plate`, `color_1`, `color_2`, `park_x`, `park_y`, `park_z`, `park_a`, `interior_id`, `virtual_world`, `health`, `panels_damage`, `doors_damage`, `lights_damage`, `tyres_damage`, `mileage_km`, `storage_state`, `is_favorite`, `is_locked`, `gps_installed`, `gps_active`, `theft_state`, COALESCE(`last_driver_character_id`, 0) AS `last_driver_character_id` FROM `player_vehicles` WHERE `owner_character_id` = %d AND `deleted_at` IS NULL ORDER BY `is_favorite` DESC, `vehicle_id` ASC LIMIT %d",
        characterID,
        MAX_OWNED_VEHICLES
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Vehicle_OnLoaded",
        "dd",
        playerid,
        characterID
    );
    return 1;
}

public Vehicle_OnLoaded(playerid, characterID)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID ||
        s_OwnedVehicleCharacterID[playerid] != characterID)
    {
        return 1;
    }

    new const rows = cache_num_rows();
    printf(
        "[VEHICLE DEBUG] OnLoaded p=%d character=%d rows=%d pending=%d",
        playerid,
        characterID,
        rows,
        _:s_OwnedVehicleShowPending[playerid]
    );
    new value;

    for (new row = 0; row < rows && row < MAX_OWNED_VEHICLES; row++)
    {
        Vehicle_ResetSlot(playerid, row);

        cache_get_value_name_int(row, "vehicle_id", s_OwnedVehicle[playerid][row][ov_DatabaseID]);
        cache_get_value_name_int(row, "model_id", s_OwnedVehicle[playerid][row][ov_ModelID]);
        cache_get_value_name(row, "plate", s_OwnedVehicle[playerid][row][ov_Plate], OWNED_VEHICLE_PLATE_LENGTH);
        cache_get_value_name_int(row, "color_1", s_OwnedVehicle[playerid][row][ov_Color1]);
        cache_get_value_name_int(row, "color_2", s_OwnedVehicle[playerid][row][ov_Color2]);
        cache_get_value_name_float(row, "park_x", s_OwnedVehicle[playerid][row][ov_ParkX]);
        cache_get_value_name_float(row, "park_y", s_OwnedVehicle[playerid][row][ov_ParkY]);
        cache_get_value_name_float(row, "park_z", s_OwnedVehicle[playerid][row][ov_ParkZ]);
        cache_get_value_name_float(row, "park_a", s_OwnedVehicle[playerid][row][ov_ParkA]);
        cache_get_value_name_int(row, "interior_id", s_OwnedVehicle[playerid][row][ov_Interior]);
        cache_get_value_name_int(row, "virtual_world", s_OwnedVehicle[playerid][row][ov_VirtualWorld]);
        cache_get_value_name_float(row, "health", s_OwnedVehicle[playerid][row][ov_Health]);

        cache_get_value_name_int(row, "panels_damage", value);
        s_OwnedVehicle[playerid][row][ov_Panels] = VEHICLE_PANEL_STATUS:value;
        cache_get_value_name_int(row, "doors_damage", value);
        s_OwnedVehicle[playerid][row][ov_Doors] = VEHICLE_DOOR_STATUS:value;
        cache_get_value_name_int(row, "lights_damage", value);
        s_OwnedVehicle[playerid][row][ov_Lights] = VEHICLE_LIGHT_STATUS:value;
        cache_get_value_name_int(row, "tyres_damage", value);
        s_OwnedVehicle[playerid][row][ov_Tyres] = VEHICLE_TYRE_STATUS:value;

        cache_get_value_name_float(row, "mileage_km", s_OwnedVehicle[playerid][row][ov_Mileage]);
        cache_get_value_name_int(row, "storage_state", value);
        s_OwnedVehicle[playerid][row][ov_Storage] = E_OWNED_VEHICLE_STORAGE:value;
        cache_get_value_name_bool(row, "is_favorite", s_OwnedVehicle[playerid][row][ov_Favorite]);
        cache_get_value_name_bool(row, "is_locked", s_OwnedVehicle[playerid][row][ov_Locked]);
        cache_get_value_name_bool(row, "gps_installed", s_OwnedVehicle[playerid][row][ov_GPSInstalled]);
        cache_get_value_name_bool(row, "gps_active", s_OwnedVehicle[playerid][row][ov_GPSActive]);
        cache_get_value_name_bool(row, "theft_state", s_OwnedVehicle[playerid][row][ov_Stolen]);
        cache_get_value_name_int(row, "last_driver_character_id", s_OwnedVehicle[playerid][row][ov_LastDriverCharacterID]);

        // A runtime vehicle cannot survive a gamemode restart.
        if (s_OwnedVehicle[playerid][row][ov_Storage] == OV_STORAGE_SPAWNED)
        {
            s_OwnedVehicle[playerid][row][ov_Storage] = OV_STORAGE_STORED;
            s_OwnedVehicle[playerid][row][ov_Dirty] = true;
        }
    }

    s_OwnedVehicleCount[playerid] = rows;
    s_OwnedVehiclesLoaded[playerid] = true;

    if (s_OwnedVehicleShowPending[playerid])
    {
        s_OwnedVehicleShowPending[playerid] = false;
        SetTimerEx("Vehicle_ShowListDeferred", 0, false, "d", playerid);
    }

    return 1;
}

stock Vehicle_SaveSlot(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new query[1400];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `park_x` = %f, `park_y` = %f, `park_z` = %f, `park_a` = %f, `interior_id` = %d, `virtual_world` = %d, `health` = %f, `panels_damage` = %d, `doors_damage` = %d, `lights_damage` = %d, `tyres_damage` = %d, `mileage_km` = %f, `storage_state` = %d, `is_favorite` = %d, `is_locked` = %d, `gps_installed` = %d, `gps_active` = %d, `theft_state` = %d, `last_driver_character_id` = NULLIF(%d, 0) WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `deleted_at` IS NULL",
        s_OwnedVehicle[playerid][slot][ov_ParkX],
        s_OwnedVehicle[playerid][slot][ov_ParkY],
        s_OwnedVehicle[playerid][slot][ov_ParkZ],
        s_OwnedVehicle[playerid][slot][ov_ParkA],
        s_OwnedVehicle[playerid][slot][ov_Interior],
        s_OwnedVehicle[playerid][slot][ov_VirtualWorld],
        s_OwnedVehicle[playerid][slot][ov_Health],
        _:s_OwnedVehicle[playerid][slot][ov_Panels],
        _:s_OwnedVehicle[playerid][slot][ov_Doors],
        _:s_OwnedVehicle[playerid][slot][ov_Lights],
        _:s_OwnedVehicle[playerid][slot][ov_Tyres],
        s_OwnedVehicle[playerid][slot][ov_Mileage],
        _:s_OwnedVehicle[playerid][slot][ov_Storage],
        _:s_OwnedVehicle[playerid][slot][ov_Favorite],
        _:s_OwnedVehicle[playerid][slot][ov_Locked],
        _:s_OwnedVehicle[playerid][slot][ov_GPSInstalled],
        _:s_OwnedVehicle[playerid][slot][ov_GPSActive],
        _:s_OwnedVehicle[playerid][slot][ov_Stolen],
        s_OwnedVehicle[playerid][slot][ov_LastDriverCharacterID],
        s_OwnedVehicle[playerid][slot][ov_DatabaseID],
        s_OwnedVehicleCharacterID[playerid]
    );
    mysql_tquery(g_DatabaseHandle, query);
    s_OwnedVehicle[playerid][slot][ov_Dirty] = false;
    return 1;
}

stock Vehicle_SaveAll(playerid)
{
    if (!s_OwnedVehiclesLoaded[playerid])
    {
        return 0;
    }

    for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
    {
        if (Vehicle_IsValidSlot(playerid, slot) &&
            s_OwnedVehicle[playerid][slot][ov_Dirty])
        {
            Vehicle_SaveSlot(playerid, slot);
        }
    }

    return 1;
}

stock Vehicle_RequestDelete(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `deleted_at` = CURRENT_TIMESTAMP WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `storage_state` IN (%d, %d) AND `deleted_at` IS NULL",
        s_OwnedVehicle[playerid][slot][ov_DatabaseID],
        s_OwnedVehicleCharacterID[playerid],
        _:OV_STORAGE_STORED,
        _:OV_STORAGE_DESTROYED
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "Vehicle_OnDeleted",
        "dddd",
        playerid,
        s_OwnedVehicleCharacterID[playerid],
        s_OwnedVehicle[playerid][slot][ov_DatabaseID],
        slot
    );
    return 1;
}

public Vehicle_OnDeleted(playerid, characterID, databaseID, slot)
{
    if (!IsPlayerConnected(playerid) ||
        s_OwnedVehicleCharacterID[playerid] != characterID ||
        !Vehicle_IsValidSlot(playerid, slot) ||
        s_OwnedVehicle[playerid][slot][ov_DatabaseID] != databaseID)
    {
        return 1;
    }

    if (cache_affected_rows() == 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the xoa xe. Hay thu lai.");
        return 1;
    }

    Vehicle_ResetSlot(playerid, slot);

    if (s_OwnedVehicleCount[playerid] > 0)
    {
        s_OwnedVehicleCount[playerid]--;
    }

    s_OwnedVehicleDeleteSlot[playerid] = INVALID_OWNED_VEHICLE_SLOT;
    SendClientMessage(playerid, COLOR_WHITE, "Da xoa xe khoi danh sach so huu.");
    return 1;
}

public Vehicle_LoadDeferred(playerid)
{
    if (IsPlayerConnected(playerid) && IsPlayerCharacterLoaded(playerid))
    {
        Vehicle_LoadForPlayer(playerid);
    }

    return 1;
}

hook OnCharacterLoaded(playerid)
{
    // Hooks run before the original callback. Defer one tick so character/core
    // has finished filling s_Character* before the vehicle query starts.
    SetTimerEx("Vehicle_LoadDeferred", 50, false, "d", playerid);
    return 1;
}

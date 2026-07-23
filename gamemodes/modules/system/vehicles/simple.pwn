//-----------------------------------------------------------------------------
// Simple owned vehicle list
//
// This is intentionally incremental. It keeps the existing /vehicles dialog
// and adds vehicle state one feature at a time.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>
#include <YSI_Game\y_vehicledata>

#define SIMPLE_VEHICLE_MAX            (20)
#define SIMPLE_VEHICLE_PLATE_LENGTH   (17)
#define INVALID_SIMPLE_VEHICLE_SLOT   (-1)

#define SIMPLE_VEHICLE_STORED         (0)
#define SIMPLE_VEHICLE_SPAWNED        (1)
#define SIMPLE_VEHICLE_IMPOUNDED      (2)
#define SIMPLE_VEHICLE_DESTROYED      (3)

#define SIMPLE_VEHICLE_SPAWN_X        (2491.5000)
#define SIMPLE_VEHICLE_SPAWN_Y        (-1684.0000)
#define SIMPLE_VEHICLE_SPAWN_Z        (13.3500)
#define SIMPLE_VEHICLE_SPAWN_A        (90.0000)
#define SIMPLE_VEHICLE_STORE_DISTANCE (8.0)
#define SIMPLE_VEHICLE_MAX_FUEL        (100.0)
#define SIMPLE_VEHICLE_TICK_MS         (5000)
#define SIMPLE_VEHICLE_GPS_MS          (60000)
#define SIMPLE_VEHICLE_DAMAGE_LIMIT    (250.0)

#define DIALOG_SIMPLE_VEHICLES        (5100)
#define DIALOG_SIMPLE_VEHICLE_INFO    (5101)
#define DIALOG_SIMPLE_VEHICLE_ACTIONS (5102)
#define SIMPLE_VEHICLE_DEFAULT_MODEL  (560)

new
    s_SimpleVehicleCount[MAX_PLAYERS],
    s_SimpleVehicleCharacterID[MAX_PLAYERS],
    s_SimpleVehicleActiveSlot[MAX_PLAYERS],
    s_SimpleVehicleSelectedSlot[MAX_PLAYERS],
    bool:s_SimpleVehiclesLoaded[MAX_PLAYERS],
    bool:s_SimpleVehiclesLoading[MAX_PLAYERS],
    s_SimpleVehicleDatabaseID[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleServerID[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleModelID[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleColor1[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleColor2[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleStorage[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleLocked[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleEngine[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleTrunk[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleFuel[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleMileage[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleHealth[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleParkX[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleParkY[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleParkZ[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    Float:s_SimpleVehicleParkA[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleInterior[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleVirtualWorld[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    VEHICLE_PANEL_STATUS:s_SimpleVehiclePanels[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    VEHICLE_DOOR_STATUS:s_SimpleVehicleDoors[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    VEHICLE_LIGHT_STATUS:s_SimpleVehicleLights[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    VEHICLE_TYRE_STATUS:s_SimpleVehicleTyres[MAX_PLAYERS][SIMPLE_VEHICLE_MAX],
    s_SimpleVehicleGPSTimer[MAX_PLAYERS],
    s_SimpleVehicleTimer,
    s_SimpleVehiclePlate[MAX_PLAYERS][SIMPLE_VEHICLE_MAX][SIMPLE_VEHICLE_PLATE_LENGTH],
    s_SimpleRuntimeOwner[MAX_VEHICLES] = {INVALID_PLAYER_ID, ...},
    s_SimpleRuntimeSlot[MAX_VEHICLES] = {INVALID_SIMPLE_VEHICLE_SLOT, ...};

forward SimpleVehicle_LoadDeferred(playerid);
forward SimpleVehicle_OnLoaded(playerid, characterID);
forward SimpleVehicle_OnInserted(playerid, characterID);
forward SimpleVehicle_ClearGPS(playerid);
forward SimpleVehicle_RuntimeTick();

stock SimpleVehicle_Reset(playerid)
{
    s_SimpleVehicleCount[playerid] = 0;
    s_SimpleVehicleCharacterID[playerid] = INVALID_CHARACTER_ID;
    s_SimpleVehicleActiveSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    s_SimpleVehicleSelectedSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    s_SimpleVehiclesLoaded[playerid] = false;
    s_SimpleVehiclesLoading[playerid] = false;
    s_SimpleVehicleGPSTimer[playerid] = 0;
    DisablePlayerCheckpoint(playerid);

    for (new slot = 0; slot < SIMPLE_VEHICLE_MAX; slot++)
    {
        s_SimpleVehicleDatabaseID[playerid][slot] = 0;
        s_SimpleVehicleServerID[playerid][slot] = INVALID_VEHICLE_ID;
        s_SimpleVehicleModelID[playerid][slot] = 0;
        s_SimpleVehicleColor1[playerid][slot] = 1;
        s_SimpleVehicleColor2[playerid][slot] = 1;
        s_SimpleVehicleStorage[playerid][slot] = SIMPLE_VEHICLE_STORED;
        s_SimpleVehicleLocked[playerid][slot] = 1;
        s_SimpleVehicleEngine[playerid][slot] = 0;
        s_SimpleVehicleTrunk[playerid][slot] = 0;
        s_SimpleVehicleFuel[playerid][slot] = SIMPLE_VEHICLE_MAX_FUEL;
        s_SimpleVehicleMileage[playerid][slot] = 0.0;
        s_SimpleVehicleHealth[playerid][slot] = 1000.0;
        s_SimpleVehicleParkX[playerid][slot] = GANTON_SPAWN_X;
        s_SimpleVehicleParkY[playerid][slot] = GANTON_SPAWN_Y;
        s_SimpleVehicleParkZ[playerid][slot] = GANTON_SPAWN_Z;
        s_SimpleVehicleParkA[playerid][slot] = GANTON_SPAWN_A;
        s_SimpleVehicleInterior[playerid][slot] = 0;
        s_SimpleVehicleVirtualWorld[playerid][slot] = 0;
        s_SimpleVehiclePanels[playerid][slot] = VEHICLE_PANEL_STATUS:0;
        s_SimpleVehicleDoors[playerid][slot] = VEHICLE_DOOR_STATUS:0;
        s_SimpleVehicleLights[playerid][slot] = VEHICLE_LIGHT_STATUS:0;
        s_SimpleVehicleTyres[playerid][slot] = VEHICLE_TYRE_STATUS:0;
        s_SimpleVehiclePlate[playerid][slot][0] = 0;
    }
    return 1;
}

stock SimpleVehicle_GetStorageName(storage, destination[], size)
{
    switch (storage)
    {
        case SIMPLE_VEHICLE_SPAWNED: format(destination, size, "Dang ra");
        case SIMPLE_VEHICLE_IMPOUNDED: format(destination, size, "Tam giu");
        case SIMPLE_VEHICLE_DESTROYED: format(destination, size, "Hu hong");
        default: format(destination, size, "Da cat");
    }
    return 1;
}

stock bool:SimpleVehicle_IsValidSlot(playerid, slot)
{
    return (
        s_SimpleVehiclesLoaded[playerid] &&
        slot >= 0 &&
        slot < s_SimpleVehicleCount[playerid] &&
        s_SimpleVehicleDatabaseID[playerid][slot] > 0
    );
}

stock SimpleVehicle_UpdateStorage(playerid, slot, storage)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        s_SimpleVehicleDatabaseID[playerid][slot] <= 0 ||
        s_SimpleVehicleCharacterID[playerid] == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    s_SimpleVehicleStorage[playerid][slot] = storage;

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `storage_state` = %d WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `deleted_at` IS NULL",
        storage,
        s_SimpleVehicleDatabaseID[playerid][slot],
        s_SimpleVehicleCharacterID[playerid]
    );
    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

stock SimpleVehicle_GetModelName(modelID, destination[], size)
{
    if (modelID < 400 || modelID > 611)
    {
        format(destination, size, "Khong ro");
        return 0;
    }

    new modelName[32];
    Model_GetName(modelID, modelName);
    format(destination, size, "%s", modelName);
    return 1;
}

stock SimpleVehicle_CaptureRuntime(playerid, slot)
{
    if (slot < 0 || slot >= SIMPLE_VEHICLE_MAX)
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        return 0;
    }

    GetVehicleHealth(vehicleid, s_SimpleVehicleHealth[playerid][slot]);
    GetVehicleDamageStatus(
        vehicleid,
        s_SimpleVehiclePanels[playerid][slot],
        s_SimpleVehicleDoors[playerid][slot],
        s_SimpleVehicleLights[playerid][slot],
        s_SimpleVehicleTyres[playerid][slot]
    );

    new engine, lights, alarm, doors, bonnet, boot, objective;
    GetVehicleParamsEx(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );
    s_SimpleVehicleLocked[playerid][slot] = doors == 1;
    s_SimpleVehicleEngine[playerid][slot] = engine == 1;
    s_SimpleVehicleTrunk[playerid][slot] = boot == 1;
    return 1;
}

stock SimpleVehicle_SaveState(playerid, slot, bool:updatePark, storage)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        s_SimpleVehicleDatabaseID[playerid][slot] <= 0 ||
        s_SimpleVehicleCharacterID[playerid] == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    SimpleVehicle_CaptureRuntime(playerid, slot);

    if (updatePark &&
        s_SimpleVehicleServerID[playerid][slot] != INVALID_VEHICLE_ID &&
        IsValidVehicle(s_SimpleVehicleServerID[playerid][slot]))
    {
        new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
        GetVehiclePos(
            vehicleid,
            s_SimpleVehicleParkX[playerid][slot],
            s_SimpleVehicleParkY[playerid][slot],
            s_SimpleVehicleParkZ[playerid][slot]
        );
        GetVehicleZAngle(
            vehicleid,
            s_SimpleVehicleParkA[playerid][slot]
        );
        s_SimpleVehicleInterior[playerid][slot] = GetVehicleInterior(vehicleid);
        s_SimpleVehicleVirtualWorld[playerid][slot] = GetVehicleVirtualWorld(vehicleid);
    }

    s_SimpleVehicleStorage[playerid][slot] = storage;

    new query[1200];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `park_x` = %f, `park_y` = %f, `park_z` = %f, `park_a` = %f, `interior_id` = %d, `virtual_world` = %d, `health` = %f, `fuel_liters` = %f, `panels_damage` = %d, `doors_damage` = %d, `lights_damage` = %d, `tyres_damage` = %d, `mileage_km` = %f, `storage_state` = %d, `is_locked` = %d WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `deleted_at` IS NULL",
        s_SimpleVehicleParkX[playerid][slot],
        s_SimpleVehicleParkY[playerid][slot],
        s_SimpleVehicleParkZ[playerid][slot],
        s_SimpleVehicleParkA[playerid][slot],
        s_SimpleVehicleInterior[playerid][slot],
        s_SimpleVehicleVirtualWorld[playerid][slot],
        s_SimpleVehicleHealth[playerid][slot],
        s_SimpleVehicleFuel[playerid][slot],
        _:s_SimpleVehiclePanels[playerid][slot],
        _:s_SimpleVehicleDoors[playerid][slot],
        _:s_SimpleVehicleLights[playerid][slot],
        _:s_SimpleVehicleTyres[playerid][slot],
        s_SimpleVehicleMileage[playerid][slot],
        storage,
        s_SimpleVehicleLocked[playerid][slot],
        s_SimpleVehicleDatabaseID[playerid][slot],
        s_SimpleVehicleCharacterID[playerid]
    );
    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

stock SimpleVehicle_ToggleLock(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        SendClientMessage(playerid, COLOR_RED, "Xe chua duoc lay ra.");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    if (!IsPlayerInVehicle(playerid, vehicleid) &&
        !IsPlayerInRangeOfPoint(playerid, SIMPLE_VEHICLE_STORE_DISTANCE, x, y, z))
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai dung gan xe.");
        return 0;
    }

    s_SimpleVehicleLocked[playerid][slot] =
        !s_SimpleVehicleLocked[playerid][slot];
    SetVehicleParamsEx(
        vehicleid,
        -1,
        -1,
        -1,
        s_SimpleVehicleLocked[playerid][slot] ? 1 : 0,
        -1,
        -1,
        -1
    );
    SimpleVehicle_SaveState(
        playerid,
        slot,
        false,
        s_SimpleVehicleStorage[playerid][slot]
    );

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        s_SimpleVehicleLocked[playerid][slot] ? "Da khoa xe." : "Da mo khoa xe."
    );
    return 1;
}

stock SimpleVehicle_Park(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        SendClientMessage(playerid, COLOR_RED, "Xe chua duoc lay ra.");
        return 0;
    }
    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai ngoi o ghe lai de do xe.");
        return 0;
    }
    if (Vehicle_Speed(vehicleid) > 2)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay dung xe truoc khi do.");
        return 0;
    }

    SimpleVehicle_SaveState(
        playerid,
        slot,
        true,
        s_SimpleVehicleStorage[playerid][slot]
    );
    SendClientMessage(playerid, COLOR_WHITE, "Da luu vi tri do xe.");
    return 1;
}

stock SimpleVehicle_ToggleTrunk(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        SendClientMessage(playerid, COLOR_RED, "Xe chua duoc lay ra.");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    if (!IsPlayerInRangeOfPoint(playerid, SIMPLE_VEHICLE_STORE_DISTANCE, x, y, z))
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai dung gan xe.");
        return 0;
    }

    s_SimpleVehicleTrunk[playerid][slot] =
        !s_SimpleVehicleTrunk[playerid][slot];
    SetVehicleParamsEx(
        vehicleid,
        -1,
        -1,
        -1,
        -1,
        -1,
        s_SimpleVehicleTrunk[playerid][slot] ? 1 : 0,
        -1
    );
    SendClientMessage(
        playerid,
        COLOR_WHITE,
        s_SimpleVehicleTrunk[playerid][slot] ? "Da mo cop xe." : "Da dong cop xe."
    );
    return 1;
}

stock SimpleVehicle_ShowGPS(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new Float:x, Float:y, Float:z;
    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        GetVehiclePos(vehicleid, x, y, z);
    }
    else
    {
        x = s_SimpleVehicleParkX[playerid][slot];
        y = s_SimpleVehicleParkY[playerid][slot];
        z = s_SimpleVehicleParkZ[playerid][slot];
    }

    if (s_SimpleVehicleGPSTimer[playerid])
    {
        KillTimer(s_SimpleVehicleGPSTimer[playerid]);
    }
    SetPlayerCheckpoint(playerid, x, y, z, 4.0);
    s_SimpleVehicleGPSTimer[playerid] =
        SetTimerEx("SimpleVehicle_ClearGPS", SIMPLE_VEHICLE_GPS_MS, false, "d", playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Da bat GPS tim xe trong 60 giay.");
    return 1;
}

public SimpleVehicle_ClearGPS(playerid)
{
    if (IsPlayerConnected(playerid))
    {
        DisablePlayerCheckpoint(playerid);
    }
    s_SimpleVehicleGPSTimer[playerid] = 0;
    return 1;
}

stock SimpleVehicle_ClearRuntimeLink(playerid, slot)
{
    if (slot < 0 || slot >= SIMPLE_VEHICLE_MAX)
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid >= 1 && vehicleid < MAX_VEHICLES)
    {
        s_SimpleRuntimeOwner[vehicleid] = INVALID_PLAYER_ID;
        s_SimpleRuntimeSlot[vehicleid] = INVALID_SIMPLE_VEHICLE_SLOT;
    }

    s_SimpleVehicleServerID[playerid][slot] = INVALID_VEHICLE_ID;
    if (s_SimpleVehicleActiveSlot[playerid] == slot)
    {
        s_SimpleVehicleActiveSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    }
    return 1;
}

stock bool:SimpleVehicle_GetRuntimeOwner(vehicleid, &ownerid, &slot)
{
    if (vehicleid < 1 || vehicleid >= MAX_VEHICLES)
    {
        return false;
    }

    ownerid = s_SimpleRuntimeOwner[vehicleid];
    slot = s_SimpleRuntimeSlot[vehicleid];

    return (
        ownerid != INVALID_PLAYER_ID &&
        ownerid >= 0 &&
        ownerid < MAX_PLAYERS &&
        slot >= 0 &&
        slot < SIMPLE_VEHICLE_MAX &&
        s_SimpleVehicleServerID[ownerid][slot] == vehicleid
    );
}

stock SimpleVehicle_Store(playerid, slot, bool:requireDistance, bool:notify)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        s_SimpleVehicleDatabaseID[playerid][slot] <= 0)
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        SimpleVehicle_ClearRuntimeLink(playerid, slot);
        SimpleVehicle_UpdateStorage(playerid, slot, SIMPLE_VEHICLE_STORED);

        if (notify && IsPlayerConnected(playerid))
        {
            SendClientMessage(playerid, COLOR_WHITE, "Xe khong con trong game, da chuyen ve trang thai cat.");
        }
        return 1;
    }

    if (requireDistance)
    {
        new Float:x, Float:y, Float:z;
        GetVehiclePos(vehicleid, x, y, z);

        if (!IsPlayerInRangeOfPoint(
            playerid,
            SIMPLE_VEHICLE_STORE_DISTANCE,
            x,
            y,
            z
        ))
        {
            SendClientMessage(playerid, COLOR_RED, "Ban phai dung gan xe de cat xe.");
            return 0;
        }
    }

    SimpleVehicle_SaveState(
        playerid,
        slot,
        false,
        SIMPLE_VEHICLE_STORED
    );
    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (IsPlayerConnected(targetid) && IsPlayerInVehicle(targetid, vehicleid))
        {
            RemovePlayerFromVehicle(targetid);
        }
    }

    SimpleVehicle_ClearRuntimeLink(playerid, slot);
    DestroyVehicle(vehicleid);

    if (notify && IsPlayerConnected(playerid))
    {
        SendClientMessage(playerid, COLOR_WHITE, "Da cat xe.");
    }
    return 1;
}

stock SimpleVehicle_Spawn(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        SendClientMessage(playerid, COLOR_RED, "Du lieu xe khong hop le.");
        return 0;
    }

    if (s_SimpleVehicleStorage[playerid][slot] == SIMPLE_VEHICLE_IMPOUNDED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe dang o bai tam giu.");
        return 0;
    }
    if (s_SimpleVehicleStorage[playerid][slot] == SIMPLE_VEHICLE_DESTROYED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe dang hu hong.");
        return 0;
    }
    if (s_SimpleVehicleServerID[playerid][slot] != INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe nay dang o trong game.");
        return 0;
    }
    if (s_SimpleVehicleActiveSlot[playerid] != INVALID_SIMPLE_VEHICLE_SLOT)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chi duoc lay mot xe cung luc.");
        return 0;
    }

    new const vehicleid = CreateVehicle(
        s_SimpleVehicleModelID[playerid][slot],
        s_SimpleVehicleParkX[playerid][slot],
        s_SimpleVehicleParkY[playerid][slot],
        s_SimpleVehicleParkZ[playerid][slot],
        s_SimpleVehicleParkA[playerid][slot],
        s_SimpleVehicleColor1[playerid][slot],
        s_SimpleVehicleColor2[playerid][slot],
        -1
    );
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the tao xe luc nay.");
        return 0;
    }

    LinkVehicleToInterior(vehicleid, s_SimpleVehicleInterior[playerid][slot]);
    SetVehicleVirtualWorld(vehicleid, s_SimpleVehicleVirtualWorld[playerid][slot]);
    SetVehicleNumberPlate(vehicleid, s_SimpleVehiclePlate[playerid][slot]);
    SetVehicleHealth(vehicleid, s_SimpleVehicleHealth[playerid][slot]);
    UpdateVehicleDamageStatus(
        vehicleid,
        s_SimpleVehiclePanels[playerid][slot],
        s_SimpleVehicleDoors[playerid][slot],
        s_SimpleVehicleLights[playerid][slot],
        s_SimpleVehicleTyres[playerid][slot]
    );
    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        s_SimpleVehicleLocked[playerid][slot] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF
    );
    s_SimpleVehicleEngine[playerid][slot] = 0;
    s_SimpleVehicleTrunk[playerid][slot] = 0;

    s_SimpleVehicleServerID[playerid][slot] = vehicleid;
    s_SimpleVehicleActiveSlot[playerid] = slot;
    s_SimpleRuntimeOwner[vehicleid] = playerid;
    s_SimpleRuntimeSlot[vehicleid] = slot;
    SimpleVehicle_UpdateStorage(playerid, slot, SIMPLE_VEHICLE_SPAWNED);

    SendClientMessage(playerid, COLOR_WHITE, "Da lay xe tai diem nhan xe Ganton.");
    return 1;
}

stock SimpleVehicle_Load(playerid)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        s_SimpleVehiclesLoading[playerid])
    {
        return 0;
    }

    new const characterID = GetPlayerCharacterID(playerid);
    if (characterID == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    if (s_SimpleVehicleActiveSlot[playerid] != INVALID_SIMPLE_VEHICLE_SLOT)
    {
        SimpleVehicle_Store(
            playerid,
            s_SimpleVehicleActiveSlot[playerid],
            false,
            false
        );
    }

    s_SimpleVehicleCount[playerid] = 0;
    s_SimpleVehicleCharacterID[playerid] = characterID;
    s_SimpleVehicleActiveSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    s_SimpleVehicleSelectedSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    s_SimpleVehiclesLoaded[playerid] = false;
    s_SimpleVehiclesLoading[playerid] = true;

    for (new slot = 0; slot < SIMPLE_VEHICLE_MAX; slot++)
    {
        s_SimpleVehicleDatabaseID[playerid][slot] = 0;
        s_SimpleVehicleServerID[playerid][slot] = INVALID_VEHICLE_ID;
        s_SimpleVehicleModelID[playerid][slot] = 0;
        s_SimpleVehicleStorage[playerid][slot] = SIMPLE_VEHICLE_STORED;
        s_SimpleVehiclePlate[playerid][slot][0] = 0;
    }

    new query[512];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `vehicle_id`, `model_id`, `plate`, `color_1`, `color_2`, `park_x`, `park_y`, `park_z`, `park_a`, `interior_id`, `virtual_world`, `health`, `fuel_liters`, `panels_damage`, `doors_damage`, `lights_damage`, `tyres_damage`, `mileage_km`, `storage_state`, `is_locked` FROM `player_vehicles` WHERE `owner_character_id` = %d AND `deleted_at` IS NULL ORDER BY `vehicle_id` ASC LIMIT %d",
        characterID,
        SIMPLE_VEHICLE_MAX
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "SimpleVehicle_OnLoaded",
        "dd",
        playerid,
        characterID
    );
    return 1;
}

public SimpleVehicle_OnLoaded(playerid, characterID)
{
    if (!IsPlayerConnected(playerid))
    {
        return 1;
    }

    // A player can switch character while an older query is still pending.
    // Ignore that result without blocking the new character's load.
    if (!IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID)
    {
        if (s_SimpleVehicleCharacterID[playerid] == characterID)
        {
            s_SimpleVehiclesLoading[playerid] = false;
        }
        return 1;
    }

    if (s_SimpleVehicleCharacterID[playerid] != characterID)
    {
        return 1;
    }

    new rows = cache_num_rows();
    if (rows > SIMPLE_VEHICLE_MAX)
    {
        rows = SIMPLE_VEHICLE_MAX;
    }

    new value;
    for (new row = 0; row < rows; row++)
    {
        cache_get_value_name_int(
            row,
            "vehicle_id",
            s_SimpleVehicleDatabaseID[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "model_id",
            s_SimpleVehicleModelID[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "color_1",
            s_SimpleVehicleColor1[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "color_2",
            s_SimpleVehicleColor2[playerid][row]
        );
        cache_get_value_name(
            row,
            "plate",
            s_SimpleVehiclePlate[playerid][row],
            SIMPLE_VEHICLE_PLATE_LENGTH
        );
        cache_get_value_name_float(
            row,
            "park_x",
            s_SimpleVehicleParkX[playerid][row]
        );
        cache_get_value_name_float(
            row,
            "park_y",
            s_SimpleVehicleParkY[playerid][row]
        );
        cache_get_value_name_float(
            row,
            "park_z",
            s_SimpleVehicleParkZ[playerid][row]
        );
        cache_get_value_name_float(
            row,
            "park_a",
            s_SimpleVehicleParkA[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "interior_id",
            s_SimpleVehicleInterior[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "virtual_world",
            s_SimpleVehicleVirtualWorld[playerid][row]
        );
        cache_get_value_name_float(
            row,
            "health",
            s_SimpleVehicleHealth[playerid][row]
        );
        cache_get_value_name_float(
            row,
            "fuel_liters",
            s_SimpleVehicleFuel[playerid][row]
        );
        cache_get_value_name_int(row, "panels_damage", value);
        s_SimpleVehiclePanels[playerid][row] = VEHICLE_PANEL_STATUS:value;
        cache_get_value_name_int(row, "doors_damage", value);
        s_SimpleVehicleDoors[playerid][row] = VEHICLE_DOOR_STATUS:value;
        cache_get_value_name_int(row, "lights_damage", value);
        s_SimpleVehicleLights[playerid][row] = VEHICLE_LIGHT_STATUS:value;
        cache_get_value_name_int(row, "tyres_damage", value);
        s_SimpleVehicleTyres[playerid][row] = VEHICLE_TYRE_STATUS:value;
        cache_get_value_name_float(
            row,
            "mileage_km",
            s_SimpleVehicleMileage[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "storage_state",
            s_SimpleVehicleStorage[playerid][row]
        );
        cache_get_value_name_int(
            row,
            "is_locked",
            s_SimpleVehicleLocked[playerid][row]
        );

        if (s_SimpleVehicleFuel[playerid][row] < 0.0)
        {
            s_SimpleVehicleFuel[playerid][row] = 0.0;
        }
        if (s_SimpleVehicleFuel[playerid][row] > SIMPLE_VEHICLE_MAX_FUEL)
        {
            s_SimpleVehicleFuel[playerid][row] = SIMPLE_VEHICLE_MAX_FUEL;
        }
        if (s_SimpleVehicleHealth[playerid][row] <= 0.0)
        {
            s_SimpleVehicleStorage[playerid][row] = SIMPLE_VEHICLE_DESTROYED;
            SimpleVehicle_UpdateStorage(
                playerid,
                row,
                SIMPLE_VEHICLE_DESTROYED
            );
        }

        // A runtime vehicle cannot survive a disconnect or server restart.
        // If the database still says "spawned", safely normalize it on load.
        if (s_SimpleVehicleStorage[playerid][row] == SIMPLE_VEHICLE_SPAWNED)
        {
            s_SimpleVehicleStorage[playerid][row] = SIMPLE_VEHICLE_STORED;
            SimpleVehicle_UpdateStorage(
                playerid,
                row,
                SIMPLE_VEHICLE_STORED
            );
        }
    }

    s_SimpleVehicleCount[playerid] = rows;
    s_SimpleVehiclesLoaded[playerid] = true;
    s_SimpleVehiclesLoading[playerid] = false;

    printf(
        "[VEHICLES SIMPLE] loaded player=%d character=%d rows=%d",
        playerid,
        characterID,
        rows
    );
    return 1;
}

stock SimpleVehicle_ToggleEngine(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    if (vehicleid == INVALID_VEHICLE_ID ||
        !IsValidVehicle(vehicleid) ||
        GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai ngoi o ghe lai cua xe.");
        return 0;
    }

    if (!s_SimpleVehicleEngine[playerid][slot] &&
        s_SimpleVehicleFuel[playerid][slot] <= 0.0)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe da het xang.");
        return 0;
    }

    s_SimpleVehicleEngine[playerid][slot] =
        !s_SimpleVehicleEngine[playerid][slot];
    SetVehicleParamsEx(
        vehicleid,
        s_SimpleVehicleEngine[playerid][slot] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1
    );
    SimpleVehicle_SaveState(
        playerid,
        slot,
        false,
        s_SimpleVehicleStorage[playerid][slot]
    );

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        s_SimpleVehicleEngine[playerid][slot] ? "Da khoi dong xe." : "Da tat dong co."
    );
    return 1;
}

stock SimpleVehicle_MarkDestroyed(playerid, slot)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        s_SimpleVehicleDatabaseID[playerid][slot] <= 0)
    {
        return 0;
    }

    new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
    s_SimpleVehicleHealth[playerid][slot] = 0.0;
    s_SimpleVehicleEngine[playerid][slot] = 0;
    s_SimpleVehicleStorage[playerid][slot] = SIMPLE_VEHICLE_DESTROYED;
    SimpleVehicle_SaveState(
        playerid,
        slot,
        false,
        SIMPLE_VEHICLE_DESTROYED
    );
    SimpleVehicle_ClearRuntimeLink(playerid, slot);

    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        DestroyVehicle(vehicleid);
    }
    return 1;
}

public SimpleVehicle_RuntimeTick()
{
    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid) ||
            !s_SimpleVehiclesLoaded[playerid] ||
            s_SimpleVehicleActiveSlot[playerid] == INVALID_SIMPLE_VEHICLE_SLOT)
        {
            continue;
        }

        new const slot = s_SimpleVehicleActiveSlot[playerid];
        new const vehicleid = s_SimpleVehicleServerID[playerid][slot];
        if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
        {
            SimpleVehicle_ClearRuntimeLink(playerid, slot);
            SimpleVehicle_UpdateStorage(playerid, slot, SIMPLE_VEHICLE_STORED);
            continue;
        }

        SimpleVehicle_CaptureRuntime(playerid, slot);
        if (s_SimpleVehicleHealth[playerid][slot] <= 0.0)
        {
            SimpleVehicle_MarkDestroyed(playerid, slot);
            SendClientMessage(playerid, COLOR_RED, "Xe da bi pha huy va chuyen sang trang thai hu hong.");
            continue;
        }

        if (s_SimpleVehicleEngine[playerid][slot] &&
            GetPlayerState(playerid) == PLAYER_STATE_DRIVER &&
            GetPlayerVehicleID(playerid) == vehicleid)
        {
            new const speed = Vehicle_Speed(vehicleid);
            if (speed > 0)
            {
                s_SimpleVehicleFuel[playerid][slot] -=
                    (Float:speed * 5.0 / 3600.0 * 0.35);
                s_SimpleVehicleMileage[playerid][slot] +=
                    (Float:speed * 5.0 / 3600.0);
            }

            if (s_SimpleVehicleFuel[playerid][slot] <= 0.0)
            {
                s_SimpleVehicleFuel[playerid][slot] = 0.0;
                s_SimpleVehicleEngine[playerid][slot] = 0;
                SetVehicleParamsEx(
                    vehicleid,
                    VEHICLE_PARAMS_OFF,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1,
                    -1
                );
                SendClientMessage(playerid, COLOR_RED, "Xe da het xang va tu dong tat may.");
            }
        }

        SimpleVehicle_SaveState(
            playerid,
            slot,
            false,
            SIMPLE_VEHICLE_SPAWNED
        );
    }
    return 1;
}

public SimpleVehicle_LoadDeferred(playerid)
{
    if (IsPlayerConnected(playerid) && IsPlayerCharacterLoaded(playerid))
    {
        SimpleVehicle_Load(playerid);
    }
    return 1;
}

stock SimpleVehicle_ShowList(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chua tai nhan vat.");
        return 1;
    }

    if (!s_SimpleVehiclesLoaded[playerid])
    {
        if (!s_SimpleVehiclesLoading[playerid])
        {
            SimpleVehicle_Load(playerid);
        }
        SendClientMessage(playerid, COLOR_WHITE, "Dang tai danh sach xe, thu lai sau.");
        return 1;
    }

    new body[2048];
    new row[128];
    new storage[24];
    new modelName[32];

    format(body, sizeof(body), "#\tXe\tBien so\tTrang thai\n");

    if (s_SimpleVehicleCount[playerid] == 0)
    {
        strcat(body, "-\t-\tChua co xe\t-\n", sizeof(body));
    }
    else
    {
        for (new slot = 0; slot < s_SimpleVehicleCount[playerid]; slot++)
        {
            SimpleVehicle_GetModelName(
                s_SimpleVehicleModelID[playerid][slot],
                modelName,
                sizeof(modelName)
            );
            SimpleVehicle_GetStorageName(
                s_SimpleVehicleStorage[playerid][slot],
                storage,
                sizeof(storage)
            );
            format(
                row,
                sizeof(row),
                "%d\t%s\t%s\t%s\n",
                slot + 1,
                modelName,
                s_SimpleVehiclePlate[playerid][slot],
                storage
            );
            strcat(body, row, sizeof(body));
        }
    }

    ShowPlayerDialog(
        playerid,
        DIALOG_SIMPLE_VEHICLES,
        DIALOG_STYLE_TABLIST_HEADERS,
        "Xe cua toi",
        body,
        "Chon",
        "Dong"
    );
    return 1;
}

stock SimpleVehicle_ShowActions(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return SimpleVehicle_ShowList(playerid);
    }

    s_SimpleVehicleSelectedSlot[playerid] = slot;

    new modelName[32];
    SimpleVehicle_GetModelName(
        s_SimpleVehicleModelID[playerid][slot],
        modelName,
        sizeof(modelName)
    );

    new title[64];
    format(
        title,
        sizeof(title),
        "%s - %s",
        modelName,
        s_SimpleVehiclePlate[playerid][slot]
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_SIMPLE_VEHICLE_ACTIONS,
        DIALOG_STYLE_LIST,
        title,
        "Lay xe\nCat xe\nThong tin\nKhoa/Mo khoa\nDo xe\nGPS tim xe\nMo/Dong cop",
        "Chon",
        "Quay lai"
    );
    return 1;
}

stock SimpleVehicle_ShowInfo(playerid, slot)
{
    if (slot < 0 || slot >= s_SimpleVehicleCount[playerid])
    {
        return SimpleVehicle_ShowList(playerid);
    }

    new storage[24];
    new modelName[32];
    new locked[16];
    new engine[16];
    new trunk[16];
    new body[1024];

    SimpleVehicle_GetModelName(
        s_SimpleVehicleModelID[playerid][slot],
        modelName,
        sizeof(modelName)
    );
    SimpleVehicle_GetStorageName(
        s_SimpleVehicleStorage[playerid][slot],
        storage,
        sizeof(storage)
    );
    format(
        locked,
        sizeof(locked),
        "%s",
        s_SimpleVehicleLocked[playerid][slot] ? "Da khoa" : "Da mo"
    );
    format(
        engine,
        sizeof(engine),
        "%s",
        s_SimpleVehicleEngine[playerid][slot] ? "Dang chay" : "Tat"
    );
    format(
        trunk,
        sizeof(trunk),
        "%s",
        s_SimpleVehicleTrunk[playerid][slot] ? "Dang mo" : "Dong"
    );
    format(
        body,
        sizeof(body),
        "Xe: %s (model %d)\nDatabase ID: %d\nBien so: %s\nTrang thai: %s\nMau: %d/%d\nHP: %.0f/1000\nXang: %.1f/100.0 L\nQuang duong: %.1f km\nKhoa: %s\nDong co: %s\nCop: %s\nDamage: P%d D%d L%d T%d\nVi tri do: %.1f, %.1f, %.1f",
        modelName,
        s_SimpleVehicleModelID[playerid][slot],
        s_SimpleVehicleDatabaseID[playerid][slot],
        s_SimpleVehiclePlate[playerid][slot],
        storage,
        s_SimpleVehicleColor1[playerid][slot],
        s_SimpleVehicleColor2[playerid][slot],
        s_SimpleVehicleHealth[playerid][slot],
        s_SimpleVehicleFuel[playerid][slot],
        s_SimpleVehicleMileage[playerid][slot],
        locked,
        engine,
        trunk,
        _:s_SimpleVehiclePanels[playerid][slot],
        _:s_SimpleVehicleDoors[playerid][slot],
        _:s_SimpleVehicleLights[playerid][slot],
        _:s_SimpleVehicleTyres[playerid][slot],
        s_SimpleVehicleParkX[playerid][slot],
        s_SimpleVehicleParkY[playerid][slot],
        s_SimpleVehicleParkZ[playerid][slot]
    );

    ShowPlayerDialog(
        playerid,
        DIALOG_SIMPLE_VEHICLE_INFO,
        DIALOG_STYLE_MSGBOX,
        "Thong tin xe",
        body,
        "Quay lai",
        "Dong"
    );
    return 1;
}

stock SimpleVehicle_CreateTestRow(playerid, modelID)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        !s_SimpleVehiclesLoaded[playerid])
    {
        SendClientMessage(playerid, COLOR_RED, "Du lieu nhan vat/xe chua tai xong.");
        return 0;
    }

    if (s_SimpleVehicleActiveSlot[playerid] != INVALID_SIMPLE_VEHICLE_SLOT)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay cat xe dang hoat dong truoc.");
        return 0;
    }

    if (modelID < 400 || modelID > 611)
    {
        SendClientMessage(playerid, COLOR_RED, "Model phai nam trong khoang 400-611.");
        return 0;
    }

    new plate[SIMPLE_VEHICLE_PLATE_LENGTH];
    format(
        plate,
        sizeof(plate),
        "TEST-%d-%d",
        GetPlayerCharacterID(playerid),
        GetTickCount() % 10000
    );

    new query[512];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "INSERT INTO `player_vehicles` (`owner_character_id`, `model_id`, `plate`) VALUES (%d, %d, '%e')",
        GetPlayerCharacterID(playerid),
        modelID,
        plate
    );
    mysql_tquery(
        g_DatabaseHandle,
        query,
        "SimpleVehicle_OnInserted",
        "dd",
        playerid,
        GetPlayerCharacterID(playerid)
    );

    SendClientMessage(playerid, COLOR_WHITE, "Dang tao xe test...");
    return 1;
}

public SimpleVehicle_OnInserted(playerid, characterID)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID)
    {
        return 1;
    }

    if (cache_insert_id() <= 0)
    {
        SendClientMessage(playerid, COLOR_RED, "Tao xe test that bai.");
        return 1;
    }

    s_SimpleVehiclesLoading[playerid] = false;
    SimpleVehicle_Load(playerid);
    SendClientMessage(playerid, COLOR_WHITE, "Da tao xe test. Mo /vehicles sau khi tai xong.");
    return 1;
}

CMD:vehicles(playerid, params[])
{
    #pragma unused params
    SimpleVehicle_ShowList(playerid);
    return 1;
}

CMD:addvehicle(playerid, params[])
{
    new modelID = SIMPLE_VEHICLE_DEFAULT_MODEL;
    if (params[0] != 0)
    {
        modelID = strval(params);
    }

    SimpleVehicle_CreateTestRow(playerid, modelID);
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    switch (dialogid)
    {
        case DIALOG_SIMPLE_VEHICLES:
        {
            if (!response)
            {
                return 1;
            }

            if (listitem < 0 || listitem >= s_SimpleVehicleCount[playerid])
            {
                SendClientMessage(playerid, COLOR_RED, "Khong co xe o dong nay.");
                return SimpleVehicle_ShowList(playerid);
            }

            return SimpleVehicle_ShowActions(playerid, listitem);
        }
        case DIALOG_SIMPLE_VEHICLE_ACTIONS:
        {
            if (!response)
            {
                return SimpleVehicle_ShowList(playerid);
            }

            new const slot = s_SimpleVehicleSelectedSlot[playerid];
            if (!SimpleVehicle_IsValidSlot(playerid, slot))
            {
                return SimpleVehicle_ShowList(playerid);
            }

            switch (listitem)
            {
                case 0:
                {
                    SimpleVehicle_Spawn(playerid, slot);
                    return SimpleVehicle_ShowList(playerid);
                }
                case 1:
                {
                    SimpleVehicle_Store(playerid, slot, true, true);
                    return SimpleVehicle_ShowList(playerid);
                }
                case 2:
                {
                    return SimpleVehicle_ShowInfo(playerid, slot);
                }
                case 3:
                {
                    SimpleVehicle_ToggleLock(playerid, slot);
                    return SimpleVehicle_ShowActions(playerid, slot);
                }
                case 4:
                {
                    SimpleVehicle_Park(playerid, slot);
                    return SimpleVehicle_ShowActions(playerid, slot);
                }
                case 5:
                {
                    SimpleVehicle_ShowGPS(playerid, slot);
                    return SimpleVehicle_ShowActions(playerid, slot);
                }
                case 6:
                {
                    SimpleVehicle_ToggleTrunk(playerid, slot);
                    return SimpleVehicle_ShowActions(playerid, slot);
                }
            }
            return SimpleVehicle_ShowActions(playerid, slot);
        }
        case DIALOG_SIMPLE_VEHICLE_INFO:
        {
            if (response)
            {
                return SimpleVehicle_ShowActions(
                    playerid,
                    s_SimpleVehicleSelectedSlot[playerid]
                );
            }
            return 1;
        }
    }
    return 1;
}

hook OnGameModeInit()
{
    for (new vehicleid = 0; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        s_SimpleRuntimeOwner[vehicleid] = INVALID_PLAYER_ID;
        s_SimpleRuntimeSlot[vehicleid] = INVALID_SIMPLE_VEHICLE_SLOT;
    }
    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        SimpleVehicle_Reset(playerid);
    }
    s_SimpleVehicleTimer =
        SetTimer("SimpleVehicle_RuntimeTick", SIMPLE_VEHICLE_TICK_MS, true);
    return 1;
}

hook OnGameModeExit()
{
    if (s_SimpleVehicleTimer)
    {
        KillTimer(s_SimpleVehicleTimer);
        s_SimpleVehicleTimer = 0;
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    SimpleVehicle_Reset(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (s_SimpleVehicleActiveSlot[playerid] != INVALID_SIMPLE_VEHICLE_SLOT)
    {
        SimpleVehicle_Store(
            playerid,
            s_SimpleVehicleActiveSlot[playerid],
            false,
            false
        );
    }

    if (s_SimpleVehicleGPSTimer[playerid])
    {
        KillTimer(s_SimpleVehicleGPSTimer[playerid]);
        s_SimpleVehicleGPSTimer[playerid] = 0;
    }
    DisablePlayerCheckpoint(playerid);
    SimpleVehicle_Reset(playerid);
    return 1;
}

hook OnPlayerStateChange(playerid, PLAYER_STATE:newState, PLAYER_STATE:oldState)
{
    #pragma unused oldState

    if (newState != PLAYER_STATE_DRIVER &&
        newState != PLAYER_STATE_PASSENGER)
    {
        return 1;
    }

    new ownerid, slot;
    new const vehicleid = GetPlayerVehicleID(playerid);
    if (!SimpleVehicle_GetRuntimeOwner(vehicleid, ownerid, slot))
    {
        return 1;
    }

    if (playerid != ownerid)
    {
        RemovePlayerFromVehicle(playerid);
        SendClientMessage(playerid, COLOR_RED, "Day la xe ca nhan, ban khong co quyen su dung.");
    }
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    #pragma unused killerid

    new ownerid, slot;
    if (!SimpleVehicle_GetRuntimeOwner(vehicleid, ownerid, slot))
    {
        return 1;
    }

    SimpleVehicle_MarkDestroyed(ownerid, slot);
    if (IsPlayerConnected(ownerid))
    {
        SendClientMessage(ownerid, COLOR_RED, "Xe da no, chuyen sang trang thai hu hong va khong the lay ra.");
    }
    return 1;
}

hook OnCharacterLoaded(playerid)
{
    SetTimerEx("SimpleVehicle_LoadDeferred", 50, false, "d", playerid);
    return 1;
}

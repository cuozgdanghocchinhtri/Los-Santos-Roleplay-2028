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

enum E_PLAYER_VEHICLE_DATA
{
    pvDatabaseID,
    pvServerID,
    pvModelID,
    pvColor1,
    pvColor2,
    pvStorage,
    pvLocked,
    pvEngine,
    pvTrunk,
    Float:pvFuel,
    Float:pvMileage,
    Float:pvHealth,
    Float:pvParkX,
    Float:pvParkY,
    Float:pvParkZ,
    Float:pvParkA,
    pvInterior,
    pvVirtualWorld,
    VEHICLE_PANEL_STATUS:pvPanels,
    VEHICLE_DOOR_STATUS:pvDoors,
    VEHICLE_LIGHT_STATUS:pvLights,
    VEHICLE_TYRE_STATUS:pvTyres,
    pvPlate[SIMPLE_VEHICLE_PLATE_LENGTH]
};

enum E_RUNTIME_VEHICLE_TYPE
{
    VEHICLE_TYPE_NONE = 0,
    VEHICLE_TYPE_PLAYER,
    VEHICLE_TYPE_JOB,
    VEHICLE_TYPE_FACTION,
    VEHICLE_TYPE_FAMILY,
    VEHICLE_TYPE_ADMIN
};

enum E_RUNTIME_VEHICLE_DATA
{
    bool:vrExists,
    E_RUNTIME_VEHICLE_TYPE:vrType,
    vrSourceID,
    vrSourceSlot,
    vrDatabaseID
};

new PlayerVehicle[MAX_PLAYERS][SIMPLE_VEHICLE_MAX][E_PLAYER_VEHICLE_DATA];
new VehicleRuntime[MAX_VEHICLES][E_RUNTIME_VEHICLE_DATA];

new
    s_SimpleVehicleCount[MAX_PLAYERS],
    s_SimpleVehicleCharacterID[MAX_PLAYERS],
    s_SimpleVehicleActiveSlot[MAX_PLAYERS],
    s_SimpleVehicleSelectedSlot[MAX_PLAYERS],
    bool:s_SimpleVehiclesLoaded[MAX_PLAYERS],
    bool:s_SimpleVehiclesLoading[MAX_PLAYERS],
    s_SimpleVehicleGPSTimer[MAX_PLAYERS],
    s_SimpleVehicleTimer;

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
        PlayerVehicle[playerid][slot][pvDatabaseID] = 0;
        PlayerVehicle[playerid][slot][pvServerID] = INVALID_VEHICLE_ID;
        PlayerVehicle[playerid][slot][pvModelID] = 0;
        PlayerVehicle[playerid][slot][pvColor1] = 1;
        PlayerVehicle[playerid][slot][pvColor2] = 1;
        PlayerVehicle[playerid][slot][pvStorage] = SIMPLE_VEHICLE_STORED;
        PlayerVehicle[playerid][slot][pvLocked] = 1;
        PlayerVehicle[playerid][slot][pvEngine] = 0;
        PlayerVehicle[playerid][slot][pvTrunk] = 0;
        PlayerVehicle[playerid][slot][pvFuel] = SIMPLE_VEHICLE_MAX_FUEL;
        PlayerVehicle[playerid][slot][pvMileage] = 0.0;
        PlayerVehicle[playerid][slot][pvHealth] = 1000.0;
        PlayerVehicle[playerid][slot][pvParkX] = GANTON_SPAWN_X;
        PlayerVehicle[playerid][slot][pvParkY] = GANTON_SPAWN_Y;
        PlayerVehicle[playerid][slot][pvParkZ] = GANTON_SPAWN_Z;
        PlayerVehicle[playerid][slot][pvParkA] = GANTON_SPAWN_A;
        PlayerVehicle[playerid][slot][pvInterior] = 0;
        PlayerVehicle[playerid][slot][pvVirtualWorld] = 0;
        PlayerVehicle[playerid][slot][pvPanels] = VEHICLE_PANEL_STATUS:0;
        PlayerVehicle[playerid][slot][pvDoors] = VEHICLE_DOOR_STATUS:0;
        PlayerVehicle[playerid][slot][pvLights] = VEHICLE_LIGHT_STATUS:0;
        PlayerVehicle[playerid][slot][pvTyres] = VEHICLE_TYRE_STATUS:0;
        PlayerVehicle[playerid][slot][pvPlate][0] = 0;
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
        PlayerVehicle[playerid][slot][pvDatabaseID] > 0
    );
}


stock VehicleRuntime_Reset(vehicleid)
{
    if (vehicleid < 0 || vehicleid >= MAX_VEHICLES)
    {
        return 0;
    }

    VehicleRuntime[vehicleid][vrExists] = false;
    VehicleRuntime[vehicleid][vrType] = VEHICLE_TYPE_NONE;
    VehicleRuntime[vehicleid][vrSourceID] = -1;
    VehicleRuntime[vehicleid][vrSourceSlot] = INVALID_SIMPLE_VEHICLE_SLOT;
    VehicleRuntime[vehicleid][vrDatabaseID] = 0;
    return 1;
}

stock VehicleRuntime_Register(
    vehicleid,
    E_RUNTIME_VEHICLE_TYPE:type,
    sourceID,
    sourceSlot,
    databaseID = 0
)
{
    if (vehicleid <= 0 || vehicleid >= MAX_VEHICLES || !IsValidVehicle(vehicleid))
    {
        return 0;
    }

    VehicleRuntime[vehicleid][vrExists] = true;
    VehicleRuntime[vehicleid][vrType] = type;
    VehicleRuntime[vehicleid][vrSourceID] = sourceID;
    VehicleRuntime[vehicleid][vrSourceSlot] = sourceSlot;
    VehicleRuntime[vehicleid][vrDatabaseID] = databaseID;
    return 1;
}

stock bool:VehicleRuntime_IsRegistered(vehicleid)
{
    return (
        vehicleid > 0 &&
        vehicleid < MAX_VEHICLES &&
        VehicleRuntime[vehicleid][vrExists]
    );
}

stock SimpleVehicle_FindPlayerByCharacter(characterID)
{
    if (characterID == INVALID_CHARACTER_ID)
    {
        return INVALID_PLAYER_ID;
    }

    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid) ||
            !s_SimpleVehiclesLoaded[playerid] ||
            s_SimpleVehicleCharacterID[playerid] != characterID)
        {
            continue;
        }
        return playerid;
    }
    return INVALID_PLAYER_ID;
}

stock Float:PlayerVehicle_GetFuelBySource(characterID, slot)
{
    new const playerid = SimpleVehicle_FindPlayerByCharacter(characterID);
    if (playerid == INVALID_PLAYER_ID || !SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0.0;
    }
    return PlayerVehicle[playerid][slot][pvFuel];
}

stock PlayerVehicle_SetFuelBySource(characterID, slot, Float:amount)
{
    new const playerid = SimpleVehicle_FindPlayerByCharacter(characterID);
    if (playerid == INVALID_PLAYER_ID || !SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    if (amount < 0.0) amount = 0.0;
    if (amount > SIMPLE_VEHICLE_MAX_FUEL) amount = SIMPLE_VEHICLE_MAX_FUEL;

    PlayerVehicle[playerid][slot][pvFuel] = amount;
    return 1;
}

stock Float:Vehicle_GetFuel(vehicleid)
{
    if (!VehicleRuntime_IsRegistered(vehicleid))
    {
        return 0.0;
    }

    switch (VehicleRuntime[vehicleid][vrType])
    {
        case VEHICLE_TYPE_PLAYER:
        {
            return PlayerVehicle_GetFuelBySource(
                VehicleRuntime[vehicleid][vrSourceID],
                VehicleRuntime[vehicleid][vrSourceSlot]
            );
        }
    }
    return 0.0;
}

stock Vehicle_SetFuel(vehicleid, Float:amount)
{
    if (!VehicleRuntime_IsRegistered(vehicleid))
    {
        return 0;
    }

    switch (VehicleRuntime[vehicleid][vrType])
    {
        case VEHICLE_TYPE_PLAYER:
        {
            return PlayerVehicle_SetFuelBySource(
                VehicleRuntime[vehicleid][vrSourceID],
                VehicleRuntime[vehicleid][vrSourceSlot],
                amount
            );
        }
    }
    return 0;
}

stock SimpleVehicle_UpdateStorage(playerid, slot, storage)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        PlayerVehicle[playerid][slot][pvDatabaseID] <= 0 ||
        s_SimpleVehicleCharacterID[playerid] == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    PlayerVehicle[playerid][slot][pvStorage] = storage;

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `storage_state` = %d WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `deleted_at` IS NULL",
        storage,
        PlayerVehicle[playerid][slot][pvDatabaseID],
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

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        return 0;
    }

    GetVehicleHealth(vehicleid, PlayerVehicle[playerid][slot][pvHealth]);
    GetVehicleDamageStatus(
        vehicleid,
        PlayerVehicle[playerid][slot][pvPanels],
        PlayerVehicle[playerid][slot][pvDoors],
        PlayerVehicle[playerid][slot][pvLights],
        PlayerVehicle[playerid][slot][pvTyres]
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
    PlayerVehicle[playerid][slot][pvLocked] = doors == 1;
    PlayerVehicle[playerid][slot][pvEngine] = engine == 1;
    PlayerVehicle[playerid][slot][pvTrunk] = boot == 1;
    return 1;
}

stock SimpleVehicle_SaveState(playerid, slot, bool:updatePark, storage)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        PlayerVehicle[playerid][slot][pvDatabaseID] <= 0 ||
        s_SimpleVehicleCharacterID[playerid] == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    SimpleVehicle_CaptureRuntime(playerid, slot);

    if (updatePark &&
        PlayerVehicle[playerid][slot][pvServerID] != INVALID_VEHICLE_ID &&
        IsValidVehicle(PlayerVehicle[playerid][slot][pvServerID]))
    {
        new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
        GetVehiclePos(
            vehicleid,
            PlayerVehicle[playerid][slot][pvParkX],
            PlayerVehicle[playerid][slot][pvParkY],
            PlayerVehicle[playerid][slot][pvParkZ]
        );
        GetVehicleZAngle(
            vehicleid,
            PlayerVehicle[playerid][slot][pvParkA]
        );
        PlayerVehicle[playerid][slot][pvInterior] = GetVehicleInterior(vehicleid);
        PlayerVehicle[playerid][slot][pvVirtualWorld] = GetVehicleVirtualWorld(vehicleid);
    }

    PlayerVehicle[playerid][slot][pvStorage] = storage;

    new query[1200];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_vehicles` SET `park_x` = %f, `park_y` = %f, `park_z` = %f, `park_a` = %f, `interior_id` = %d, `virtual_world` = %d, `health` = %f, `fuel_liters` = %f, `panels_damage` = %d, `doors_damage` = %d, `lights_damage` = %d, `tyres_damage` = %d, `mileage_km` = %f, `storage_state` = %d, `is_locked` = %d WHERE `vehicle_id` = %d AND `owner_character_id` = %d AND `deleted_at` IS NULL",
        PlayerVehicle[playerid][slot][pvParkX],
        PlayerVehicle[playerid][slot][pvParkY],
        PlayerVehicle[playerid][slot][pvParkZ],
        PlayerVehicle[playerid][slot][pvParkA],
        PlayerVehicle[playerid][slot][pvInterior],
        PlayerVehicle[playerid][slot][pvVirtualWorld],
        PlayerVehicle[playerid][slot][pvHealth],
        PlayerVehicle[playerid][slot][pvFuel],
        _:PlayerVehicle[playerid][slot][pvPanels],
        _:PlayerVehicle[playerid][slot][pvDoors],
        _:PlayerVehicle[playerid][slot][pvLights],
        _:PlayerVehicle[playerid][slot][pvTyres],
        PlayerVehicle[playerid][slot][pvMileage],
        storage,
        PlayerVehicle[playerid][slot][pvLocked],
        PlayerVehicle[playerid][slot][pvDatabaseID],
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

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
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

    PlayerVehicle[playerid][slot][pvLocked] =
        !PlayerVehicle[playerid][slot][pvLocked];
    SetVehicleParamsEx(
        vehicleid,
        -1,
        -1,
        -1,
        PlayerVehicle[playerid][slot][pvLocked] ? 1 : 0,
        -1,
        -1,
        -1
    );
    SimpleVehicle_SaveState(
        playerid,
        slot,
        false,
        PlayerVehicle[playerid][slot][pvStorage]
    );

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        PlayerVehicle[playerid][slot][pvLocked] ? "Da khoa xe." : "Da mo khoa xe."
    );
    return 1;
}

stock SimpleVehicle_Park(playerid, slot)
{
    if (!SimpleVehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
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
        PlayerVehicle[playerid][slot][pvStorage]
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

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
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

    PlayerVehicle[playerid][slot][pvTrunk] =
        !PlayerVehicle[playerid][slot][pvTrunk];
    SetVehicleParamsEx(
        vehicleid,
        -1,
        -1,
        -1,
        -1,
        -1,
        PlayerVehicle[playerid][slot][pvTrunk] ? 1 : 0,
        -1
    );
    SendClientMessage(
        playerid,
        COLOR_WHITE,
        PlayerVehicle[playerid][slot][pvTrunk] ? "Da mo cop xe." : "Da dong cop xe."
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
    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        GetVehiclePos(vehicleid, x, y, z);
    }
    else
    {
        x = PlayerVehicle[playerid][slot][pvParkX];
        y = PlayerVehicle[playerid][slot][pvParkY];
        z = PlayerVehicle[playerid][slot][pvParkZ];
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

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
    if (vehicleid >= 1 && vehicleid < MAX_VEHICLES)
    {
        VehicleRuntime_Reset(vehicleid);
    }

    PlayerVehicle[playerid][slot][pvServerID] = INVALID_VEHICLE_ID;
    if (s_SimpleVehicleActiveSlot[playerid] == slot)
    {
        s_SimpleVehicleActiveSlot[playerid] = INVALID_SIMPLE_VEHICLE_SLOT;
    }
    return 1;
}

stock bool:SimpleVehicle_GetRuntimeOwner(vehicleid, &ownerid, &slot)
{
    if (!VehicleRuntime_IsRegistered(vehicleid) ||
        VehicleRuntime[vehicleid][vrType] != VEHICLE_TYPE_PLAYER)
    {
        return false;
    }

    slot = VehicleRuntime[vehicleid][vrSourceSlot];
    ownerid = SimpleVehicle_FindPlayerByCharacter(
        VehicleRuntime[vehicleid][vrSourceID]
    );

    return (
        ownerid != INVALID_PLAYER_ID &&
        slot >= 0 &&
        slot < SIMPLE_VEHICLE_MAX &&
        PlayerVehicle[ownerid][slot][pvServerID] == vehicleid
    );
}

stock SimpleVehicle_Store(playerid, slot, bool:requireDistance, bool:notify)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        PlayerVehicle[playerid][slot][pvDatabaseID] <= 0)
    {
        return 0;
    }

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
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

    if (PlayerVehicle[playerid][slot][pvStorage] == SIMPLE_VEHICLE_IMPOUNDED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe dang o bai tam giu.");
        return 0;
    }
    if (PlayerVehicle[playerid][slot][pvStorage] == SIMPLE_VEHICLE_DESTROYED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe dang hu hong.");
        return 0;
    }
    if (PlayerVehicle[playerid][slot][pvServerID] != INVALID_VEHICLE_ID)
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
        PlayerVehicle[playerid][slot][pvModelID],
        PlayerVehicle[playerid][slot][pvParkX],
        PlayerVehicle[playerid][slot][pvParkY],
        PlayerVehicle[playerid][slot][pvParkZ],
        PlayerVehicle[playerid][slot][pvParkA],
        PlayerVehicle[playerid][slot][pvColor1],
        PlayerVehicle[playerid][slot][pvColor2],
        -1
    );
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the tao xe luc nay.");
        return 0;
    }

    LinkVehicleToInterior(vehicleid, PlayerVehicle[playerid][slot][pvInterior]);
    SetVehicleVirtualWorld(vehicleid, PlayerVehicle[playerid][slot][pvVirtualWorld]);
    SetVehicleNumberPlate(vehicleid, PlayerVehicle[playerid][slot][pvPlate]);
    SetVehicleHealth(vehicleid, PlayerVehicle[playerid][slot][pvHealth]);
    UpdateVehicleDamageStatus(
        vehicleid,
        PlayerVehicle[playerid][slot][pvPanels],
        PlayerVehicle[playerid][slot][pvDoors],
        PlayerVehicle[playerid][slot][pvLights],
        PlayerVehicle[playerid][slot][pvTyres]
    );
    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        PlayerVehicle[playerid][slot][pvLocked] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF
    );
    PlayerVehicle[playerid][slot][pvEngine] = 0;
    PlayerVehicle[playerid][slot][pvTrunk] = 0;

    PlayerVehicle[playerid][slot][pvServerID] = vehicleid;
    s_SimpleVehicleActiveSlot[playerid] = slot;

    VehicleRuntime_Register(
        vehicleid,
        VEHICLE_TYPE_PLAYER,
        s_SimpleVehicleCharacterID[playerid],
        slot,
        PlayerVehicle[playerid][slot][pvDatabaseID]
    );

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
        PlayerVehicle[playerid][slot][pvDatabaseID] = 0;
        PlayerVehicle[playerid][slot][pvServerID] = INVALID_VEHICLE_ID;
        PlayerVehicle[playerid][slot][pvModelID] = 0;
        PlayerVehicle[playerid][slot][pvStorage] = SIMPLE_VEHICLE_STORED;
        PlayerVehicle[playerid][slot][pvPlate][0] = 0;
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
            PlayerVehicle[playerid][row][pvDatabaseID]
        );
        cache_get_value_name_int(
            row,
            "model_id",
            PlayerVehicle[playerid][row][pvModelID]
        );
        cache_get_value_name_int(
            row,
            "color_1",
            PlayerVehicle[playerid][row][pvColor1]
        );
        cache_get_value_name_int(
            row,
            "color_2",
            PlayerVehicle[playerid][row][pvColor2]
        );
        cache_get_value_name(
            row,
            "plate",
            PlayerVehicle[playerid][row][pvPlate],
            SIMPLE_VEHICLE_PLATE_LENGTH
        );
        cache_get_value_name_float(
            row,
            "park_x",
            PlayerVehicle[playerid][row][pvParkX]
        );
        cache_get_value_name_float(
            row,
            "park_y",
            PlayerVehicle[playerid][row][pvParkY]
        );
        cache_get_value_name_float(
            row,
            "park_z",
            PlayerVehicle[playerid][row][pvParkZ]
        );
        cache_get_value_name_float(
            row,
            "park_a",
            PlayerVehicle[playerid][row][pvParkA]
        );
        cache_get_value_name_int(
            row,
            "interior_id",
            PlayerVehicle[playerid][row][pvInterior]
        );
        cache_get_value_name_int(
            row,
            "virtual_world",
            PlayerVehicle[playerid][row][pvVirtualWorld]
        );
        cache_get_value_name_float(
            row,
            "health",
            PlayerVehicle[playerid][row][pvHealth]
        );
        cache_get_value_name_float(
            row,
            "fuel_liters",
            PlayerVehicle[playerid][row][pvFuel]
        );
        cache_get_value_name_int(row, "panels_damage", value);
        PlayerVehicle[playerid][row][pvPanels] = VEHICLE_PANEL_STATUS:value;
        cache_get_value_name_int(row, "doors_damage", value);
        PlayerVehicle[playerid][row][pvDoors] = VEHICLE_DOOR_STATUS:value;
        cache_get_value_name_int(row, "lights_damage", value);
        PlayerVehicle[playerid][row][pvLights] = VEHICLE_LIGHT_STATUS:value;
        cache_get_value_name_int(row, "tyres_damage", value);
        PlayerVehicle[playerid][row][pvTyres] = VEHICLE_TYRE_STATUS:value;
        cache_get_value_name_float(
            row,
            "mileage_km",
            PlayerVehicle[playerid][row][pvMileage]
        );
        cache_get_value_name_int(
            row,
            "storage_state",
            PlayerVehicle[playerid][row][pvStorage]
        );
        cache_get_value_name_int(
            row,
            "is_locked",
            PlayerVehicle[playerid][row][pvLocked]
        );

        if (PlayerVehicle[playerid][row][pvFuel] < 0.0)
        {
            PlayerVehicle[playerid][row][pvFuel] = 0.0;
        }
        if (PlayerVehicle[playerid][row][pvFuel] > SIMPLE_VEHICLE_MAX_FUEL)
        {
            PlayerVehicle[playerid][row][pvFuel] = SIMPLE_VEHICLE_MAX_FUEL;
        }
        if (PlayerVehicle[playerid][row][pvHealth] <= 0.0)
        {
            PlayerVehicle[playerid][row][pvStorage] = SIMPLE_VEHICLE_DESTROYED;
            SimpleVehicle_UpdateStorage(
                playerid,
                row,
                SIMPLE_VEHICLE_DESTROYED
            );
        }

        // A runtime vehicle cannot survive a disconnect or server restart.
        // If the database still says "spawned", safely normalize it on load.
        if (PlayerVehicle[playerid][row][pvStorage] == SIMPLE_VEHICLE_SPAWNED)
        {
            PlayerVehicle[playerid][row][pvStorage] = SIMPLE_VEHICLE_STORED;
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

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
    if (vehicleid == INVALID_VEHICLE_ID ||
        !IsValidVehicle(vehicleid) ||
        GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai ngoi o ghe lai cua xe.");
        return 0;
    }

    if (!PlayerVehicle[playerid][slot][pvEngine] &&
        PlayerVehicle[playerid][slot][pvFuel] <= 0.0)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe da het xang.");
        return 0;
    }

    PlayerVehicle[playerid][slot][pvEngine] =
        !PlayerVehicle[playerid][slot][pvEngine];
    SetVehicleParamsEx(
        vehicleid,
        PlayerVehicle[playerid][slot][pvEngine] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF,
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
        PlayerVehicle[playerid][slot][pvStorage]
    );

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        PlayerVehicle[playerid][slot][pvEngine] ? "Da khoi dong xe." : "Da tat dong co."
    );
    return 1;
}

stock SimpleVehicle_MarkDestroyed(playerid, slot)
{
    if (slot < 0 ||
        slot >= SIMPLE_VEHICLE_MAX ||
        PlayerVehicle[playerid][slot][pvDatabaseID] <= 0)
    {
        return 0;
    }

    new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
    PlayerVehicle[playerid][slot][pvHealth] = 0.0;
    PlayerVehicle[playerid][slot][pvEngine] = 0;
    PlayerVehicle[playerid][slot][pvStorage] = SIMPLE_VEHICLE_DESTROYED;
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
        new const vehicleid = PlayerVehicle[playerid][slot][pvServerID];
        if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
        {
            SimpleVehicle_ClearRuntimeLink(playerid, slot);
            SimpleVehicle_UpdateStorage(playerid, slot, SIMPLE_VEHICLE_STORED);
            continue;
        }

        SimpleVehicle_CaptureRuntime(playerid, slot);
        if (PlayerVehicle[playerid][slot][pvHealth] <= 0.0)
        {
            SimpleVehicle_MarkDestroyed(playerid, slot);
            SendClientMessage(playerid, COLOR_RED, "Xe da bi pha huy va chuyen sang trang thai hu hong.");
            continue;
        }

        if (PlayerVehicle[playerid][slot][pvEngine] &&
            GetPlayerState(playerid) == PLAYER_STATE_DRIVER &&
            GetPlayerVehicleID(playerid) == vehicleid)
        {
            new const speed = Vehicle_Speed(vehicleid);
            if (speed > 0)
            {
                PlayerVehicle[playerid][slot][pvFuel] -=
                    (Float:speed * 5.0 / 3600.0 * 0.35);
                PlayerVehicle[playerid][slot][pvMileage] +=
                    (Float:speed * 5.0 / 3600.0);
            }

            if (PlayerVehicle[playerid][slot][pvFuel] <= 0.0)
            {
                PlayerVehicle[playerid][slot][pvFuel] = 0.0;
                PlayerVehicle[playerid][slot][pvEngine] = 0;
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
                PlayerVehicle[playerid][slot][pvModelID],
                modelName,
                sizeof(modelName)
            );
            SimpleVehicle_GetStorageName(
                PlayerVehicle[playerid][slot][pvStorage],
                storage,
                sizeof(storage)
            );
            format(
                row,
                sizeof(row),
                "%d\t%s\t%s\t%s\n",
                slot + 1,
                modelName,
                PlayerVehicle[playerid][slot][pvPlate],
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
        PlayerVehicle[playerid][slot][pvModelID],
        modelName,
        sizeof(modelName)
    );

    new title[64];
    format(
        title,
        sizeof(title),
        "%s - %s",
        modelName,
        PlayerVehicle[playerid][slot][pvPlate]
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
        PlayerVehicle[playerid][slot][pvModelID],
        modelName,
        sizeof(modelName)
    );
    SimpleVehicle_GetStorageName(
        PlayerVehicle[playerid][slot][pvStorage],
        storage,
        sizeof(storage)
    );
    format(
        locked,
        sizeof(locked),
        "%s",
        PlayerVehicle[playerid][slot][pvLocked] ? "Da khoa" : "Da mo"
    );
    format(
        engine,
        sizeof(engine),
        "%s",
        PlayerVehicle[playerid][slot][pvEngine] ? "Dang chay" : "Tat"
    );
    format(
        trunk,
        sizeof(trunk),
        "%s",
        PlayerVehicle[playerid][slot][pvTrunk] ? "Dang mo" : "Dong"
    );
    format(
        body,
        sizeof(body),
        "Xe: %s (model %d)\nDatabase ID: %d\nBien so: %s\nTrang thai: %s\nMau: %d/%d\nHP: %.0f/1000\nXang: %.1f/100.0 L\nQuang duong: %.1f km\nKhoa: %s\nDong co: %s\nCop: %s\nDamage: P%d D%d L%d T%d\nVi tri do: %.1f, %.1f, %.1f",
        modelName,
        PlayerVehicle[playerid][slot][pvModelID],
        PlayerVehicle[playerid][slot][pvDatabaseID],
        PlayerVehicle[playerid][slot][pvPlate],
        storage,
        PlayerVehicle[playerid][slot][pvColor1],
        PlayerVehicle[playerid][slot][pvColor2],
        PlayerVehicle[playerid][slot][pvHealth],
        PlayerVehicle[playerid][slot][pvFuel],
        PlayerVehicle[playerid][slot][pvMileage],
        locked,
        engine,
        trunk,
        _:PlayerVehicle[playerid][slot][pvPanels],
        _:PlayerVehicle[playerid][slot][pvDoors],
        _:PlayerVehicle[playerid][slot][pvLights],
        _:PlayerVehicle[playerid][slot][pvTyres],
        PlayerVehicle[playerid][slot][pvParkX],
        PlayerVehicle[playerid][slot][pvParkY],
        PlayerVehicle[playerid][slot][pvParkZ]
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
        VehicleRuntime_Reset(vehicleid);
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

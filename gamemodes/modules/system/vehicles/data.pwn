#include <YSI_Game\y_vehicledata>

//-----------------------------------------------------------------------------
// Owned vehicle definitions and runtime state
//-----------------------------------------------------------------------------

#define MAX_OWNED_VEHICLES          (20)
#define OWNED_VEHICLE_PLATE_LENGTH  (17)
#define INVALID_OWNED_VEHICLE_SLOT  (-1)

#define VEHICLE_ACTION_COOLDOWN_MS  (10000)
#define VEHICLE_GPS_DURATION_MS     (60000)
#define VEHICLE_GPS_MAP_ICON        (20)
#define VEHICLE_GPS_MARKER_TYPE     (55)
#define VEHICLE_STORE_DISTANCE      (8.0)
#define VEHICLE_PARK_SPEED_LIMIT    (0.08)
#define VEHICLE_DAMAGE_HEALTH       (650.0)
#define VEHICLE_DESTROYED_HEALTH    (250.0)

enum E_OWNED_VEHICLE_STORAGE
{
    OV_STORAGE_STORED = 0,
    OV_STORAGE_SPAWNED,
    OV_STORAGE_IMPOUNDED,
    OV_STORAGE_DESTROYED
};

enum E_OWNED_VEHICLE_FILTER
{
    OV_FILTER_ALL = 0,
    OV_FILTER_SPAWNED,
    OV_FILTER_STORED,
    OV_FILTER_DAMAGED,
    OV_FILTER_IMPOUNDED,
    OV_FILTER_FAVORITE
};

enum E_OWNED_VEHICLE_ACTION
{
    OV_ACTION_INFO = 0,
    OV_ACTION_SPAWN,
    OV_ACTION_STORE,
    OV_ACTION_FIND,
    OV_ACTION_PARK,
    OV_ACTION_LOCK,
    OV_ACTION_FAVORITE,
    OV_ACTION_DELETE
};

enum E_OWNED_VEHICLE_DATA
{
    ov_DatabaseID,
    ov_ServerID,
    ov_ModelID,
    ov_Plate[OWNED_VEHICLE_PLATE_LENGTH],
    ov_Color1,
    ov_Color2,
    Float:ov_ParkX,
    Float:ov_ParkY,
    Float:ov_ParkZ,
    Float:ov_ParkA,
    ov_Interior,
    ov_VirtualWorld,
    Float:ov_Health,
    VEHICLE_PANEL_STATUS:ov_Panels,
    VEHICLE_DOOR_STATUS:ov_Doors,
    VEHICLE_LIGHT_STATUS:ov_Lights,
    VEHICLE_TYRE_STATUS:ov_Tyres,
    Float:ov_Mileage,
    E_OWNED_VEHICLE_STORAGE:ov_Storage,
    bool:ov_Favorite,
    bool:ov_Locked,
    bool:ov_GPSInstalled,
    bool:ov_GPSActive,
    bool:ov_Stolen,
    ov_LastDriverCharacterID,
    bool:ov_Dirty,
    Float:ov_LastX,
    Float:ov_LastY,
    Float:ov_LastZ
};

new
    s_OwnedVehicle[MAX_PLAYERS][MAX_OWNED_VEHICLES][E_OWNED_VEHICLE_DATA],
    s_OwnedVehicleCount[MAX_PLAYERS],
    bool:s_OwnedVehiclesLoaded[MAX_PLAYERS],
    bool:s_OwnedVehicleShowPending[MAX_PLAYERS],
    s_OwnedVehicleCharacterID[MAX_PLAYERS],
    E_OWNED_VEHICLE_FILTER:s_OwnedVehicleFilter[MAX_PLAYERS],
    s_OwnedVehicleSelectedSlot[MAX_PLAYERS],
    s_OwnedVehicleDeleteSlot[MAX_PLAYERS],
    s_OwnedVehicleDialogSlots[MAX_PLAYERS][MAX_OWNED_VEHICLES + 1],
    E_OWNED_VEHICLE_ACTION:s_OwnedVehicleDialogActions[MAX_PLAYERS][10],
    s_OwnedVehicleActionCount[MAX_PLAYERS],
    s_OwnedVehicleLastActionTick[MAX_PLAYERS],
    s_OwnedVehicleGPSTimer[MAX_PLAYERS],
    s_ServerVehicleOwner[MAX_VEHICLES] = {INVALID_PLAYER_ID, ...},
    s_ServerVehicleSlot[MAX_VEHICLES] = {INVALID_OWNED_VEHICLE_SLOT, ...},
    s_OwnedVehicleRuntimeTimer;

forward Vehicle_OnLoaded(playerid, characterID);
forward Vehicle_OnDeleted(playerid, characterID, databaseID, slot);
forward Vehicle_LoadDeferred(playerid);
forward Vehicle_ClearGPS(playerid);
forward Vehicle_ProcessRuntime();
forward Vehicle_ShowList(playerid);

stock bool:Vehicle_IsValidSlot(playerid, slot)
{
    return (
        slot >= 0 &&
        slot < MAX_OWNED_VEHICLES &&
        s_OwnedVehicle[playerid][slot][ov_DatabaseID] > 0
    );
}

stock Vehicle_GetModelName(modelID, destination[], size)
{
    if (modelID < 400 || modelID > 611)
    {
        format(destination, size, "Unknown");
        return 0;
    }

    new modelName[32];
    Model_GetName(modelID, modelName);
    format(destination, size, "%s", modelName);
    return 1;
}

stock Vehicle_GetStorageName(E_OWNED_VEHICLE_STORAGE:storage, destination[], size)
{
    switch (storage)
    {
        case OV_STORAGE_SPAWNED: format(destination, size, "Dang hoat dong");
        case OV_STORAGE_IMPOUNDED: format(destination, size, "Impound");
        case OV_STORAGE_DESTROYED: format(destination, size, "Hu hong nang");
        default: format(destination, size, "Da cat");
    }

    return 1;
}

stock Vehicle_GetFilterName(E_OWNED_VEHICLE_FILTER:filter, destination[], size)
{
    switch (filter)
    {
        case OV_FILTER_SPAWNED: format(destination, size, "Dang hoat dong");
        case OV_FILTER_STORED: format(destination, size, "Da cat");
        case OV_FILTER_DAMAGED: format(destination, size, "Hu hong");
        case OV_FILTER_IMPOUNDED: format(destination, size, "Impound");
        case OV_FILTER_FAVORITE: format(destination, size, "Yeu thich");
        default: format(destination, size, "Tat ca");
    }

    return 1;
}

stock bool:Vehicle_IsDamaged(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return false;
    }

    return (
        s_OwnedVehicle[playerid][slot][ov_Health] < VEHICLE_DAMAGE_HEALTH ||
        _:s_OwnedVehicle[playerid][slot][ov_Panels] != 0 ||
        _:s_OwnedVehicle[playerid][slot][ov_Doors] != 0 ||
        _:s_OwnedVehicle[playerid][slot][ov_Lights] != 0 ||
        _:s_OwnedVehicle[playerid][slot][ov_Tyres] != 0 ||
        s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_DESTROYED
    );
}

stock bool:Vehicle_MatchesFilter(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return false;
    }

    switch (s_OwnedVehicleFilter[playerid])
    {
        case OV_FILTER_ALL:
        {
            return true;
        }
        case OV_FILTER_SPAWNED:
        {
            return s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_SPAWNED;
        }
        case OV_FILTER_STORED:
        {
            return s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_STORED;
        }
        case OV_FILTER_DAMAGED:
        {
            return Vehicle_IsDamaged(playerid, slot);
        }
        case OV_FILTER_IMPOUNDED:
        {
            return s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_IMPOUNDED;
        }
        case OV_FILTER_FAVORITE:
        {
            return s_OwnedVehicle[playerid][slot][ov_Favorite];
        }
    }

    return true;
}

stock Vehicle_GetLivePosition(
    playerid,
    slot,
    &Float:x,
    &Float:y,
    &Float:z,
    &interior,
    &virtualWorld
)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];

    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        GetVehiclePos(vehicleid, x, y, z);
        interior = GetVehicleInterior(vehicleid);
        virtualWorld = GetVehicleVirtualWorld(vehicleid);
        return 1;
    }

    x = s_OwnedVehicle[playerid][slot][ov_ParkX];
    y = s_OwnedVehicle[playerid][slot][ov_ParkY];
    z = s_OwnedVehicle[playerid][slot][ov_ParkZ];
    interior = s_OwnedVehicle[playerid][slot][ov_Interior];
    virtualWorld = s_OwnedVehicle[playerid][slot][ov_VirtualWorld];
    return 1;
}

stock Vehicle_GetLocationName(playerid, slot, destination[], size)
{
    new Float:x, Float:y, Float:z, interior, virtualWorld;
    Vehicle_GetLivePosition(playerid, slot, x, y, z, interior, virtualWorld);

    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_IMPOUNDED)
    {
        format(destination, size, "Bai tam giu");
        return 1;
    }

    if (interior != 0 || virtualWorld != 0)
    {
        format(destination, size, "Garage noi that");
        return 1;
    }

    return Zone_GetNameAt(x, y, z, destination, size);
}

stock Vehicle_GetOwnerSlot(vehicleid, &playerid, &slot)
{
    if (vehicleid < 1 || vehicleid >= MAX_VEHICLES)
    {
        return 0;
    }

    playerid = s_ServerVehicleOwner[vehicleid];
    slot = s_ServerVehicleSlot[vehicleid];

    return (
        playerid != INVALID_PLAYER_ID &&
        IsPlayerConnected(playerid) &&
        Vehicle_IsValidSlot(playerid, slot) &&
        s_OwnedVehicle[playerid][slot][ov_ServerID] == vehicleid
    );
}

stock Vehicle_ResetSlot(playerid, slot)
{
    s_OwnedVehicle[playerid][slot][ov_DatabaseID] = 0;
    s_OwnedVehicle[playerid][slot][ov_ServerID] = INVALID_VEHICLE_ID;
    s_OwnedVehicle[playerid][slot][ov_ModelID] = 0;
    s_OwnedVehicle[playerid][slot][ov_Plate][0] = 0;
    s_OwnedVehicle[playerid][slot][ov_Color1] = 1;
    s_OwnedVehicle[playerid][slot][ov_Color2] = 1;
    s_OwnedVehicle[playerid][slot][ov_ParkX] = GANTON_SPAWN_X;
    s_OwnedVehicle[playerid][slot][ov_ParkY] = GANTON_SPAWN_Y;
    s_OwnedVehicle[playerid][slot][ov_ParkZ] = GANTON_SPAWN_Z;
    s_OwnedVehicle[playerid][slot][ov_ParkA] = GANTON_SPAWN_A;
    s_OwnedVehicle[playerid][slot][ov_Interior] = 0;
    s_OwnedVehicle[playerid][slot][ov_VirtualWorld] = 0;
    s_OwnedVehicle[playerid][slot][ov_Health] = 1000.0;
    s_OwnedVehicle[playerid][slot][ov_Panels] = VEHICLE_PANEL_STATUS:0;
    s_OwnedVehicle[playerid][slot][ov_Doors] = VEHICLE_DOOR_STATUS:0;
    s_OwnedVehicle[playerid][slot][ov_Lights] = VEHICLE_LIGHT_STATUS:0;
    s_OwnedVehicle[playerid][slot][ov_Tyres] = VEHICLE_TYRE_STATUS:0;
    s_OwnedVehicle[playerid][slot][ov_Mileage] = 0.0;
    s_OwnedVehicle[playerid][slot][ov_Storage] = OV_STORAGE_STORED;
    s_OwnedVehicle[playerid][slot][ov_Favorite] = false;
    s_OwnedVehicle[playerid][slot][ov_Locked] = true;
    s_OwnedVehicle[playerid][slot][ov_GPSInstalled] = true;
    s_OwnedVehicle[playerid][slot][ov_GPSActive] = true;
    s_OwnedVehicle[playerid][slot][ov_Stolen] = false;
    s_OwnedVehicle[playerid][slot][ov_LastDriverCharacterID] = 0;
    s_OwnedVehicle[playerid][slot][ov_Dirty] = false;
    s_OwnedVehicle[playerid][slot][ov_LastX] = 0.0;
    s_OwnedVehicle[playerid][slot][ov_LastY] = 0.0;
    s_OwnedVehicle[playerid][slot][ov_LastZ] = 0.0;
    return 1;
}

stock Vehicle_ResetPlayer(playerid)
{
    for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
    {
        Vehicle_ResetSlot(playerid, slot);
        s_OwnedVehicleDialogSlots[playerid][slot] = INVALID_OWNED_VEHICLE_SLOT;
    }

    s_OwnedVehicleDialogSlots[playerid][MAX_OWNED_VEHICLES] = INVALID_OWNED_VEHICLE_SLOT;
    s_OwnedVehicleCount[playerid] = 0;
    s_OwnedVehiclesLoaded[playerid] = false;
    s_OwnedVehicleShowPending[playerid] = false;
    s_OwnedVehicleCharacterID[playerid] = INVALID_CHARACTER_ID;
    s_OwnedVehicleFilter[playerid] = OV_FILTER_ALL;
    s_OwnedVehicleSelectedSlot[playerid] = INVALID_OWNED_VEHICLE_SLOT;
    s_OwnedVehicleDeleteSlot[playerid] = INVALID_OWNED_VEHICLE_SLOT;
    s_OwnedVehicleActionCount[playerid] = 0;
    s_OwnedVehicleLastActionTick[playerid] = 0;
    return 1;
}

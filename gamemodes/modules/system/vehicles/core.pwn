#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Owned vehicle runtime, lifecycle, damage, mileage and GPS
//-----------------------------------------------------------------------------

stock bool:Vehicle_IsActionCoolingDown(playerid, &remainingSeconds)
{
    if (s_OwnedVehicleLastActionTick[playerid] == 0)
    {
        remainingSeconds = 0;
        return false;
    }

    new const elapsed = GetTickCount() - s_OwnedVehicleLastActionTick[playerid];
    if (elapsed < 0 || elapsed >= VEHICLE_ACTION_COOLDOWN_MS)
    {
        remainingSeconds = 0;
        return false;
    }

    remainingSeconds = (VEHICLE_ACTION_COOLDOWN_MS - elapsed + 999) / 1000;
    return true;
}

stock Vehicle_StartActionCooldown(playerid)
{
    s_OwnedVehicleLastActionTick[playerid] = GetTickCount();
    return 1;
}

stock Vehicle_ClearServerMapping(vehicleid)
{
    if (vehicleid >= 1 && vehicleid < MAX_VEHICLES)
    {
        s_ServerVehicleOwner[vehicleid] = INVALID_PLAYER_ID;
        s_ServerVehicleSlot[vehicleid] = INVALID_OWNED_VEHICLE_SLOT;
    }
    return 1;
}

stock Vehicle_CaptureState(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        return 0;
    }

    GetVehicleHealth(vehicleid, s_OwnedVehicle[playerid][slot][ov_Health]);
    GetVehicleDamageStatus(
        vehicleid,
        s_OwnedVehicle[playerid][slot][ov_Panels],
        s_OwnedVehicle[playerid][slot][ov_Doors],
        s_OwnedVehicle[playerid][slot][ov_Lights],
        s_OwnedVehicle[playerid][slot][ov_Tyres]
    );
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
    return 1;
}

stock bool:Vehicle_IsSpawnPointBlocked(playerid, slot)
{
    new const Float:x = s_OwnedVehicle[playerid][slot][ov_ParkX];
    new const Float:y = s_OwnedVehicle[playerid][slot][ov_ParkY];
    new const Float:z = s_OwnedVehicle[playerid][slot][ov_ParkZ];
    new const virtualWorld = s_OwnedVehicle[playerid][slot][ov_VirtualWorld];

    for (new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        if (!IsValidVehicle(vehicleid) ||
            GetVehicleVirtualWorld(vehicleid) != virtualWorld)
        {
            continue;
        }

        if (GetVehicleDistanceFromPoint(vehicleid, x, y, z) < 3.5)
        {
            return true;
        }
    }
    return false;
}

stock Vehicle_GetActiveSlot(playerid)
{
    for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
    {
        if (Vehicle_IsValidSlot(playerid, slot) &&
            s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_SPAWNED)
        {
            return slot;
        }
    }
    return INVALID_OWNED_VEHICLE_SLOT;
}

stock Vehicle_SpawnOwned(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new remainingSeconds;
    if (Vehicle_IsActionCoolingDown(playerid, remainingSeconds))
    {
        new message[96];
        format(message, sizeof(message), "Vui long doi %d giay truoc khi spawn/cat xe.", remainingSeconds);
        SendClientMessage(playerid, COLOR_RED, message);
        return 0;
    }

    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_IMPOUNDED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe dang o bai tam giu.");
        return 0;
    }
    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_DESTROYED ||
        s_OwnedVehicle[playerid][slot][ov_Health] <= VEHICLE_DESTROYED_HEALTH)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe hu hong nang, can sua chua truoc khi spawn.");
        return 0;
    }
    if (s_OwnedVehicle[playerid][slot][ov_Storage] == OV_STORAGE_SPAWNED)
    {
        SendClientMessage(playerid, COLOR_RED, "Xe nay dang hoat dong.");
        return 0;
    }
    if (Vehicle_GetActiveSlot(playerid) != INVALID_OWNED_VEHICLE_SLOT)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chi co the dung mot xe so huu cung luc.");
        return 0;
    }
    if (Vehicle_IsSpawnPointBlocked(playerid, slot))
    {
        SendClientMessage(playerid, COLOR_RED, "Vi tri dau xe dang bi can.");
        return 0;
    }

    new const vehicleid = CreateVehicle(
        s_OwnedVehicle[playerid][slot][ov_ModelID],
        s_OwnedVehicle[playerid][slot][ov_ParkX],
        s_OwnedVehicle[playerid][slot][ov_ParkY],
        s_OwnedVehicle[playerid][slot][ov_ParkZ],
        s_OwnedVehicle[playerid][slot][ov_ParkA],
        s_OwnedVehicle[playerid][slot][ov_Color1],
        s_OwnedVehicle[playerid][slot][ov_Color2],
        -1
    );
    if (vehicleid == INVALID_VEHICLE_ID)
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the tao xe luc nay.");
        return 0;
    }

    LinkVehicleToInterior(vehicleid, s_OwnedVehicle[playerid][slot][ov_Interior]);
    SetVehicleVirtualWorld(vehicleid, s_OwnedVehicle[playerid][slot][ov_VirtualWorld]);
    SetVehicleNumberPlate(vehicleid, s_OwnedVehicle[playerid][slot][ov_Plate]);
    SetVehicleHealth(vehicleid, s_OwnedVehicle[playerid][slot][ov_Health]);
    UpdateVehicleDamageStatus(
        vehicleid,
        s_OwnedVehicle[playerid][slot][ov_Panels],
        s_OwnedVehicle[playerid][slot][ov_Doors],
        s_OwnedVehicle[playerid][slot][ov_Lights],
        s_OwnedVehicle[playerid][slot][ov_Tyres]
    );
    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        VEHICLE_PARAMS_OFF,
        s_OwnedVehicle[playerid][slot][ov_Locked] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF
    );

    s_OwnedVehicle[playerid][slot][ov_ServerID] = vehicleid;
    s_OwnedVehicle[playerid][slot][ov_Storage] = OV_STORAGE_SPAWNED;
    s_OwnedVehicle[playerid][slot][ov_LastX] = s_OwnedVehicle[playerid][slot][ov_ParkX];
    s_OwnedVehicle[playerid][slot][ov_LastY] = s_OwnedVehicle[playerid][slot][ov_ParkY];
    s_OwnedVehicle[playerid][slot][ov_LastZ] = s_OwnedVehicle[playerid][slot][ov_ParkZ];
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
    s_ServerVehicleOwner[vehicleid] = playerid;
    s_ServerVehicleSlot[vehicleid] = slot;
    Vehicle_StartActionCooldown(playerid);
    Vehicle_SaveSlot(playerid, slot);
    SendClientMessage(playerid, COLOR_WHITE, "Da spawn xe tai vi tri dau cuoi cung.");
    return 1;
}

stock bool:Vehicle_HasOtherOccupants(playerid, vehicleid)
{
    for (new targetid = 0; targetid < MAX_PLAYERS; targetid++)
    {
        if (targetid != playerid &&
            IsPlayerConnected(targetid) &&
            IsPlayerInVehicle(targetid, vehicleid))
        {
            return true;
        }
    }
    return false;
}

stock Vehicle_StoreOwned(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new remainingSeconds;
    if (Vehicle_IsActionCoolingDown(playerid, remainingSeconds))
    {
        new message[96];
        format(message, sizeof(message), "Vui long doi %d giay truoc khi spawn/cat xe.", remainingSeconds);
        SendClientMessage(playerid, COLOR_RED, message);
        return 0;
    }

    new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
    if (s_OwnedVehicle[playerid][slot][ov_Storage] != OV_STORAGE_SPAWNED ||
        vehicleid == INVALID_VEHICLE_ID ||
        !IsValidVehicle(vehicleid))
    {
        SendClientMessage(playerid, COLOR_RED, "Xe nay khong hoat dong.");
        return 0;
    }

    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);
    if (GetPlayerVirtualWorld(playerid) != GetVehicleVirtualWorld(vehicleid) ||
        GetPlayerDistanceFromPoint(playerid, x, y, z) > VEHICLE_STORE_DISTANCE)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai o gan xe de cat xe.");
        return 0;
    }
    if (Vehicle_HasOtherOccupants(playerid, vehicleid))
    {
        SendClientMessage(playerid, COLOR_RED, "Khong the cat khi con nguoi khac trong xe.");
        return 0;
    }

    Vehicle_CaptureState(playerid, slot);
    if (IsPlayerInVehicle(playerid, vehicleid))
    {
        RemovePlayerFromVehicle(playerid);
    }
    Vehicle_ClearServerMapping(vehicleid);
    DestroyVehicle(vehicleid);
    s_OwnedVehicle[playerid][slot][ov_ServerID] = INVALID_VEHICLE_ID;
    s_OwnedVehicle[playerid][slot][ov_Storage] = OV_STORAGE_STORED;
    s_OwnedVehicle[playerid][slot][ov_Stolen] = false;
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
    Vehicle_StartActionCooldown(playerid);
    Vehicle_SaveSlot(playerid, slot);
    SendClientMessage(playerid, COLOR_WHITE, "Da cat xe. Vi tri dau khong bi thay doi.");
    return 1;
}

stock Vehicle_ParkOwned(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
    if (s_OwnedVehicle[playerid][slot][ov_Storage] != OV_STORAGE_SPAWNED ||
        vehicleid == INVALID_VEHICLE_ID ||
        !IsValidVehicle(vehicleid) ||
        GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        SendClientMessage(playerid, COLOR_RED, "Ban phai ngoi ghe lai de dau xe.");
        return 0;
    }

    new Float:velocityX, Float:velocityY, Float:velocityZ;
    GetVehicleVelocity(vehicleid, velocityX, velocityY, velocityZ);
    new const Float:speed = floatsqroot(
        velocityX * velocityX +
        velocityY * velocityY +
        velocityZ * velocityZ
    );
    if (speed > VEHICLE_PARK_SPEED_LIMIT)
    {
        SendClientMessage(playerid, COLOR_RED, "Hay dung han xe truoc khi dau.");
        return 0;
    }

    new Float:x, Float:y, Float:z, Float:angle, rejectReason;
    GetVehiclePos(vehicleid, x, y, z);
    GetVehicleZAngle(vehicleid, angle);
    if (!Zone_IsParkingPositionValid(
        x,
        y,
        z,
        GetVehicleInterior(vehicleid),
        GetVehicleVirtualWorld(vehicleid),
        rejectReason
    ))
    {
        switch (rejectReason)
        {
            case PARK_REJECT_WATER: SendClientMessage(playerid, COLOR_RED, "Khong the dau xe trong nuoc.");
            case PARK_REJECT_ROOFTOP: SendClientMessage(playerid, COLOR_RED, "Khong the dau xe tren mai nha.");
            case PARK_REJECT_RESTRICTED: SendClientMessage(playerid, COLOR_RED, "Khu vuc nay cam dau xe.");
            default: SendClientMessage(playerid, COLOR_RED, "Chua ho tro dau xe trong interior/virtual world.");
        }
        return 0;
    }

    Vehicle_CaptureState(playerid, slot);
    s_OwnedVehicle[playerid][slot][ov_ParkX] = x;
    s_OwnedVehicle[playerid][slot][ov_ParkY] = y;
    s_OwnedVehicle[playerid][slot][ov_ParkZ] = z;
    s_OwnedVehicle[playerid][slot][ov_ParkA] = angle;
    s_OwnedVehicle[playerid][slot][ov_Interior] = GetVehicleInterior(vehicleid);
    s_OwnedVehicle[playerid][slot][ov_VirtualWorld] = GetVehicleVirtualWorld(vehicleid);
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
    Vehicle_SaveSlot(playerid, slot);

    new location[40], message[112];
    Zone_GetNameAt(x, y, z, location, sizeof(location));
    format(message, sizeof(message), "Da luu vi tri dau xe moi tai %s.", location);
    SendClientMessage(playerid, COLOR_WHITE, message);
    return 1;
}

stock Vehicle_FindOwned(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }
    if (!s_OwnedVehicle[playerid][slot][ov_GPSInstalled] ||
        !s_OwnedVehicle[playerid][slot][ov_GPSActive])
    {
        SendClientMessage(playerid, COLOR_RED, "Khong nhan duoc tin hieu GPS cua xe.");
        return 0;
    }

    new Float:x, Float:y, Float:z, interior, virtualWorld;
    Vehicle_GetLivePosition(playerid, slot, x, y, z, interior, virtualWorld);
    Vehicle_ClearGPS(playerid);
    SetPlayerCheckpoint(playerid, x, y, z, 4.0);
    SetPlayerMapIcon(
        playerid,
        VEHICLE_GPS_MAP_ICON,
        x,
        y,
        z,
        VEHICLE_GPS_MARKER_TYPE,
        COLOR_RED,
        MAPICON_GLOBAL
    );
    s_OwnedVehicleGPSTimer[playerid] = SetTimerEx(
        "Vehicle_ClearGPS",
        VEHICLE_GPS_DURATION_MS,
        false,
        "d",
        playerid
    );

    new location[40], message[160];
    Zone_GetNameAt(x, y, z, location, sizeof(location));
    if (interior != GetPlayerInterior(playerid) ||
        virtualWorld != GetPlayerVirtualWorld(playerid))
    {
        format(message, sizeof(message), "GPS ghi nhan xe tai %s (khac interior/world), danh dau 60 giay.", location);
    }
    else
    {
        format(message, sizeof(message), "GPS da danh dau xe tai %s trong 60 giay.", location);
    }
    SendClientMessage(playerid, COLOR_WHITE, message);
    return 1;
}

public Vehicle_ClearGPS(playerid)
{
    if (IsPlayerConnected(playerid))
    {
        DisablePlayerCheckpoint(playerid);
        RemovePlayerMapIcon(playerid, VEHICLE_GPS_MAP_ICON);
    }
    if (s_OwnedVehicleGPSTimer[playerid])
    {
        KillTimer(s_OwnedVehicleGPSTimer[playerid]);
        s_OwnedVehicleGPSTimer[playerid] = 0;
    }
    return 1;
}

stock Vehicle_ToggleLock(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        new Float:x, Float:y, Float:z;
        GetVehiclePos(vehicleid, x, y, z);
        if (!IsPlayerInVehicle(playerid, vehicleid) &&
            GetPlayerDistanceFromPoint(playerid, x, y, z) > 6.0)
        {
            SendClientMessage(playerid, COLOR_RED, "Ban phai o gan xe de khoa/mo khoa.");
            return 0;
        }
    }

    s_OwnedVehicle[playerid][slot][ov_Locked] =
        !s_OwnedVehicle[playerid][slot][ov_Locked];
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;

    if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
    {
        new engine, lights, alarm, doors, bonnet, boot, objective;
        GetVehicleParamsEx(vehicleid, engine, lights, alarm, doors, bonnet, boot, objective);
        SetVehicleParamsEx(
            vehicleid,
            engine,
            lights,
            alarm,
            s_OwnedVehicle[playerid][slot][ov_Locked] ? VEHICLE_PARAMS_ON : VEHICLE_PARAMS_OFF,
            bonnet,
            boot,
            objective
        );
    }

    Vehicle_SaveSlot(playerid, slot);
    SendClientMessage(
        playerid,
        COLOR_WHITE,
        s_OwnedVehicle[playerid][slot][ov_Locked] ? "Da khoa xe." : "Da mo khoa xe."
    );
    return 1;
}

stock Vehicle_ToggleFavorite(playerid, slot)
{
    if (!Vehicle_IsValidSlot(playerid, slot))
    {
        return 0;
    }

    s_OwnedVehicle[playerid][slot][ov_Favorite] =
        !s_OwnedVehicle[playerid][slot][ov_Favorite];
    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
    Vehicle_SaveSlot(playerid, slot);
    SendClientMessage(
        playerid,
        COLOR_WHITE,
        s_OwnedVehicle[playerid][slot][ov_Favorite]
            ? "Da them xe vao danh sach yeu thich."
            : "Da bo xe khoi danh sach yeu thich."
    );
    return 1;
}

stock Vehicle_UnloadPlayer(playerid)
{
    Vehicle_ClearGPS(playerid);
    for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
    {
        if (!Vehicle_IsValidSlot(playerid, slot))
        {
            continue;
        }

        new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
        if (vehicleid != INVALID_VEHICLE_ID && IsValidVehicle(vehicleid))
        {
            Vehicle_CaptureState(playerid, slot);
            Vehicle_ClearServerMapping(vehicleid);
            DestroyVehicle(vehicleid);
            s_OwnedVehicle[playerid][slot][ov_ServerID] = INVALID_VEHICLE_ID;
            s_OwnedVehicle[playerid][slot][ov_Storage] = OV_STORAGE_STORED;
            s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
        }
    }
    Vehicle_SaveAll(playerid);
    Vehicle_ResetPlayer(playerid);
    return 1;
}

public Vehicle_ProcessRuntime()
{
    static autosaveCycle;
    autosaveCycle++;

    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        if (!IsPlayerConnected(playerid) || !s_OwnedVehiclesLoaded[playerid])
        {
            continue;
        }

        for (new slot = 0; slot < MAX_OWNED_VEHICLES; slot++)
        {
            if (!Vehicle_IsValidSlot(playerid, slot) ||
                s_OwnedVehicle[playerid][slot][ov_Storage] != OV_STORAGE_SPAWNED)
            {
                continue;
            }

            new const vehicleid = s_OwnedVehicle[playerid][slot][ov_ServerID];
            if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
            {
                s_OwnedVehicle[playerid][slot][ov_ServerID] = INVALID_VEHICLE_ID;
                s_OwnedVehicle[playerid][slot][ov_Storage] = OV_STORAGE_STORED;
                s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
                continue;
            }

            new Float:x, Float:y, Float:z;
            GetVehiclePos(vehicleid, x, y, z);
            if (IsVehicleOccupied(vehicleid))
            {
                new const Float:deltaX = x - s_OwnedVehicle[playerid][slot][ov_LastX];
                new const Float:deltaY = y - s_OwnedVehicle[playerid][slot][ov_LastY];
                new const Float:deltaZ = z - s_OwnedVehicle[playerid][slot][ov_LastZ];
                new const Float:distance = floatsqroot(
                    deltaX * deltaX +
                    deltaY * deltaY +
                    deltaZ * deltaZ
                );
                if (distance > 0.05 && distance < 250.0)
                {
                    s_OwnedVehicle[playerid][slot][ov_Mileage] += distance / 1000.0;
                    s_OwnedVehicle[playerid][slot][ov_Dirty] = true;
                }
            }
            s_OwnedVehicle[playerid][slot][ov_LastX] = x;
            s_OwnedVehicle[playerid][slot][ov_LastY] = y;
            s_OwnedVehicle[playerid][slot][ov_LastZ] = z;
            Vehicle_CaptureState(playerid, slot);
        }

        if (autosaveCycle >= 12)
        {
            Vehicle_SaveAll(playerid);
        }
    }

    if (autosaveCycle >= 12)
    {
        autosaveCycle = 0;
    }
    return 1;
}

hook OnGameModeInit()
{
    for (new vehicleid = 0; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        s_ServerVehicleOwner[vehicleid] = INVALID_PLAYER_ID;
        s_ServerVehicleSlot[vehicleid] = INVALID_OWNED_VEHICLE_SLOT;
    }
    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        Vehicle_ResetPlayer(playerid);
        s_OwnedVehicleGPSTimer[playerid] = 0;
    }
    s_OwnedVehicleRuntimeTimer = SetTimer("Vehicle_ProcessRuntime", 5000, true);
    return 1;
}

hook OnGameModeExit()
{
    if (s_OwnedVehicleRuntimeTimer)
    {
        KillTimer(s_OwnedVehicleRuntimeTimer);
        s_OwnedVehicleRuntimeTimer = 0;
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    Vehicle_ResetPlayer(playerid);
    s_OwnedVehicleGPSTimer[playerid] = 0;
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    Vehicle_UnloadPlayer(playerid);
    return 1;
}

hook OnPlayerStateChange(playerid, PLAYER_STATE:newState, PLAYER_STATE:oldState)
{
    #pragma unused oldState
    if (newState != PLAYER_STATE_DRIVER)
    {
        return 1;
    }

    new ownerid, slot;
    new const vehicleid = GetPlayerVehicleID(playerid);
    if (!Vehicle_GetOwnerSlot(vehicleid, ownerid, slot))
    {
        return 1;
    }

    if (playerid == ownerid)
    {
        s_OwnedVehicle[ownerid][slot][ov_Stolen] = false;
        s_OwnedVehicle[ownerid][slot][ov_LastDriverCharacterID] =
            GetPlayerCharacterID(playerid);
        s_OwnedVehicle[ownerid][slot][ov_Dirty] = true;
        return 1;
    }

    if (s_OwnedVehicle[ownerid][slot][ov_Locked])
    {
        RemovePlayerFromVehicle(playerid);
        SendClientMessage(playerid, COLOR_RED, "Xe da khoa, ban khong the lay xe.");
        return 1;
    }

    s_OwnedVehicle[ownerid][slot][ov_Stolen] = true;
    s_OwnedVehicle[ownerid][slot][ov_LastDriverCharacterID] =
        IsPlayerCharacterLoaded(playerid) ? GetPlayerCharacterID(playerid) : 0;
    s_OwnedVehicle[ownerid][slot][ov_Dirty] = true;
    SendClientMessage(ownerid, COLOR_RED, "Canh bao GPS: xe cua ban dang bi nguoi khac lai.");
    return 1;
}

hook OnVehicleDamageStatusUpdate(vehicleid, playerid)
{
    #pragma unused playerid
    new ownerid, slot;
    if (Vehicle_GetOwnerSlot(vehicleid, ownerid, slot))
    {
        Vehicle_CaptureState(ownerid, slot);
    }
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    #pragma unused killerid
    new ownerid, slot;
    if (!Vehicle_GetOwnerSlot(vehicleid, ownerid, slot))
    {
        return 1;
    }

    Vehicle_CaptureState(ownerid, slot);
    s_OwnedVehicle[ownerid][slot][ov_Health] = VEHICLE_DESTROYED_HEALTH;
    s_OwnedVehicle[ownerid][slot][ov_Storage] = OV_STORAGE_DESTROYED;
    s_OwnedVehicle[ownerid][slot][ov_ServerID] = INVALID_VEHICLE_ID;
    s_OwnedVehicle[ownerid][slot][ov_Dirty] = true;
    Vehicle_ClearServerMapping(vehicleid);
    DestroyVehicle(vehicleid);
    Vehicle_SaveSlot(ownerid, slot);
    SendClientMessage(ownerid, COLOR_RED, "Xe cua ban da hu hong nang.");
    return 1;
}

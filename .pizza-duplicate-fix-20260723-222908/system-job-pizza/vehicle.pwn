//-----------------------------------------------------------------------------
// Pizza job - rental vehicle ownership and lifecycle
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

stock Pizza_ClearRentalState(playerid)
{
    DisablePlayerCheckpoint(playerid);
    Pizza_SetCarryState(playerid, PIZZA_CARRY_NONE);

    s_PizzaVehicleCargo[playerid] = 0;
    s_PizzaDeliveryPoint[playerid] = -1;
    s_PizzaShiftDeliveries[playerid] = 0;
    return 1;
}

stock Pizza_DestroyRentalVehicle(playerid)
{
    new const vehicleid = s_PizzaRentalVehicle[playerid];
    new const rentalToken = s_PizzaRentalToken[playerid];

    if (s_PizzaVehicleLabel[playerid] != Text3D:INVALID_3DTEXT_ID)
    {
        Delete3DTextLabel(s_PizzaVehicleLabel[playerid]);
        s_PizzaVehicleLabel[playerid] = Text3D:INVALID_3DTEXT_ID;
    }

    if (IsPlayerConnected(playerid) &&
        Pizza_IsVehicleIndexValid(vehicleid) &&
        IsPlayerInVehicle(playerid, vehicleid))
    {
        RemovePlayerFromVehicle(playerid);
    }

    // Clear mapping BEFORE DestroyVehicle. Vehicle IDs can be reused.
    if (Pizza_IsVehicleIndexValid(vehicleid) &&
        s_PizzaManagedOwner[vehicleid] == playerid &&
        s_PizzaManagedToken[vehicleid] == rentalToken)
    {
        s_PizzaManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_PizzaManagedToken[vehicleid] = 0;
        s_PizzaRentalVehicle[playerid] = INVALID_VEHICLE_ID;
        s_PizzaRentalToken[playerid]++;

        if (IsValidVehicle(vehicleid))
        {
            DestroyVehicle(vehicleid);
        }
    }
    else
    {
        s_PizzaRentalVehicle[playerid] = INVALID_VEHICLE_ID;
        s_PizzaRentalToken[playerid]++;
    }

    Pizza_ClearRentalState(playerid);
    return 1;
}

stock Pizza_RentVehicle(playerid)
{
    if (!Pizza_IsEmployee(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban chua phai nhan vien Pizza Stack.", 4000);
        return 0;
    }

    if (Pizza_HasRentalVehicle(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban dang co mot chiec Pizzaboy thue theo ca.", 4000);
        return 0;
    }

    // Stale local vehicle ID from a previous broken/aborted state.
    if (s_PizzaRentalVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        Pizza_DestroyRentalVehicle(playerid);
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay xuong xe truoc khi thue Pizzaboy.", 4000);
        return 0;
    }

    new const spawn = Pizza_FindFreeVehicleSpawn();
    if (spawn == -1)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Bai xe Pizza Stack dang het cho trong. Hay thu lai sau.", 5000);
        return 0;
    }

    if (!Job_Start(playerid, JOB_PIZZA))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Khong the bat dau ca luc nay. Hay thu lai sau.", 4500);
        return 0;
    }

    s_PizzaRentalToken[playerid]++;

    new const vehicleid = CreateVehicle(
        448,
        g_PizzaVehicleSpawns[spawn][0],
        g_PizzaVehicleSpawns[spawn][1],
        g_PizzaVehicleSpawns[spawn][2],
        g_PizzaVehicleSpawns[spawn][3],
        3,
        6,
        -1
    );

    if (!Pizza_IsVehicleIndexValid(vehicleid) || !IsValidVehicle(vehicleid))
    {
        Job_Stop(playerid, JOB_STOP_QUIT);
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Khong the tao Pizzaboy luc nay.", 4000);
        return 0;
    }

    s_PizzaRentalVehicle[playerid] = vehicleid;
    s_PizzaManagedOwner[vehicleid] = playerid;
    s_PizzaManagedToken[vehicleid] = s_PizzaRentalToken[playerid];
    s_PizzaVehicleCargo[playerid] = 0;
    s_PizzaDeliveryPoint[playerid] = -1;
    s_PizzaShiftDeliveries[playerid] = 0;

    new labelText[128];
    format(labelText, sizeof(labelText), "{FFFFFF}Pizza Boy\n{E53935}Chu so huu: {FFFFFF}%s", s_CharacterName[playerid]);

    s_PizzaVehicleLabel[playerid] = Create3DTextLabel(labelText, COLOR_WHITE, 0.0, 0.0, 0.0, 25.0, 0, true);
    Attach3DTextLabelToVehicle(s_PizzaVehicleLabel[playerid], vehicleid, 0.0, 0.0, 1.0);

    SetVehicleHealth(vehicleid, 1000.0);

    if (!PutPlayerInVehicle(playerid, vehicleid, 0))
    {
        Job_Stop(playerid, JOB_STOP_QUIT);
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Khong the dua ban vao xe. Hop dong thue da huy.", 4500);
        return 0;
    }

    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da thue Pizzaboy. Lai den diem lay banh va nhan Y de nhan hang.", 6000);
    return 1;
}

stock Pizza_ReturnRentalVehicle(playerid)
{
    if (!Pizza_HasRentalVehicle(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban khong co Pizzaboy dang thue.", 4000);
        return 0;
    }

    if (!Pizza_IsRentalVehicleNear(playerid, PIZZA_VEHICLE_RETURN_X, PIZZA_VEHICLE_RETURN_Y, PIZZA_VEHICLE_RETURN_Z, 6.0))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay dua Pizzaboy vao dung khu vuc tra xe.", 4000);
        return 0;
    }

    if (Pizza_IsCarryingBox(playerid) || s_PizzaDeliveryPoint[playerid] >= 0)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay hoan tat don hang va cat hop pizza truoc khi tra xe.", 4500);
        return 0;
    }

    if (s_PizzaVehicleCargo[playerid] > 0)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Trong xe van con pizza. Hay giao het hang truoc khi tra xe.", 4500);
        return 0;
    }

    Job_CompleteRun(playerid, PIZZA_RETURN_BONUS, PIZZA_RETURN_XP);
    Job_Stop(playerid, JOB_STOP_COMPLETE);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da ban giao Pizzaboy. Thuong ket ca: $100.", 5000);
    return 1;
}

hook OnPlayerStateChange(playerid, newstate, oldstate)
{
    #pragma unused oldstate

    if (newstate != _:PLAYER_STATE_DRIVER &&
        newstate != _:PLAYER_STATE_PASSENGER)
    {
        return 1;
    }

    new const vehicleid = GetPlayerVehicleID(playerid);

    if (Pizza_IsCarryingBox(playerid))
    {
        RemovePlayerFromVehicle(playerid);
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban dang cam hop pizza. Nhan Y gan Pizzaboy de cat banh truoc.", 4500);
        return 1;
    }

    if (!Pizza_IsVehicleIndexValid(vehicleid) ||
        s_PizzaManagedOwner[vehicleid] == INVALID_PLAYER_ID)
    {
        return 1;
    }

    new const ownerid = s_PizzaManagedOwner[vehicleid];

    if (ownerid != playerid ||
        s_PizzaManagedToken[vehicleid] != s_PizzaRentalToken[playerid] ||
        s_PizzaRentalVehicle[playerid] != vehicleid)
    {
        RemovePlayerFromVehicle(playerid);
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Pizzaboy nay thuoc hop dong thue cua nhan vien khac.", 4500);
    }
    return 1;
}

hook OnVehicleDeath(vehicleid, killerid)
{
    #pragma unused killerid

    if (!Pizza_IsVehicleIndexValid(vehicleid) ||
        s_PizzaManagedOwner[vehicleid] == INVALID_PLAYER_ID)
    {
        return 1;
    }

    new const playerid = s_PizzaManagedOwner[vehicleid];
    new const rentalToken = s_PizzaManagedToken[vehicleid];

    if (IsPlayerConnected(playerid) &&
        s_PizzaRentalVehicle[playerid] == vehicleid &&
        s_PizzaRentalToken[playerid] == rentalToken)
    {
        if (Job_IsActive(playerid, JOB_PIZZA))
        {
            Job_Stop(playerid, JOB_STOP_VEHICLE_LOST);
        }
        else
        {
            Pizza_DestroyRentalVehicle(playerid);
        }
    }
    else
    {
        s_PizzaManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_PizzaManagedToken[vehicleid] = 0;
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (Pizza_HasRentalVehicle(playerid) ||
        s_PizzaRentalVehicle[playerid] != INVALID_VEHICLE_ID)
    {
        Pizza_DestroyRentalVehicle(playerid);
    }
    return 1;
}

hook OnPlayerJobStopping(playerid, jobid, reason)
{
    if (jobid != JOB_PIZZA)
    {
        return 1;
    }

    Pizza_DestroyRentalVehicle(playerid);

    if (reason == JOB_STOP_VEHICLE_LOST)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Pizzaboy da bi pha huy. Xe va hang tam da duoc thu hoi.", 5000);
    }
    else if (reason == JOB_STOP_DEATH)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ca Pizza da huy vi ban bat tinh. Xe va hang tam da duoc thu hoi.", 5000);
    }
    return 1;
}

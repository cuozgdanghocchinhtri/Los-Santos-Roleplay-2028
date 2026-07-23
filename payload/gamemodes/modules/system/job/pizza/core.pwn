//-----------------------------------------------------------------------------
// Pizza job - world, pJob loading and delivery interaction
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

forward OnPizzaCharacterJobLoaded(playerid, characterID);

stock Pizza_LoadCharacterJob(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new const characterID = GetPlayerCharacterID(playerid);
    if (characterID == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    pJobLoaded[playerid] = false;

    new query[384];
    mysql_format(g_DatabaseHandle, query, sizeof(query), "SELECT `job`,COALESCE(DATE_FORMAT(`job_hired_at`,'%%Y-%%m-%%d %%H:%%i:%%s'),'') AS `job_hired_at`,`job_salary`,`job_allowance` FROM `player_characters` WHERE `character_id`=%d AND `account_id`=%d LIMIT 1;", characterID, GetPlayerAccountID(playerid));
    mysql_tquery(g_DatabaseHandle, query, "OnPizzaCharacterJobLoaded", "dd", playerid, characterID);
    return 1;
}

public OnPizzaCharacterJobLoaded(playerid, characterID)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID)
    {
        return 1;
    }

    pJob[playerid] = JOB_NONE;
    pJobHiredAt[playerid][0] = 0;
    pJobSalary[playerid] = 0;
    pJobAllowance[playerid] = 0;

    if (cache_num_rows() > 0)
    {
        cache_get_value_name_int(0, "job", pJob[playerid]);
        cache_get_value_name(0, "job_hired_at", pJobHiredAt[playerid], sizeof(pJobHiredAt[]));
        cache_get_value_name_int(0, "job_salary", pJobSalary[playerid]);
        cache_get_value_name_int(0, "job_allowance", pJobAllowance[playerid]);
    }

    pJobLoaded[playerid] = true;
    return 1;
}

stock Pizza_CreateWorld()
{
    g_PizzaRecruiterActor = CreateActor(PIZZA_RECRUITER_SKIN, PIZZA_NPC_X, PIZZA_NPC_Y, PIZZA_NPC_Z, PIZZA_NPC_A);

    if (g_PizzaRecruiterActor != INVALID_ACTOR_ID)
    {
        SetActorInvulnerable(g_PizzaRecruiterActor, true);
        SetActorVirtualWorld(g_PizzaRecruiterActor, 0);
    }

    g_PizzaRecruiterPickup = CreatePickup(1239, 1, PIZZA_NPC_X, PIZZA_NPC_Y, PIZZA_NPC_Z, 0);
    g_PizzaBoxPickup = CreatePickup(PIZZA_BOX_OBJECT, 1, PIZZA_BOX_PICKUP_X, PIZZA_BOX_PICKUP_Y, PIZZA_BOX_PICKUP_Z, 0);
    g_PizzaReturnPickup = CreatePickup(1239, 1, PIZZA_VEHICLE_RETURN_X, PIZZA_VEHICLE_RETURN_Y, PIZZA_VEHICLE_RETURN_Z, 0);

    g_PizzaRecruiterLabel = Create3DTextLabel("{E53935}Pizza Stack\n{FFFFFF}Quan ly tuyen dung\n{FFD54F}Nhan Y de tuong tac", COLOR_WHITE, PIZZA_NPC_X, PIZZA_NPC_Y, PIZZA_NPC_Z + 1.0, 18.0, 0, true);
    g_PizzaBoxLabel = Create3DTextLabel("{FFFFFF}Khu lay banh\n{FFD54F}Nhan Y de lay hop pizza", COLOR_WHITE, PIZZA_BOX_PICKUP_X, PIZZA_BOX_PICKUP_Y, PIZZA_BOX_PICKUP_Z + 0.5, 16.0, 0, true);
    g_PizzaReturnLabel = Create3DTextLabel("{FFFFFF}Khu tra Pizzaboy\n{FFD54F}Dua xe vao day va nhan Y", COLOR_WHITE, PIZZA_VEHICLE_RETURN_X, PIZZA_VEHICLE_RETURN_Y, PIZZA_VEHICLE_RETURN_Z + 0.7, 18.0, 0, true);
    return 1;
}

stock Pizza_DestroyWorld()
{
    if (IsValidActor(g_PizzaRecruiterActor)) DestroyActor(g_PizzaRecruiterActor);
    if (IsValidPickup(g_PizzaRecruiterPickup)) DestroyPickup(g_PizzaRecruiterPickup);
    if (IsValidPickup(g_PizzaBoxPickup)) DestroyPickup(g_PizzaBoxPickup);
    if (IsValidPickup(g_PizzaReturnPickup)) DestroyPickup(g_PizzaReturnPickup);

    if (IsValid3DTextLabel(g_PizzaRecruiterLabel)) Delete3DTextLabel(g_PizzaRecruiterLabel);
    if (IsValid3DTextLabel(g_PizzaBoxLabel)) Delete3DTextLabel(g_PizzaBoxLabel);
    if (IsValid3DTextLabel(g_PizzaReturnLabel)) Delete3DTextLabel(g_PizzaReturnLabel);

    g_PizzaRecruiterActor = INVALID_ACTOR_ID;
    g_PizzaRecruiterPickup = -1;
    g_PizzaBoxPickup = -1;
    g_PizzaReturnPickup = -1;

    g_PizzaRecruiterLabel = Text3D:INVALID_3DTEXT_ID;
    g_PizzaBoxLabel = Text3D:INVALID_3DTEXT_ID;
    g_PizzaReturnLabel = Text3D:INVALID_3DTEXT_ID;
    return 1;
}

stock Pizza_StartDelivery(playerid)
{
    if (!Pizza_IsEmployee(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban chua phai nhan vien Pizza Stack.", 4000);
        return 0;
    }

    if (!Pizza_IsOnShift(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay thue Pizzaboy va bat dau ca lam viec truoc.", 4500);
        return 0;
    }

    if (s_PizzaVehicleCargo[playerid] < 1)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Pizzaboy khong co banh. Hay quay ve Pizza Stack de lay hang.", 4500);
        return 0;
    }

    if (Pizza_IsCarryingBox(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay cat hop pizza dang cam truoc khi nhan don.", 4000);
        return 0;
    }

    if (s_PizzaDeliveryPoint[playerid] >= 0)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban dang co mot don giao chua hoan tat.", 4000);
        return 0;
    }

    new point = random(sizeof(g_PizzaDeliveryPoints));

    if (sizeof(g_PizzaDeliveryPoints) > 1 &&
        point == s_PizzaLastDeliveryPoint[playerid])
    {
        point = (point + 1 + random(sizeof(g_PizzaDeliveryPoints) - 1)) % sizeof(g_PizzaDeliveryPoints);
    }

    s_PizzaDeliveryPoint[playerid] = point;

    SetPlayerCheckpoint(playerid,
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_X],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Y],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Z],
        2.5
    );

    new message[160];
    format(message, sizeof(message), "Don moi: %s. Den diem giao, xuong xe va nhan Y gan Pizzaboy de lay banh.", g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_ZONE]);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, message, 6500);
    return 1;
}

stock Pizza_TakeStoreBox(playerid)
{
    if (!Pizza_IsOnShift(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban can thue Pizzaboy truoc khi nhan banh.", 4000);
        return 0;
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay xuong xe de nhan hop pizza.", 3500);
        return 0;
    }

    if (Pizza_IsCarryingBox(playerid))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Ban dang cam mot hop pizza.", 3500);
        return 0;
    }

    if (s_PizzaVehicleCargo[playerid] >= PIZZA_MAX_CARGO)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Pizzaboy da du 5/5 hop. Su dung /giaobanh de nhan don.", 5000);
        return 0;
    }

    if (!Pizza_IsRentalVehicleNear(playerid, PIZZA_BOX_PICKUP_X, PIZZA_BOX_PICKUP_Y, PIZZA_BOX_PICKUP_Z, PIZZA_STORE_VEHICLE_RANGE))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay dua Pizzaboy lai gan khu lay banh truoc.", 4000);
        return 0;
    }

    Pizza_SetCarryState(playerid, PIZZA_CARRY_FROM_STORE);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da nhan mot hop pizza. Den gan Pizzaboy va nhan Y de chat len xe.", 5000);
    return 1;
}

stock Pizza_LoadCarriedBox(playerid)
{
    if (s_PizzaCarryState[playerid] != PIZZA_CARRY_FROM_STORE)
    {
        return 0;
    }

    if (s_PizzaVehicleCargo[playerid] >= PIZZA_MAX_CARGO)
    {
        Pizza_SetCarryState(playerid, PIZZA_CARRY_NONE);
        return 0;
    }

    Pizza_SetCarryState(playerid, PIZZA_CARRY_NONE);
    s_PizzaVehicleCargo[playerid]++;

    new message[128];
    format(message, sizeof(message), "Da chat banh len Pizzaboy: %d/%d hop.", s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, message, 4000);

    if (s_PizzaVehicleCargo[playerid] == 1)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da co 1 banh tren xe. Ban co the dung /giaobanh ngay hoac lay them.", 5000);
    }
    else if (s_PizzaVehicleCargo[playerid] >= PIZZA_MAX_CARGO)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Kho xe da day 5/5. Su dung /giaobanh de nhan dia chi giao.", 5500);
    }
    return 1;
}

stock Pizza_TakeDeliveryBox(playerid)
{
    new const point = s_PizzaDeliveryPoint[playerid];

    if (point < 0 ||
        point >= sizeof(g_PizzaDeliveryPoints) ||
        s_PizzaVehicleCargo[playerid] < 1)
    {
        return 0;
    }

    if (GetPlayerState(playerid) != PLAYER_STATE_ONFOOT ||
        Pizza_IsCarryingBox(playerid))
    {
        return 0;
    }

    if (!IsPlayerInRangeOfPoint(playerid, PIZZA_DELIVERY_AREA_RANGE,
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_X],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Y],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Z]))
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Chi lay hop giao hang khi da den gan dia chi khach.", 4000);
        return 0;
    }

    Pizza_SetCarryState(playerid, PIZZA_CARRY_FOR_DELIVERY);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da lay hop giao hang. Mang den checkpoint va nhan Y.", 4500);
    return 1;
}

stock Pizza_PutDeliveryBoxBack(playerid)
{
    if (s_PizzaCarryState[playerid] != PIZZA_CARRY_FOR_DELIVERY)
    {
        return 0;
    }

    Pizza_SetCarryState(playerid, PIZZA_CARRY_NONE);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Da dat hop pizza tro lai Pizzaboy.", 3500);
    return 1;
}

stock Pizza_CompleteDelivery(playerid)
{
    new const point = s_PizzaDeliveryPoint[playerid];

    if (point < 0 || point >= sizeof(g_PizzaDeliveryPoints))
    {
        return 0;
    }

    if (s_PizzaCarryState[playerid] != PIZZA_CARRY_FOR_DELIVERY)
    {
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Hay quay lai Pizzaboy, nhan Y de lay hop pizza giao cho khach.", 4500);
        return 0;
    }

    if (!IsPlayerInRangeOfPoint(playerid, 2.7,
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_X],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Y],
        g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Z]))
    {
        return 0;
    }

    // Cargo is decremented ONLY here, after a successful handoff.
    Pizza_SetCarryState(playerid, PIZZA_CARRY_NONE);

    if (s_PizzaVehicleCargo[playerid] > 0)
    {
        s_PizzaVehicleCargo[playerid]--;
    }

    s_PizzaLastDeliveryPoint[playerid] = point;
    s_PizzaDeliveryPoint[playerid] = -1;
    s_PizzaShiftDeliveries[playerid]++;
    DisablePlayerCheckpoint(playerid);

    Job_RecordTask(playerid, PIZZA_DELIVERY_BASE_PAY, PIZZA_DELIVERY_XP, true);

    new message[160];
    format(message, sizeof(message), "Giao banh thanh cong +$%d. Con %d/%d hop tren xe.", PIZZA_DELIVERY_BASE_PAY, s_PizzaVehicleCargo[playerid], PIZZA_MAX_CARGO);
    ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, message, 5500);

    if (s_PizzaVehicleCargo[playerid] > 0)
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Su dung /giaobanh de nhan don tiep theo.", 4000);
    else
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Xe da het banh. Quay ve lay them hoac dua xe den khu tra xe.", 5000);

    return 1;
}

stock Pizza_HandleRecruiterInteraction(playerid)
{
    if (!pJobLoaded[playerid])
    {
        Pizza_LoadCharacterJob(playerid);
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN, "Dang tai ho so cong viec. Hay nhan Y lai sau giay lat.", 4000);
        return 1;
    }

    if (Pizza_IsEmployee(playerid))
        Pizza_ShowEmployeeMenu(playerid);
    else
        Pizza_ShowApplication(playerid);

    return 1;
}

stock Pizza_HandleYInteraction(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    if (IsPlayerInRangeOfPoint(playerid, PIZZA_INTERACT_RANGE, PIZZA_NPC_X, PIZZA_NPC_Y, PIZZA_NPC_Z))
    {
        return Pizza_HandleRecruiterInteraction(playerid);
    }

    if (IsPlayerInRangeOfPoint(playerid, 4.0, PIZZA_VEHICLE_RETURN_X, PIZZA_VEHICLE_RETURN_Y, PIZZA_VEHICLE_RETURN_Z))
    {
        return Pizza_ReturnRentalVehicle(playerid);
    }

    if (IsPlayerInRangeOfPoint(playerid, PIZZA_INTERACT_RANGE, PIZZA_BOX_PICKUP_X, PIZZA_BOX_PICKUP_Y, PIZZA_BOX_PICKUP_Z))
    {
        return Pizza_TakeStoreBox(playerid);
    }

    new const point = s_PizzaDeliveryPoint[playerid];

    if (point >= 0 &&
        point < sizeof(g_PizzaDeliveryPoints) &&
        IsPlayerInRangeOfPoint(playerid, 2.7,
            g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_X],
            g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Y],
            g_PizzaDeliveryPoints[point][PIZZA_DELIVERY_Z]))
    {
        return Pizza_CompleteDelivery(playerid);
    }

    if (!Pizza_HasRentalVehicle(playerid) ||
        GetPlayerState(playerid) != PLAYER_STATE_ONFOOT)
    {
        return 0;
    }

    new const vehicleid = Pizza_GetRentalVehicle(playerid);
    new Float:x, Float:y, Float:z;
    GetVehiclePos(vehicleid, x, y, z);

    if (!IsPlayerInRangeOfPoint(playerid, PIZZA_VEHICLE_INTERACT_RANGE, x, y, z))
    {
        return 0;
    }

    if (s_PizzaCarryState[playerid] == PIZZA_CARRY_FROM_STORE)
        return Pizza_LoadCarriedBox(playerid);

    if (s_PizzaCarryState[playerid] == PIZZA_CARRY_FOR_DELIVERY)
        return Pizza_PutDeliveryBoxBack(playerid);

    if (s_PizzaDeliveryPoint[playerid] >= 0)
        return Pizza_TakeDeliveryBox(playerid);

    return 0;
}

hook OnGameModeInit()
{
    Pizza_ResetVehicleRegistry();
    Job_Register(JOB_PIZZA, "Pizza Boy");
    Pizza_CreateWorld();
    return 1;
}

hook OnGameModeExit()
{
    Pizza_DestroyWorld();
    return 1;
}

hook OnPlayerConnect(playerid)
{
    Pizza_InitializePlayer(playerid);
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    if (IsPlayerCharacterLoaded(playerid))
    {
        Pizza_LoadCharacterJob(playerid);
    }
    return 1;
}

hook OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    if ((newkeys & KEY_YES) && !(oldkeys & KEY_YES))
    {
        Pizza_HandleYInteraction(playerid);
    }
    return 1;
}

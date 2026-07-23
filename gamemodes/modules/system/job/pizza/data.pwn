//-----------------------------------------------------------------------------
// Pizza job - constants, locations and runtime data
//-----------------------------------------------------------------------------

#define PIZZA_DIALOG_APPLICATION             (9000)
#define PIZZA_DIALOG_EMPLOYEE_MENU           (9001)
#define PIZZA_DIALOG_PROFILE                 (9002)
#define PIZZA_DIALOG_GUIDE                   (9003)
#define PIZZA_DIALOG_RENT                    (9004)
#define PIZZA_DIALOG_RESIGN                  (9005)

#define PIZZA_MAX_CARGO                      (5)
#define PIZZA_DAILY_SALARY                   (350)
#define PIZZA_DAILY_FOOD_ALLOWANCE           (75)
#define PIZZA_DAILY_TRANSPORT_ALLOWANCE      (50)
#define PIZZA_DAILY_ALLOWANCE_TOTAL          (125)
#define PIZZA_MAX_KPI_BONUS                  (200)

#define PIZZA_DELIVERY_BASE_PAY              (90)
#define PIZZA_DELIVERY_XP                    (12)
#define PIZZA_RETURN_BONUS                   (100)
#define PIZZA_RETURN_XP                      (20)

#define PIZZA_BOX_OBJECT                     (1582)
#define PIZZA_BOX_ATTACH_SLOT                (8)
#define PIZZA_RECRUITER_SKIN                 (155)

#define PIZZA_INTERACT_RANGE                 (2.5)
#define PIZZA_VEHICLE_INTERACT_RANGE         (4.0)
#define PIZZA_STORE_VEHICLE_RANGE            (12.0)
#define PIZZA_DELIVERY_AREA_RANGE            (35.0)
#define PIZZA_VEHICLE_SPAWN_CLEARANCE        (3.0)

#define PIZZA_NPC_X                          (2105.2300)
#define PIZZA_NPC_Y                          (-1806.5000)
#define PIZZA_NPC_Z                          (13.5547)
#define PIZZA_NPC_A                          (90.0000)

#define PIZZA_BOX_PICKUP_X           (2099.2500)
#define PIZZA_BOX_PICKUP_Y           (-1809.6000)
#define PIZZA_BOX_PICKUP_Z           (13.5547)

#define PIZZA_VEHICLE_RETURN_X               (2090.5000)
#define PIZZA_VEHICLE_RETURN_Y               (-1810.2000)
#define PIZZA_VEHICLE_RETURN_Z               (13.1000)

enum _:E_PIZZA_CARRY_STATE
{
    PIZZA_CARRY_NONE = 0,
    PIZZA_CARRY_FROM_STORE,
    PIZZA_CARRY_FOR_DELIVERY
};

enum E_PIZZA_DELIVERY_POINT
{
    Float:PIZZA_DELIVERY_X,
    Float:PIZZA_DELIVERY_Y,
    Float:PIZZA_DELIVERY_Z,
    PIZZA_DELIVERY_ZONE[24]
};

new const Float:g_PizzaVehicleSpawns[][4] =
{
    {2095.3000, -1810.2000, 13.1000, 90.0000},
    {2095.3000, -1813.4000, 13.1000, 90.0000},
    {2095.3000, -1816.6000, 13.1000, 90.0000},
    {2091.8000, -1810.2000, 13.1000, 90.0000},
    {2091.8000, -1813.4000, 13.1000, 90.0000},
    {2091.8000, -1816.6000, 13.1000, 90.0000}
};

new const g_PizzaDeliveryPoints[][E_PIZZA_DELIVERY_POINT] =
{
    {2495.36, -1687.31, 13.52, "Ganton"},
    {2327.10, -1681.00, 14.93, "Ganton"},
    {2185.10, -1364.00, 25.83, "Jefferson"},
    {2140.60, -1082.50, 24.70, "Jefferson"},
    {2285.70, -1102.70, 37.98, "Las Colinas"},
    {2712.10, -1497.80, 30.55, "East Los Santos"},
    {2801.80, -1775.10, 11.84, "East Beach"},
    {2636.20, -2012.20, 13.55, "East Beach"},
    {2441.70, -1941.10, 13.55, "Willowfield"},
    {1812.40, -2100.50, 13.56, "El Corona"},
    {1695.40, -2124.70, 13.81, "El Corona"},
    {1421.80, -1882.00, 13.57, "El Corona"},
    {1246.00, -1543.00, 13.55, "Idlewood"},
    {1087.00, -1426.00, 22.76, "Market"},
    {953.80, -1335.20, 13.54, "Verona"},
    {910.50, -1235.50, 17.21, "Market"},
    {841.40, -1822.70, 12.37, "Verona Beach"},
    {653.40, -1714.10, 14.76, "Verona Beach"},
    {319.80, -1769.40, 4.70, "Santa Maria"},
    {225.60, -1408.40, 51.61, "Richman"},
    {700.20, -1060.40, 49.42, "Richman"},
    {827.90, -858.00, 70.33, "Richman"},
    {1093.90, -806.60, 107.40, "Vinewood"},
    {1442.60, -629.90, 95.72, "Mulholland"}
};

// pJob belongs to the loaded character.
// DB source: player_characters.job / job_hired_at / job_salary / job_allowance.
new
    pJob[MAX_PLAYERS],
    pJobHiredAt[MAX_PLAYERS][20],
    pJobSalary[MAX_PLAYERS],
    pJobAllowance[MAX_PLAYERS],
    bool:pJobLoaded[MAX_PLAYERS];

new
    g_PizzaRecruiterActor = INVALID_ACTOR_ID,
    g_PizzaRecruiterPickup = -1,
    g_PizzaBoxPickup = -1,
    g_PizzaReturnPickup = -1,

    Text3D:g_PizzaRecruiterLabel = Text3D:INVALID_3DTEXT_ID,
    Text3D:g_PizzaBoxLabel = Text3D:INVALID_3DTEXT_ID,
    Text3D:g_PizzaReturnLabel = Text3D:INVALID_3DTEXT_ID,

    s_PizzaRentalVehicle[MAX_PLAYERS],
    Text3D:s_PizzaVehicleLabel[MAX_PLAYERS],
    s_PizzaRentalToken[MAX_PLAYERS],
    s_PizzaVehicleCargo[MAX_PLAYERS],
    s_PizzaCarryState[MAX_PLAYERS],
    s_PizzaDeliveryPoint[MAX_PLAYERS],
    s_PizzaLastDeliveryPoint[MAX_PLAYERS],
    s_PizzaShiftDeliveries[MAX_PLAYERS],

    s_PizzaManagedOwner[MAX_VEHICLES],
    s_PizzaManagedToken[MAX_VEHICLES];

stock Pizza_ResetEmployment(playerid)
{
    pJob[playerid] = JOB_NONE;
    pJobHiredAt[playerid][0] = 0;
    pJobSalary[playerid] = 0;
    pJobAllowance[playerid] = 0;
    pJobLoaded[playerid] = false;
    return 1;
}

stock Pizza_InitializePlayer(playerid)
{
    Pizza_ResetEmployment(playerid);

    s_PizzaRentalVehicle[playerid] = INVALID_VEHICLE_ID;
    s_PizzaVehicleLabel[playerid] = Text3D:INVALID_3DTEXT_ID;
    s_PizzaRentalToken[playerid]++;
    s_PizzaVehicleCargo[playerid] = 0;
    s_PizzaCarryState[playerid] = PIZZA_CARRY_NONE;
    s_PizzaDeliveryPoint[playerid] = -1;
    s_PizzaLastDeliveryPoint[playerid] = -1;
    s_PizzaShiftDeliveries[playerid] = 0;
    return 1;
}

stock bool:Pizza_IsEmployee(playerid)
{
    return pJobLoaded[playerid] && pJob[playerid] == JOB_PIZZA;
}

stock bool:Pizza_IsVehicleIndexValid(vehicleid)
{
    return vehicleid > 0 && vehicleid < MAX_VEHICLES;
}

stock Pizza_ResetVehicleRegistry()
{
    for (new vehicleid = 0; vehicleid < MAX_VEHICLES; vehicleid++)
    {
        s_PizzaManagedOwner[vehicleid] = INVALID_PLAYER_ID;
        s_PizzaManagedToken[vehicleid] = 0;
    }
    return 1;
}

stock bool:Pizza_HasRentalVehicle(playerid)
{
    new const vehicleid = s_PizzaRentalVehicle[playerid];

    return Pizza_IsVehicleIndexValid(vehicleid) &&
        IsValidVehicle(vehicleid) &&
        s_PizzaManagedOwner[vehicleid] == playerid &&
        s_PizzaManagedToken[vehicleid] == s_PizzaRentalToken[playerid];
}

stock Pizza_GetRentalVehicle(playerid)
{
    if (!Pizza_HasRentalVehicle(playerid))
    {
        return INVALID_VEHICLE_ID;
    }
    return s_PizzaRentalVehicle[playerid];
}

stock bool:Pizza_IsOnShift(playerid)
{
    return Job_IsActive(playerid, JOB_PIZZA) && Pizza_HasRentalVehicle(playerid);
}

stock bool:Pizza_IsCarryingBox(playerid)
{
    return s_PizzaCarryState[playerid] != PIZZA_CARRY_NONE;
}

stock Float:Pizza_Distance2D(Float:x1, Float:y1, Float:x2, Float:y2)
{
    return floatsqroot(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2)));
}

stock Pizza_FindFreeVehicleSpawn()
{
    for (new spawn = 0; spawn < sizeof(g_PizzaVehicleSpawns); spawn++)
    {
        new bool:occupied = false;

        for (new vehicleid = 1; vehicleid < MAX_VEHICLES; vehicleid++)
        {
            if (s_PizzaManagedOwner[vehicleid] == INVALID_PLAYER_ID)
            {
                continue;
            }

            if (!IsValidVehicle(vehicleid))
            {
                s_PizzaManagedOwner[vehicleid] = INVALID_PLAYER_ID;
                s_PizzaManagedToken[vehicleid] = 0;
                continue;
            }

            new Float:x, Float:y, Float:z;
            GetVehiclePos(vehicleid, x, y, z);

            if (Pizza_Distance2D(x, y, g_PizzaVehicleSpawns[spawn][0], g_PizzaVehicleSpawns[spawn][1]) <= PIZZA_VEHICLE_SPAWN_CLEARANCE &&
                floatabs(z - g_PizzaVehicleSpawns[spawn][2]) <= 4.0)
            {
                occupied = true;
                break;
            }
        }

        if (!occupied)
        {
            return spawn;
        }
    }
    return -1;
}

stock bool:Pizza_IsRentalVehicleNear(playerid, Float:x, Float:y, Float:z, Float:range)
{
    new const vehicleid = Pizza_GetRentalVehicle(playerid);

    if (vehicleid == INVALID_VEHICLE_ID)
    {
        return false;
    }

    new Float:vehicleX, Float:vehicleY, Float:vehicleZ;
    GetVehiclePos(vehicleid, vehicleX, vehicleY, vehicleZ);

    return Pizza_Distance2D(vehicleX, vehicleY, x, y) <= range &&
        floatabs(vehicleZ - z) <= 10.0;
}

stock Pizza_SetCarryState(playerid, carryState)
{
    if (IsPlayerAttachedObjectSlotUsed(playerid, PIZZA_BOX_ATTACH_SLOT))
    {
        RemovePlayerAttachedObject(playerid, PIZZA_BOX_ATTACH_SLOT);
    }

    s_PizzaCarryState[playerid] = carryState;

    if (carryState == PIZZA_CARRY_NONE)
    {
        SetPlayerSpecialAction(playerid, SPECIAL_ACTION_NONE);
        ClearAnimations(playerid, SYNC_ALL);
        return 1;
    }

    SetPlayerAttachedObject(playerid, PIZZA_BOX_ATTACH_SLOT, PIZZA_BOX_OBJECT, 6, 0.08, 0.02, -0.02, 0.0, 90.0, 0.0, 0.75, 0.75, 0.75);
    SetPlayerSpecialAction(playerid, SPECIAL_ACTION_CARRY);
    return 1;
}


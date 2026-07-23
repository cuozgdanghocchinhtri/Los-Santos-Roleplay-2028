//-----------------------------------------------------------------------------
// Runtime controls for every vehicle on the server.
//
// This module is intentionally independent from ownership and persistence.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>
#include <YSI_Game\y_vehicledata>

#define DIALOG_CAR_CONTROLS (5110)

enum E_CAR_CONTROL_ACTION
{
    CAR_ACTION_ENGINE,
    CAR_ACTION_LIGHTS,
    CAR_ACTION_WINDOWS,
    CAR_ACTION_LOCK,
    CAR_ACTION_HOOD,
    CAR_ACTION_TRUNK
};

new
    bool:s_CarStartPending[MAX_PLAYERS],
    s_CarStartVehicle[MAX_PLAYERS],
    s_CarStartTimer[MAX_PLAYERS];

forward CarControls_FinishStart(playerid, vehicleid);

stock CarControls_Reset(playerid)
{
    s_CarStartPending[playerid] = false;
    s_CarStartVehicle[playerid] = INVALID_VEHICLE_ID;
    s_CarStartTimer[playerid] = 0;
    return 1;
}

stock CarControls_CancelStart(playerid)
{
    if (s_CarStartTimer[playerid])
    {
        KillTimer(s_CarStartTimer[playerid]);
    }
    CarControls_Reset(playerid);
    return 1;
}

stock bool:CarControls_GetDriverVehicle(playerid, &vehicleid)
{
    if (GetPlayerState(playerid) != PLAYER_STATE_DRIVER)
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Ban phai ngoi o ghe lai cua phuong tien.",
            3000
        );
        return false;
    }

    vehicleid = GetPlayerVehicleID(playerid);
    if (vehicleid == INVALID_VEHICLE_ID || !IsValidVehicle(vehicleid))
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Khong tim thay phuong tien dang dieu khien.",
            3000
        );
        return false;
    }
    return true;
}

stock CarControls_GetParams(
    vehicleid,
    &engine,
    &lights,
    &alarm,
    &doors,
    &bonnet,
    &boot,
    &objective
)
{
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

    if (engine < 0) engine = VEHICLE_PARAMS_OFF;
    if (lights < 0) lights = VEHICLE_PARAMS_OFF;
    if (alarm < 0) alarm = VEHICLE_PARAMS_OFF;
    if (doors < 0) doors = VEHICLE_PARAMS_OFF;
    if (bonnet < 0) bonnet = VEHICLE_PARAMS_OFF;
    if (boot < 0) boot = VEHICLE_PARAMS_OFF;
    if (objective < 0) objective = VEHICLE_PARAMS_OFF;
    return 1;
}

stock CarControls_BeginStart(playerid, vehicleid)
{
    if (s_CarStartPending[playerid])
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Phuong tien dang duoc khoi dong.",
            2500
        );
        return 0;
    }

    new modelName[32];
    new message[144];
    new const modelID = GetVehicleModel(vehicleid);

    if (modelID >= 400 && modelID <= 611)
    {
        Model_GetName(modelID, modelName);
    }
    else
    {
        format(modelName, sizeof(modelName), "Unknown");
    }

    new const startDelay = 2000 + random(3001);
    format(
        message,
        sizeof(message),
        "Dang khoi dong phuong tien ~r~%s..~w~ vui long doi",
        modelName
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_BASIC,
        message,
        startDelay + 500
    );

    s_CarStartPending[playerid] = true;
    s_CarStartVehicle[playerid] = vehicleid;
    s_CarStartTimer[playerid] =
        SetTimerEx(
            "CarControls_FinishStart",
            startDelay,
            false,
            "dd",
            playerid,
            vehicleid
        );
    return 1;
}

public CarControls_FinishStart(playerid, vehicleid)
{
    s_CarStartPending[playerid] = false;
    s_CarStartVehicle[playerid] = INVALID_VEHICLE_ID;
    s_CarStartTimer[playerid] = 0;

    if (!IsPlayerConnected(playerid) ||
        !IsValidVehicle(vehicleid) ||
        GetPlayerState(playerid) != PLAYER_STATE_DRIVER ||
        GetPlayerVehicleID(playerid) != vehicleid)
    {
        if (IsPlayerConnected(playerid))
        {
            ShowNotifyText(
                playerid,
                NOTIFY_TYPE_MODERN,
                "Khoi dong phuong tien da bi huy.",
                3000
            );
        }
        return 1;
    }

    SetVehicleParamsEx(
        vehicleid,
        VEHICLE_PARAMS_ON,
        -1,
        -1,
        -1,
        -1,
        -1,
        -1
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_BASIC,
        "Da khoi dong phuong tien thanh cong",
        3000
    );
    return 1;
}

stock CarControls_ToggleEngine(playerid, vehicleid)
{
    new engine, lights, alarm, doors, bonnet, boot, objective;
    CarControls_GetParams(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );

    if (engine == VEHICLE_PARAMS_ON)
    {
        CarControls_CancelStart(playerid);
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
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_BASIC,
            "Da tat dong co phuong tien.",
            2500
        );
        return 1;
    }

    return CarControls_BeginStart(playerid, vehicleid);
}

stock CarControls_ToggleLights(playerid, vehicleid)
{
    new engine, lights, alarm, doors, bonnet, boot, objective;
    CarControls_GetParams(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );

    lights = lights == VEHICLE_PARAMS_ON ?
        VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON;
    SetVehicleParamsEx(vehicleid, -1, lights, -1, -1, -1, -1, -1);
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        lights == VEHICLE_PARAMS_ON ?
            "Da bat den phuong tien." :
            "Da tat den phuong tien.",
        2500
    );
    return 1;
}

stock CarControls_ToggleWindows(playerid, vehicleid)
{
    new frontLeft, frontRight, rearLeft, rearRight;
    GetVehicleParamsCarWindows(
        vehicleid,
        frontLeft,
        frontRight,
        rearLeft,
        rearRight
    );

    new const windowState = (
        frontLeft == VEHICLE_PARAMS_ON ||
        frontRight == VEHICLE_PARAMS_ON ||
        rearLeft == VEHICLE_PARAMS_ON ||
        rearRight == VEHICLE_PARAMS_ON
    ) ? VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON;

    SetVehicleParamsCarWindows(
        vehicleid,
        windowState,
        windowState,
        windowState,
        windowState
    );
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        windowState == VEHICLE_PARAMS_ON ?
            "Da ha cua kinh phuong tien." :
            "Da dong cua kinh phuong tien.",
        2500
    );
    return 1;
}

stock CarControls_ToggleLock(playerid, vehicleid)
{
    new engine, lights, alarm, doors, bonnet, boot, objective;
    CarControls_GetParams(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );

    doors = doors == VEHICLE_PARAMS_ON ?
        VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON;
    SetVehicleParamsEx(vehicleid, -1, -1, -1, doors, -1, -1, -1);
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        doors == VEHICLE_PARAMS_ON ?
            "Da khoa cua phuong tien." :
            "Da mo khoa cua phuong tien.",
        2500
    );
    return 1;
}

stock CarControls_ToggleHood(playerid, vehicleid)
{
    new engine, lights, alarm, doors, bonnet, boot, objective;
    CarControls_GetParams(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );

    bonnet = bonnet == VEHICLE_PARAMS_ON ?
        VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON;
    SetVehicleParamsEx(vehicleid, -1, -1, -1, -1, bonnet, -1, -1);
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        bonnet == VEHICLE_PARAMS_ON ?
            "Da mo nap capo." :
            "Da dong nap capo.",
        2500
    );
    return 1;
}

stock CarControls_ToggleTrunk(playerid, vehicleid)
{
    new engine, lights, alarm, doors, bonnet, boot, objective;
    CarControls_GetParams(
        vehicleid,
        engine,
        lights,
        alarm,
        doors,
        bonnet,
        boot,
        objective
    );

    boot = boot == VEHICLE_PARAMS_ON ?
        VEHICLE_PARAMS_OFF : VEHICLE_PARAMS_ON;
    SetVehicleParamsEx(vehicleid, -1, -1, -1, -1, -1, boot, -1);
    ShowNotifyText(
        playerid,
        NOTIFY_TYPE_MODERN,
        boot == VEHICLE_PARAMS_ON ?
            "Da mo cop phuong tien." :
            "Da dong cop phuong tien.",
        2500
    );
    return 1;
}

stock CarControls_Execute(playerid, E_CAR_CONTROL_ACTION:action)
{
    new vehicleid;
    if (!CarControls_GetDriverVehicle(playerid, vehicleid))
    {
        return 0;
    }

    switch (action)
    {
        case CAR_ACTION_ENGINE:
            return CarControls_ToggleEngine(playerid, vehicleid);
        case CAR_ACTION_LIGHTS:
            return CarControls_ToggleLights(playerid, vehicleid);
        case CAR_ACTION_WINDOWS:
            return CarControls_ToggleWindows(playerid, vehicleid);
        case CAR_ACTION_LOCK:
            return CarControls_ToggleLock(playerid, vehicleid);
        case CAR_ACTION_HOOD:
            return CarControls_ToggleHood(playerid, vehicleid);
        case CAR_ACTION_TRUNK:
            return CarControls_ToggleTrunk(playerid, vehicleid);
    }
    return 0;
}

stock CarControls_ShowMenu(playerid)
{
    new vehicleid;
    if (!CarControls_GetDriverVehicle(playerid, vehicleid))
    {
        return 0;
    }

    #pragma unused vehicleid

    ShowPlayerDialog(
        playerid,
        DIALOG_CAR_CONTROLS,
        DIALOG_STYLE_LIST,
        "Dieu khien phuong tien",
        "Dong co\nDen xe\nCua kinh\nKhoa cua\nNap capo\nCop xe",
        "Chon",
        "Dong"
    );
    return 1;
}

CMD:car(playerid, params[])
{
    if (params[0] == 0)
    {
        CarControls_ShowMenu(playerid);
        return 1;
    }

    if (!strcmp(params, "engine", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_ENGINE);
    }
    else if (!strcmp(params, "lights", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_LIGHTS);
    }
    else if (!strcmp(params, "windows", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_WINDOWS);
    }
    else if (!strcmp(params, "lock", true) ||
        !strcmp(params, "doors", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_LOCK);
    }
    else if (!strcmp(params, "hood", true) ||
        !strcmp(params, "bonnet", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_HOOD);
    }
    else if (!strcmp(params, "trunk", true) ||
        !strcmp(params, "boot", true))
    {
        CarControls_Execute(playerid, CAR_ACTION_TRUNK);
    }
    else
    {
        ShowNotifyText(
            playerid,
            NOTIFY_TYPE_MODERN,
            "Su dung: /car [engine/lights/windows/lock/hood/trunk]",
            4500
        );
    }
    return 1;
}

hook OnGameModeInit()
{
    ManualVehicleEngineAndLights();

    for (new playerid = 0; playerid < MAX_PLAYERS; playerid++)
    {
        CarControls_Reset(playerid);
    }
    return 1;
}

hook OnPlayerConnect(playerid)
{
    CarControls_Reset(playerid);
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason
    CarControls_CancelStart(playerid);
    return 1;
}

hook OnPlayerKeyStateChange(playerid, KEY:newkeys, KEY:oldkeys)
{
    if ((newkeys & KEY_NO) &&
        !(oldkeys & KEY_NO) &&
        GetPlayerState(playerid) == PLAYER_STATE_DRIVER)
    {
        new vehicleid;
        if (CarControls_GetDriverVehicle(playerid, vehicleid))
        {
            CarControls_ToggleEngine(playerid, vehicleid);
        }
    }
    return 1;
}

hook OnPlayerStateChange(playerid, PLAYER_STATE:newState, PLAYER_STATE:oldState)
{
    if (oldState == PLAYER_STATE_DRIVER &&
        newState != PLAYER_STATE_DRIVER &&
        s_CarStartPending[playerid])
    {
        CarControls_CancelStart(playerid);
    }
    return 1;
}

hook OnDialogResponse(playerid, dialogid, response, listitem, inputtext[])
{
    #pragma unused inputtext

    if (dialogid != DIALOG_CAR_CONTROLS)
    {
        return 1;
    }
    if (!response)
    {
        return 1;
    }
    if (listitem < 0 || listitem > _:CAR_ACTION_TRUNK)
    {
        return CarControls_ShowMenu(playerid);
    }

    CarControls_Execute(playerid, E_CAR_CONTROL_ACTION:listitem);
    return 1;
}

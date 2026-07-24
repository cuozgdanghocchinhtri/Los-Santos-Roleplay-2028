// LSRP patch - /car command-only override.
// IMPORTANT: replace the existing CMD:car in modules/system/vehicles/controls.pwn
// with this function. Also remove/ignore the old car dialog handler if desired.

CMD:car(playerid, params[])
{
    if (params[0] == 0)
    {
        SendClien(playerid, NOTIFY_TYPE_MODERN,
            "Su dung: /car [engine/lights/windows/lock/hood/trunk]", 4500);
        return 1;
    }

    if (!strcmp(params, "engine", true))
        CarControls_Execute(playerid, CAR_ACTION_ENGINE);
    else if (!strcmp(params, "lights", true))
        CarControls_Execute(playerid, CAR_ACTION_LIGHTS);
    else if (!strcmp(params, "windows", true))
        CarControls_Execute(playerid, CAR_ACTION_WINDOWS);
    else if (!strcmp(params, "lock", true) || !strcmp(params, "doors", true))
        CarControls_Execute(playerid, CAR_ACTION_LOCK);
    else if (!strcmp(params, "hood", true) || !strcmp(params, "bonnet", true))
        CarControls_Execute(playerid, CAR_ACTION_HOOD);
    else if (!strcmp(params, "trunk", true) || !strcmp(params, "boot", true))
        CarControls_Execute(playerid, CAR_ACTION_TRUNK);
    else
        ShowNotifyText(playerid, NOTIFY_TYPE_MODERN,
            "Su dung: /car [engine/lights/windows/lock/hood/trunk]", 4500);

    return 1;
}

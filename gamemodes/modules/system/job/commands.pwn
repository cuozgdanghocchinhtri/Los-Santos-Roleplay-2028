//-----------------------------------------------------------------------------
// Generic job commands
//-----------------------------------------------------------------------------

CMD:job(playerid, params[])
{
    if (!params[0])
    {
        return Job_ShowStatus(playerid);
    }

    if (!strcmp(params, "quit", true) ||
        !strcmp(params, "stop", true) ||
        !strcmp(params, "nghi", true))
    {
        if (Job_GetActive(playerid) == JOB_NONE)
        {
            SendClientMessage(playerid, COLOR_RED, "Ban khong trong ca lam viec nao.");
            return 1;
        }

        Job_Stop(playerid, JOB_STOP_QUIT);
        SendClientMessage(playerid, COLOR_WHITE, "Ban da ket thuc ca lam viec.");
        return 1;
    }

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        "Su dung: /job de xem tien do, /job quit de nghi viec."
    );
    return 1;
}

CMD:jobs(playerid, params[])
{
    return cmd_job(playerid, params);
}


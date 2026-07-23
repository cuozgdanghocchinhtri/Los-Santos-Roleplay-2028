//-----------------------------------------------------------------------------
// Pizza job - commands
//-----------------------------------------------------------------------------

CMD:giaobanh(playerid, params[])
{
    #pragma unused params
    return Pizza_StartDelivery(playerid);
}

CMD:pizza(playerid, params[])
{
    #pragma unused params

    if (Job_IsEmployed(playerid, JOB_PIZZA))
        return Pizza_ShowEmployeeMenu(playerid);

    return Pizza_ShowApplication(playerid);
}

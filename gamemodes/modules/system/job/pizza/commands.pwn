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

    if (!pJobLoaded[playerid])
    {
        return Pizza_LoadCharacterJob(playerid);
    }

    if (Pizza_IsEmployee(playerid))
    {
        return Pizza_ShowEmployeeMenu(playerid);
    }

    return Pizza_ShowApplication(playerid);
}

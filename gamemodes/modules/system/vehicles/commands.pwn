//-----------------------------------------------------------------------------
// Owned vehicle commands
//-----------------------------------------------------------------------------

CMD:vehicles(playerid, params[])
{
    #pragma unused params

    printf(
        "[VEHICLE DEBUG] CMD vehicles p=%d char_loaded=%d owner=%d loaded=%d count=%d",
        playerid,
        _:IsPlayerCharacterLoaded(playerid),
        GetPlayerCharacterID(playerid),
        _:s_OwnedVehiclesLoaded[playerid],
        s_OwnedVehicleCount[playerid]
    );

    if (!IsPlayerCharacterLoaded(playerid))
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chua tai nhan vat.");
        return 1;
    }

    Vehicle_ShowList(playerid);
    return 1;
}

//-----------------------------------------------------------------------------
// LS:RP Medical Commands.
//
// File này chỉ chứa command/player-facing flow.
// Medical state logic nằm trong medical/core.pwn.
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

// Player tự chấp nhận death/hospital sau thời gian tối thiểu.
//
// DOWNED:
//     chỉ được dùng sau MEDICAL_ACCEPT_DEATH_DELAY_SECONDS.
//
// DEAD:
//     được phép dùng ngay.
CMD:acceptdeath(playerid, params[])
{
    #pragma unused params

    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    if (!Medical_IsDowned(playerid) &&
        !Medical_IsDead(playerid))
    {
        SendClientMessage(
            playerid,
            0x858585FF,
            "Ban khong o trong tinh trang can /acceptdeath."
        );
        return 1;
    }

    if (Medical_IsDowned(playerid) &&
        !PlayerMedical[playerid][medicalCanAcceptDeath])
    {
        new const remaining =
            MEDICAL_ACCEPT_DEATH_DELAY_SECONDS -
            PlayerMedical[playerid][medicalDownedElapsed];

        new message[112];
        format(
            message,
            sizeof(message),
            "Ban can cho them %d giay truoc khi co the chap nhan death.",
            remaining > 0 ? remaining : 0
        );

        SendClientMessage(
            playerid,
            0x858585FF,
            message
        );
        return 1;
    }

    Medical_HospitalRespawn(playerid);
    SendClientMessage(
        playerid,
        0xFFFFFFAA,
        "Ban tinh lai tai All Saints General Hospital."
    );
    return 1;
}

// Debug/status command tạm thời cho development.
// Không thay đổi state; dùng để kiểm tra countdown/server health.
CMD:medicalstate(playerid, params[])
{
    #pragma unused params

    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 1;
    }

    new stateName[16];

    switch (Medical_GetState(playerid))
    {
        case MEDICAL_STATE_NORMAL:
        {
            format(stateName, sizeof(stateName), "NORMAL");
        }

        case MEDICAL_STATE_INJURED:
        {
            format(stateName, sizeof(stateName), "INJURED");
        }

        case MEDICAL_STATE_DOWNED:
        {
            format(stateName, sizeof(stateName), "DOWNED");
        }

        case MEDICAL_STATE_DEAD:
        {
            format(stateName, sizeof(stateName), "DEAD");
        }
    }

    new message[160];
    format(
        message,
        sizeof(message),
        "Medical: %s | HP %.1f | Armour %.1f | Downed %ds/%ds | Stabilized: %s",
        stateName,
        PlayerHealth_Get(playerid),
        PlayerHealth_GetArmour(playerid),
        PlayerMedical[playerid][medicalDownedElapsed],
        MEDICAL_DOWNED_DURATION_SECONDS,
        PlayerMedical[playerid][medicalStabilized] ? "Yes" : "No"
    );

    SendClientMessage(
        playerid,
        0xBFC0C2FF,
        message
    );
    return 1;
}

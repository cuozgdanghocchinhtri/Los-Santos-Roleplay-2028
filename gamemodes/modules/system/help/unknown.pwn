#include <YSI_Coding\y_hooks>

//-----------------------------------------------------------------------------
// Final command fallback. This file must be included after every command.
//-----------------------------------------------------------------------------

hook OnPlayerCommandText(playerid, cmdtext[])
{
    new command[40], index;

    while (index < sizeof(command) - 1 &&
        cmdtext[index] != 0 &&
        cmdtext[index] != ' ' &&
        cmdtext[index] != '\t')
    {
        command[index] = cmdtext[index];
        index++;
    }
    command[index] = 0;

    new message[128];
    format(
        message,
        sizeof(message),
        "Lenh %s khong ton tai, su dung /help de xem chi tiet",
        command
    );
    SendClientMessage(playerid, COLOR_RED, message);

    // Stop the callback chain so open.mp does not append its own
    // "Unknown command" message.
    return ~1;
}

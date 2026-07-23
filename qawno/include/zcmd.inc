#if defined _INC_ZCMD_COMPAT
    #endinput
#endif
#define _INC_ZCMD_COMPAT

// Small ZCMD-compatible command layer used by this project.
// Commands are declared as:
//
//     CMD:vehicles(playerid, params[])
//
// Unknown commands return 0 so other command systems can handle them.

#include <YSI_Coding\y_hooks>

#define CMD:%1(%2) forward cmd_%1(%2); public cmd_%1(%2)

stock bool:zcmd_IsSpace(character)
{
    return character == ' ' || character == '\t';
}

stock zcmd_Dispatch(playerid, const cmdtext[])
{
    if (cmdtext[0] != '/')
    {
        return 0;
    }

    new commandName[32], params[128], functionName[40];
    new length = strlen(cmdtext);
    new index = 1;
    new commandLength;

    while (index < length &&
        !zcmd_IsSpace(cmdtext[index]) &&
        commandLength < sizeof(commandName) - 1)
    {
        commandName[commandLength] = cmdtext[index];
        commandLength++;
        index++;
    }
    commandName[commandLength] = 0;

    while (index < length && zcmd_IsSpace(cmdtext[index]))
    {
        index++;
    }

    strmid(params, cmdtext, index, length, sizeof(params));
    StrToLower(commandName);
    format(functionName, sizeof(functionName), "cmd_%s", commandName);

    return CallLocalFunction(functionName, "ds", playerid, params);
}

hook OnPlayerCommandText(playerid, cmdtext[])
{
    // A recognized command must stop the remaining OnPlayerCommandText hook
    // chain. Chat/stats hooks intentionally return 0 for commands they do not
    // own; without this early exit the server would still report "Unknown
    // command" even though the command handler already ran.
    if (zcmd_Dispatch(playerid, cmdtext))
    {
        return ~1;
    }

    return 0;
}

//-----------------------------------------------------------------------------
// Generic job system - persistence
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

forward public OnJobProgressLoaded(playerid, characterID, loadToken);

stock Job_LoadProgress(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new const characterID = GetPlayerCharacterID(playerid);

    if (characterID == INVALID_CHARACTER_ID)
    {
        return 0;
    }

    if (s_PlayerJobProgressLoading[playerid])
    {
        return 0;
    }

    Job_ResetProgress(playerid);
    s_PlayerJobProgressLoaded[playerid] = false;
    s_PlayerJobProgressLoading[playerid] = true;
    s_PlayerJobCharacterID[playerid] = characterID;
    s_PlayerJobLoadToken[playerid]++;

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "SELECT `job_type`,`experience`,`completed_runs`,`completed_tasks`,`best_streak`,`total_earnings` FROM `character_jobs` WHERE `character_id`=%d;",
        characterID
    );

    mysql_tquery(
        g_DatabaseHandle,
        query,
        "OnJobProgressLoaded",
        "ddd",
        playerid,
        characterID,
        s_PlayerJobLoadToken[playerid]
    );
    return 1;
}

public OnJobProgressLoaded(playerid, characterID, loadToken)
{
    if (!IsPlayerConnected(playerid) ||
        !IsPlayerCharacterLoaded(playerid) ||
        GetPlayerCharacterID(playerid) != characterID ||
        s_PlayerJobCharacterID[playerid] != characterID ||
        s_PlayerJobLoadToken[playerid] != loadToken)
    {
        return 1;
    }

    Job_ResetProgress(playerid);

    new const rows = cache_num_rows();

    for (new row = 0; row < rows; row++)
    {
        new jobid;
        cache_get_value_name_int(row, "job_type", jobid);

        if (jobid <= JOB_NONE || jobid >= MAX_JOB_TYPES)
        {
            continue;
        }

        cache_get_value_name_int(
            row,
            "experience",
            s_PlayerJobExperience[playerid][jobid]
        );
        cache_get_value_name_int(
            row,
            "completed_runs",
            s_PlayerJobCompletedRuns[playerid][jobid]
        );
        cache_get_value_name_int(
            row,
            "completed_tasks",
            s_PlayerJobCompletedTasks[playerid][jobid]
        );
        cache_get_value_name_int(
            row,
            "best_streak",
            s_PlayerJobBestStreak[playerid][jobid]
        );
        cache_get_value_name_int(
            row,
            "total_earnings",
            s_PlayerJobTotalEarnings[playerid][jobid]
        );

    }

    s_PlayerJobProgressLoading[playerid] = false;
    s_PlayerJobProgressLoaded[playerid] = true;

    SendClientMessage(
        playerid,
        COLOR_WHITE,
        "Du lieu nghe nghiep cua nhan vat da duoc tai."
    );
    return 1;
}

stock Job_SaveProgress(playerid, jobid)
{
    if (!IsPlayerCharacterLoaded(playerid) ||
        !Job_IsValid(jobid) ||
        !Job_IsProgressReady(playerid))
    {
        return 0;
    }

    new query[768];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "INSERT INTO `character_jobs` (`character_id`,`job_type`,`experience`,`completed_runs`,`completed_tasks`,`best_streak`,`total_earnings`) VALUES (%d,%d,%d,%d,%d,%d,%d) ON DUPLICATE KEY UPDATE `experience`=VALUES(`experience`),`completed_runs`=VALUES(`completed_runs`),`completed_tasks`=VALUES(`completed_tasks`),`best_streak`=VALUES(`best_streak`),`total_earnings`=VALUES(`total_earnings`),`updated_at`=CURRENT_TIMESTAMP;",
        GetPlayerCharacterID(playerid),
        jobid,
        s_PlayerJobExperience[playerid][jobid],
        s_PlayerJobCompletedRuns[playerid][jobid],
        s_PlayerJobCompletedTasks[playerid][jobid],
        s_PlayerJobBestStreak[playerid][jobid],
        s_PlayerJobTotalEarnings[playerid][jobid]
    );

    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

stock Job_SaveAllProgress(playerid)
{
    if (!Job_IsProgressReady(playerid))
    {
        return 0;
    }

    for (new jobid = 1; jobid < MAX_JOB_TYPES; jobid++)
    {
        if (g_JobRegistered[jobid] &&
            (s_PlayerJobExperience[playerid][jobid] > 0 ||
            s_PlayerJobCompletedTasks[playerid][jobid] > 0))
        {
            Job_SaveProgress(playerid, jobid);
        }
    }
    return 1;
}

stock Job_SaveCharacterCash(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        return 0;
    }

    new query[256];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `player_characters` SET `cash`=%d WHERE `character_id`=%d AND `account_id`=%d;",
        s_CharacterCash[playerid],
        GetPlayerCharacterID(playerid),
        GetPlayerAccountID(playerid)
    );

    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

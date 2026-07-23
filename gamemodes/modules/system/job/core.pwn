//-----------------------------------------------------------------------------
// Generic job system - lifecycle and rewards
//-----------------------------------------------------------------------------

#include <YSI_Coding\y_hooks>

forward public OnPlayerJobStopping(playerid, jobid, reason);

public OnPlayerJobStopping(playerid, jobid, reason)
{
    #pragma unused playerid
    #pragma unused jobid
    #pragma unused reason
    return 1;
}

stock Job_Register(jobid, const name[])
{
    if (jobid <= JOB_NONE || jobid >= MAX_JOB_TYPES || !name[0])
    {
        return 0;
    }

    g_JobRegistered[jobid] = true;
    format(g_JobName[jobid], MAX_JOB_NAME_LENGTH, "%s", name);
    return 1;
}

stock Job_Hire(playerid, jobid, dailySalary, dailyAllowance)
{
    if (!Job_IsValid(jobid) ||
        !Job_IsProgressReady(playerid) ||
        Job_IsEmployed(playerid, jobid) ||
        dailySalary < 0 ||
        dailyAllowance < 0)
    {
        return 0;
    }

    new
        year,
        month,
        day,
        hour,
        minute,
        second;

    getdate(year, month, day);
    gettime(hour, minute, second);

    s_PlayerJobEmployed[playerid][jobid] = true;
    s_PlayerJobDailySalary[playerid][jobid] = dailySalary;
    s_PlayerJobDailyAllowance[playerid][jobid] = dailyAllowance;

    format(
        s_PlayerJobHiredAt[playerid][jobid],
        MAX_JOB_HIRE_DATE_LENGTH,
        "%04d-%02d-%02d %02d:%02d:%02d",
        year,
        month,
        day,
        hour,
        minute,
        second
    );

    new query[1024];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "INSERT INTO `character_jobs` (`character_id`,`job_type`,`experience`,`completed_runs`,`completed_tasks`,`best_streak`,`total_earnings`,`is_employed`,`hired_at`,`daily_salary`,`daily_allowance`) VALUES (%d,%d,%d,%d,%d,%d,%d,1,CURRENT_TIMESTAMP,%d,%d) ON DUPLICATE KEY UPDATE `is_employed`=1,`hired_at`=CURRENT_TIMESTAMP,`resigned_at`=NULL,`daily_salary`=VALUES(`daily_salary`),`daily_allowance`=VALUES(`daily_allowance`),`updated_at`=CURRENT_TIMESTAMP;",
        GetPlayerCharacterID(playerid),
        jobid,
        s_PlayerJobExperience[playerid][jobid],
        s_PlayerJobCompletedRuns[playerid][jobid],
        s_PlayerJobCompletedTasks[playerid][jobid],
        s_PlayerJobBestStreak[playerid][jobid],
        s_PlayerJobTotalEarnings[playerid][jobid],
        dailySalary,
        dailyAllowance
    );
    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

stock Job_Resign(playerid, jobid)
{
    if (!Job_IsValid(jobid) ||
        !Job_IsProgressReady(playerid) ||
        !Job_IsEmployed(playerid, jobid))
    {
        return 0;
    }

    s_PlayerJobEmployed[playerid][jobid] = false;
    s_PlayerJobDailySalary[playerid][jobid] = 0;
    s_PlayerJobDailyAllowance[playerid][jobid] = 0;

    new query[384];
    mysql_format(
        g_DatabaseHandle,
        query,
        sizeof(query),
        "UPDATE `character_jobs` SET `is_employed`=0,`resigned_at`=CURRENT_TIMESTAMP,`daily_salary`=0,`daily_allowance`=0,`updated_at`=CURRENT_TIMESTAMP WHERE `character_id`=%d AND `job_type`=%d;",
        GetPlayerCharacterID(playerid),
        jobid
    );
    mysql_tquery(g_DatabaseHandle, query);
    return 1;
}

stock bool:Job_CanStart(playerid, jobid, bool:sendError = true)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        if (sendError)
        {
            SendClientMessage(playerid, COLOR_RED, "Ban chua tai nhan vat.");
        }
        return false;
    }

    if (!Job_IsValid(jobid))
    {
        if (sendError)
        {
            SendClientMessage(playerid, COLOR_RED, "Cong viec nay khong hop le.");
        }
        return false;
    }

    // Progress/XP is secondary data and must never block the player from
    // starting the job. Load it quietly in the background when necessary.
    if (!Job_IsProgressReady(playerid) &&
        !s_PlayerJobProgressLoading[playerid])
    {
        Job_LoadProgress(playerid);
    }

    if (s_PlayerActiveJob[playerid] != JOB_NONE)
    {
        if (sendError)
        {
            SendClientMessage(
                playerid,
                COLOR_RED,
                "Ban dang trong mot ca lam viec khac. Dung /job quit truoc."
            );
        }
        return false;
    }

    if (GetPlayerState(playerid) == PLAYER_STATE_WASTED ||
        GetPlayerState(playerid) == PLAYER_STATE_SPECTATING)
    {
        if (sendError)
        {
            SendClientMessage(playerid, COLOR_RED, "Ban khong the bat dau cong viec luc nay.");
        }
        return false;
    }

    return true;
}

stock Job_Start(playerid, jobid)
{
    if (!Job_CanStart(playerid, jobid))
    {
        return 0;
    }

    s_PlayerActiveJob[playerid] = jobid;
    s_PlayerJobShiftEarnings[playerid] = 0;
    return 1;
}

stock Job_Stop(playerid, reason)
{
    new const jobid = s_PlayerActiveJob[playerid];

    if (jobid == JOB_NONE)
    {
        return 0;
    }

    CallLocalFunction(
        "OnPlayerJobStopping",
        "iii",
        playerid,
        jobid,
        reason
    );

    s_PlayerActiveJob[playerid] = JOB_NONE;
    s_PlayerJobShiftEarnings[playerid] = 0;
    return 1;
}

stock Job_GivePay(playerid, amount)
{
    if (amount <= 0 || amount > JOB_MAX_SINGLE_PAYMENT)
    {
        return 0;
    }

    GivePlayerMoney(playerid, amount);
    s_CharacterCash[playerid] = GetPlayerMoney(playerid);
    s_PlayerJobShiftEarnings[playerid] += amount;
    Job_SaveCharacterCash(playerid);
    return 1;
}

stock Job_AddExperience(playerid, jobid, amount)
{
    if (!Job_IsValid(jobid) || amount <= 0)
    {
        return 0;
    }

    new const oldLevel = Job_GetLevel(playerid, jobid);
    s_PlayerJobExperience[playerid][jobid] += amount;
    new const newLevel = Job_GetLevel(playerid, jobid);

    if (newLevel > oldLevel)
    {
        new message[128];
        format(
            message,
            sizeof(message),
            "Ban da dat cap %d trong nghe %s.",
            newLevel,
            g_JobName[jobid]
        );
        SendClientMessage(playerid, COLOR_WHITE, message);
    }
    return 1;
}

stock Job_RecordTask(
    playerid,
    reward,
    experience,
    bool:streakEligible = true
)
{
    new const jobid = s_PlayerActiveJob[playerid];

    if (!Job_IsValid(jobid))
    {
        return 0;
    }

    // Gameplay/reward is not allowed to fail just because XP history is
    // still loading. Pay the completed delivery and skip only progression.
    if (!Job_IsProgressReady(playerid))
    {
        Job_GivePay(playerid, reward);
        return 1;
    }

    if (streakEligible)
    {
        s_PlayerJobCurrentStreak[playerid][jobid]++;

        if (s_PlayerJobCurrentStreak[playerid][jobid] >
            s_PlayerJobBestStreak[playerid][jobid])
        {
            s_PlayerJobBestStreak[playerid][jobid] =
                s_PlayerJobCurrentStreak[playerid][jobid];
        }
    }
    else
    {
        s_PlayerJobCurrentStreak[playerid][jobid] = 0;
    }

    s_PlayerJobCompletedTasks[playerid][jobid]++;
    s_PlayerJobTotalEarnings[playerid][jobid] += reward;

    Job_GivePay(playerid, reward);
    Job_AddExperience(playerid, jobid, experience);
    Job_SaveProgress(playerid, jobid);
    return 1;
}

stock Job_CompleteRun(playerid, reward, experience)
{
    new const jobid = s_PlayerActiveJob[playerid];

    if (!Job_IsValid(jobid))
    {
        return 0;
    }

    // Shift completion/reward must remain functional even while historical
    // progression is unavailable.
    if (!Job_IsProgressReady(playerid))
    {
        Job_GivePay(playerid, reward);
        return 1;
    }

    s_PlayerJobCompletedRuns[playerid][jobid]++;
    s_PlayerJobTotalEarnings[playerid][jobid] += reward;

    Job_GivePay(playerid, reward);
    Job_AddExperience(playerid, jobid, experience);
    Job_SaveProgress(playerid, jobid);
    return 1;
}

stock Job_ShowStatus(playerid)
{
    if (!IsPlayerCharacterLoaded(playerid))
    {
        SendClientMessage(playerid, COLOR_RED, "Ban chua tai nhan vat.");
        return 0;
    }

    new
        body[1024],
        line[160],
        activeName[MAX_JOB_NAME_LENGTH];

    Job_GetName(s_PlayerActiveJob[playerid], activeName, sizeof(activeName));

    format(
        body,
        sizeof(body),
        "Cong viec dang hoat dong: %s\nThu nhap ca hien tai: $%d\n\nTIEN DO NGHE NGHIEP\n",
        activeName,
        s_PlayerJobShiftEarnings[playerid]
    );

    for (new jobid = 1; jobid < MAX_JOB_TYPES; jobid++)
    {
        if (!g_JobRegistered[jobid])
        {
            continue;
        }

        new const level = Job_GetLevel(playerid, jobid);
        new const nextXP = Job_GetNextLevelExperience(level);

        new employment[20];
        format(
            employment,
            sizeof(employment),
            "%s",
            Job_IsEmployed(playerid, jobid) ? "Dang lam viec" : "Chua tuyen dung"
        );

        if (nextXP > 0)
        {
            format(
                line,
                sizeof(line),
                "\n%s: %s - Cap %d - XP %d/%d - Hoan thanh %d chuyen",
                g_JobName[jobid],
                employment,
                level,
                s_PlayerJobExperience[playerid][jobid],
                nextXP,
                s_PlayerJobCompletedRuns[playerid][jobid]
            );
        }
        else
        {
            format(
                line,
                sizeof(line),
                "\n%s: %s - Cap %d (toi da) - Hoan thanh %d chuyen",
                g_JobName[jobid],
                employment,
                level,
                s_PlayerJobCompletedRuns[playerid][jobid]
            );
        }

        strcat(body, line, sizeof(body));
    }

    ShowPlayerDialog(
        playerid,
        DIALOG_JOB_STATUS,
        DIALOG_STYLE_MSGBOX,
        "LS:RP - Nghe nghiep",
        body,
        "Dong",
        ""
    );
    return 1;
}

hook OnPlayerConnect(playerid)
{
    Job_ResetPlayer(playerid);
    return 1;
}

hook OnPlayerSpawn(playerid)
{
    if (IsPlayerCharacterLoaded(playerid) &&
        GetPlayerCharacterID(playerid) != INVALID_CHARACTER_ID &&
        s_PlayerJobCharacterID[playerid] != GetPlayerCharacterID(playerid) &&
        !s_PlayerJobProgressLoading[playerid])
    {
        Job_LoadProgress(playerid);
    }
    return 1;
}

hook OnPlayerDeath(playerid, killerid, WEAPON:reason)
{
    #pragma unused killerid
    #pragma unused reason

    if (s_PlayerActiveJob[playerid] != JOB_NONE)
    {
        Job_Stop(playerid, JOB_STOP_DEATH);
    }
    return 1;
}

hook OnPlayerDisconnect(playerid, reason)
{
    #pragma unused reason

    if (s_PlayerActiveJob[playerid] != JOB_NONE)
    {
        Job_Stop(playerid, JOB_STOP_DISCONNECT);
    }

    Job_SaveAllProgress(playerid);
    Job_ResetPlayer(playerid);
    return 1;
}

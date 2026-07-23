param(
    [string]$ProjectRoot = ".",
    [switch]$Push
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$jobCore = Join-Path $ProjectRoot "gamemodes\modules\system\job\core.pwn"
$jobPersistence = Join-Path $ProjectRoot "gamemodes\modules\system\job\persistence.pwn"
$pizzaCore = Join-Path $ProjectRoot "gamemodes\modules\system\job\pizza\core.pwn"

foreach ($file in @($jobCore, $jobPersistence, $pizzaCore)) {
    if (!(Test-Path $file)) {
        throw "Khong tim thay: $file"
    }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $ProjectRoot ".pizza-progress-backup-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

Copy-Item $jobCore (Join-Path $backup "job-core.pwn") -Force
Copy-Item $jobPersistence (Join-Path $backup "job-persistence.pwn") -Force
Copy-Item $pizzaCore (Join-Path $backup "pizza-core.pwn") -Force

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Save-NoBom([string]$Path, [string]$Text) {
    [System.IO.File]::WriteAllText($Path, $Text, $utf8NoBom)
}

# 1) Progress/XP must not block starting the shift.
$core = [System.IO.File]::ReadAllText($jobCore)

$oldCanStart = @'
    if (!Job_IsProgressReady(playerid))
    {
        if (!s_PlayerJobProgressLoading[playerid])
        {
            Job_LoadProgress(playerid);
        }

        if (sendError)
        {
            SendClientMessage(
                playerid,
                COLOR_RED,
                "Du lieu nghe nghiep dang duoc tai. Hay thu lai sau giay lat."
            );
        }
        return false;
    }
'@

$newCanStart = @'
    // Progress/XP is secondary data and must never block the player from
    // starting the job. Load it quietly in the background when necessary.
    if (!Job_IsProgressReady(playerid) &&
        !s_PlayerJobProgressLoading[playerid])
    {
        Job_LoadProgress(playerid);
    }
'@

if (!$core.Contains($oldCanStart)) {
    throw "Khong tim thay block Job_CanStart cu. Source local da khac ban GitHub."
}
$core = $core.Replace($oldCanStart, $newCanStart)

$oldRecordTask = @'
    if (!Job_IsValid(jobid) || !Job_IsProgressReady(playerid))
    {
        return 0;
    }

    if (streakEligible)
'@

$newRecordTask = @'
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
'@

if (!$core.Contains($oldRecordTask)) {
    throw "Khong tim thay block Job_RecordTask cu."
}
$core = $core.Replace($oldRecordTask, $newRecordTask)

$oldCompleteRun = @'
    if (!Job_IsValid(jobid) || !Job_IsProgressReady(playerid))
    {
        return 0;
    }

    s_PlayerJobCompletedRuns[playerid][jobid]++;
'@

$newCompleteRun = @'
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
'@

if (!$core.Contains($oldCompleteRun)) {
    throw "Khong tim thay block Job_CompleteRun cu."
}
$core = $core.Replace($oldCompleteRun, $newCompleteRun)

Save-NoBom $jobCore $core

# 2) character_jobs is progression/history only.
$persistence = [System.IO.File]::ReadAllText($jobPersistence)

$oldSelect = @'
        "SELECT `job_type`,`experience`,`completed_runs`,`completed_tasks`,`best_streak`,`total_earnings`,`is_employed`,COALESCE(DATE_FORMAT(`hired_at`,'%%Y-%%m-%%d %%H:%%i:%%s'),'') AS `hired_at`,`daily_salary`,`daily_allowance` FROM `character_jobs` WHERE `character_id`=%d;",
'@

$newSelect = @'
        "SELECT `job_type`,`experience`,`completed_runs`,`completed_tasks`,`best_streak`,`total_earnings` FROM `character_jobs` WHERE `character_id`=%d;",
'@

if (!$persistence.Contains($oldSelect)) {
    throw "Khong tim thay SELECT character_jobs cu."
}
$persistence = $persistence.Replace($oldSelect, $newSelect)

$oldEmploymentLoad = @'
        cache_get_value_name_bool(
            row,
            "is_employed",
            s_PlayerJobEmployed[playerid][jobid]
        );
        cache_get_value_name(
            row,
            "hired_at",
            s_PlayerJobHiredAt[playerid][jobid],
            MAX_JOB_HIRE_DATE_LENGTH
        );
        cache_get_value_name_int(
            row,
            "daily_salary",
            s_PlayerJobDailySalary[playerid][jobid]
        );
        cache_get_value_name_int(
            row,
            "daily_allowance",
            s_PlayerJobDailyAllowance[playerid][jobid]
        );
'@

if (!$persistence.Contains($oldEmploymentLoad)) {
    throw "Khong tim thay block load employment cu trong persistence.pwn."
}
$persistence = $persistence.Replace($oldEmploymentLoad, "")

Save-NoBom $jobPersistence $persistence

# 3) pJob load completed -> start progression load in the background.
$pizza = [System.IO.File]::ReadAllText($pizzaCore)

$oldPizzaLoaded = @'
    pJobLoaded[playerid] = true;
    return 1;
}
'@

$newPizzaLoaded = @'
    pJobLoaded[playerid] = true;

    // pJob decides employment immediately. Progress/history loads separately
    // and never blocks renting a Pizzaboy.
    if (!Job_IsProgressReady(playerid) &&
        !s_PlayerJobProgressLoading[playerid])
    {
        Job_LoadProgress(playerid);
    }

    return 1;
}
'@

if (!$pizza.Contains($oldPizzaLoaded)) {
    throw "Khong tim thay OnPizzaCharacterJobLoaded block cu."
}
$pizza = $pizza.Replace($oldPizzaLoaded, $newPizzaLoaded)

Save-NoBom $pizzaCore $pizza

Write-Host ""
Write-Host "DA FIX PIZZA PROGRESS LOAD." -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host ""
Write-Host "Thay doi:"
Write-Host "- Thue Pizzaboy khong bi chan boi Job_IsProgressReady."
Write-Host "- character_jobs chi load XP/runs/tasks/streak/earnings."
Write-Host "- pJob load xong tu kick-off Job_LoadProgress."
Write-Host "- Neu progress chua san sang luc giao banh, tien van duoc tra."
Write-Host ""

Push-Location $ProjectRoot
try {
    & git diff --check
    if ($LASTEXITCODE -ne 0) {
        throw "git diff --check that bai."
    }

    if ($Push) {
        & git add -- `
            "gamemodes/modules/system/job/core.pwn" `
            "gamemodes/modules/system/job/persistence.pwn" `
            "gamemodes/modules/system/job/pizza/core.pwn"

        & git commit -m "fix(job): prevent pizza rental from waiting on progression"
        if ($LASTEXITCODE -ne 0) {
            throw "git commit that bai."
        }

        & git push
        if ($LASTEXITCODE -ne 0) {
            throw "git push that bai."
        }

        Write-Host ""
        Write-Host "DA COMMIT + PUSH THANH CONG." -ForegroundColor Green
    }
    else {
        Write-Host "Chua commit/push. Chay FIX_AND_PUSH.bat de fix + commit + push."
    }
}
finally {
    Pop-Location
}

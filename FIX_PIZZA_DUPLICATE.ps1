param(
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$main = Join-Path $ProjectRoot "gamemodes\main.pwn"
if (!(Test-Path $main)) {
    throw "Khong tim thay gamemodes\main.pwn"
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $ProjectRoot ".pizza-duplicate-fix-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null
Copy-Item $main (Join-Path $backup "main.pwn") -Force

$systemPizza = Join-Path $ProjectRoot "gamemodes\modules\system\job\pizza"
$oldPizza = Join-Path $ProjectRoot "gamemodes\modules\job\pizza"

if (Test-Path $systemPizza) {
    Copy-Item $systemPizza (Join-Path $backup "system-job-pizza") -Recurse -Force
}

# ---------------------------------------------------------------------------
# 1) Remove BOTH Pizza include blocks from main.pwn.
# 2) Re-add ONLY modules/system/job/pizza exactly once.
# ---------------------------------------------------------------------------
$lines = Get-Content $main

$clean = foreach ($line in $lines) {
    if ($line -match '^\s*#include\s+"modules/(system/job/)?job?/pizza/') {
        continue
    }

    if ($line -match '^\s*#include\s+"modules/job/pizza/') {
        continue
    }

    if ($line -match '^\s*#include\s+"modules/system/job/pizza/') {
        continue
    }

    $line
}

$anchor = '#include "modules/system/job/core.pwn"'
$index = [Array]::IndexOf($clean, $anchor)

if ($index -lt 0) {
    throw "Khong tim thay include modules/system/job/core.pwn trong main.pwn"
}

$block = @(
    '',
    '#include "modules/system/job/pizza/data.pwn"',
    '#include "modules/system/job/pizza/vehicle.pwn"',
    '#include "modules/system/job/pizza/ui.pwn"',
    '#include "modules/system/job/pizza/core.pwn"',
    '#include "modules/system/job/pizza/commands.pwn"'
)

$before = @()
$after = @()

if ($index -ge 0) {
    $before = $clean[0..$index]

    if ($index + 1 -lt $clean.Count) {
        $after = $clean[($index + 1)..($clean.Count - 1)]
    }
}

$newMain = @($before + $block + $after)
Set-Content -Path $main -Value $newMain -Encoding UTF8

# ---------------------------------------------------------------------------
# Fix open.mp ClearAnimations tag warning in the active Pizza data file.
# open.mp expects FORCE_SYNC enum; SYNC_ALL is the correct explicit value.
# ---------------------------------------------------------------------------
$data = Join-Path $systemPizza "data.pwn"

if (Test-Path $data) {
    $dataText = Get-Content $data -Raw
    $dataText = $dataText.Replace(
        'ClearAnimations(playerid, true);',
        'ClearAnimations(playerid, SYNC_ALL);'
    )
    Set-Content -Path $data -Value $dataText -Encoding UTF8
}
else {
    Write-Warning "Khong tim thay $data"
}

# ---------------------------------------------------------------------------
# Old folder is the duplicate source seen in compiler paths.
# Rename instead of deleting so nothing is lost.
# ---------------------------------------------------------------------------
if (Test-Path $oldPizza) {
    $disabled = Join-Path $ProjectRoot "gamemodes\modules\job\pizza_DUPLICATE_DISABLED"

    if (Test-Path $disabled) {
        Remove-Item $disabled -Recurse -Force
    }

    Move-Item $oldPizza $disabled
    Write-Host "Da doi ten folder duplicate:"
    Write-Host "  gamemodes\modules\job\pizza"
    Write-Host "->gamemodes\modules\job\pizza_DUPLICATE_DISABLED"
}

Write-Host ""
Write-Host "FIX XONG." -ForegroundColor Green
Write-Host "Main chi con 1 Pizza include block:"
Write-Host '  modules/system/job/pizza/...'
Write-Host ""
Write-Host "Backup: $backup"
Write-Host "Bay gio compile lai main.pwn."

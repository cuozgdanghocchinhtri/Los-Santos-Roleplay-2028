param(
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
$PackageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$Payload = Join-Path $PackageRoot "payload"

$main = Join-Path $ProjectRoot "gamemodes\main.pwn"
if (!(Test-Path $main)) {
    throw "Khong tim thay gamemodes\main.pwn. Hay chay script tai root project hoac truyen -ProjectRoot."
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $ProjectRoot ".pizza-backup-$stamp"
New-Item -ItemType Directory -Force -Path $backup | Out-Null

function Backup-IfExists([string]$path) {
    if (Test-Path $path) {
        $relative = $path.Substring($ProjectRoot.Length).TrimStart('\')
        $dest = Join-Path $backup $relative
        New-Item -ItemType Directory -Force -Path (Split-Path -Parent $dest) | Out-Null
        Copy-Item $path $dest -Force
    }
}

# Backup main, notify and old pizza folder.
Backup-IfExists $main
$notifyTarget = Join-Path $ProjectRoot "gamemodes\modules\utils\shownotifytext.pwn"
Backup-IfExists $notifyTarget

$pizzaTarget = Join-Path $ProjectRoot "gamemodes\modules\system\job\pizza"
if (Test-Path $pizzaTarget) {
    $pizzaBackup = Join-Path $backup "gamemodes\modules\system\job\pizza"
    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $pizzaBackup) | Out-Null
    Copy-Item $pizzaTarget $pizzaBackup -Recurse -Force
}

# Copy full replacement files.
New-Item -ItemType Directory -Force -Path $pizzaTarget | Out-Null
Copy-Item (Join-Path $Payload "gamemodes\modules\system\job\pizza\*.pwn") $pizzaTarget -Force

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $notifyTarget) | Out-Null
Copy-Item (Join-Path $Payload "gamemodes\modules\utils\shownotifytext.pwn") $notifyTarget -Force

$migrationTarget = Join-Path $ProjectRoot "database\migrations\007_character_current_job.sql"
New-Item -ItemType Directory -Force -Path (Split-Path -Parent $migrationTarget) | Out-Null
Copy-Item (Join-Path $Payload "database\migrations\007_character_current_job.sql") $migrationTarget -Force

# Add Pizza includes to main.pwn, without relying on line numbers.
$mainText = Get-Content $main -Raw

$includeBlock = @'
#include "modules/system/job/pizza/data.pwn"
#include "modules/system/job/pizza/vehicle.pwn"
#include "modules/system/job/pizza/ui.pwn"
#include "modules/system/job/pizza/core.pwn"
#include "modules/system/job/pizza/commands.pwn"
'@

if ($mainText -notmatch [regex]::Escape('modules/system/job/pizza/data.pwn')) {
    $anchor = '#include "modules/system/job/core.pwn"'

    if ($mainText.Contains($anchor)) {
        $mainText = $mainText.Replace($anchor, $anchor + "`r`n`r`n" + $includeBlock.TrimEnd())
    }
    else {
        throw "Khong tim thay include modules/system/job/core.pwn trong main.pwn. Backup da tao tai $backup"
    }

    Set-Content -Path $main -Value $mainText -Encoding UTF8
}

Write-Host ""
Write-Host "DA CAI FILE PIZZA + NOTIFY." -ForegroundColor Green
Write-Host "Backup: $backup"
Write-Host ""
Write-Host "BUOC CON LAI:"
Write-Host "1) Import database\migrations\007_character_current_job.sql vao database lsrp."
Write-Host "2) Compile gamemode."
Write-Host "3) Neu co error/warning, gui nguyen log compile."

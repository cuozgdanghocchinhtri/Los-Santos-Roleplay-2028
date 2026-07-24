param(
    [string]$RepoRoot = "."
)

$ErrorActionPreference = "Stop"

# Resolve repository root so all paths work regardless of current shell format.
$RepoRoot = (Resolve-Path $RepoRoot).Path

$MainPath = Join-Path $RepoRoot "gamemodes\main.pwn"
$MedicalDir = Join-Path $RepoRoot "gamemodes\modules\system\medical"
$CoreTarget = Join-Path $MedicalDir "core.pwn"
$CommandsTarget = Join-Path $MedicalDir "commands.pwn"

$InstallerDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$CoreSource = Join-Path $InstallerDir "gamemodes\modules\system\medical\core.pwn"
$CommandsSource = Join-Path $InstallerDir "gamemodes\modules\system\medical\commands.pwn"

if (!(Test-Path $MainPath)) {
    throw "Khong tim thay gamemodes\main.pwn. Hay chay script tu root repository."
}

if (!(Test-Path $CoreSource) -or !(Test-Path $CommandsSource)) {
    throw "Bo cai bi thieu core.pwn hoac commands.pwn."
}

# Ensure destination directory exists.
New-Item -ItemType Directory -Force -Path $MedicalDir | Out-Null

# Back up current medical core before replacing it.
if (Test-Path $CoreTarget) {
    Copy-Item $CoreTarget "$CoreTarget.phase1.bak" -Force
}

# Install complete Phase 2 files.
Copy-Item $CoreSource $CoreTarget -Force
Copy-Item $CommandsSource $CommandsTarget -Force

# Update main.pwn idempotently.
$MainText = Get-Content $MainPath -Raw

$CoreInclude = '#include "modules/system/medical/core.pwn"'
$CommandsInclude = '#include "modules/system/medical/commands.pwn"'
$HealthInclude = '#include "modules/core/player/health.pwn"'

if ($MainText -notmatch [regex]::Escape($HealthInclude)) {
    $CharacterUtils = '#include "modules/core/player/character/utils.pwn"'

    if ($MainText -notmatch [regex]::Escape($CharacterUtils)) {
        throw "Khong tim thay character/utils.pwn include de chen Health Core."
    }

    $Replacement = $CharacterUtils + "`r`n`r`n" +
        "// Server-authoritative player health.`r`n" +
        $HealthInclude

    $MainText = $MainText.Replace($CharacterUtils, $Replacement)
}

if ($MainText -notmatch [regex]::Escape($CoreInclude)) {
    $MainText = $MainText.Replace(
        $HealthInclude,
        $HealthInclude + "`r`n" + $CoreInclude
    )
}

if ($MainText -notmatch [regex]::Escape($CommandsInclude)) {
    $MainText = $MainText.Replace(
        $CoreInclude,
        $CoreInclude + "`r`n" + $CommandsInclude
    )
}

Set-Content -Path $MainPath -Value $MainText -Encoding UTF8

Write-Host ""
Write-Host "Medical Phase 2 installed." -ForegroundColor Green
Write-Host "Installed:"
Write-Host "  gamemodes\modules\system\medical\core.pwn"
Write-Host "  gamemodes\modules\system\medical\commands.pwn"
Write-Host ""
Write-Host "main.pwn includes verified:"
Write-Host "  $HealthInclude"
Write-Host "  $CoreInclude"
Write-Host "  $CommandsInclude"
Write-Host ""
Write-Host "Backup (neu core cu ton tai):"
Write-Host "  gamemodes\modules\system\medical\core.pwn.phase1.bak"

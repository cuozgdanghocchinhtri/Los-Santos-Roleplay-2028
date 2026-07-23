$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# ============================================================
# LSRP GitHub Dependency Installer
# Dat file nay trong ROOT server, cung cap voi omp-server.exe.
#
# Tu dong tai:
#   - pBlueG SA-MP-MySQL R41-4
#   - samp-bcrypt 0.4.1
#   - YSI-Includes v5.10.0006
#
# Dich den:
#   qawno\include\a_mysql.inc
#   qawno\include\samp_bcrypt.inc
#   qawno\include\YSI_*
#   plugins\mysql.dll
#   plugins\samp_bcrypt.dll
#   libmariadb.dll / log-core.dll (root)
# ============================================================

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$DownloadDir = Join-Path $Root ".deps-download"
$ExtractDir  = Join-Path $Root ".deps-extract"

$IncludeDir = Join-Path $Root "qawno\include"
$PluginDir  = Join-Path $Root "plugins"

$MySQLRepo = "pBlueG/SA-MP-MySQL"
$MySQLTag  = "R41-4"

$BCryptRepo = "Sreyas-Sreelal/samp-bcrypt"
$BCryptTag  = "0.4.1"

$YSITag = "v5.10.0006"

function Write-Step([string]$Text) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host $Text -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
}

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Get-GitHubReleaseAsset {
    param(
        [Parameter(Mandatory=$true)][string]$Repo,
        [Parameter(Mandatory=$true)][string]$Tag,
        [Parameter(Mandatory=$true)][string[]]$PreferredPatterns
    )

    $Headers = @{
        "User-Agent" = "LSRP-Dependency-Installer"
        "Accept" = "application/vnd.github+json"
    }

    $Api = "https://api.github.com/repos/$Repo/releases/tags/$Tag"
    Write-Host "[GitHub API] $Api"

    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers

    foreach ($Pattern in $PreferredPatterns) {
        $Asset = $Release.assets | Where-Object { $_.name -match $Pattern } | Select-Object -First 1
        if ($Asset) {
            return $Asset
        }
    }

    throw "Khong tim thay release asset phu hop trong $Repo tag $Tag."
}

function Download-Asset {
    param(
        [Parameter(Mandatory=$true)]$Asset,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    Write-Host "[DOWNLOAD] $($Asset.name)"
    Invoke-WebRequest `
        -Uri $Asset.browser_download_url `
        -OutFile $Destination `
        -Headers @{ "User-Agent" = "LSRP-Dependency-Installer" }
}

function Copy-FoundFile {
    param(
        [Parameter(Mandatory=$true)][string]$SearchRoot,
        [Parameter(Mandatory=$true)][string]$FileName,
        [Parameter(Mandatory=$true)][string]$Destination
    )

    $Found = Get-ChildItem -Path $SearchRoot -Recurse -File -Filter $FileName | Select-Object -First 1

    if (-not $Found) {
        throw "Khong tim thay '$FileName' trong package."
    }

    Copy-Item $Found.FullName $Destination -Force
    Write-Host "[OK] $FileName -> $Destination" -ForegroundColor Green
}

Ensure-Dir $DownloadDir
Ensure-Dir $ExtractDir
Ensure-Dir $IncludeDir
Ensure-Dir $PluginDir

# ------------------------------------------------------------
# MySQL R41-4
# ------------------------------------------------------------
Write-Step "1/3 - MySQL R41-4"

$MySQLAsset = Get-GitHubReleaseAsset `
    -Repo $MySQLRepo `
    -Tag $MySQLTag `
    -PreferredPatterns @(
        '(?i)^mysql-R41-4-win32\.zip$',
        '(?i)win32.*\.zip$',
        '(?i)windows.*\.zip$'
    )

$MySQLZip = Join-Path $DownloadDir $MySQLAsset.name
$MySQLExtract = Join-Path $ExtractDir "mysql"

if (-not (Test-Path $MySQLZip)) {
    Download-Asset -Asset $MySQLAsset -Destination $MySQLZip
} else {
    Write-Host "[CACHE] $($MySQLAsset.name)"
}

if (Test-Path $MySQLExtract) {
    Remove-Item $MySQLExtract -Recurse -Force
}
Ensure-Dir $MySQLExtract
Expand-Archive $MySQLZip $MySQLExtract -Force

Copy-FoundFile $MySQLExtract "a_mysql.inc" (Join-Path $IncludeDir "a_mysql.inc")
Copy-FoundFile $MySQLExtract "mysql.dll" (Join-Path $PluginDir "mysql.dll")
Copy-FoundFile $MySQLExtract "libmariadb.dll" (Join-Path $Root "libmariadb.dll")
Copy-FoundFile $MySQLExtract "log-core.dll" (Join-Path $Root "log-core.dll")

# ------------------------------------------------------------
# BCrypt 0.4.1
# ------------------------------------------------------------
Write-Step "2/3 - samp-bcrypt 0.4.1"

$BCryptAsset = Get-GitHubReleaseAsset `
    -Repo $BCryptRepo `
    -Tag $BCryptTag `
    -PreferredPatterns @(
        '(?i)win32.*\.zip$',
        '(?i)windows.*\.zip$',
        '(?i).*win.*\.zip$',
        '(?i).*\.zip$'
    )

$BCryptZip = Join-Path $DownloadDir $BCryptAsset.name
$BCryptExtract = Join-Path $ExtractDir "bcrypt"

if (-not (Test-Path $BCryptZip)) {
    Download-Asset -Asset $BCryptAsset -Destination $BCryptZip
} else {
    Write-Host "[CACHE] $($BCryptAsset.name)"
}

if (Test-Path $BCryptExtract) {
    Remove-Item $BCryptExtract -Recurse -Force
}
Ensure-Dir $BCryptExtract
Expand-Archive $BCryptZip $BCryptExtract -Force

Copy-FoundFile $BCryptExtract "samp_bcrypt.inc" (Join-Path $IncludeDir "samp_bcrypt.inc")
Copy-FoundFile $BCryptExtract "samp_bcrypt.dll" (Join-Path $PluginDir "samp_bcrypt.dll")

# ------------------------------------------------------------
# YSI Includes
# ------------------------------------------------------------
Write-Step "3/3 - YSI Includes $YSITag"

$YSIZip = Join-Path $DownloadDir "YSI-Includes-$YSITag.zip"
$YSIExtract = Join-Path $ExtractDir "ysi"
$YSIUrl = "https://github.com/pawn-lang/YSI-Includes/archive/refs/tags/$YSITag.zip"

if (-not (Test-Path $YSIZip)) {
    Write-Host "[DOWNLOAD] $YSIUrl"
    Invoke-WebRequest `
        -Uri $YSIUrl `
        -OutFile $YSIZip `
        -Headers @{ "User-Agent" = "LSRP-Dependency-Installer" }
} else {
    Write-Host "[CACHE] YSI $YSITag"
}

if (Test-Path $YSIExtract) {
    Remove-Item $YSIExtract -Recurse -Force
}
Ensure-Dir $YSIExtract
Expand-Archive $YSIZip $YSIExtract -Force

# Find the extracted repository root that directly contains YSI_* folders.
$YSIRoot = Get-ChildItem -Path $YSIExtract -Directory -Recurse |
    Where-Object {
        (Get-ChildItem -Path $_.FullName -Directory -Filter "YSI_*" -ErrorAction SilentlyContinue).Count -gt 0
    } |
    Select-Object -First 1

if (-not $YSIRoot) {
    throw "Khong tim thay cac folder YSI_* sau khi giai nen."
}

$YSIFolders = Get-ChildItem -Path $YSIRoot.FullName -Directory -Filter "YSI_*"
foreach ($Folder in $YSIFolders) {
    $Dest = Join-Path $IncludeDir $Folder.Name
    if (Test-Path $Dest) {
        Remove-Item $Dest -Recurse -Force
    }
    Copy-Item $Folder.FullName $Dest -Recurse -Force
    Write-Host "[OK] $($Folder.Name) -> qawno\include\$($Folder.Name)" -ForegroundColor Green
}

# Copy any top-level .inc files shipped with YSI.
Get-ChildItem -Path $YSIRoot.FullName -File -Filter "*.inc" | ForEach-Object {
    Copy-Item $_.FullName (Join-Path $IncludeDir $_.Name) -Force
    Write-Host "[OK] $($_.Name) -> qawno\include\$($_.Name)" -ForegroundColor Green
}

# ------------------------------------------------------------
# Validation
# ------------------------------------------------------------
Write-Step "KIEM TRA"

$Required = @(
    "qawno\include\a_mysql.inc",
    "qawno\include\samp_bcrypt.inc",
    "plugins\mysql.dll",
    "plugins\samp_bcrypt.dll",
    "libmariadb.dll",
    "log-core.dll"
)

$Failed = $false

foreach ($Rel in $Required) {
    $Path = Join-Path $Root $Rel
    if (Test-Path $Path) {
        Write-Host "[OK] $Rel" -ForegroundColor Green
    } else {
        Write-Host "[THIEU] $Rel" -ForegroundColor Red
        $Failed = $true
    }
}

$YSICoding = Join-Path $IncludeDir "YSI_Coding"
if (Test-Path $YSICoding) {
    Write-Host "[OK] qawno\include\YSI_Coding" -ForegroundColor Green
} else {
    Write-Host "[THIEU] qawno\include\YSI_Coding" -ForegroundColor Red
    $Failed = $true
}

if ($Failed) {
    Write-Host ""
    Write-Host "Dependency setup CHUA hoan tat." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "DEPENDENCIES DA SAN SANG" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Bay gio compile lai:"
Write-Host "  Ctrl + Shift + B"
Write-Host ""
Write-Host "config.json legacy_plugins nen co:"
Write-Host '  "mysql", "samp_bcrypt"'
Write-Host ""

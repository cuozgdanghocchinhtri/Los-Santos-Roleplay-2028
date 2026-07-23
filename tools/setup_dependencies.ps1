$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Downloads = Join-Path $Root "_downloads"
$Temp = Join-Path $Root "_dependency_temp"
$Plugins = Join-Path $Root "plugins"
$Includes = Join-Path $Root "qawno\include"

New-Item -ItemType Directory -Force -Path $Downloads, $Temp, $Plugins, $Includes | Out-Null

function Download-WithFallback {
    param([string[]]$Urls, [string]$Destination)
    if (Test-Path $Destination) { return }
    $last = $null
    foreach ($url in $Urls) {
        try {
            Write-Host "[DOWNLOAD] $url" -ForegroundColor Cyan
            Invoke-WebRequest -Uri $url -OutFile $Destination -UseBasicParsing
            return
        }
        catch { $last = $_ }
    }
    throw $last
}

function Fresh-Expand {
    param([string]$Archive, [string]$Destination)
    if (Test-Path $Destination) { Remove-Item $Destination -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $Destination | Out-Null
    Expand-Archive -Path $Archive -DestinationPath $Destination -Force
}

function Copy-FirstMatch {
    param([string]$SearchRoot, [string]$Filter, [string]$Destination)
    $file = Get-ChildItem -Path $SearchRoot -Recurse -File -Filter $Filter | Select-Object -First 1
    if (-not $file) { throw "Khong tim thay $Filter trong $SearchRoot" }
    Copy-Item $file.FullName $Destination -Force
    Write-Host "[OK] $Destination" -ForegroundColor Green
}

Write-Host "=== LS:RP DEPENDENCY SETUP ===" -ForegroundColor Yellow

# MySQL R41-4 x86
if (-not (Test-Path (Join-Path $Plugins "mysql.dll")) -or -not (Test-Path (Join-Path $Includes "a_mysql.inc"))) {
    $zip = Join-Path $Downloads "mysql-R41-4-win32.zip"
    Download-WithFallback @(
        "https://github.com/pBlueG/SA-MP-MySQL/releases/download/R41-4/mysql-R41-4-win32.zip"
    ) $zip
    $dir = Join-Path $Temp "mysql"
    Fresh-Expand $zip $dir
    Copy-FirstMatch $dir "mysql.dll" (Join-Path $Plugins "mysql.dll")
    Copy-FirstMatch $dir "a_mysql.inc" (Join-Path $Includes "a_mysql.inc")
    Copy-FirstMatch $dir "libmariadb.dll" (Join-Path $Root "libmariadb.dll")
    Copy-FirstMatch $dir "log-core.dll" (Join-Path $Root "log-core.dll")
}
else { Write-Host "[OK] MySQL da co." -ForegroundColor Green }

# BCrypt 0.4.1 x86
if (-not (Test-Path (Join-Path $Plugins "samp_bcrypt.dll")) -or -not (Test-Path (Join-Path $Includes "samp_bcrypt.inc"))) {
    $zip = Join-Path $Downloads "samp-bcrypt-windows-x86.zip"
    Download-WithFallback @(
        "https://github.com/Sreyas-Sreelal/samp-bcrypt/releases/download/0.4.1/samp-bcrypt-windows-x86.zip"
    ) $zip
    $dir = Join-Path $Temp "bcrypt"
    Fresh-Expand $zip $dir
    Copy-FirstMatch $dir "samp_bcrypt.dll" (Join-Path $Plugins "samp_bcrypt.dll")
    Copy-FirstMatch $dir "samp_bcrypt.inc" (Join-Path $Includes "samp_bcrypt.inc")
}
else { Write-Host "[OK] BCrypt da co." -ForegroundColor Green }

# YSI 5.10.0006
$YsiHook = Join-Path $Includes "YSI_Coding\y_hooks.inc"
if (-not (Test-Path $YsiHook)) {
    $zip = Join-Path $Downloads "YSI-Includes-v5.10.0006.zip"
    Download-WithFallback @(
        "https://github.com/pawn-lang/YSI-Includes/releases/download/v5.10.0006/YSI-Includes.zip",
        "https://codeload.github.com/pawn-lang/YSI-Includes/zip/refs/tags/v5.10.0006"
    ) $zip
    $dir = Join-Path $Temp "ysi"
    Fresh-Expand $zip $dir

    $coding = Get-ChildItem -Path $dir -Recurse -Directory -Filter "YSI_Coding" | Select-Object -First 1
    if (-not $coding) { throw "Khong tim thay YSI_Coding trong YSI archive." }
    $ysiRoot = $coding.Parent.FullName

    Get-ChildItem -Path $ysiRoot | Where-Object { $_.Name -like "YSI*" } | ForEach-Object {
        Copy-Item $_.FullName $Includes -Recurse -Force
    }
    if (-not (Test-Path $YsiHook)) { throw "YSI da giai nen nhung thieu YSI_Coding\y_hooks.inc" }
    Write-Host "[OK] YSI 5.10.0006" -ForegroundColor Green
}
else { Write-Host "[OK] YSI da co." -ForegroundColor Green }

Write-Host ""
Write-Host "Dependency setup hoan tat." -ForegroundColor Green

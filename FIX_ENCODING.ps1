param(
    [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

$gamemodes = Join-Path $ProjectRoot "gamemodes"
if (!(Test-Path $gamemodes)) {
    throw "Khong tim thay folder gamemodes."
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
$count = 0

Get-ChildItem -Path $gamemodes -Recurse -File -Filter *.pwn | ForEach-Object {
    $text = [System.IO.File]::ReadAllText($_.FullName)
    [System.IO.File]::WriteAllText($_.FullName, $text, $utf8NoBom)
    $count++
}

Write-Host ""
Write-Host "DA XOA UTF-8 BOM CHO $count FILE .pwn" -ForegroundColor Green
Write-Host "Khong thay doi noi dung code."
Write-Host "Bay gio compile lai gamemodes\main.pwn."

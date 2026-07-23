$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$ManifestPath = Join-Path $Root "dependencies.json"
$CacheDir = Join-Path $Root ".deps-cache"
$TempDir = Join-Path $Root ".deps-temp"

function Ensure-Dir([string]$Path) {
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Download-File([string]$Url, [string]$Destination) {
    if (Test-Path $Destination) {
        Write-Host "[CACHE] $(Split-Path $Destination -Leaf)"
        return
    }

    Write-Host "[DOWNLOAD] $Url" -ForegroundColor Cyan
    Invoke-WebRequest `
        -Uri $Url `
        -OutFile $Destination `
        -Headers @{ "User-Agent" = "LSRP-Dependency-Manager" }
}

function Get-ReleaseAsset($Dependency) {
    $Headers = @{
        "User-Agent" = "LSRP-Dependency-Manager"
        "Accept" = "application/vnd.github+json"
    }

    $Api = "https://api.github.com/repos/$($Dependency.repo)/releases/tags/$($Dependency.tag)"
    $Release = Invoke-RestMethod -Uri $Api -Headers $Headers

    foreach ($Pattern in $Dependency.asset_patterns) {
        $Asset = $Release.assets |
            Where-Object { $_.name -match $Pattern } |
            Select-Object -First 1

        if ($Asset) {
            return $Asset
        }
    }

    throw "Khong tim thay asset phu hop cho $($Dependency.name)."
}

function Install-FileCopies($Dependency, [string]$ExtractRoot) {
    foreach ($Copy in $Dependency.copies) {
        $Found = Get-ChildItem `
            -Path $ExtractRoot `
            -Recurse `
            -File `
            -Filter $Copy.find |
            Select-Object -First 1

        if (-not $Found) {
            throw "[$($Dependency.name)] Khong tim thay file: $($Copy.find)"
        }

        $Destination = Join-Path $Root $Copy.to
        $Parent = Split-Path -Parent $Destination
        if ($Parent) {
            Ensure-Dir $Parent
        }

        Copy-Item $Found.FullName $Destination -Force
        Write-Host "[OK] $($Copy.find) -> $($Copy.to)" -ForegroundColor Green
    }
}

function Install-DirectoryPatterns($Dependency, [string]$ExtractRoot) {
    foreach ($Rule in $Dependency.copy_directory_patterns) {
        $DestinationRoot = Join-Path $Root $Rule.to
        Ensure-Dir $DestinationRoot

        $Matches = Get-ChildItem `
            -Path $ExtractRoot `
            -Recurse `
            -Directory |
            Where-Object { $_.Name -like $Rule.pattern }

        # Avoid copying nested duplicates: only use top-most matching dirs.
        $Top = @()
        foreach ($Dir in $Matches) {
            $NestedUnderExisting = $false
            foreach ($Existing in $Top) {
                if ($Dir.FullName.StartsWith($Existing.FullName + "\")) {
                    $NestedUnderExisting = $true
                    break
                }
            }
            if (-not $NestedUnderExisting) {
                $Top += $Dir
            }
        }

        foreach ($Dir in $Top) {
            $Destination = Join-Path $DestinationRoot $Dir.Name
            if (Test-Path $Destination) {
                Remove-Item $Destination -Recurse -Force
            }
            Copy-Item $Dir.FullName $Destination -Recurse -Force
            Write-Host "[OK] $($Dir.Name) -> $($Rule.to)" -ForegroundColor Green
        }
    }
}

if (-not (Test-Path $ManifestPath)) {
    throw "Khong tim thay dependencies.json"
}

Ensure-Dir $CacheDir
Ensure-Dir $TempDir

$Manifest = Get-Content $ManifestPath -Raw | ConvertFrom-Json

foreach ($Dependency in $Manifest.dependencies) {
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Yellow
    Write-Host " $($Dependency.name) - $($Dependency.tag)" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor Yellow

    $SafeName = ($Dependency.name -replace '[^A-Za-z0-9_.-]', '_')
    $ExtractRoot = Join-Path $TempDir $SafeName

    if (Test-Path $ExtractRoot) {
        Remove-Item $ExtractRoot -Recurse -Force
    }
    Ensure-Dir $ExtractRoot

    if ($Dependency.type -eq "github_release") {
        $Asset = Get-ReleaseAsset $Dependency
        $Archive = Join-Path $CacheDir $Asset.name

        Download-File $Asset.browser_download_url $Archive

        if ($Archive.ToLower().EndsWith(".zip")) {
            Expand-Archive $Archive $ExtractRoot -Force
        } else {
            throw "Hien tai manager chi tu giai nen asset .zip."
        }
    }
    elseif ($Dependency.type -eq "github_archive") {
        $ArchiveName = "$SafeName-$($Dependency.tag).zip"
        $Archive = Join-Path $CacheDir $ArchiveName
        $Url = "https://github.com/$($Dependency.repo)/archive/refs/tags/$($Dependency.tag).zip"

        Download-File $Url $Archive
        Expand-Archive $Archive $ExtractRoot -Force
    }
    else {
        throw "Dependency type khong duoc ho tro: $($Dependency.type)"
    }

    if ($Dependency.PSObject.Properties.Name -contains "copies") {
        Install-FileCopies $Dependency $ExtractRoot
    }

    if ($Dependency.PSObject.Properties.Name -contains "copy_directory_patterns") {
        Install-DirectoryPatterns $Dependency $ExtractRoot
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host " TAT CA DEPENDENCY DA DUOC CAI" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Muon them plugin:"
Write-Host "1. Mo dependencies.json"
Write-Host "2. Them mot dependency"
Write-Host "3. Chay INSTALL_DEPS.bat"

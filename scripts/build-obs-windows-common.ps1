# Shared local build for OBS Studio 33.0.1 Windows x64 (CMake preset windows-x64 / VS 2026).
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('RelWithDebInfo', 'Debug')]
    [string] $Configuration,

    [switch] $Reconfigure,
    [switch] $SkipConfigure
)

$ErrorActionPreference = 'Stop'

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$SourceDir = Join-Path $RepoRoot 'obs-studio-33.0.1'
$BuildDir = Join-Path $SourceDir 'build_x64'
$Rundir = Join-Path $BuildDir 'rundir'
$CMakeLists = Join-Path $SourceDir 'CMakeLists.txt'
$CMakePresets = Join-Path $SourceDir 'CMakePresets.json'

function Test-CMakeVersion {
    $cmake = Get-Command cmake -ErrorAction SilentlyContinue
    if (-not $cmake) {
        throw 'cmake not found on PATH. Install CMake 3.28+ and add it to PATH.'
    }
    $versionLine = & cmake --version | Select-Object -First 1
    if ($versionLine -match 'cmake version (\d+)\.(\d+)') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        if ($major -lt 3 -or ($major -eq 3 -and $minor -lt 28)) {
            throw "CMake 3.28+ required; found: $versionLine"
        }
    }
    Write-Host "Using $versionLine"
}

function Test-ObsSourceReady {
    if (-not (Test-Path $CMakeLists)) {
        throw "Missing $CMakeLists"
    }
    if (-not (Test-Path $CMakePresets)) {
        throw "Missing $CMakePresets"
    }

    $submoduleProbes = @(
        (Join-Path $SourceDir 'plugins\obs-browser'),
        (Join-Path $SourceDir 'plugins\obs-websocket')
    )
    $missing = @($submoduleProbes | Where-Object { -not (Test-Path $_) })
    if ($missing.Count -gt 0) {
        throw @(
            'Git submodules appear missing (typical for GitHub zip source).'
            'From an obs-studio git clone at tag 33.0.1, run:'
            '  git submodule update --init --recursive'
            "Missing: $($missing -join ', ')"
        ) -join "`n"
    }
}

function Invoke-CMakeConfigure {
    $cacheFile = Join-Path $BuildDir 'CMakeCache.txt'
    if ((Test-Path $cacheFile) -and -not $Reconfigure) {
        Write-Host "CMake cache exists at $BuildDir (use -Reconfigure to regenerate)."
        return
    }

    Write-Host 'Configuring with cmake --preset windows-x64 (downloads .deps on first run)...'
    Push-Location $SourceDir
    try {
        & cmake --preset windows-x64
        if ($LASTEXITCODE -ne 0) {
            throw @(
                'cmake --preset windows-x64 failed.'
                'Ensure Visual Studio 2026 is installed (generator: Visual Studio 18 2026).'
                'See docs-analysis/07-Windows编译指南.md for troubleshooting.'
            ) -join ' '
        }
    } finally {
        Pop-Location
    }
}

function Invoke-CMakeBuild {
    if (-not (Test-Path $BuildDir)) {
        throw "Build directory not found: $BuildDir. Run without -SkipConfigure first."
    }

    Write-Host "Building configuration: $Configuration"
    & cmake --build $BuildDir --config $Configuration --parallel
    if ($LASTEXITCODE -ne 0) {
        throw "cmake --build failed with exit code $LASTEXITCODE"
    }
}

function Write-ObsBuildHints {
    Write-Host ''
    Write-Host 'Build finished successfully.'
    Write-Host "  Source:     $SourceDir"
    Write-Host "  Build tree: $BuildDir"
    Write-Host "  Rundir:     $Rundir"
    Write-Host "  Config:     $Configuration"

    $exeCandidates = Get-ChildItem -Path $BuildDir -Filter obs64.exe -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match [regex]::Escape($Configuration) } |
        Select-Object -First 3 -ExpandProperty FullName

    if ($exeCandidates) {
        Write-Host '  obs64.exe candidates:'
        foreach ($p in $exeCandidates) {
            Write-Host "    $p"
        }
    } else {
        Write-Host '  Search obs64.exe under build_x64 if rundir is not populated yet.'
    }
}

Test-CMakeVersion
Test-ObsSourceReady

if (-not $SkipConfigure) {
    Invoke-CMakeConfigure
} else {
    Write-Host 'Skipping configure (-SkipConfigure).'
}

Invoke-CMakeBuild
Write-ObsBuildHints
# Copies version-controlled launch.vs.json into obs-studio-33.0.1/.vs/ for Visual Studio 2022.
# Replaces __REPO_ROOT__ with this clone's absolute path (forward slashes).
param(
    [string]$Template = "launch.vs.json"
)

$ErrorActionPreference = "Stop"
$runtimeDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $runtimeDir "..")).Path
$studioDir = Join-Path $repoRoot "obs-studio-33.0.1"
$vsDir = Join-Path $studioDir ".vs"
$dest = Join-Path $vsDir "launch.vs.json"
$src = Join-Path $runtimeDir $Template

if (-not (Test-Path $src)) {
    throw "Missing template: $src"
}
if (-not (Test-Path $studioDir)) {
    throw "obs-studio-33.0.1 not found at $studioDir"
}

$repoRootForJson = ($repoRoot -replace '\\', '/')
$content = Get-Content $src -Raw -Encoding UTF8
$content = $content.Replace('__REPO_ROOT__', $repoRootForJson)

New-Item -ItemType Directory -Force -Path $vsDir | Out-Null
[System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Wrote $dest"
Write-Host "Open folder in VS: $studioDir"
Write-Host "Restart Visual Studio if it is already open, then pick startup item: OBS 33.0.1 官方二进制 (GitHub PDB)"
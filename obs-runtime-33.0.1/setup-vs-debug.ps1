# Copies version-controlled launch.vs.json into obs-studio-33.0.1/.vs/ for Visual Studio.
# Rewrites the template repo root (E:/code/AI/Obs-Study) to this clone's directory.
param(
    [string]$TemplateRoot = "E:/code/AI/Obs-Study"
)

$ErrorActionPreference = "Stop"
$runtimeDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $runtimeDir "..")).Path
$studioDir = Join-Path $repoRoot "obs-studio-33.0.1"
$vsDir = Join-Path $studioDir ".vs"
$dest = Join-Path $vsDir "launch.vs.json"
$src = Join-Path $runtimeDir "launch.vs.json"

if (-not (Test-Path $src)) {
    throw "Missing template: $src"
}
if (-not (Test-Path $studioDir)) {
    throw "obs-studio-33.0.1 not found at $studioDir"
}

$repoRootForJson = ($repoRoot -replace '\\', '/')
$content = Get-Content $src -Raw -Encoding UTF8
$content = $content.Replace($TemplateRoot, $repoRootForJson)

New-Item -ItemType Directory -Force -Path $vsDir | Out-Null
[System.IO.File]::WriteAllText($dest, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Wrote $dest"
Write-Host "Open folder in VS: $studioDir"
# Copies version-controlled launch template into obs-studio-33.0.1/.vs/launch.vs.json for Visual Studio.
# Rewrites template repo root paths to this clone's directory.
param(
    [string]$Template = "launch.vs.json",
    [string]$TemplateRoot = ""
)

$ErrorActionPreference = "Stop"
$runtimeDir = $PSScriptRoot
$repoRoot = (Resolve-Path (Join-Path $runtimeDir "..")).Path
$studioDir = Join-Path $repoRoot "obs-studio-33.0.1"
$vsDir = Join-Path $studioDir ".vs"
$dest = Join-Path $vsDir "launch.vs.json"
$src = Join-Path $runtimeDir $Template

if (-not $TemplateRoot) {
    if ($Template -eq "launch.vs2026.json") {
        $TemplateRoot = "E:/code/obs/obs-AI"
    } else {
        $TemplateRoot = "E:/code/AI/Obs-Study"
    }
}

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

Write-Host "Wrote $dest (from $Template)"
Write-Host "Open folder in VS: $studioDir"
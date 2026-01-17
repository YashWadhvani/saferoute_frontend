# Script: fix_pub_cache_on_windows.ps1
# Purpose: Create a project-local pub cache on the same drive as the project (useful when project and global pub cache are on different drives)
# Usage: Run from PowerShell (Run as normal user). This will set PUB_CACHE for this session and run flutter pub get.

param(
    [string]$ProjectRoot = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)\..",
    [switch]$Repair
)

# Resolve absolute project root
$projectRoot = (Get-Item (Resolve-Path $ProjectRoot)).FullName
$projectLocalCache = Join-Path $projectRoot '.pub-cache'

Write-Host "Project root: $projectRoot"
Write-Host "Project-local pub cache: $projectLocalCache"

# Ensure directory exists
if (-not (Test-Path $projectLocalCache)) {
    New-Item -ItemType Directory -Path $projectLocalCache | Out-Null
}

# Set environment variable for this session
$env:PUB_CACHE = $projectLocalCache
Write-Host "PUB_CACHE set to: $env:PUB_CACHE"

# Remove stale build copy for flutter_plugin_android_lifecycle if present (common cause of cross-drive path issues)
$stalePluginDir = Join-Path $projectRoot 'build\flutter_plugin_android_lifecycle'
if (Test-Path $stalePluginDir) {
    Write-Host "Removing stale build/plugin dir: $stalePluginDir"
    Remove-Item -Recurse -Force $stalePluginDir
}

# Optionally repair global cache (slower) or run pub get to re-populate project-local cache
if ($Repair) {
    Write-Host "Running 'flutter pub cache repair' (may take a while)..."
    flutter pub cache repair
} else {
    Write-Host "Running 'flutter pub get' to populate project-local pub cache..."
    Push-Location $projectRoot
    flutter pub get
    Pop-Location
}

Write-Host "Done. Note: This script only sets PUB_CACHE for this PowerShell session."
Write-Host "To make the project-local pub cache permanent for your user/IDE, set the environment variable PUB_CACHE to $projectLocalCache in your Windows Environment Variables."
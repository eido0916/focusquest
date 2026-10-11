param([string]$Flutter = 'C:\src\flutter\bin\flutter.bat', [string]$PartyServerUrl = '', [string]$OutputName = 'FocusQuest-debug.apk')
$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqSource = Join-Path $fqRoot 'mobile'
# Flutter 3.24 Windows shader compiler can crash on non-ASCII paths.
# Build an isolated copy; never move or delete the working source tree.
$fqBuildRoot = Join-Path $env:LOCALAPPDATA 'FocusQuestTools\build'
$fqStage = Join-Path $fqBuildRoot ('fq-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $fqStage -Force | Out-Null
# Android-only staging avoids desktop plugin symlinks on Windows.
& robocopy $fqSource $fqStage /E /XD build .dart_tool .gradle windows linux macos /XF local.properties /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw "Source copy failed: $LASTEXITCODE" }
Push-Location $fqStage
try {
    & $Flutter pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
    $fqBuildArgs = @('build', 'apk', '--debug', '--target-platform', 'android-arm64', '--no-pub')
    if ($PartyServerUrl) { $fqBuildArgs += "--dart-define=PARTY_SERVER_URL=$PartyServerUrl" }
    & $Flutter @fqBuildArgs
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed' }
    $fqOutput = Join-Path $fqRoot 'output\android'
    New-Item -ItemType Directory -Path $fqOutput -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $fqStage 'build\app\outputs\flutter-apk\app-debug.apk') -Destination (Join-Path $fqOutput $OutputName) -Force
    Write-Output "APK: $fqOutput\$OutputName"
    Write-Output "Build workspace retained: $fqStage"
} finally { Pop-Location }

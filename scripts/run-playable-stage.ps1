param([switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo 'mobile'
$stageDirectory = Join-Path $env:USERPROFILE 'FocusQuestTools\stage-build'
$flutter = Join-Path $env:USERPROFILE 'FocusQuestTools\flutter\bin\flutter.bat'
if (-not (Test-Path -LiteralPath $flutter)) { throw 'Flutter SDK was not found.' }
New-Item -ItemType Directory -Force -Path $stageDirectory | Out-Null
& robocopy $source $stageDirectory /E /NFL /NDL /NJH /NJS /XD build .dart_tool ephemeral .gradle /XF local.properties .flutter-plugins .flutter-plugins-dependencies | Out-Null
if ($LASTEXITCODE -gt 7) { throw 'Failed to copy the project.' }
Push-Location $stageDirectory
try {
    # NTFS junctions support plugin directories without requiring Developer Mode.
    & $flutter pub get
    if (-not (Test-Path .flutter-plugins-dependencies)) { throw 'Failed to resolve dependencies.' }
    $dependencies = Get-Content .flutter-plugins-dependencies -Raw | ConvertFrom-Json
    $links = 'windows\flutter\ephemeral\.plugin_symlinks'
    New-Item -ItemType Directory -Force -Path $links | Out-Null
    foreach ($plugin in $dependencies.plugins.windows) {
        $link = Join-Path $links $plugin.name
        if (-not (Test-Path -LiteralPath $link)) {
            New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null
        }
    }
    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw 'Failed to configure dependencies.' }
    & $flutter build windows --release --no-pub -t lib/main_playable_stage.dart
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
    if (-not $BuildOnly) {
        $release = Join-Path $stageDirectory 'build\windows\x64\runner\Release'
        Start-Process -FilePath (Join-Path $release 'focusquest.exe') -WorkingDirectory $release -WindowStyle Hidden
    }
} finally { Pop-Location }

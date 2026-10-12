param([switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo 'mobile'
$demoBuildDirectory = Join-Path $env:USERPROFILE 'FocusQuestTools\character-demo-v016'
$flutter = Join-Path $env:USERPROFILE 'FocusQuestTools\flutter\bin\flutter.bat'
New-Item -ItemType Directory -Force -Path $demoBuildDirectory | Out-Null
& robocopy $source $demoBuildDirectory /E /NFL /NDL /NJH /NJS /XD build .dart_tool ephemeral .gradle /XF local.properties .flutter-plugins .flutter-plugins-dependencies | Out-Null
if ($LASTEXITCODE -gt 7) { throw 'Failed to copy demo source.' }
Push-Location $demoBuildDirectory
try {
    & $flutter pub get
    if (-not (Test-Path .flutter-plugins-dependencies)) { throw 'Dependency resolution failed.' }
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
    if ($LASTEXITCODE -ne 0) { throw 'Dependency configuration failed.' }
    & $flutter build windows --release --no-pub -t lib/main_playable_stage.dart --dart-define=DEMO_CHARACTER_SELECTION=true
    if ($LASTEXITCODE -ne 0) { throw 'Windows demo build failed.' }
    if (-not $BuildOnly) {
        $release = Join-Path $demoBuildDirectory 'build\windows\x64\runner\Release'
        Start-Process -FilePath (Join-Path $release 'focusquest.exe') -WorkingDirectory $release -WindowStyle Normal
    }
} finally { Pop-Location }

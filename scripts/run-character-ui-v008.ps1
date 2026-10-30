param([switch]$BuildOnly)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$source = Join-Path $repo 'mobile'
$stageDirectory = Join-Path $env:USERPROFILE 'FocusQuestTools\character-ui-v008'
$flutter = 'C:\flutter\bin\flutter.bat'
New-Item -ItemType Directory -Force -Path $stageDirectory | Out-Null
& robocopy $source $stageDirectory /E /NFL /NDL /NJH /NJS /XD assets build .dart_tool ephemeral .gradle /XF local.properties .flutter-plugins .flutter-plugins-dependencies | Out-Null
if ($LASTEXITCODE -gt 7) { throw 'Project copy failed.' }
if (-not (Test-Path -LiteralPath (Join-Path $stageDirectory 'assets'))) {
    New-Item -ItemType Junction -Path (Join-Path $stageDirectory 'assets') -Target (Join-Path $source 'assets') | Out-Null
}
Push-Location $stageDirectory
try {
    & $flutter pub get --offline
    $dependencies = Get-Content .flutter-plugins-dependencies -Raw | ConvertFrom-Json
    $links = 'windows\flutter\ephemeral\.plugin_symlinks'
    New-Item -ItemType Directory -Force -Path $links | Out-Null
    foreach ($plugin in $dependencies.plugins.windows) {
        $link = Join-Path $links $plugin.name
        if (-not (Test-Path -LiteralPath $link)) {
            New-Item -ItemType Junction -Path $link -Target $plugin.path | Out-Null
        }
    }
    & $flutter pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    # Release executable must be closed before the linker writes the update.
    Get-Process focusquest -ErrorAction SilentlyContinue | Where-Object {
        $_.Path -eq (Join-Path $stageDirectory 'build\windows\x64\runner\Release\focusquest.exe')
    } | Stop-Process
    & $flutter build windows --release --no-pub -t lib/main.dart
    if ($LASTEXITCODE -ne 0) { throw 'Windows build failed.' }
    if (-not $BuildOnly) {
        $release = Join-Path $stageDirectory 'build\windows\x64\runner\Release'
        Start-Process -FilePath (Join-Path $release 'focusquest.exe') -WorkingDirectory $release -WindowStyle Normal
    }
} finally { Pop-Location }

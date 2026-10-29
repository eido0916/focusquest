$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqWorkspace = Join-Path $env:LOCALAPPDATA ('FocusQuestTools/build/party-lobby-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$fqStage = Join-Path $fqWorkspace 'mobile'
New-Item -ItemType Directory -Force -Path $fqStage | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $fqWorkspace 'server') | Out-Null
Copy-Item -LiteralPath (Join-Path $fqRoot 'server/party_server.dart') -Destination (Join-Path $fqWorkspace 'server/party_server.dart')
foreach ($fqFolder in @('lib', 'test')) {
    & robocopy (Join-Path $fqRoot "mobile/$fqFolder") (Join-Path $fqStage $fqFolder) /E /R:0 /W:0 /NFL /NDL /NJH /NJS /NP
    if ($LASTEXITCODE -ge 8) { throw "Copy failed: $fqFolder" }
}
foreach ($fqFile in @('pubspec.yaml', 'pubspec.lock', 'analysis_options.yaml')) {
    Copy-Item -LiteralPath (Join-Path $fqRoot "mobile/$fqFile") -Destination (Join-Path $fqStage $fqFile)
}
# Read original assets through a junction instead of copying the large library.
New-Item -ItemType Junction -Path (Join-Path $fqStage 'assets') -Target (Join-Path $fqRoot 'mobile/assets') | Out-Null
Push-Location $fqStage
try {
    & C:/src/flutter/bin/flutter.bat pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
    & C:/src/flutter/bin/flutter.bat analyze --no-pub lib/features/party/presentation/party_page.dart lib/features/party/presentation/party_lobby_art.dart test/party_lobby_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Analysis failed' }
    & C:/src/flutter/bin/flutter.bat test --no-pub --concurrency=1 --dart-define=CAPTURE_LOBBY=true test/party_lobby_test.dart test/party_online_test.dart
    if ($LASTEXITCODE -ne 0) { throw 'Lobby tests failed' }
    & C:/src/flutter/bin/flutter.bat test --no-pub test/party_ui_test.dart --plain-name 'focus screen opens code party lobby on narrow phone'
    if ($LASTEXITCODE -ne 0) { throw 'Navigation test failed' }
    Get-ChildItem -LiteralPath (Join-Path $fqWorkspace 'output/party-lobby') -Filter '*.png' | Copy-Item -Destination (Join-Path $fqRoot 'art/party_lobby_v001/previews') -Force
    Write-Output "Validation workspace: $fqStage"
} finally { Pop-Location }

$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqWorkspace = Join-Path $env:LOCALAPPDATA ('FocusQuestTools/build/party-ui-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$fqStage = Join-Path $fqWorkspace 'mobile'
New-Item -ItemType Directory -Force -Path (Join-Path $fqWorkspace 'server') | Out-Null
Copy-Item -LiteralPath (Join-Path $fqRoot 'server/party_server.dart') -Destination (Join-Path $fqWorkspace 'server/party_server.dart')
New-Item -ItemType Directory -Force -Path $fqStage | Out-Null
& robocopy (Join-Path $fqRoot 'mobile') $fqStage /E /XD build .dart_tool .gradle windows linux macos /XF local.properties /NFL /NDL /NJH /NJS /NP
if ($LASTEXITCODE -ge 8) { throw 'Source copy failed' }
Write-Output "Validation workspace: $fqStage"
Push-Location $fqStage
try {
  & C:/src/flutter/bin/flutter.bat pub get --offline
  if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed' }
  & C:/src/flutter/bin/flutter.bat test --no-pub --concurrency=1 --dart-define=CAPTURE_PARTY=true test/party_ui_test.dart test/party_online_test.dart test/party_battle_page_test.dart
  if ($LASTEXITCODE -ne 0) { throw 'Party validation failed' }
  $fqCapture = Join-Path (Split-Path -Parent $fqStage) 'output/party'
  $fqPreview = Join-Path $fqRoot 'art/party_focus_v001/previews'
  Copy-Item -LiteralPath (Join-Path $fqCapture 'party-4-ghost-ship.png') -Destination (Join-Path $fqPreview 'ghost-ship-4.png') -Force
  Copy-Item -LiteralPath (Join-Path $fqCapture 'party-2-ghost-ship.png') -Destination (Join-Path $fqPreview 'ghost-ship-2.png') -Force
  Copy-Item -LiteralPath (Join-Path $fqCapture 'party-4-skill-ghost-ship.png') -Destination (Join-Path $fqPreview 'ghost-ship-4-skill.png') -Force
  Copy-Item -LiteralPath (Join-Path $fqCapture 'party-4.png') -Destination (Join-Path $fqPreview 'grassland-4.png') -Force
  Copy-Item -LiteralPath (Join-Path $fqCapture 'party-complete-page.png') -Destination (Join-Path $fqPreview 'complete-page.png') -Force
} finally { Pop-Location }

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = Join-Path $repoRoot 'mobile'
$stageRoot = Join-Path $env:TEMP 'focusquest-display-v001'
$reportRoot = Join-Path $repoRoot 'art/display_layout_v001'
New-Item -ItemType Directory -Force -Path $stageRoot,$reportRoot | Out-Null
foreach ($part in @('lib','test','.dart_tool')) {
  & robocopy (Join-Path $sourceRoot $part) (Join-Path $stageRoot $part) /E /NFL /NDL /NJH /NJS /XD flutter_build | Out-Null
  if ($LASTEXITCODE -gt 7) { throw "Failed to stage $part" }
}
Copy-Item -LiteralPath (Join-Path $sourceRoot 'pubspec.lock'),(Join-Path $sourceRoot 'analysis_options.yaml') -Destination $stageRoot
$yaml = Get-Content -LiteralPath (Join-Path $sourceRoot 'pubspec.yaml') | Where-Object {
  $_ -notmatch '^    - assets/' -or $_ -match '^    - assets/(fonts/|images/(home_|character_|adventure_map_|settings_|focus_selection_v001/|focus_timer_v001/|lobby/|role_logos/|certificates|ui/))'
}
[IO.File]::WriteAllLines((Join-Path $stageRoot 'pubspec.yaml'),$yaml,[Text.UTF8Encoding]::new($false))
if (-not (Test-Path -LiteralPath (Join-Path $stageRoot 'assets'))) {
  New-Item -ItemType Junction -Path (Join-Path $stageRoot 'assets') -Target (Join-Path $sourceRoot 'assets') | Out-Null
}
Push-Location $stageRoot
try {
  & C:/flutter/bin/flutter.bat test --no-pub --concurrency=1 --reporter expanded --dart-define=CAPTURE_DISPLAY=true "--dart-define=DISPLAY_CAPTURE_DIRECTORY=$reportRoot/previews" test/quest_display_test.dart test/home_focus_reference_test.dart 2>&1 | Tee-Object -FilePath (Join-Path $reportRoot 'validation-tests.log')
  if ($LASTEXITCODE -ne 0) { throw 'Display validation failed.' }
} finally { Pop-Location }

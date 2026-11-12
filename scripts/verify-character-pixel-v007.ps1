param([switch]$PrepareOnly)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$mobileRoot = Join-Path $repoRoot 'mobile'
$qaRoot = Join-Path $env:TEMP 'focusquest-character-pixel-v007'
$reportRoot = Join-Path $repoRoot 'art/character_pixel_v007'
New-Item -ItemType Directory -Force -Path $qaRoot | Out-Null
foreach ($part in @('lib', 'test', '.dart_tool')) {
    & robocopy (Join-Path $mobileRoot $part) (Join-Path $qaRoot $part) /E /NFL /NDL /NJH /NJS /XD flutter_build | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Could not stage $part" }
}
Copy-Item -LiteralPath (Join-Path $mobileRoot 'pubspec.lock'), (Join-Path $mobileRoot 'analysis_options.yaml') -Destination $qaRoot
# UI-only tests do not need to rebundle the thousands of battle motion frames.
$yamlLines = Get-Content -LiteralPath (Join-Path $mobileRoot 'pubspec.yaml')
$qaYaml = $yamlLines | Where-Object {
    $_ -notmatch '^    - assets/' -or
    $_ -match '^    - assets/(fonts/|images/(character_|focus_selection_v001/|certificates|lobby/|role_logos/|home_|ui/))'
}
[IO.File]::WriteAllLines((Join-Path $qaRoot 'pubspec.yaml'), $qaYaml, [Text.UTF8Encoding]::new($false))
if (-not (Test-Path -LiteralPath (Join-Path $qaRoot 'assets'))) {
    New-Item -ItemType Junction -Path (Join-Path $qaRoot 'assets') -Target (Join-Path $mobileRoot 'assets') | Out-Null
}
if ($PrepareOnly) { Write-Output $qaRoot; exit 0 }
$previewRoot = Join-Path $reportRoot 'previews'
New-Item -ItemType Directory -Force -Path $previewRoot | Out-Null
Push-Location $qaRoot
try {
    & C:/flutter/bin/flutter.bat test --no-pub --concurrency=1 --reporter expanded --dart-define=CAPTURE_LOBBY=true "--dart-define=LOBBY_CAPTURE_DIRECTORY=$previewRoot" test/character_pixel_assets_test.dart test/character_lobby_test.dart test/character_titles_test.dart test/role_lobby_mapping_test.dart 2>&1 | Tee-Object -FilePath (Join-Path $reportRoot 'validation-tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Character pixel UI tests failed.' }
} finally { Pop-Location }

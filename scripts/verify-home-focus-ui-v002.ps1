param([string]$NameFilter = '')
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
$sourceRoot = Join-Path $repoRoot 'mobile'
$stageRoot = Join-Path $env:TEMP 'focusquest-home-focus-ui-v002'
$artRoot = Join-Path $repoRoot 'art/home_focus_ui_v002'
New-Item -ItemType Directory -Force -Path $stageRoot | Out-Null
foreach ($part in @('lib','test','.dart_tool')) {
    & robocopy (Join-Path $sourceRoot $part) (Join-Path $stageRoot $part) /E /NFL /NDL /NJH /NJS /XD flutter_build | Out-Null
    if ($LASTEXITCODE -gt 7) { throw "Failed to stage $part" }
}
Copy-Item -LiteralPath (Join-Path $sourceRoot 'pubspec.lock'),(Join-Path $sourceRoot 'analysis_options.yaml') -Destination $stageRoot
$yaml = Get-Content -LiteralPath (Join-Path $sourceRoot 'pubspec.yaml') | Where-Object {
    $_ -notmatch '^    - assets/' -or $_ -match '^    - assets/(fonts/|images/(home_|character_|adventure_map_|focus_selection_v001/|focus_timer_v001/|lobby/|role_logos/|certificates|ui/))'
}
[IO.File]::WriteAllLines((Join-Path $stageRoot 'pubspec.yaml'),$yaml,[Text.UTF8Encoding]::new($false))
if (-not (Test-Path -LiteralPath (Join-Path $stageRoot 'assets'))) {
    New-Item -ItemType Junction -Path (Join-Path $stageRoot 'assets') -Target (Join-Path $sourceRoot 'assets') | Out-Null
}
Push-Location $stageRoot
try {
    $testArgs = @('test','--no-pub','--concurrency=1','--reporter','expanded','--dart-define=CAPTURE_REFERENCE=true',"--dart-define=REFERENCE_CAPTURE_DIRECTORY=$artRoot/previews",'test/home_focus_reference_test.dart')
    if ($NameFilter) { $testArgs += @('--name',$NameFilter) }
    & C:/flutter/bin/flutter.bat @testArgs 2>&1 | Tee-Object -FilePath (Join-Path $artRoot 'validation-tests.log')
    if ($LASTEXITCODE -ne 0) { throw 'Home/focus UI validation failed' }
} finally { Pop-Location }

param([string]$Stage = 'C:/Users/eido0/AppData/Local/FocusQuestTools/build/fq-20261012-143347')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskStage = [IO.Path]::GetFullPath($Stage)
if (-not (Test-Path -LiteralPath "$taskStage/pubspec.yaml")) { throw 'The previously verified Android build workspace was not found.' }
$taskBusy = Get-CimInstance Win32_Process -Filter "name = 'java.exe'" | Where-Object { $_.CommandLine -and $_.CommandLine.Replace('\','/').Contains($taskStage.Replace('\','/')) }
if ($taskBusy) { throw 'This isolated workspace is currently building. Retry after its build completes.' }
# Reuse the preceding verified character APK snapshot and its build cache.
# Copy only the character UI refinement; preserve workspace and previous APKs.
foreach ($taskFile in @('lib/features/character/presentation/character_screen.dart','lib/features/character/presentation/character_art.dart','lib/core/widgets/quest_widgets.dart')) {
    Copy-Item -LiteralPath "$taskRoot/mobile/$taskFile" -Destination "$taskStage/$taskFile"
}
New-Item -ItemType Directory -Force "$taskStage/assets/images/character_ui_v004" | Out-Null
Copy-Item "$taskRoot/mobile/assets/images/character_ui_v004/*.png" -Destination "$taskStage/assets/images/character_ui_v004"
$taskPub = "$taskStage/pubspec.yaml"
$taskText = [IO.File]::ReadAllText($taskPub).Replace('    - assets/images/character_ui_v003/', '    - assets/images/character_ui_v004/')
[IO.File]::WriteAllText($taskPub,$taskText)
Push-Location $taskStage
try {
    & C:/src/flutter/bin/flutter.bat pub get --offline
    if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
    & C:/src/flutter/bin/flutter.bat build apk --debug --target-platform android-arm64 --no-pub
    if ($LASTEXITCODE -ne 0) { throw 'Android build failed.' }
    $taskOutput = "$taskRoot/output/android/FocusQuest-character-ui-v004-debug.apk"
    Copy-Item -LiteralPath "$taskStage/build/app/outputs/flutter-apk/app-debug.apk" -Destination $taskOutput
    Write-Output "APK: $taskOutput"
} finally { Pop-Location }

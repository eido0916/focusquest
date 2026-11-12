param([string]$DeviceId = '', [switch]$Build)
$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqAdbCommand = Get-Command adb -ErrorAction SilentlyContinue
$fqAdb = if ($fqAdbCommand) { $fqAdbCommand.Source } else { Join-Path $env:USERPROFILE 'FocusQuestTools\android-sdk\platform-tools\adb.exe' }
if (-not (Test-Path -LiteralPath $fqAdb)) { throw 'ADB not found. Add Android SDK platform-tools to PATH.' }
$fqDevices = @(& $fqAdb devices -l)
if ($LASTEXITCODE -ne 0) { throw 'Cannot connect to ADB. Check the Android SDK and USB connection.' }
$fqDevices | Write-Output
$fqReady = @($fqDevices | Where-Object { $_ -match '^\S+\s+device\b' } | ForEach-Object { ($_ -split '\s+')[0] })
if (-not $DeviceId) {
    if ($fqReady.Count -eq 0) { throw 'No authorized Android device. Connect the phone by USB, enable USB debugging, unlock it, and accept Allow USB debugging on the phone.' }
    if ($fqReady.Count -gt 1) { throw 'Multiple devices connected. Specify -DeviceId from the list above.' }
    $DeviceId = $fqReady[0]
}
if ($fqReady -notcontains $DeviceId) { throw 'Selected device is offline or unauthorized. Unlock the phone and allow USB debugging.' }
$fqApk = Join-Path $fqRoot 'output\android\FocusQuest-debug.apk'
if ($Build -or -not (Test-Path -LiteralPath $fqApk)) {
    & (Join-Path $PSScriptRoot 'build-android.ps1')
}
if (-not (Test-Path -LiteralPath $fqApk)) { throw 'APK build did not produce FocusQuest-debug.apk.' }
& $fqAdb -s $DeviceId install -r $fqApk
if ($LASTEXITCODE -ne 0) { throw 'Installation failed. Check the phone for an install confirmation. Existing app data has not been erased.' }
& $fqAdb -s $DeviceId shell am start -W -n dev.focusquest.focusquest/.MainActivity
if ($LASTEXITCODE -ne 0) { throw 'Android could not start FocusQuest.' }
& $fqAdb -s $DeviceId shell pidof dev.focusquest.focusquest
if ($LASTEXITCODE -ne 0) { throw 'FocusQuest exited after launch. Inspect adb logcat for the cause.' }
Write-Output 'FocusQuest is running. USB may now be disconnected.'

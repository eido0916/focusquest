param([string]$ApkName = 'FocusQuest-character-ui-v003-debug.apk', [string]$AssetVersion = 'character_ui_v003')
$ErrorActionPreference = 'Stop'
$taskRoot = Split-Path $PSScriptRoot -Parent
$taskApk = Join-Path $taskRoot "output/android/$ApkName"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$taskArchive = [IO.Compression.ZipFile]::OpenRead($taskApk)
$taskChecks = @()
try {
    foreach ($taskFile in Get-ChildItem "$taskRoot/mobile/assets/images/$AssetVersion/*.png") {
        $taskEntry = $taskArchive.GetEntry("assets/flutter_assets/assets/images/$AssetVersion/$($taskFile.Name)")
        if ($null -eq $taskEntry) { throw "APK asset missing: $($taskFile.Name)" }
        $taskStream = $taskEntry.Open()
        $taskSha = [Security.Cryptography.SHA256]::Create()
        try { $taskHash = [BitConverter]::ToString($taskSha.ComputeHash($taskStream)).Replace('-', '') }
        finally { $taskStream.Dispose(); $taskSha.Dispose() }
        $taskExpected = (Get-FileHash -LiteralPath $taskFile.FullName -Algorithm SHA256).Hash
        if ($taskHash -ne $taskExpected) { throw "APK asset differs: $($taskFile.Name)" }
        $taskChecks += @{asset=$taskFile.Name; sha256=$taskHash; matches=$true}
    }
    if (-not $taskArchive.GetEntry('lib/arm64-v8a/libflutter.so')) { throw 'ARM64 Flutter runtime missing' }
} finally { $taskArchive.Dispose() }
$taskReport = @{
    apk=$ApkName
    bytes=(Get-Item -LiteralPath $taskApk).Length
    sha256=(Get-FileHash -LiteralPath $taskApk -Algorithm SHA256).Hash
    verified_assets=$taskChecks.Count
    assets=$taskChecks
}
$taskReport | ConvertTo-Json -Depth 5 | Set-Content "$taskRoot/art/$AssetVersion/android-verification.json" -Encoding utf8
Write-Output "Verified $($taskChecks.Count) APK assets against the workspace originals."
Write-Output "APK SHA256: $($taskReport.sha256)"

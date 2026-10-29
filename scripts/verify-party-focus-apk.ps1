param([string]$ApkName = 'FocusQuest-party-focus-v001-debug.apk')
$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqApk = Join-Path $fqRoot "output/android/$ApkName"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fqArchive = [IO.Compression.ZipFile]::OpenRead($fqApk)
$fqChecks = @()
$fqDirs = @('party_focus_v001', 'focus_selection_v001/avatars/male', 'focus_selection_v001/avatars/female', 'role_logos')
$fqImageRoot = (Join-Path $fqRoot 'mobile/assets/images').TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
$fqFiles = @()
foreach ($fqDir in $fqDirs) {
  $fqFiles += Get-ChildItem -LiteralPath (Join-Path $fqRoot "mobile/assets/images/$fqDir") -Filter '*.png'
}
$fqFiles += Get-Item -LiteralPath (Join-Path $fqRoot 'mobile/assets/images/stage_backgrounds/ghost_ship_focus_v002.png')
$fqFiles += Get-Item -LiteralPath (Join-Path $fqRoot 'mobile/assets/images/ui/forest_meadow_pixel_v001.png')
try {
  foreach ($fqFile in $fqFiles) {
    $fqRelative = $fqFile.FullName.Substring($fqImageRoot.Length).Replace('\', '/')
    $fqEntry = $fqArchive.GetEntry("assets/flutter_assets/assets/images/$fqRelative")
    if ($null -eq $fqEntry) { throw "APK asset missing: $fqRelative" }
    $fqStream = $fqEntry.Open()
    $fqSha = [Security.Cryptography.SHA256]::Create()
    try { $fqHash = [BitConverter]::ToString($fqSha.ComputeHash($fqStream)).Replace('-', '') }
    finally { $fqStream.Dispose(); $fqSha.Dispose() }
    $fqExpected = (Get-FileHash -LiteralPath $fqFile.FullName -Algorithm SHA256).Hash
    if ($fqHash -ne $fqExpected) { throw "APK asset differs: $fqRelative" }
    $fqChecks += @{asset=$fqRelative; sha256=$fqHash; matches=$true}
  }
  if (-not $fqArchive.GetEntry('lib/arm64-v8a/libflutter.so')) { throw 'ARM64 Flutter runtime missing' }
} finally { $fqArchive.Dispose() }
$fqReport = @{
  apk=$ApkName
  bytes=(Get-Item -LiteralPath $fqApk).Length
  sha256=(Get-FileHash -LiteralPath $fqApk -Algorithm SHA256).Hash
  verified_assets=$fqChecks.Count
  assets=$fqChecks
}
$fqReport | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $fqRoot 'art/party_focus_v001/android-verification.json') -Encoding utf8
Write-Output "Verified $($fqChecks.Count) APK assets against the workspace originals."
Write-Output "APK SHA256: $($fqReport.sha256)"

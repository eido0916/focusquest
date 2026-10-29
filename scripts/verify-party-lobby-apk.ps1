param([string]$ApkName = 'FocusQuest-party-lobby-v001-debug.apk')
$ErrorActionPreference = 'Stop'
$fqRoot = Split-Path -Parent $PSScriptRoot
$fqApk = Join-Path $fqRoot "output/android/$ApkName"
Add-Type -AssemblyName System.IO.Compression.FileSystem
$fqArchive = [IO.Compression.ZipFile]::OpenRead($fqApk)
$fqChecks = @()
$fqImageRoot = (Join-Path $fqRoot 'mobile/assets/images').TrimEnd([char[]]'\/') + [IO.Path]::DirectorySeparatorChar
$fqFiles = foreach ($fqDir in @('party_lobby_v001', 'lobby/portraits', 'lobby/portraits/female')) {
    Get-ChildItem -LiteralPath (Join-Path $fqImageRoot $fqDir) -Filter '*.png'
}
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
        $fqChecks += @{ asset = $fqRelative; sha256 = $fqHash; matches = $true }
    }
    if (-not $fqArchive.GetEntry('lib/arm64-v8a/libflutter.so')) { throw 'ARM64 Flutter runtime missing' }
} finally { $fqArchive.Dispose() }
$fqReport = @{
    apk = $ApkName
    bytes = (Get-Item -LiteralPath $fqApk).Length
    sha256 = (Get-FileHash -LiteralPath $fqApk -Algorithm SHA256).Hash
    verified_assets = $fqChecks.Count
    assets = $fqChecks
}
$fqReport | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $fqRoot 'art/party_lobby_v001/android-verification.json') -Encoding utf8
Write-Output "Verified $($fqChecks.Count) APK assets against the workspace originals."
Write-Output "APK SHA256: $($fqReport.sha256)"

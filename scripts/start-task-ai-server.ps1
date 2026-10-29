param([switch]$Foreground)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$dart = Join-Path $env:USERPROFILE 'FocusQuestTools\flutter\bin\cache\dart-sdk\bin\dart.exe'
if (-not (Test-Path -LiteralPath $dart)) { throw 'Dart SDK was not found.' }
if ([string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    $env:GEMINI_API_KEY = [Environment]::GetEnvironmentVariable('GEMINI_API_KEY', 'User')
}
if ([string]::IsNullOrWhiteSpace($env:GEMINI_API_KEY)) {
    throw 'Set the GEMINI_API_KEY user environment variable before starting. Do not put the key in source code or chat.'
}
$server = Join-Path $repo 'server\task_ai_server.dart'
if ($Foreground) { & $dart $server; exit $LASTEXITCODE }
$taskAiProcess = Start-Process -FilePath $dart -ArgumentList @('"' + $server + '"') -WorkingDirectory $repo -WindowStyle Hidden -PassThru
Write-Output ('Task AI server process: ' + $taskAiProcess.Id)

# Windowsパッケージ作成スクリプトの復旧メモ

2026-10-24のAIタスク連携作業中、`scripts/package-windows-app.ps1` に追加した自動起動用コードをWindowsの保護機能がブロックしました。その方式を取りやめ、AI接続プログラムはWindowsアプリ本体の起動処理から起動する方式へ変更しました。

同スクリプトは読み込み・書き戻し・削除がWindows側で拒否され、現在のファイルサイズは0バイトです。下に作業開始時の内容を保存します。Windowsの保護履歴を確認し、ファイルへのアクセスが復旧した後に戻すための控えです。保護機能の無効化や除外設定は行っていません。

作成済みの新アプリは `output/FocusQuest-Windows/20261024-224305/` にあり、作業フォルダーの `FocusQuest.lnk` はこの版へ更新済みです。AIゲートウェイも同梱済みです。スクリプトのロックは、この作成済みアプリの起動に必要なものではありません。

なお元のスクリプトはAIゲートウェイの同梱に未対応です。再ビルドする場合は `run-integrated-app.ps1 -BuildOnly -Offline` の出力一式と、`dart compile exe server/task_ai_server.dart -o 出力先/focusquest_task_ai.exe` の生成物を同じ新規パッケージへコピーします。

## 作業開始時のスクリプト

```powershell
param(
    [switch]$SkipBuild,
    [switch]$Offline,
    [switch]$DesktopShortcut,
    [switch]$Launch
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
if (-not $SkipBuild) {
    & (Join-Path $PSScriptRoot 'run-integrated-app.ps1') -BuildOnly -Offline:$Offline
}
$release = Join-Path $env:USERPROFILE 'FocusQuestTools\integrated-build\build\windows\x64\runner\Release'
if (-not (Test-Path -LiteralPath (Join-Path $release 'focusquest.exe'))) {
    throw 'Build the integrated Windows app first.'
}
# Keep previous packages intact, including any currently running application.
$package = Join-Path $repo ('output\FocusQuest-Windows\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
New-Item -ItemType Directory -Path $package -Force | Out-Null
Copy-Item -Path (Join-Path $release '*') -Destination $package -Recurse -Force
$exe = Join-Path $package 'focusquest.exe'
$shell = New-Object -ComObject WScript.Shell
$shortcutPaths = @((Join-Path (Split-Path $repo -Parent) 'FocusQuest.lnk'))
if ($DesktopShortcut) {
    $shortcutPaths += Join-Path ([Environment]::GetFolderPath('Desktop')) 'FocusQuest.lnk'
}
foreach ($shortcutPath in $shortcutPaths) {
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exe
    $shortcut.WorkingDirectory = $package
    $shortcut.IconLocation = "$exe,0"
    $shortcut.Description = 'FocusQuest'
    $shortcut.Save()
    Write-Output "Shortcut: $shortcutPath"
}
Write-Output "Windows app: $exe"
if ($Launch) {
    Start-Process -FilePath $exe -WorkingDirectory $package -WindowStyle Normal
}
```

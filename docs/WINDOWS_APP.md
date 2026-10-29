# FocusQuest Windowsアプリ

ビルド済みの通常版（`lib/main.dart`）は、作業フォルダーまたはデスクトップの `FocusQuest` ショートカットをダブルクリックして起動できます。Flutter SDKやターミナルを開く必要はありません。

アプリ一式は `output/FocusQuest-Windows/日時/` に保存します。別の場所へ移す際は、exeだけでなくDLLとdataを含むフォルダー全体をコピーしてください。移動後はショートカットの参照先も変更してください。

ソースを更新した後は、リポジトリ直下で次を実行すると再ビルドし、新しいアプリへショートカットを更新します。

```powershell
.\scripts\package-windows-app.ps1 -DesktopShortcut -Launch
```

既に `run-integrated-app.ps1 -BuildOnly` でビルドした場合は `-SkipBuild` を追加できます。ビルドには既存の `FocusQuestTools` 内のFlutter SDKとWindows開発環境を使用します。

パッケージを取得済みでネットワーク接続を使わずにビルドする場合は `-Offline` を追加してください。

旧アプリ一式は上書きしません。端末内のゲーム保存データは既存アプリと同じ保存先を使用します。

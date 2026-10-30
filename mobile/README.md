# FocusQuest アプリ

ログインなしで遊べる端末内保存版です。
通常起動は `lib/main.dart`、保存なし診断プレビューは `lib/main_preview.dart`。

Android向けの集中支援機能と、Windowsでの動作確認に対応しています。[2026年10月30日の更新内容](../docs/UPDATE_2026-10-30.md)に、最新の画面・操作・検証結果を記載しています。

[環境構築・実機起動・Firebase後続工程・Git運用・素材差替え](../docs/DEVELOPMENT.md)
および[実装・検証計画](../docs/IMPLEMENTATION.md)を参照してください。

```
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --target-platform android-arm64
flutter run
```

## 仮設の開発者用ツール

設定画面の「開発者用（仮設）」でアプリのリセットと職業・性別の変更ができます。
リセットは確認後に端末内のゲームデータを初期化します。職業・性別の変更は名前・レベル・経験値・履歴を引き継ぎます。
開発中はデバッグ・リリースの両ビルドに表示します。`--dart-define=FOCUSQUEST_DEVELOPER_TOOLS=false` を起動・ビルド時に指定すると全ボタンをまとめて非表示にできます。

UIと確認処理は `lib/features/settings/developer_settings_panel.dart` に分離しています。
完全に削除する場合は、`settings_screen.dart` の同ファイルのimport・`showDeveloperTools` 引数とフィールド・条件付きの `DeveloperSettingsPanel` ブロックを削除し、`developer_settings_panel.dart` と `developer_character_screen.dart` を削除してください。
保存処理も不要なら `GameController` の `resetForDevelopment`・`setCharacterForDevelopment` と関連テストを削除できます。

## 画面統合（2026-10-11）

通常の `lib/main.dart` でホーム・集中・プレイアブルステージを利用できます。
ホームの「冒険に出発する」と下部の「冒険」は同じステージ選択画面へ進みます。
集中成功で得たレベル、選択中の職業・性別を戦闘へ引き継ぎます。
原画PNGの再生・戦闘操作・音声は既存のプレイアブルステージを使用します。

36ステージのクリア記録は端末内に保存し、保存失敗時は画面内で再試行できます。
集中中は出発できず、冒険中は集中開始・キャラクターの変更を制限します。
以前の5ステージ版の入口は削除し、現在は九つの世界・全36ステージの冒険へ統一しています。
プレイアブルステージには既存仕様どおりポイント・装備のクリア報酬はありません。

`lib/main_playable_stage.dart` は保存なしの単独デモとして残しています。
統合版の確認には通常起動を使用してください。

本バージョンでは装備機能を提供しません。過去の所持品・装備データは保存互換性のため残し、戦闘能力には加算しません。

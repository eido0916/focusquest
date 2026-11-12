# 最新版の検証結果（2026年10月30日）

現在のPCで動作確認している版をGitHubへ保存するにあたり、アプリのソースとテスト一式を英数字のビルド用パスへ同期して検証しました。検証準備では、現行の経験値設定とスクロールなしの画面にテストを合わせ、飛び道具の発生を待つテストへ待機上限を設けました。アプリの動作コードは、このアップロード準備では変更していません。

## 最終結果

| 項目 | 結果 |
| --- | --- |
| 静的解析 | 指摘なし |
| テスト成功 | 529件 |
| テスト失敗 | 37件 |
| テストのスキップ | 1件 |
| Windows Releaseビルドと起動 | 直近の同一アプリコードで確認済み |
| Android実機での追加一括検証 | 今回は未実施 |

全体テストは未通過です。旧描画コンポーネントの期待値を含む不一致や、飛び道具・画面遷移等の検証失敗について、個別の原因確認と修正が必要です。最新版の保存と日本語資料の整備を行うドラフトPRとして提出します。

## 未解消項目

| テストファイル | 失敗数 | 主な確認内容 |
| --- | ---: | --- |
| [boxer_animation_test.dart](../mobile/test/boxer_animation_test.dart) | 2 | 拳闘士の動作時間と描画コンポーネント |
| [boxer_front_kick_test.dart](../mobile/test/boxer_front_kick_test.dart) | 1 | 前蹴りから走行へ戻る際の描画 |
| [boxer_run_test.dart](../mobile/test/boxer_run_test.dart) | 1 | 拳闘士の走行と攻撃後の復帰 |
| [dragon_berserker_test.dart](../mobile/test/dragon_berserker_test.dart) | 14 | 床投げの投射・命中・床素材の表示 |
| [playable_stage_demo_test.dart](../mobile/test/playable_stage_demo_test.dart) | 1 | 横長サイズでの重騎士のHP表示 |
| [playable_stage_contact_test.dart](../mobile/test/playable_stage_contact_test.dart) | 1 | 近接職と遠距離職の位置・接近。実行時にタイムアウト |
| [playable_stage_page_test.dart](../mobile/test/playable_stage_page_test.dart) | 5 | 戦闘画面の操作・描画・バックグラウンド時の一時停止 |
| [playable_stage_party_test.dart](../mobile/test/playable_stage_party_test.dart) | 2 | 終盤ステージのクリアと各職業の原画・戦闘イベント |
| [playable_stage_selection_test.dart](../mobile/test/playable_stage_selection_test.dart) | 4 | 選択画面とボス撃破後の遷移 |
| [role_portrait_ui_test.dart](../mobile/test/role_portrait_ui_test.dart) | 4 | 男女各職業の立ち絵の参照 |
| [player_reaction_test.dart](../mobile/test/player_reaction_test.dart) | 1 | 全32体の被弾・瀕死原画の読み込みと表示 |
| [widget_test.dart](../mobile/test/widget_test.dart) | 1 | 初回診断の結果表示・保存再試行 |

## 再現コマンド

Flutter SDKを用意し、`mobile` ディレクトリで実行します。このPCでは日本語パスでのビルド問題を避け、ソースを同期した英数字のパスで実行しました。

```powershell
flutter pub get --offline
flutter analyze --no-pub
flutter test --no-pub --reporter expanded
```

個別に確認する場合は対象ファイルを指定します。

```powershell
flutter test --no-pub test/dragon_berserker_test.dart --reporter expanded
flutter test --no-pub test/playable_stage_selection_test.dart --reporter expanded
```

## 確認済みの画面修正

直近の個別検証では、下部メニューの位置・大きさ・タップ遷移、集中時間選択とのメニューの一致、縦スクロールなしの表示、冒険マップの縦横比と全幅表示、タイマーと戦闘の画面方向の切り替えを確認しました。小型・縦長・タブレットサイズと文字拡大を含めて検証しています。

画面例は[最新版の更新内容](UPDATE_2026-10-30.md#画面例)を参照してください。ユーザーの保存データを使う検証や、記録のリセットは行っていません。

# 設定画面 v002

2026-10-28の添付画像を参考に、濃紺・金の装飾と白い明朝文字で設定画面を制作。

- `reference.png`: 今回の参照画像。
- `materials/`: 個別PNG21点＋既存の城背景1点。
- `vectors/`: 装飾枠、見出し帯、ボタン、設定行、注意枠、メダル、アイコン、ON/OFFスイッチの編集可能なSVG。
- `material_catalog.png`: 個別素材一覧。
- `manifest.json`: 素材名と寸法。
- `preview-458.png`: Flutter実描画プレビュー（458×859の画面を2倍で出力）。

再生成: `node scripts/build-settings-ui-v002.cjs`。新規装飾はコードで描いたSVGをPNG化。背景は既存の`mobile/assets/images/lobby/castle_courtyard.png`を再利用。従来のv001および他画面の素材は保持。

組込先: `mobile/assets/images/settings_ui_v002/`。
実装: `mobile/lib/features/settings/settings_art.dart`、`settings_screen.dart`。

枠は四隅を保持して中央のみ伸長。文字は画像に焼き込まず、Flutterで配置。権限設定、復帰時の権限更新、BGM/SE保存、開発用機能と確認付きリセットを維持。戻る矢印はホームへ移動する。クラウド同期は従来通り未実装。

検証・プレビュー生成:

```powershell
cd mobile
C:/src/flutter/bin/flutter.bat test --no-pub --dart-define=CAPTURE_SETTINGS=true test/settings_layout_test.dart
```

幅320/390/470/844、文字倍率1.0/1.6で権限ボタン・音声切替・戻る・リセットのキャンセルを確認する。参照比率のプレビューでは開発者パネルを非表示にする。通常のdebugビルドでは既存の開発者パネルを維持する。

検証結果: 静的解析エラーなし。レイアウト・操作8件＋参照比率の描画1件＋個別素材の書出し1件、全10件成功（`validation.log`）。大量の無関係なゲーム画像の準備を避けるため、同一のlib/test・依存設定を`C:/src/fq-settings-v002/`へコピーし、assets登録を設定用画像とフォントに絞って実行した。Android実機のOS権限画面は今回の検証対象外。

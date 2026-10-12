# 設定画面素材 v001

- `materials/`: 背景・タイトル・見出し帯・羊皮紙パネル・青ボタン・赤ボタン・個別アイコンPNG。
- `reference.png`: ユーザー指定の参照画像。
- `preview-470.png`: 設定画面プレビュー。
- `material_catalog.png`: 個別素材一覧。
- `generation.json`: built-in image_genで使用した各素材の生成指示。
- `manifest.json`: 素材寸法・原画の切り出し範囲・組み込み先。
- `raw/`: 生成原画。

背景と装飾6点は1点ずつ生成。アイコンは既存アプリのMaterial Iconsを1点ずつ透過PNGに書き出す。画面内の文字はFlutterで配置する。

アプリ用PNG: `../../mobile/assets/images/settings_ui_v001/`。
設定画面: `../../mobile/lib/features/settings/settings_screen.dart`。
可変サイズの枠は中央部分だけを伸ばして四隅を保持する。権限設定、復帰後の権限更新、開発用キャラクター選択、確認付きリセットを維持。

生成素材の配置: `node scripts/package-settings-ui.cjs`。
表示・操作検証およびPNG書き出し: `flutter test --no-pub --dart-define=CAPTURE_SETTINGS=true test/settings_layout_test.dart`。

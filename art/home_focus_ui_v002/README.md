# ホーム・集中中画面 v002

添付された左右のUI案をもとに、Flutterの実画面へ実装した素材と確認記録です。

- ホーム：顔・名前・職業・Lv・EXPを上部に集約。城と湖の背景に既存の立ち絵を配置し、旅の記録、集中実績、集中・冒険ボタンを続けています。
- 集中中：章と設定時間を上部に表示。残り時間を主役にし、進捗、経過時間、戦闘表示、サウンド、中断を配置しています。
- 立ち絵は `mobile/assets/images/lobby/portraits/` の既存イラストを参照。男女16職の画像選択は既存の `JobPortrait` を使用し、武器・服・髪型を描き替えていません。
- 文字や数値を背景画像へ焼き込まず、FlutterのTextで表示。名前とLvの領域を分離し、大きい文字では縦配置へ切り替えます。狭い画面ではスクロールとボタンの縦配置で対応します。

## 素材

`materials/` とアプリの `mobile/assets/images/home_focus_ui_v002/` に、背景・各種枠・肖像枠・紋章・アイコン・ゲージ・区切り線の28個のPNGを保存しています。装飾枠は角を保持する9スライスで伸縮し、中央の小さな装飾は別PNGとして配置します。

背景・装飾の原画は組み込みの **image_gen** で個別生成しました。採用原画は `originals/`、最終プロンプト一式は [generation.json](generation.json) と [generation-revisions.json](generation-revisions.json) に保存しています。アイコンとゲージ・区切り線の編集可能なSVGは `vectors/` です。`manifest.json` に寸法・透過・由来・SHA256を記録しています。

- [素材一覧](index.html)
- [ホーム実装プレビュー](previews/home-390x844-1.png)
- [集中中の実装プレビュー](previews/timer-390x844-1.png)
- [両画面の比較プレビュー](previews/implemented-screens.png)
- [ユーザー参照案](reference.png)

## 実装と確認

共通部品：`mobile/lib/core/widgets/reference_game_art.dart`。画面本体：`mobile/lib/features/home/home_reference_scene.dart`、`mobile/lib/features/focus/presentation/focus_reference_timer.dart`。変更前の画面本体は `source_before/` に保存しています。

`scripts/verify-home-focus-ui-v002.ps1` で5画面サイズ（320×568、390×844、390×1150、844×390、1280×800）×文字倍率1.0/1.6×両画面の20ケースを検証します。文字領域の重なり、ゲージの高さ、既存立ち絵の使用、経過・残り時間、ボタンのコールバックを確認し、`previews/` に実描画を保存します。大きい文字や横画面ではスクロールが必要です。

素材の再配置は `node scripts/package-home-focus-ui-v002.cjs`。元の人物素材やアニメーションは変更しません。

静的解析の結果は `validation-analyze.log`、20通りの画面テストは `validation-tests.log`、男女16職の既存画像選択テストは `validation-role-mapping.log` に保存しています。画像選択テストでは関連するキャラクター画面の共通ヘッダー用素材も必要なため、検証用バンドルには冒険マップ素材も含めています。

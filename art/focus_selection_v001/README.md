# 集中時間選択画面 v001

参考画像の草原・城・遺跡を背景に、羊皮紙と濃紺・金縁の独立素材を配置したFlutter画面です。文字と操作は画像に焼き込まず、実際のウィジェットで表示します。説明用会話窓と常設の入力欄を取り除き、カスタム時間はタップして指定します。

- `materials/`: 背景、装飾枠、ボタン、個別アイコンPNG。
- `icons/`: アイコンの編集可能なSVG原稿。
- `avatars/male/`・`avatars/female/`: 16職×男女の顔アバター。128×128透過、64論理格子を最近傍2倍で保存。
- `raw/`: 画像生成ツールの元出力。以前の立ち絵・原画・アニメーションは変更しません。
- `manifest.json`・`avatar_manifest.json`: 素材サイズ、職業・性別、参照元、対応ファイル。
- `layout.json`: 参考サイズでの配置情報と時間選択の範囲。
- `prompts.json`・`avatar_generation.json`: built-in image_genによる生成プロンプト。
- `material_catalog.png`・`avatar_catalog.png`: 素材一覧。
- `preview_390.png`・`preview_1024.png`: Flutterから描画した画面プレビュー。

画面実装: `mobile/lib/features/focus/presentation/focus_selection_scene.dart`。
各職業のアバターは既存の立ち絵と`playable_stage/character_XX[_female]_run_000.png`を参照して個別生成し、`typeId`と`appearance`で選択します。女性アサシンの赤髪・赤黒衣装、魔法使いの紫髪、女性ガンナーの濃い茶髪を保持します。

操作: 15/30/45/60分、1〜180分のカスタム、集中開始、パーティ、所持アイテム、職業図鑑、設定、戻る。第二章は既存の幽霊船背景と章名に切り替わります。集中中のタイマー、監視、保存・報酬処理は既存のロジックを使います。

検証: 時間切替・カスタム入力の範囲確認、320/390/1024px幅の描画、パーティへの遷移を確認。32種のアバターすべてで透過・128×128px・2×2画素の完全一致とアプリ内素材の一致を確認しています。

再パッケージ: `scripts/package-focus-selection.cjs`と`scripts/package-focus-avatars.cjs`。画像生成の元出力が必要です。

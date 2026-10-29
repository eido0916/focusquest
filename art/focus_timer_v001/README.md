# 集中タイマー画面・個別素材 v001

添付画像を参考に、戦闘画面から「タイマーに戻る」で開く集中中画面を更新。
背景以外は実際のアルファ透過を持つ独立PNG。すべて個別に画像生成した素材です。

| ファイル | 用途 |
| --- | --- |
| background.png | 青空・城・遺跡・滝の縦長背景 |
| panel_frame.png | 中央パネルの金色装飾枠（内外透過） |
| name_banner.png | 名前・レベル用の空欄リボン |
| chapter_crest.png | 章見出し用の紋章 |
| gold_divider.png | 見出し下の金色区切り線 |
| crossed_swords.png | 戦闘画面へのボタン用の交差剣 |
| timer_circle.png | タイマー背面の青い魔法陣 |
| gauge_frame.png | 進捗ゲージの金色枠と空の紺色トラック |
| gauge_fill.png | 進捗ゲージの青い発光部分 |

`reference.png` はユーザーの参照画像。`preview.png` はFlutterで描画した画面。
`asset_layout.json` に元PNGの寸法とアルファ値8超の内容領域（左・上・右・下、右下は排他的）を記録。
元PNGを保持し、Flutterの `FocusTimerAsset` がこの内容領域を表示します。

素材の実装用コピー：`../../mobile/assets/images/focus_timer_v001/`。
画面：`../../mobile/lib/features/focus/presentation/focus_timer_scene.dart`。
タイマーの値・章・職業ロゴ・名前・レベルは実データから表示。
進捗は経過時間の割合で左から増加。文字や数字はPNGに含めていません。
サウンド設定・中断確認・パーティー表示・保存の再試行を維持。
小型・横画面ではスクロールして全操作へ到達できます。

キャラクター・敵の原画アニメーションは変更していません。

検証：`mobile/test/focus_timer_scene_test.dart` で390×844、320×568、844×390の
レイアウト・戦闘ボタン・中断ボタンを確認し、プレビューを出力します。

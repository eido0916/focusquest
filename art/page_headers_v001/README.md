# 主要画面の見出し統一

キャラクター・設定のタイトルを「冒険の書」の紺色ダマスク模様と金の装飾枠に統一。

- 共通部品: `mobile/lib/core/widgets/quest_page_header.dart`
- 共通背景: `mobile/assets/images/adventure_map_v001/header.png`
- 書体: SunlitSerif、標準ウェイト、字間0、アイボリー。副題も同じ色と書式。
- 左右のアイコン領域を同じ幅にして、タイトルを中央配置。
- キャラクターは従来の単独タイトル、設定は副題と戻る操作を維持。
- 画面幅と文字拡大への対応を維持。

新しい生成画像は使わず、既存の冒険画面の素材を共通参照。
`previews/comparison.png` は左が変更前、右がFlutterで描画した変更後。
`previews/character-screen.png` と `settings-screen.png` は検査時の実画面。

関連テスト49件通過。変更した4ファイルの静的解析で問題なし。
Windows Releaseビルド成功（214.2秒）。

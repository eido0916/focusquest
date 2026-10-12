# 冒険画面の文字・地面・操作ボタン配置

- HP、職業、レベル、フェーズを固定サイズのレイアウトに縮小する方式から、画面幅に合わせた文字サイズと枠内余白へ変更。
- 小さい横画面ではフェーズ表示を中央へ移し、右側のボスの頭を隠さない配置に変更。
- 全36ステージの足元を共通の基準位置へ移動。各背景の元の地面位置を使って背景と原画を揃え、下部の地面領域に攻撃・スキル・オートを配置。
- 地面が足りない部分は既存の背景の地面を繰り返して表示。キャラクター・敵の原画や補間方式は変更しない。
- 小さいユーティリティ枠に限り、共通枠の画像スケールを8へ指定。その他の画面の既定値は4のまま。

検証: adventure_battle_hud_test.dart および playable_stage_demo_test.dart の関連12件、game_ui_test.dart の2件が成功。変更5ファイルのflutter analyzeで問題なし。

プレビュー: art/adventure_ui_v001/adventure_preview.png、art/adventure_layout_v002/boss-landscape.png、boss-portrait.png。


# FocusQuest: 森の入口の野原

制作: imagegenスキル、組み込み image_gen ツール（CLI/APIフォールバック不使用）。
保存先: `mobile/assets/images/ui/forest_meadow_battlefield.png`
既存の背景画像は変更・削除せず、新しいアセットとして追加。

使用プロンプト:

```text
Use case: stylized-concept. Asset type: horizontally scrolling 2D side-scroller background for FocusQuest, a fantasy anime swordsman auto-running game. Generate a new environment-only raster image, very wide landscape roughly 2:1. Scene: a beginner adventure area, a sunlit grassy meadow at the entrance to a gentle deciduous forest. Lush natural grass, scattered leafy trees and a distant tree line, modest low hills, blue sky partly visible through green foliage, soft golden daylight, calm inviting early-game atmosphere. Style: polished hand-painted anime JRPG environment art, matching detailed anime character sprites. Composition: side-on level view, not a road vanishing into the center. A horizontal grassy-earth walking lane at roughly 75 percent of image height, visually level across full width. Keep the center battle space uncluttered so characters remain readable; trees behind the lane, small tufts and wildflowers lower down. Designed for endless horizontal repetition: left and right borders should match in ground level, foliage density, sky color and lighting; no distinctive landmark at either border. Avoid huge central tree trunks or major vertical objects at image borders. No characters, weapons, castles, monumental ruins, stone arches, waterfalls, HUD, text, borders, logos or watermarks. Opaque background.
```

描画: 108論理px/秒で右から左へ移動（前回90から20%増速）。高さを540に合わせて縦横比を維持。
元画像と水平反転画像を交互につないで端の境界を連続させる。背景だけを反転し、人物は反転しない。
移動量は集中セッションの経過時間から求め、通常攻撃・スキル中も移動する。
集中終了後は経過時間が止まるため、背景の移動も停止。
速度の調整箇所: `BackgroundComponent.scrollSpeed`。

ユーザーの指定により、実装後のテスト・静的解析・動作確認・Android更新は未実施。

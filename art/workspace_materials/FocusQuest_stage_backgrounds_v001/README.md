# Focus Quest ステージ背景

横スクロールの戦闘画面向けドット絵PNGです。左にプレイヤー、右に敵を配置できる空間を確保しています。生成は組み込みimage_genを使用しました。生成画像は加工せず保存しています。

| 背景 | ファイル | 内容 |
| --- | --- | --- |
| 草原 | [grassland_v001.png](grassland_v001.png) | 青空と山々、平坦な草地 |
| 幽霊船 | [ghost_ship_v001.png](ghost_ship_v001.png) | 月夜の海と沈没船を望む、古い木製甲板 |
| 火山 | [volcano_v001.png](volcano_v001.png) | 噴火する山と溶岩、足場となる玄武岩の岩棚 |
| 魔王城 | [demon_castle_v001.png](demon_castle_v001.png) | 黒い柱・赤い旗・紫の空、奥に玉座がある大広間 |

草原のプロンプトは `generation_prompt.txt`、追加3枚の完全なプロンプトは `generation_prompts_additions_v001.json` に保存しています。追加画像は `mobile/assets/images/stage_backgrounds/` に同一のPNGをコピーし、pubspec.yamlに登録しています。

```dart
Image.asset(
  'assets/images/stage_backgrounds/ghost_ship_v001.png',
  filterQuality: FilterQuality.none,
  fit: BoxFit.cover,
)
```

背景ごとに足場の高さは異なります。キャラクターの足元を、甲板・岩棚・石床の上に合わせて配置してください。横方向の端が連続するシームレス素材としては検証していません。今回の追加は背景素材の作成・登録で、ステージ選択や敵編成の変更は含みません。

# 追加ステージ背景 v002

ビルトインimage_genで生成した5枚のドット絵背景。既存の草原・幽霊船・火山・魔王城を保持し、別の地形・色合い・舞台として追加しました。PNGは生成結果を加工せず保存し、同じバイト列をFlutterのassetsへコピーしています。生成プロンプトはgeneration_prompts_v002.json。

| ステージ | 背景 | ファイル | 最終ボス |
|---|---|---|---|
| 13〜16 | 毒茸の湿地 | poison_marsh_v001.png | ケルベロス |
| 17〜20 | 砂漠の迷宮 | desert_labyrinth_v001.png | ミノタウロス |
| 21〜24 | 氷晶洞窟 | ice_crystal_cavern_v001.png | 石のゴーレム |
| 25〜28 | 月影の墓地 | moonlit_graveyard_v001.png | リッチ |
| 29〜32 | 星界の祭壇 | astral_altar_v001.png | サイクロプス |

Flutterへの組み込みはmobile/assets/images/stage_backgrounds/。戦闘用の水平な足場に合わせ、groundLine=.82でキャラクターの足元を配置します。キャラクターは左、敵は右。3フェーズとクリア後のステージ選択復帰は従来どおりです。詳細はdocs/STAGE_EXPANSION_V013.md。

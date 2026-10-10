# Focus Quest 制作素材の統合（2026-10-10）

このフォルダは「ヒーローズリーグ」ワークスペースで制作した素材・制作履歴・編集元を保存します。

- 現行のキャラクター・敵原画素材: [FocusQuest_pixel_keyframes_v012](FocusQuest_pixel_keyframes_v012/README.md)。男性10体・女性10体・通常敵3体・ボス4体。プレビューは同フォルダの index.html。
- 草原ステージ背景: [grassland_v001.png](FocusQuest_stage_backgrounds_v001/grassland_v001.png)。生成プロンプトも同梱。
- 追加ステージ背景: [幽霊船・火山・魔王城](FocusQuest_stage_backgrounds_v001/README.md)。PNGと生成プロンプトを保存し、Flutterのassetsにも登録。
- 過去の原画素材: FocusQuest_pixel_keyframes_v001〜v011。制作履歴として保持。
- 初期の調査・参照画像・試作: FocusQuest_character_preproduction_v01。パーツ変形による古い試作は現行原画アニメーションとして使用しません。
- 制作方針: リポジトリルートの AGENTS.md。完成原画の保持再生、補間・変形なし、整数倍の最近傍表示を遵守します。
- 制作補助Python、受け渡し仕様書、生成プロンプト、検証記録を保存。

原画と24fps連番は元ファイルのバイト列を維持してコピーしています。コピーのSHA-256と、現行v012の全連番のRGBAが対応原画と完全一致することを検証し、結果を integration_verification_v012.json に記録しています。以前のv010の検証結果は integration_verification.json に保持します。

同じ内容の配布ZIP、Pythonキャッシュ、実行ログは収録しません。元ワークスペースの素材は上書きしません。

現行Flutterアプリへの素材登録とプレイアブルステージの実装は [動作説明](../../docs/PLAYABLE_STAGE.md) を参照してください。

# Focus Quest 制作素材の統合（2026-10-10）

このフォルダは「ヒーローズリーグ」ワークスペースで制作した素材・制作履歴・編集元を保存します。

- 現行のキャラクター・敵原画素材: [FocusQuest_pixel_keyframes_v013](FocusQuest_pixel_keyframes_v013/README.md)。男性10体・女性10体・通常敵8体・ボス9体。プレビューは同フォルダの index.html。
- 草原ステージ背景: [grassland_v001.png](FocusQuest_stage_backgrounds_v001/grassland_v001.png)。生成プロンプトも同梱。
- 追加ステージ背景: [幽霊船・火山・魔王城](FocusQuest_stage_backgrounds_v001/README.md)。PNGと生成プロンプトを保存し、Flutterのassetsにも登録。
- 新しい5背景: [毒茸の湿地・砂漠の迷宮・氷晶洞窟・星界の祭壇・月影の墓地](FocusQuest_stage_backgrounds_v002/README.md)。PNG原本・プロンプト・コピー検証を保存。
- 過去の原画素材: FocusQuest_pixel_keyframes_v001〜v012。制作履歴として保持。
- 初期の調査・参照画像・試作: FocusQuest_character_preproduction_v01。パーツ変形による古い試作は現行原画アニメーションとして使用しません。
- 制作方針: リポジトリルートの AGENTS.md。完成原画の保持再生、補間・変形なし、整数倍の最近傍表示を遵守します。
- 制作補助Python、受け渡し仕様書、生成プロンプト、検証記録を保存。

原画と24fps連番は元ファイルのバイト列を維持してコピーしています。コピーのSHA-256と、現行v012の全連番のRGBAが対応原画と完全一致することを検証し、結果を integration_verification_v012.json に記録しています。以前のv010の検証結果は integration_verification.json に保持します。

v013で追加した10体・40動作・170原画・780表示用連番の検証は integration_verification_v013.json に記録しています。

同じ内容の配布ZIP、Pythonキャッシュ、実行ログは収録しません。元ワークスペースの素材は上書きしません。

現行Flutterアプリへの素材登録とプレイアブルステージの実装は [動作説明](../../docs/PLAYABLE_STAGE.md) を参照してください。

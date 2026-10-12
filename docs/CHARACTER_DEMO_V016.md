# ドラゴンナイト・バーサーカーのFlutterデモ

`scripts/run-character-demo-v016.ps1` を実行すると、男女16職業のキャラクター選択から始まるWindows版Flutterデモを起動します。専用ビルド先は `%USERPROFILE%/FocusQuestTools/character-demo-v016/`。本アプリ用のintegrated-buildには触れません。

選択 → ステージ選択 → 冒険。赤ボタンは通常攻撃、通常攻撃3命中で青ボタンのスキルが使用できます。右上に音・一時停止・再開の操作があります。

- character_15：走行8原画、槍突き8原画、蓄力と剣槍乱舞12原画。乱舞は3回命中、合計威力を分配。
- character_16：走行8原画、振りかぶり強打8原画、床剥がし投げ12原画。床材はステージから選択。投げた物体の着弾までダメージは発生しません。
- 床材：芝付き土、木板、溶岩岩、泥、砂岩、氷、石床の7種。それぞれ持ち上げ・頭上・飛行・破砕の4原画。

素材元はワークスペースの `FocusQuest_pixel_keyframes_v016/`。`scripts/package-flutter-stage.py` が128×128の原画PNGを画素変更なしでmobile/assets/images/playable_stage/へコピーします。背景とキャラクター画像を別々に描き、キャラクターと飛行物体のワールド座標のみを動かします。身体パーツの変形やフレーム補間はありません。

`mobile/test/dragon_berserker_test.dart` を含む関連テスト58件合格。7材質の保持・飛行画像、男女選択、全原画読み込み、乱舞3命中を確認。床投げは他の遠距離攻撃と同じく移動中の標的へ着弾し、一度だけダメージを与える。男女・表示サイズ3種で敵が攻撃移動中でも命中し、着弾前にダメージが発生しないことを検証。表示サイズ依存の射程による不命中を廃止。`flutter analyze --no-pub` の指摘なし。

Windowsビルド済み実行ファイル：`%USERPROFILE%/FocusQuestTools/character-demo-v016/build/windows/x64/runner/Release/focusquest.exe`。実行時は同じフォルダのdataとDLLも必要です。

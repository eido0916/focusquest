# 検証記録

- `character_lobby_test.dart`: 390×844 / 320×568、文字倍率1.0 / 1.6の4条件で装備変更・所持数維持・描画エラーなしを確認。
- `role_portrait_ui_test.dart`: 男女各2幅の4テストが成功。
- `game_ui_test.dart`: 集中→冒険報酬→キャラクター画面の既存フローが成功。
- 男性16職PNGのSHA-256が指定フォルダーの原画像と一致。
- アイコン3枚のRGBA透過を確認。
- `output/character_lobby/character.png` と `equipment.png` を実描画して目視確認。
- 全体の静的解析には、今回変更していない `test/boxer_front_kick_test.dart:83` の `invalid_use_of_internal_member` 警告が1件。
- 今回変更した画面・立ち絵Widget・テストの4ファイルに限定した `flutter analyze --no-pub` は問題なし。
- Android arm64 debug APKのビルド成功。`output/android/FocusQuest-debug.apk` 内の背景・ウィンドウ・アイコン・男性16職PNGを確認。実機操作は未確認。

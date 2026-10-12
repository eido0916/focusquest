# 集中冒険：森の入口のドット背景 v001

2026-10-11制作。組み込みimage_genツールで新規制作。

実使用素材：`mobile/assets/images/ui/forest_meadow_pixel_v001.png`。
制作プロンプト：このフォルダの`prompt.txt`。
以前の`forest_meadow_battlefield.png`は保持。

ソロの集中冒険とパーティー集中で同じ原画を使用。
縦横比を保ち、FilterQuality.none（最近傍法）で描画する。
ソロでは108論理px/秒のスクロールを原画像の1px単位に揃える。
原画と水平反転背景を交互に接続し、両端の画素を連続させる。
パーティーでは静止背景として描画。元のタイマー・戦闘処理を使用。
手描き風背景用の滑らかな暗色グラデーションは除去し、背景の色をそのまま表示。
キャラクターは既存のドット絵原画を継続使用。

確認用画面は`output/focus/960-battle.png`と`390-battle.png`。

検証：変更した4ファイルの静的解析に問題なし。
`battle_replay_page_test.dart`・`party_ui_test.dart`・`runner_battle_test.dart`の計12テスト成功。
OneDriveのファイルロックを避け、LocalAppData配下の検証用コピーで実行。
960×540横画面と390×844の縦画面フォールバックを画像で確認。
道の足元・キャラクターの視認性・HUDの読みやすさを確認済み。
Android APKのビルド・実機へのインストールは今回未実施。

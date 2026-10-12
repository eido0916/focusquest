# 老王と輝く魔石・導入画面 v002

添付「冒険のはじまり：王と輝く魔石.png」を参照して制作。元画像と以前の導入素材は保持。

## 個別素材
本体で使うPNG: `../../mobile/assets/images/diagnosis/king_intro_v002/`

- `cathedral.png`: 紫の夕空・大聖堂・金の柱・蝋燭・床。
- `old_king.png`: 透過。影に隠れた顔、長い髪と髭、黒金の王冠、毛皮と刺繍のローブ、差し出した手。
- `magic_crystal.png`: 透過。紫と水色の魔石・光の軌道・星の輝き。
- `touch_hand.png`: 透過。手前の指先と接触の光輪。

UI装飾は `king_intro_ornaments.dart` でサイズに合わせて描画。確認用の独立PNGもこのフォルダに書き出す:
`dialogue_frame.png`, `title_rule.png`, `continue_arrow.png`。
文字は既存のOFLフォント `SunlitSerif / NotoSerifJP` を使用し、画像に焼き込まない。

## 表示・操作
縦画面は背景・老王・魔石・指先の順で重ね、タイトルを上、会話枠を下部へ置く。
横画面は絵と会話を左右に配置。小さい画面は会話枠の下端を調整。
会話をタップすると全文表示。魔石または二重矢印でホワイトアウト後に既存診断へ進む。
文字拡大時は会話枠内をスクロールできる。
画像は静止原画。パーツ変形・補間アニメーションなし。

## 制作・検証
画像は内蔵 `image_gen` で個別制作。全プロンプトを `prompts.json` に記録。
`king_intro_scene_previous.dart` は更新前の画面ソース。
`preview-390x844.png`、`preview-320x568.png`、`preview-844x390.png` はFlutterの実描画。
検証コマンド:
`flutter test --no-pub --concurrency=1 --dart-define=CAPTURE_KING=true test/king_intro_scene_test.dart test/diagnosis_layout_test.dart test/widget_test.dart`

画面・操作テスト: 5件成功。3サイズの描画を確認済み。
診断・保存への連結テスト: 7件成功（合計12件）。

持ち出し用の個別PNGは assets/、画面ソースは source/ に複製。index.html で一覧表示。
静的解析: 指摘なし。

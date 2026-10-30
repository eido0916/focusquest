# パーティー入口 v002

2026-10-29。添付画像を参照し、入口を草原の訓練場・濃紺の唐草模様・金の装飾枠で再制作。

- 「パーティーを作成」「コードで参加」と説明欄を参照画像の位置関係で配置。
- 入口の集中時間設定を削除。作成前に時間を選択・送信する処理も削除。結成後の待機室でリーダーが設定する。ゲストの変更制限、準備解除、同期開始は既存の動作を継続。
- 原画アニメーション・キャラクター素材に変更なし。既存ロビー素材v001は保持。

## 個別素材

`materials/` と `mobile/assets/images/party_entry_v002/` に同じPNGを保存。11点の寸法とSHA256は `manifest.json`。一覧は `material_catalog.png`。

|素材|用途|制作|
|---|---|---|
|background|青空・山・草原・旗・柵・的の背景|組み込みImageGen|
|title|上部の見出し枠|組み込みImageGen|
|action|作成／参加のボタン枠|組み込みImageGen|
|information|説明欄の枠|組み込みImageGen|
|back|戻るボタンの枠|組み込みImageGen|
|icon-back|戻る矢印|個別SVG|
|compass|金のコンパス|個別SVG|
|icon-create|白い人物アイコン|個別SVG|
|icon-join|白い参加アイコン|個別SVG|
|icon-chevron|右矢印|個別SVG|
|separator|アイコンと文字の区切り|個別SVG|

生成前の参照画像は `reference.png`、生成結果は `originals/`、編集可能な小物は `vectors/`。生成指示は `generation-prompts.md`。生成結果の透過余白を除き、アプリ用寸法へ正規化した。背景は最近傍法で処理・表示。文字は画像へ焼き込まずFlutterの日本語フォントで描画する。

実装: `mobile/lib/features/party/presentation/party_entry_scene.dart`。
パッケージ化: `node scripts/package-party-entry-v002.cjs`。

実画面プレビューは `previews/entry-reference.png`（参照と同じ縦横比）、`previews/entry.png`（390×844）、`previews/join.png`（コード入力）。

## 検証

- 入口・結成後の待機室13件、作成／参加の操作3件、通信6件、集中画面からの遷移1件、計23件合格。
- 320px幅・横画面・文字倍率1.6を含む。入口に時間設定がないこと、待機室ではホストだけが変更できることを確認。
- 素材11点の制作版・アプリ版のSHA256一致を `asset-verification.json` に記録。
- Windows releaseビルド成功。更新版を起動し、ウィンドウの応答を確認。
- 通信テストはローカルサーバー。公開サーバーへの接続は今回の検証に含まない。
- 操作テストの実ソケットのハートビートがFlutterの仮想時計に残る問題を、テスト用接続のタイマーを実時間へ委譲して解消。アプリ本体の通信実装は変更していない。

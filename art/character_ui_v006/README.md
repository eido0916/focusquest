# キャラクター画面 v006 — 装飾素材による参照画面の再現

添付された `reference.png` をもとに、青金の名札、羊皮紙の能力値欄・冒険者情報欄、青い能力値バーと操作ボタンを独立したPNGとして新規制作した。

- `originals/`: built-in image_genで制作した5種類の透過原本。
- `materials/`: アプリで使用する個別PNG。文字・名前・数値を画像へ焼き込まず、動的に表示する。
- `previews/`: Flutterによる実描画。320pxの小画面、文字1.6倍、横長画面も確認する。
- `prompts.json`: 生成プロンプト一式と使用モード。
- `manifest.json`: 各PNGの寸法とSHA256。

新規素材: `identity_panel`, `stats_parchment`, `info_parchment`, `stat_row`, `action_row`。
EXPの枠と充填、見出し飾り、数値の区切り線は専用の個別PNGとして制作。背景、見出し、職業紋章・立ち絵、既存のアイコンは再利用した。

枠は四隅の寸法を保持する9分割描画で表示する。文字拡大時は内容に応じて高さを確保し、能力値を1列へ切り替える。PCでも参照画像の縦の構成を保持する。

パッケージ用コード: `scripts/package-character-ui-v006.ps1`。
以前のv004・v005と元イラスト、ドット絵・アニメーション素材は保持する。

最終検証: 専用フォルダでキャラクター画面・称号の20テスト成功。9画面サイズ × 文字倍率1.0/1.6、見出しの中央揃え、操作の到達性を検証。枠の描画倍率は1.0/1.5の2段階。

最終Windows Releaseビルド成功。修正版を起動。

最終静的解析: character_screen.dart / character_art.dart / character_lobby_test.dart は指摘なし。起動プロセスの応答も確認済み。

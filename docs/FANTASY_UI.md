# ファンタジーUI（2026-10-04）

## GitHubチェックポイント：ゲーム画面化の途中

以下は前版の検証記録。現在は常設ロゴとキャッチコピーを外し、全面背景・小型ステータス・コマンドウィンドウへ改修中。
ホーム、仲間、冒険、召喚、集中の構成を変更。冒険と召喚の履歴はダイアログで開く。
最新の解析は問題なし。最新テストではゲームループの戦闘履歴が空のままになる1件が失敗しており、原因確認が必要。
最新UIのAPKビルドと実機表示確認は未完了。前版APKを最新UIの検証済み成果物と扱わないこと。

参考: [ドラゴンクエストXI公式・各ハードの特徴](https://dq11.jp/feature/index.html)。
画面構成を参考にし、背景・人物・コードはプロジェクト独自のものを使用。

## 前版の実装・検証記録

21日チャレンジの表示、初回説明、未使用の目標定数を削除。今日・累計時間と連続記録は継続。

深緑とアンティークゴールド、二重の装飾枠、羊皮紙パネル、独自の下部メニューを採用。
ホーム・冒険・集中画面に背景画を同梱。仲間の能力値は羊皮紙のタイルで表示。
画面内の文字と操作ボタンはFlutterのUIとして描画し、画像には含めない。

## 背景画像

- 保存先: `mobile/assets/images/enchanted_forest.png`
- 生成: imagegenスキル、組み込み画像生成ツール。
- 参照画像は雰囲気の参考に使用。生成した背景はオリジナルの構図。
- プロンプト:

> Use case: stylized-concept. Asset type: background illustration bundled into FocusQuest mobile RPG productivity app. Create original atmospheric fantasy environment: an ancient elegant steel sword with restrained brass hilt embedded in mossy stone, in a deep enchanted evergreen forest, distant ruined archway and softly glowing turquoise stream, amber sunbeams cutting through canopy. Painterly premium RPG concept art, textured brushwork, rich dark teal and forest green shadows, warm antique gold light. Landscape 1536x1024 composition, sword and stone in center-right, left upper area quiet dark foliage with negative space for live UI text. Full bleed artwork only, no text, no typography, no logo, no watermark, no frame, no UI, no people. Inspired by the mood of the user's reference forest sword, but original scene and composition.

## 検証

- Flutter解析: 問題なし。
- 既存テスト28件成功（390×844のゲームループ操作を含む）。
- APKビルド成功、TB373FU / Android 16にUSBで更新インストール。
- 実機でホームと仲間画面のスクリーンショットを確認。既存の記録と木の剣の装備を保持。
- 画像確認記録: `output/android/fantasy-home.png`、`output/android/fantasy-character.png`。

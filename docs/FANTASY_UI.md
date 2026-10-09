# ファンタジーUI（2026-10-04）

## GitHubチェックポイント：ゲーム画面化の途中

以下は前版の検証記録。現在は常設ロゴとキャッチコピーを外し、全面背景・小型ステータス・コマンドウィンドウへ改修中。
ホーム、キャラクター、召喚、設定の4タブ構成。冒険は独立タブではなく、集中中に進む自動戦闘として扱う。
チェックポイント時はゲームループの戦闘履歴が空になる1件が失敗。後続の戦闘Phase 1〜3実装で、テスト側が非同期画像ロードを待つよう修正し成功。
最新UIのAPKビルドと実機表示確認は未完了。前版APKを最新UIの検証済み成果物と扱わないこと。

参考: [ドラゴンクエストXI公式・各ハードの特徴](https://dq11.jp/feature/index.html)。
画面構成を参考にし、背景・人物・コードはプロジェクト独自のものを使用。

## 前版の実装・検証記録

21日チャレンジの表示、初回説明、未使用の目標定数を削除。今日・累計時間と連続記録は継続。

深緑とアンティークゴールド、二重の装飾枠、羊皮紙パネル、独自の下部メニューを採用。
ホーム・集中画面に背景画を同梱。キャラクターの能力値は羊皮紙のタイルで表示。
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

## 明昼ファンタジーUI v2（2026-10-05）

添付6画面を雰囲気の参考とし、深緑中心の画面から、青空・白い城・濃紺・アンティークゴールドを主軸に再設計。
ホーム、集中、キャラクター、召喚、設定、横画面戦闘へ共通の装飾枠・配色・背景を適用した。文字・ボタン・ステータスは画像へ焼き込まずFlutterで描画する。

画像生成には組み込みimagegenを使用。生成物は以下へ保存した。

- `mobile/assets/images/ui/sunlit_kingdom.png`: 縦長の白亜城・渓谷・遺跡背景。人物、文字、UIなし。
- `mobile/assets/images/ui/sunlit_battlefield.png`: 16:9の草原・遺跡・遠景城の戦闘背景。人物、敵、文字、UIなし。
- `mobile/assets/images/ui/hero_swordsman.png`: 青い外套と白い服のオリジナル剣士立ち絵。透過背景。

共通プロンプト方針: premium Japanese mobile RPG illustration, painterly anime fantasy, cobalt blue / ivory stone / antique gold, original world and composition, no text, no logo, no watermark. 背景はライブUI用の余白を確保し、添付作品の固有構図やキャラクターを複製しない。

検証結果: `flutter analyze --no-pub` 問題なし、全31テスト成功、Android debug APK生成・TB373FUへの上書きインストール成功。実機は通知シェード／ロック状態のため、最終スクリーンショット確認は解除後に行う。

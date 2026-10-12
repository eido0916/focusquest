# 初回職業決定画面 v001

参照画像に合わせた大聖堂・青金装飾・羊皮紙の画面。Flutter本体の初回診断結果へ接続しています。

- materials/: 個別PNG素材8点。背景、人物カード、会話枠、青金ボタン、魔法石の名前札、案内枠、本、強みの帯。
- source/: 内蔵image_genの生成原本。既存の立ち絵は生成・上書きしていません。
- previews/: Flutter画面の実描画。男女16職の既存透過立ち絵を使用。
- role-codes.json: ユーザー指定の16職のコード。D/S・F/H・I/T・R/Vの4軸から算出します。
- prompt-set.json: 内蔵image_genの素材別制作指示。
- reference.png: ユーザー指定の参考画像。
- manifest.json / asset-sheet.jpg: 素材寸法と一覧。

文字はすべてSunlitSerif（Noto Serif JP）の明朝体で画面側に配置。名前、職業名、コード、説明、強みは診断データから反映します。「冒険に進む」で保存後にホームへ移動し、「答えを見直す」で回答へ戻ります。保存中は二重操作を防ぎ、保存失敗時は再試行できます。小画面と横画面はスクロール可能です。

コードはユーザー提供の確定対応表に従います。第1軸 D/S（突破型/洞察型）、第2軸 F/H（テンポ型/集中型）、第3軸 I/T（自立型/連携型）、第4軸 R/V（実践型/創造型）。剣士DFIR、侍SHIR、魔法使いSHTV。判定はQ1〜3・Q4〜6の多数決、Q7とQ9・Q8とQ10の重み1:2で、既存の質問と職業判定は変更していません。

実装: mobile/lib/features/diagnosis/presentation/job_reveal_screen.dart。ゲームで使う素材はmobile/assets/images/diagnosis/job_reveal_v001/。元イラストと以前の制作素材は保持しています。

検証は英数字パスの独立コピーを使用し、容量を抑えるため当該画面に必要な素材のみを検証用pubspecへ登録しています。本体のpubspecには既存素材を残し、この素材フォルダーを追加しています。Android arm64用のFocusQuest-job-reveal-v001-debug.apkを作成しました。端末へのインストールは未実施です。

検証結果: 職業コード16件の一意性、既存立ち絵32件、4画面サイズでの表示・ボタン操作、診断から保存後ホームへの遷移、全1024回答パターンを含む24テストが成功しました。
変更した診断画面・診断ドメイン・表示テストの静的解析はNo issues found。全体解析には今回の変更外のfocus_chapter_visual_test.dartに既存のconstに関するinfoが2件残っています。

追加確認: 全16職×男女32画面の実描画・ボタン操作テストが成功。合計56テストが通過し、バーサーカー等の長い職業名も一行で表示します。男女別の一覧はmale-all-roles.jpg / female-all-roles.jpg。

APK検証: UI素材8点・立ち絵32点・明朝体フォント1点の計41点がSHA-256で元ファイルと一致し、arm64のみを含む有効なAndroid Debug署名を確認しました。診断画面関連ソース4件は作業ソースとビルド用コピーで一致。Flutterツールは生成済みAPKのハッシュ計算でメモリ不足になりましたが、生成済みAPKをストリーム処理で検証・保存しました。詳細はandroid-verification.jsonとandroid-recovery.json。

容量確保のため、完了済みの古いビルド4件のbuild/app/intermediatesと今回の不要な一時ファイルを整理しました。各ビルドのソースと完成APK、プロジェクトの元素材は保持しています。

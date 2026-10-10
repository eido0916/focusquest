# FocusQuest / FQ

character_01で挑む [Flutter版プレイアブルステージ](docs/PLAYABLE_STAGE.md) は全16ステージです。1〜4は草原、5〜8は幽霊船、9〜12は火山、13〜16は魔王城。4・8・12・16の最終フェーズにボスが登場し、クリア後はステージ選択へ戻ります。各フェーズは複数の敵と戦い、ボスはプレイヤーの3倍の表示サイズです。デモ専用の男女20キャラクター選択とステータス棒グラフ、素早さによる行動間隔、赤・青の丸ボタン、命中・クリティカル判定、戦闘BGM・効果音に対応しています。アプリの冒険画面から「ステージを選ぶ」を開くか、`mobile/lib/main_playable_stage.dart` で直接起動できます。以前の [ブラウザ版](playable-demo/README.md) も制作履歴として保持しています。

キャラクター・敵の現行原画素材（v012）、v001〜v011の制作履歴、4種類のステージ背景は [制作素材一覧](art/workspace_materials/README.md) を参照してください。弓・銃・魔法・手裏剣は配置位置から発射し、飛び道具の着弾時にダメージを判定します。制作方針は [AGENTS.md](AGENTS.md) に記録しています。

集中した時間が、冒険と成長に変わるAndroid向けRPG。

## 現在の構成

Flutter本体は **mobile/**。2026-10-03の方針変更により、ログインとFirebase同期は後回しにし、端末内保存でゲームループを実装しています。アプリ削除／データ消去では記録も削除されます。

- 初回は老王と魔法石の導入シーン → ホワイトアウト → 名前・見た目（男／女） → 10問の二択診断（5問ずつ） → 16職の結果・職業イラスト → 冒険に進む → ホーム。黒地・白枠の会話を一文字ずつ表示し、会話枠タップで全文表示、魔法石タップで光の演出から診断へ進みます。
- 15 / 30 / 45 / 60分、または1〜180分の集中。終了日時基準でバックグラウンドから復帰。
- 集中成功でEXPを獲得。日別記録、連続・最長日数。
- 黒地・白枠の会話窓とコマンド選択、王国や森の背景を使った王道RPG風UI。21日チャレンジは削除。
- 集中はタイマーとEXP獲得。開始時に戦闘演出を表示し、タイマーとの切り替えが可能。演出の討伐数やダメージは報酬・冒険の進行に影響しない。
- 独立した「冒険」で5ステージを攻略。成長・装備を反映した自動戦闘、HP・勝敗判定、最終ステージのボス。
- ステージ初回クリアでポイントと装備、次のステージを解放。敗北で所持品は減らず、挑戦時はHP全回復。
- 冒険開始時のステータス・乱数シード・開始時刻を保存し、再起動後も同じ戦闘を復元。初回報酬の重複受取りを防止。
- レベルアップ、装備、仲間編成、1回／10回召喚、N / R / SR / SSR、排出率表示、召喚履歴。
- Android UsageStatsの任意連携。対象アプリ選択、許可状態表示、タイマーのみでの利用。
- 端末内JSON保存。書込みを直列化し、一時ファイルへflush後に置換。セッションIDで報酬重複を防止。
- 保存失敗時の再試行。破損した保存データを勝手に初期化しません。

ルートのHTML/CSS/JSは以前の簡易Webタイマーであり、Android本体ではありません。
実機上での権限・画面オフ・端末再起動の検証は、接続したAndroid端末で別途行います。

## 開発環境

現在検証している組合せ:
- Flutter 3.24.3 / Dart 3.5.3
- Flame 1.18.0 / path_provider 2.1.3（pubspec.lockを共有）
- Java 17、Android SDK、Gradle 8.3
- VS Code + Flutter / Dart拡張

このPCではFlutterが `%USERPROFILE%\FocusQuestTools\flutter`、
Java / Android SDKも `%USERPROFILE%\FocusQuestTools\` 配下です。
Flutterに `flutter config --android-sdk ... --jdk-dir ...` で登録済みです。
Android Studio・エミュレーターは導入していません。

PowerShell:

```powershell
$env:Path = "$env:USERPROFILE\FocusQuestTools\flutter\bin;" + $env:Path
cd mobile
flutter pub get
flutter analyze --no-pub
flutter test --no-pub
flutter devices
flutter run
```

初回取得済みなら `flutter pub get --offline` も利用できます。
日本語を含むWindowsパスではFlutter 3.24のシェーダーコンパイラがクラッシュするため、
このPCでは後述のビルドスクリプトを使ってください。
ソースを保持したまま英数字パスへコピーしてビルドします。

## Android実機とAPK

端末側で開発者向けオプション・USBデバッグを有効化し、PC接続の許可を操作してください。
`flutter devices` に出た実機を指定して `flutter run -d <device-id>` を実行できます。

```powershell
flutter build apk --debug --target-platform android-arm64
```

生成先は `mobile/build/app/outputs/flutter-apk/app-debug.apk`。
これはarm64実機向けの開発用APKです。ストア配布用署名は設定していません。
旧32bit端末は `--target-platform android-arm` を指定します。

このリポジトリのWindows環境では、ルートで以下を実行します。

```powershell
.\scripts\build-android.ps1
```

成果物: `output/android/FocusQuest-debug.apk`。
ビルド用コピーは `%LOCALAPPDATA%\FocusQuestTools\build\fq-日時` に保持します。
スクリプトが表示するビルド用フォルダへ移動し `flutter run` を実行することもできます。
ビルド後にソースを変更した場合は再実行して最新APKを生成してください。

通常起動: `lib/main.dart`。初回に診断、次回以降はホーム。
保存なしの診断確認用: `flutter run -t lib/main_preview.dart`。
VS Codeの実行構成にも両方を登録しています。

## 使用状況確認

「その他」で対象アプリを選択 → Androidの使用状況設定でアクセス許可 → 確認スイッチON。
確認機能をOFFにすれば権限なしでタイマーのみ使えます。

確認ONの集中では、開始〜終了の区間に対象アプリが使われた場合は未達成。
権限取消や観測不能も報酬対象にしません。アプリの強制終了や操作ブロックは行いません。
UsageStatsは端末内で判定し、外部へ送信しません。
端末メーカーやOSによるイベント取得差は実機で確認してください。
端末時計の意図的変更に対する不正防止は、将来サーバー連携時の課題です。

## 構成と担当の分け方

```text
mobile/lib/
  app.dart                      # 起動分岐と下部Navigation
  core/
    game_controller.dart        # コマンド・保存と画面更新の調整
    config/                     # EXP、報酬、確率など
    assets/                     # Assetキーと状態
    theme/                      # ThemeData
    widgets/                    # 共通カード・キャラクター表示
  data/                         # カタログ、PlayerState、Repository
  features/
    auth/                       # A: 保留中の認証UI・インターフェース
    diagnosis/                  # A: 診断・オンボーディング
    focus/                      # B: 集中・履歴・報酬・ネイティブ連携
    character/                  # C: 成長・装備
    adventure/                  # ステージ、勝敗、報酬、ドット絵の冒険画面
    gacha/                      # C: 抽選・演出・結果
    home/                       # B: ホーム・継続状況
    settings/                   # B: 使用状況設定・履歴
  game/runner/                  # 集中中のFlame戦闘演出
mobile/test/                    # 単体・永続化・画面操作テスト
mobile/android/                 # Kotlin / Android設定
docs/IMPLEMENTATION.md          # 実装計画・検証結果
```

状態管理はFlutter標準のChangeNotifierに統一しています。
UIはRepositoryへ直接アクセスせず、GameControllerを経由します。

## Firebase（後続工程）

ログイン・クラウド同期・Storageは今回の利用条件では必須にしていません。
AuthRepository / PlayerRepositoryを置き換え、既存のローカルデータを移行できるようにします。

接続時の作業:
1. Firebaseに `dev.focusquest.focusquest` を登録し、メール／パスワード認証とFirestoreを設定。
2. SDK互換性を確認し、firebase_core / firebase_auth / cloud_firestore / firebase_storageを追加。
3. FlutterFire CLIの `flutterfire configure --platforms=android` でFirebaseOptionsを生成。
4. 所有者だけがアクセスできるルールを設定し、Emulatorで検証。
5. 起動時の認証、ローカルデータ移行・競合処理・同期を接続。

Firestoreは `users/{uid}` 配下にcharacters / focusSessions / inventory / gachaHistoryを想定。
端末内PlayerState全体を1ドキュメントに詰めず、履歴を分割・ページングします。
毎秒タイマー更新では通信しません。抽選は再試行で変わらない操作IDと結果を使用します。
秘密鍵・署名鍵・パスワードはGitへ含めません。

公式設定手順: https://firebase.google.com/docs/flutter/setup

## Asset差替え

現在は図形とアイコンのPlaceholderです。画像は
`core/assets/asset_catalog.dart` のキーに対してパスを設定します。
画像パスは `mobile/assets/images/` からの相対パスです。
実ファイルとpubspec.yamlのassets登録を追加してください。

例えば `hero.warrior` に `warrior.png` を指定するとUIとFlameに反映されます。
戦闘は `hero.warrior.idle / attack / damage / death` の個別画像を優先し、共通画像へフォールバックします。
存在しない素材はPlaceholderのまま表示します。
Sprite SheetはActorPoseごとのSpriteAnimationへ拡張する境界を設けています。
本番アート、音声、映像制作は別工程です。

職業・質問・装備・排出候補は `data/game_catalog.dart`。
診断は4軸16職。Q1〜3、Q4〜6の多数決、Q7・Q9とQ8・Q10は後者を2点として判定します。名前と見た目は端末内に保存し、旧データの見た目は男として読み込みます。立ち絵は提供された男性16職の個別画像と女性16職の一覧画像を使い、結果・ホーム・キャラクター画面に見た目に応じて反映します。原画像は `art/role_portraits/source/` に保持し、`scripts/build-role-portraits.py`（Pillow）で女性版の切り出しと表示用WebP32枚を再生成できます。元画像の背景と職名表記は保持しています。
バランスは `core/config/game_balance.dart` と各サービスで調整します。

## Git運用

機能ごとにfeatureブランチを作成し、PRに変更理由とanalyze / testの結果を記載してください。
pubspec.lockはコミット対象。build / .dart_tool / local.propertiesは対象外です。
リポジトリには別件のPowerPoint・画像もあるため、addする対象を指定してください。
今回の作業ではまだコミット・pushしていません。

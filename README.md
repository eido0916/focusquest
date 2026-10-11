# FocusQuest / FQ

キャラクター・敵の現行原画素材（v010）、v001〜v009の制作履歴、草原のプレイアブルステージ背景は [制作素材一覧](art/workspace_materials/README.md) を参照してください。制作方針は [AGENTS.md](AGENTS.md) に記録しています。

集中した時間が、冒険と成長に変わるAndroid向けRPG。

## 現在の構成

Flutter本体は **mobile/**。2026-10-03の方針変更により、ログインとFirebase同期は後回しにし、端末内保存でゲームループを実装しています。アプリ削除／データ消去では記録も削除されます。

- 初回は老王と魔法石の導入シーン → ホワイトアウト → 名前・見た目（男／女） → 10問の二択診断（5問ずつ） → 16職の結果・職業イラスト → 冒険に進む → ホーム。黒地・白枠の会話を一文字ずつ表示し、会話枠タップで全文表示、魔法石タップで光の演出から診断へ進みます。
- 15 / 30 / 45 / 60分、または1〜180分の集中。終了日時基準でバックグラウンドから復帰。
- 集中成功でEXPを獲得。日別記録、連続・最長日数。
- 黒地・白枠の会話窓とコマンド選択、王国や森の背景を使った王道RPG風UI。21日チャレンジは削除。
- 集中はタイマーとEXP獲得。開始時に戦闘演出を表示し、タイマーとの切り替えが可能。演出の討伐数やダメージは報酬・冒険の進行に影響しない。
- 集中画面から最大4人のオンラインパーティーを作成し、6文字のコードで参加。全員の準備後に同じ時刻で開始し、左にメンバー・右に人数分の敵を表示。公開サーバーの設定が必要です。接続・公開手順は [パーティー機能](docs/PARTY.md) を参照。
- 独立した「冒険」で5ステージを攻略。成長・装備を反映した自動戦闘、HP・勝敗判定、最終ステージのボス。
- ステージ初回クリアでポイントと装備、次のステージを解放。敗北で所持品は減らず、挑戦時はHP全回復。
- 冒険開始時のステータス・乱数シード・開始時刻を保存し、再起動後も同じ戦闘を復元。初回報酬の重複受取りを防止。
- レベルアップ、装備、仲間編成。下部メニューはホーム／キャラクター／設定／冒険の4項目。
- 2026-10-10: ガチャ（召喚）の画面・抽選・専用設定・履歴管理を削除。旧保存データのキャラクター・装備・ポイントは引き継ぎ、旧召喚履歴は読み飛ばします。
- Android集中中のアプリ警告。Focus Quest以外のアプリに警告を表示し、戻る／1分だけ使用するを選択。
- 端末内JSON保存。書込みを直列化し、一時ファイルへflush後に置換。セッションIDで報酬重複を防止。
- 保存失敗時の再試行。破損した保存データを勝手に初期化しません。

ルートのHTML/CSS/JSは以前の簡易Webタイマーであり、Android本体ではありません。
実機上での権限・画面オフ・端末再起動の検証は、接続したAndroid端末で別途行います。

## 開発環境

現在検証している組合せ:
- Flutter 3.24.3 / Dart 3.5.3（既存SDKを再利用）
- Flame 1.18.0 / path_provider 2.1.3（pubspec.lockを共有）
- Java 17、Android SDK、Gradle 8.3
- VS Code + Flutter / Dart拡張

このPCではFlutterが `C:\src\flutter`、
Java / Android SDKは `%LOCALAPPDATA%\FocusQuestTools\` 配下です。
Flutterに `flutter config --android-sdk ... --jdk-dir ...` で登録済みです。
Android Studio・エミュレーターは導入していません。

PowerShell:

```powershell
$env:Path = "C:\src\flutter\bin;" + $env:Path
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

## 集中中のアプリ警告

集中開始後にFocus Quest以外のアプリを開くと、他アプリ上に警告を表示します。
警告のボタンは「Focus Questに戻る」「1分だけ使用する」の2つです。
1分の許可は押した時点から60秒間、選んだアプリだけに適用します。別のアプリを開くと警告し、60秒後も使用中なら再び警告します。集中タイマーは進み続け、警告や一時使用だけで未達成にはしません。
ホーム画面・システムUI・ロック画面・画面オフでは警告しません。集中終了時・中断時に警告と常駐監視を停止します。

初回の集中開始時にAndroidの「使用状況へのアクセス」「他のアプリの上に表示」の許可へ順に案内します。
各設定から戻って「集中を開始」を押し、両方を許可した後に集中が開始されます。設定画面からも権限を変更できます。
監視中は常駐通知を表示し、使用状況は端末内だけで処理します。アプリ再起動時は保存済みの集中終了日時から監視を再開します。

新規集中では旧「選択アプリ使用で未達成」の設定を使いません。更新前に開始した使用状況確認セッションの結果判定は維持します。
OSによる強制停止や端末再起動後は、Focus Questを開くまで監視を再開できません。メーカーによるバックグラウンド制限・他アプリ側のオーバーレイ非表示指定などは実機検証が必要です。

## 構成と担当の分け方

```text
mobile/lib/
  app.dart                      # 起動分岐と下部Navigation
  core/
    game_controller.dart        # コマンド・保存と画面更新の調整
    config/                     # EXP、報酬など
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

Firestoreは `users/{uid}` 配下にcharacters / focusSessions / inventoryを想定。
端末内PlayerState全体を1ドキュメントに詰めず、履歴を分割・ページングします。
毎秒タイマー更新では通信しません。
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

職業・質問・装備は `data/game_catalog.dart`。
診断は4軸16職。Q1〜3、Q4〜6の多数決、Q7・Q9とQ8・Q10は後者を2点として判定します。名前と見た目は端末内に保存し、旧データの見た目は男として読み込みます。立ち絵は提供された男性16職の個別画像と女性16職の一覧画像を使い、結果・ホーム・キャラクター画面に見た目に応じて反映します。原画像は `art/role_portraits/source/` に保持し、`scripts/build-role-portraits.py`（Pillow）で女性版の切り出しと表示用WebP32枚を再生成できます。元画像の背景と職名表記は保持しています。
バランスは `core/config/game_balance.dart` と各サービスで調整します。

## Git運用

機能ごとにfeatureブランチを作成し、PRに変更理由とanalyze / testの結果を記載してください。
pubspec.lockはコミット対象。build / .dart_tool / local.propertiesは対象外です。
リポジトリには別件のPowerPoint・画像もあるため、addする対象を指定してください。
今回の作業ではまだコミット・pushしていません。

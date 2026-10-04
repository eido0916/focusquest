# FocusQuest / FQ

集中した時間が、冒険と成長に変わるAndroid向けRPG。

## 現在の構成

Flutter本体は **mobile/**。2026-10-03の方針変更により、ログインとFirebase同期は後回しにし、端末内保存でゲームループを実装しています。アプリ削除／データ消去では記録も削除されます。

- 初回説明 → 性格診断 → 初期職業 → チュートリアル → ホーム。
- 15 / 30 / 45 / 60分、または1〜180分の集中。終了日時基準でバックグラウンドから復帰。
- EXP、ポイント、アイテム抽選、冒険進行度、日別記録、連続・最長日数。
- 深緑と金、羊皮紙のパネル、森の背景を使ったファンタジーUI。21日チャレンジは削除。
- Flame自動戦闘。攻撃前進、ダメージ数字、Idle / Attack / Damage / Death、勝敗とドロップ。
- 進行度5で1戦。勝利後は残量があれば連戦。画面を離れると停止し、再表示時は保存済みの敵との戦闘を最初から再現。
- レベルアップ、装備、仲間編成、1回／10回召喚、N / R / SR / SSR、排出率表示、召喚履歴。
- Android UsageStatsの任意連携。対象アプリ選択、許可状態表示、タイマーのみでの利用。
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
    gacha/                      # C: 抽選・演出・結果
    home/                       # B: ホーム・継続状況
    adventure/                  # D: 冒険画面
    settings/                   # B: 使用状況設定・履歴
  game/                         # D: Flame描画と純粋Dart戦闘
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
診断は2軸4タイプ。4軸16タイプへデータとaxis設定で拡張できます。
バランスは `core/config/game_balance.dart` と各サービスで調整します。

## Git運用

機能ごとにfeatureブランチを作成し、PRに変更理由とanalyze / testの結果を記載してください。
pubspec.lockはコミット対象。build / .dart_tool / local.propertiesは対象外です。
リポジトリには別件のPowerPoint・画像もあるため、addする対象を指定してください。
今回の作業ではまだコミット・pushしていません。

# 女弓使いの走行通常攻撃（Flutter / Flame 1.18.0）

添付PNGを使った実装。新しい原画や中間画像は生成していません。既存の男性・女性剣士・拳闘士・v010素材には変更を加えていません。

## 素材と採用列

画像の添付順ではなく、ファイル名の時刻順に番号を付けました。キャラクター9枚×5＝45候補、最後は矢8本です。キャラクター画像の `source_01`〜`source_09` は16:20:46、16:20:55、16:21:02、16:21:08、16:21:17、16:21:25、16:21:35、16:21:45、16:21:53の順です。`source_10` は16:22:01の矢です。

採用32枚（1始まり）：

```text
1,2,3,5,6,7,8,9,10,13,14,21,22,24,25,26,27,29,30,31,
32,33,34,35,36,37,39,40,41,42,44,45
```

除外：4,11,12,15,16,17,18,19,20,23,28,38,43。各候補の理由と秒数は `artifacts/female_archer_attack_review/frame_review.md`。11・12は引きが逆戻りし、19・20は再装填、15〜18は別の発射列です。23は飛翔矢が焼き込まれています。14→21→22→24を「発射直前→解放→反動」として保持しています。

設定は `mobile/assets/images/characters/female_archer/normal_attack/selection.json`。1〜5の採用走行は各1tick、6〜14の採用構え・装填・引きは各2tick、21は3tick、その後は各1tick。1tick＝1/24秒。全体41tick＝1.708333秒、発射は21tick＝0.875秒のフレーム22入りです。走行の遷移先は41,42,44,45の4枚で各2tick。

## 切り出しと画素の保存

```powershell
# Python + Pillow + numpy が必要。
python scripts/build-female-archer-attack.py --source-dir 'C:/Users/eido0/Downloads'
```

元ファイルを `source_01.png`〜`source_10.png` としてバイトコピーし、単純5等分の45枚を `raw_*.png` に出力します。2172pxは5で割り切れないため、境界を整数に丸めています。実画像は弓・矢・マントが等幅境界をまたぐため、ゲーム用は透明部分を優先する行ごとの境界で分離します。23の飛翔矢が24の領域に入る箇所には明示的な境界指定があります。全45候補の切り出しは `isolated_*.png`、座標は `extraction.json`、隣接差分の参考値は `adjacent_frame_metrics.json`。

腰の整数座標と足元を共通キャンバス638×766pxに配置します。回転・伸縮・リサイズ・補間・色変更はしません。元画像の隠れている輪郭を復元する処理もありません。今回の素材は128pxのドット絵ではないため、128pxへ縮小せず原寸の画素を保持しています。元画像にある微小な色付き縁や透明度も保持します。

採用原画は `frame_*.png`。4列×4行のアトラス2枚は `normal_attack.png` と `normal_attack_02.png`（各2552×3064px）。24fps連番は `artifacts/female_archer_attack_review/24fps/` に41枚あり、RGBAバイトが対応原画と完全一致することを生成時に検証します。`timeline_24fps.json` は保持原画、画素ハッシュ、標準速度でのワールド座標、発射イベントを含みます。プレビューGIFと原画一覧PNGも同フォルダーです。

## 組み込み

`FemaleArcherAttackAssets.load(game)` がアトラスを `Map<int, Sprite>` に分割し、使用番号・保持時間を読み込みます。`loadSourceCandidates(game)` は元画像の5等分45枚を確認用に返します。`attackAnimation()` は通常の非ループSpriteAnimationとしても使えます。

```dart
final assets = await FemaleArcherAttackAssets.load(this);
final archer = FemaleArcherAttackComponent(
  assets: assets,
  position: Vector2(450, 820), // 腰x・足元y。同じ親の座標系
  runSpeed: 120,
  arrowSpeed: 1000,
  arrowLifetime: 1.2,
  onShot: (event) {
    // 発射時の位置 event.position で効果音などを再生する。
    // ダメージはプロジェクタイルの命中判定で適用する。
  },
);
await add(archer);
archer.playNormalAttack(); // 攻撃中の再入力は false
```

必要なimportは `package:flame/components.dart`、`female_archer_attack_assets.dart`、`female_archer_attack_component.dart`。pubspecには素材ディレクトリを登録済みです。

`ArcherAttackAnimationController` は時間をフレーム境界ごとに進め、発射位置までの移動を先に適用します。発射イベントは1回だけで、大きなdtでも抜けません。`ArcherArrowProjectile` はキャラクターと同じ親に追加され、残りdtぶん進んでからマウントされます。右向き・水平固定、寿命で削除します。矢は8候補のうち水平な1枚だけを使用しています。

既存の衝突システムで矢を管理する場合は `spawnProjectiles: false` とし、`onShot` で生成してください。その場合は `event.remainingSeconds` を使ってその更新の残り時間を進めます。自動生成と独自生成を同時に有効にすると矢が2本になります。命中判定・ダメージ量はこのサンプルには含まれません。

通常はワールド位置を右へ進めます。画面固定ランナーでは `onAdvance: (distance) => scrollWorld(distance)` を渡すと、キャラクターの位置を固定して背景・敵を進められます。区間別速度は `speedRatios` で変更でき、標準は走行1、構え.65、装填.4、引き.15、発射.15、反動.2、戻り.45、再加速.8です。射撃部分の脚は元画像で接地姿勢なので、全フレームで走る脚運びにはできません。小さく減速して射撃し再加速する見え方にしています。

終了後は走行へ戻り、余ったdtも走行へ適用します。`returnAnimation` で同じサイズ・アンカーのidle/runを指定できます。`cancelAttack()` は発射前なら矢を出さず走行に戻します。整数倍での表示、`FilterQuality.none` を使用してください。コンポーネント自身の反転・回転・サイズ変更は行っていません。

## 実行と検証

```powershell
cd mobile
flutter run -d windows -t lib/main_archer_preview.dart
flutter test test/female_archer_attack_test.dart
```

プレビューは1280×900の原寸スクロール領域で、ボタンから何度でも1射を再生できます。`FemaleArcherDemoGame` が組み込み例です。既存の戦闘画面は剣士と拳闘士のスキル・ダメージ制御に依存するため、今回の素材を自動で職業選択へ接続する変更はしていません。

テストは実素材のロード、二重攻撃防止、発射境界、240Hzと大きなdtの一致、矢の生成位置・寿命、キャンセル、走行復帰を確認します。

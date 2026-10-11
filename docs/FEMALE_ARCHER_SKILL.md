# 女弓使い・走行高威力スキル

添付9枚×5コマ＝45候補を全て読み込み、35コマへ整理しました。既存の通常攻撃・v010原画・元画像は上書きしていません。新規描画、パーツ変形、補間、画像のリサイズはありません。添付は通常のイラストなので、128pxへ縮小せずネイティブ画素を548×781pxの共通透過キャンバスへ配置しています。

## 採用順と選別

番号は添付の時刻順、各画像の左から右、1始まりです。

`1,2,3,4,5,6,7,8,9,11,10,12,14,16,18,19,21,22,23,24,25,26,27,28,29,30,31,32,34,36,38,39,41,44,45`

除外：`13,15,17,20,33,35,37,40,42,43`。

13・15・17は引き絞り／照準の類似姿勢、20は右端で切れた飛翔矢を含むため、残りは終盤の重複した走りを削っています。10は11より深く引いているので、9→11→10→12へ順序を修正しました。全45候補の個別理由は `artifacts/female_archer_skill_review/frame_review.md` に記載しています。完全一致の重複という意味ではなく、ポーズとテンポを目視で比較した選別です。

構成：1–3走り、4–5減速、6–9装填／構え、11→10→12→14引き、16→18照準、19発射、21→22反動、23–26戻り、27–31加速、その後は走行復帰。

表示時間は24Hzの整数tick：走り／減速／発射／加速は1tick、装填／引き／反動／戻りは2tick、照準は3tick。53tick＝2.208333秒、発射は27tick＝1.125秒。一発だけで、3連射スキルとは別素材です。

## 素材

- `mobile/assets/images/characters/female_archer/skill/skill.json`：採用順、保持時間、区間、発射、移動速度、アトラス配置。
- `skill_01.png`～`skill_03.png`：4096px以内の分割アトラス。
- `artifacts/female_archer_skill_review/candidates/`：指定どおりの5等分45候補。2172pxは5で割り切れないので、境界を丸めて434/435px幅で切り出しています。
- 同フォルダーの `frame_01.png`～`frame_45.png`：共通サイズに整えた全候補、`isolated/`：分離原画、`source_*.png`：元画像の保存コピー。
- `24fps/` と `timeline_24fps.json`：原画の複製53枚とワールド座標・発射イベント。
- `contact_sheet.png`、`skill_preview.gif`：採否一覧と、スキル→走り2周のプレビュー。

弓・マントが等分境界を越えているため、再生用は元画像のアルファが最小になる境界で分離し、整数の腰・足元アンカーへ配置しています。画素は変更していません。ただし元画像で隣の絵に隠れている部分や画像端で切れた部分は復元していません。ソースの縁の色や描き込みの揺れも保持しています。画像に元からある接地姿勢を、走る脚へ描き変えていません。

## Flameへ組み込み

Flame 1.18.0で使用。素材のpubspec登録済みです。

```dart
import 'package:flame/components.dart';
import 'female_archer_skill_assets.dart';
import 'female_archer_skill_component.dart';

final assets = await FemaleArcherSkillAssets.load(this);
final archer = FemaleArcherSkillComponent(
  assets: assets,
  position: Vector2(450, 820), // 腰x／接地y
  runSpeed: 120,
  onShot: (event) {
    // 高威力の一射のゲームイベント。発射1回につき1回だけ呼ばれる。
    // event.position: 同じ親の座標系での矢の発射位置。
    // event.remainingSeconds: このupdateの残り時間。
    // 衝突用の矢は同じ親へ追加し、残り時間を進める。
  },
);
await add(archer);
archer.playSkill(); // 使用中の再入力はfalse
```

`assets.skillAnimation()` は可変表示時間・非ループの `SpriteAnimation` を返します。`assets.frames` は元番号→Spriteのframe listとして利用できます。コンポーネントは共通の `ArcherAttackAnimationController` を用い、大きなdtでも発射を飛ばさず、終了後の余剰時間を走りへ適用します。

元19番には矢が離れ始める絵が含まれます。コンポーネントは添付の風の矢エフェクトを自動生成します。`onShot` はゲーム側の発射・衝突処理の接続点です。可視の矢を追加する場合は、元19番の矢と二重表示にならないようにしてください。命中判定や高威力の倍率はゲーム側の設定へ接続してください。

射撃中も移動倍率をゼロにせず、走行1→構え.8→装填.55→引き.35→照準／発射.3→反動.35→戻り.55→加速.85→走行1としています。元絵の射撃部分は足を接地した姿勢なので、減速しながら撃つ表現です。常時走る脚運びはこの原画だけでは表せません。

画面固定のランナーでは `onAdvance: (d) => scrollWorld(d)` を渡すと、世界を移動させられます。通常走りの接続は `returnAnimation` で差し替え可能です。サイズ・腰／足元アンカーを合わせてください。既定ループは `41,44,45,1,2,3,4,5`、スキル最終45から41へ戻ります。`cancelSkill()` は発射前なら射撃せず走りへ戻ります。右向き固定、角度0、サイズ固定、FilterQuality.none。拡大するなら整数倍で表示してください。

保持やフレーム切替については [Flame公式SpriteAnimation資料](https://github.com/flame-engine/flame/blob/main/doc/flame/components/sprite_components.md) を参照。

## 実行

```powershell
cd mobile
C:/flutter/bin/flutter.bat run -d windows -t lib/main_archer_skill_preview.dart
C:/flutter/bin/flutter.bat test test/female_archer_skill_test.dart test/female_archer_attack_test.dart
```

専用プレビュー画面にはスキル発動ボタンと移動する地面があります。本番バトルのスキル条件・ダメージルールは変更していません。

再生成：`scripts/build-female-archer-skill.py`（Pillow / numpy）。24fps連番と対応原画のRGBA完全一致、アトラスの切り出し一致、ソースSHA256は `verification.json` と `skill.json` へ保存します。


## 風の矢エフェクト（追加）

添付「風の矢エフェクト連続スプライト.png」を8つの幅の異なる原画へ分け、318×245pxの共通透過キャンバスに元画素のまま配置しました。`wind_arrow.png` は横8コマのアトラスです。元画像は `artifacts/female_archer_wind_review/source.png` に保持しています。再生成は `scripts/build-female-archer-wind.py`。

`FemaleArcherSkillComponent` は発射イベント（1.125秒）で `ArcherWindArrowComponent` を同じ親へ1個だけ追加します。弓先の座標（腰x+130、接地y-330）を発生中心として、右へ1000px/秒で飛行します。8原画を24Hzで切り替え、最後の原画を保持して画面右端まで飛ばします。拡大・変形・補間・フェードは行いません。エフェクト全体が右端を抜けると削除します。長いupdateで発射を跨いだ場合も残りdtを適用します。

標準は現在のゲーム幅を右端として使用します。カメラで移動するワールドや異なる親座標を使用する場合は、`effectRightEdge: () => viewportRightInParentCoordinates` を渡してください。独自にエフェクトを管理する場合は `showWindEffect: false` にできます。`onShot` は従来どおり1回だけ発生します。

確認用：`artifacts/female_archer_wind_review/skill_wind_preview.gif`（半サイズ・最近傍表示）、`flame_preview.png`（実際のFlame描画）。発射位置、一個だけ生成、右方向の移動、高さ一定、画面外削除をスキルテストで確認しています。


## 本番画面での調整

風の矢の最初の2原画は各3tick（0.125秒）、残りは各2tickへ変更。最初の原画は弓先で保持してから、700px/秒で右へ移動します。本番のエフェクト表示倍率は.3→.45（1.5倍）、発生位置の補正にも同じ倍率を適用します。通常攻撃の24番以降は保持時間を2倍にし、通常走りループは1.5倍の時間で再生します。通常攻撃全体は60tick＝2.5秒、発射・ダメージ時刻は従来と同じです。

本番画面の発射境界で、浮動小数点誤差により負のdt（-1.11e-15）がエフェクトへ渡され、例外が出ることを再現しました。矢・風の矢の発射後経過時間を0以上へ補正しています。時計の追いつき処理も1描画更新につき120tickまでに分割し、大きな時計ジャンプで描画を長時間占有しないようにしています。完全に追いついた時点の戦闘結果は従来の一括再生と一致します。


## 距離による命中と通常弓射の貫通

女弓使いの本番用RunnerConfigは `archerProjectiles: true`。通常攻撃は矢1本につき近い順で最大2体へダメージを与えます。敵が1体しかいない場合は1体だけに命中し、HPの高い敵は通常のダメージ計算を維持します。スキルは風の矢の先端が届いてから各敵に1回ずつ命中します。飛翔はスキル終了後も継続し、敵の移動も考慮した判定で、遠い敵ほど遅れて倒れます。戦闘シミュレーションが命中とEXPを管理し、描画側から追加の報酬は発生させません。

通常攻撃前の1・2・3・5番を各2tickへ変更。全体は64tick、発射は25tickです。前の変更による攻撃後の脚運びと走りループの減速も維持しています。風の矢は最初6tick（0.25秒）、次4tick、残り各2tick。最初の原画は弓先で保持し、その後700px/秒で飛びます。弓先・初期先端位置・飛翔速度・保持時間は、描画とシミュレーションの共通タイミングを用います。

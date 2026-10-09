# 走り斬りスキル

既存の `HeroComponent` に組み込み済みです。6枚の元PNGをファイル名そのままで
`assets/images/characters/swordsman/skills/run_slash/` に配置しています。
元PNGを直接読み込み、画像幅÷5、高さそのままで左→右の5領域を順に連結します。

## Dartコード

- `run_slash_skill.dart`: 30フレームの速度、斬撃判定範囲、前進と復帰位置。
- `run_slash_assets.dart`: 元ファイル名の配列、Sprite読み込み、非ループSpriteAnimation。
- `hero_component.dart`: run / 通常攻撃 / 蒼閃 / 走り斬りの表示切り替え。
- `battle_state_controller.dart`: 自動発動、二度の単発ダメージ、HP・EXP連携。
- `focus_quest_battle_game.dart`: 非同期読み込みと既存戦闘への接続。

## 発動例

```dart
import 'package:focusquest/game/runner/battle_state_controller.dart';

// FQではデフォルトで10秒ごとに蒼閃を自動発動します。
final state = BattleStateController(durationSeconds: 25 * 60);

// 手動発動。再生中・集中終了後はfalseを返します。
final started = state.playRunSlashSkill();

// 既存の剣士コンポーネントを保持している場合にも呼べます。
// hero.playRunSlashSkill();

// 蒼閃の自動発動へ戻す場合。
final sousenState = BattleStateController(
  durationSeconds: 25 * 60,
  config: const RunnerConfig(autoSkill: SwordsmanSkill.sousen),
);
```

## 別のPlayerへ組み込む例

```dart
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:focusquest/game/runner/run_slash_assets.dart';
import 'package:focusquest/game/runner/run_slash_skill.dart';

Future<SpriteAnimationComponent> createRunSlashPlayer(FlameGame game) async {
  final assets = await RunSlashAssets.load(game);
  return SpriteAnimationComponent(
    animation: assets.animation.clone(),
    size: assets.frameSize.clone(),
    anchor: assets.anchor,
  );
}

// Playerのupdateで経過時間から現在のフレームと攻撃判定を取得できます。
bool hasSlashHitbox(double elapsed) =>
    RunSlashSkill.isAttackFrame(RunSlashSkill.frameAt(elapsed));
```

FQでは13フレーム目と25フレーム目の開始を攻撃タイミングとし、各斬撃を1回だけ
解決します。判定領域の有効範囲は11〜15、21〜25フレームです。
スキル中は画面内で48px前進し、最後の走行フレームで元の位置へ滑らかに復帰します。
前進距離と向きは `RunSlashSkill`、表示速度は `frameTimes` から変更できます。
この変更ではテスト・静的解析・端末上の確認を実施していません。

import 'dart:ui';

import 'package:flame/components.dart';

import 'battle_state_controller.dart';
import 'swordsman_run_attack_assets.dart';

enum SwordsmanAnimationState { idle, run, runAttack, skill, bossAttack }

/// The battle hero uses a state switch so idle/skill/boss animations can be
/// added without changing the combat simulation.
class HeroComponent extends SpriteAnimationComponent {
  HeroComponent(this.state, this.assets)
      : animationState = SwordsmanAnimationState.run,
        _seenAttackSerial = state.attackSerial,
        super(
          animation: assets.swordsmanRun.clone(),
          // Keep the waist anchor fixed; sword and cape extents must not move
          // the body or clip the widest two-slash poses.
          position: Vector2(345, 405),
          size: assets.frameSize,
          anchor: assets.anchor,
          priority: 5,
        );

  final BattleStateController state;
  final SwordsmanRunAttackAssets assets;

  SwordsmanAnimationState animationState;
  int _seenAttackSerial;
  bool _attackPlaying = false;

  @override
  void update(double dt) {
    if (_attackPlaying) {
      // Combat can resolve more enemies while a two-slash motion is playing.
      // Consume those serials instead of immediately restarting the animation.
      _seenAttackSerial = state.attackSerial;
      super.update(dt);
      if (animationTicker?.done() ?? false) {
        _playRun();
      }
      return;
    }

    if (state.attackSerial != _seenAttackSerial) {
      _seenAttackSerial = state.attackSerial;
      _playRunAttack();
    }
    super.update(dt);
  }

  void _playRunAttack() {
    animationState = SwordsmanAnimationState.runAttack;
    _attackPlaying = true;
    animation = assets.swordsmanRunAttack.clone();
    animationTicker?.reset();
  }

  void _playRun() {
    animationState = SwordsmanAnimationState.run;
    _attackPlaying = false;
    animation = assets.swordsmanRun.clone();
  }

  @override
  void render(Canvas canvas) {
    final foot = Offset(anchor.x * size.x, anchor.y * size.y + 4);
    canvas.drawOval(
      Rect.fromCenter(center: foot, width: 118, height: 13),
      Paint()..color = const Color(0x42000000),
    );
    super.render(canvas);
  }
}

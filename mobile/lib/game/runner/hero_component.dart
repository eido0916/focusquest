import 'dart:ui';

import 'package:flame/components.dart';

import 'battle_state_controller.dart';
import 'sousen_slash_effect_component.dart';
import 'swordsman_run_attack_assets.dart';
import 'swordsman_sousen_assets.dart';
import 'run_slash_assets.dart';
import 'run_slash_skill.dart';

enum SwordsmanAnimationState {
  idle,
  run,
  runAttack,
  skill,
  runSlash,
  bossAttack
}

/// The battle hero uses a state switch so idle/skill/boss animations can be
/// added without changing the combat simulation.
class HeroComponent extends SpriteAnimationComponent {
  HeroComponent(this.state, this.assets, this.sousenAssets, this.runSlashAssets)
      : animationState = SwordsmanAnimationState.run,
        _seenAttackSerial = state.attackSerial,
        _seenSkillSerial = state.skillSerial,
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
  final SwordsmanSousenAssets sousenAssets;
  final RunSlashAssets runSlashAssets;

  SwordsmanAnimationState animationState;
  int _seenAttackSerial;
  int _seenSkillSerial;
  bool _attackPlaying = false;
  bool _skillPlaying = false;
  bool _slashEffectShown = false;
  double _skillElapsed = 0;
  bool _runSlashPlaying = false;
  double _returnElapsed = 0;
  double _returnFromX = 345;

  bool playRunSlashSkill() => state.playRunSlashSkill();
  bool playNormalAttack() => state.playNormalAttack();

  int get currentRunSlashFrame => RunSlashSkill.frameAt(_skillElapsed);
  bool get isRunSlashAttackActive =>
      _runSlashPlaying && RunSlashSkill.isAttackFrame(currentRunSlashFrame);

  @override
  void update(double dt) {
    if (state.skillSerial != _seenSkillSerial) {
      _seenSkillSerial = state.skillSerial;
      _seenAttackSerial = state.attackSerial;
      if (state.activeSkill == SwordsmanSkill.runSlash) {
        _playRunSlash();
      } else {
        _playSousen();
      }
    }

    if (_skillPlaying) {
      _seenAttackSerial = state.attackSerial;
      _skillElapsed += dt;
      if (_runSlashPlaying) {
        position.x = 345 + state.runSlashSkill.offsetAt(_skillElapsed);
      }
      if (!_runSlashPlaying &&
          !_slashEffectShown &&
          _skillElapsed >= sousenAssets.damageTime.inMilliseconds / 1000) {
        _slashEffectShown = true;
        if (state.config.enableSousenEffect) {
          parent?.add(
            SousenSlashEffectComponent(
              impactPosition: Vector2(position.x + 112, position.y - 86),
            ),
          );
        }
      }
      super.update(dt);
      if (animationTicker?.done() ?? false) _playRun();
      return;
    }

    // Skill recovery runs smoothly back to the runner's screen anchor.
    if (_returnElapsed < .25) {
      _returnElapsed = (_returnElapsed + dt).clamp(0.0, .25);
      position.x = _returnFromX + (345 - _returnFromX) * (_returnElapsed / .25);
    }

    if (state.attackSerial != _seenAttackSerial) {
      _seenAttackSerial = state.attackSerial;
      _playRunAttack();
    }
    if (_attackPlaying) {
      super.update(dt);
      if (animationTicker?.done() ?? false) {
        _playRun();
      }
      return;
    }

    super.update(dt);
  }

  void _playRunAttack() {
    animationState = SwordsmanAnimationState.runAttack;
    _attackPlaying = true;
    animation = assets.swordsmanRunAttack.clone();
    animationTicker?.reset();
  }

  void _playSousen() {
    animationState = SwordsmanAnimationState.skill;
    _skillPlaying = true;
    _attackPlaying = false;
    _skillElapsed = 0;
    _slashEffectShown = false;
    _runSlashPlaying = false;
    size = sousenAssets.frameSize;
    anchor = sousenAssets.anchor;
    animation = sousenAssets.animation.clone();
    animationTicker?.reset();
  }

  void _playRunSlash() {
    animationState = SwordsmanAnimationState.runSlash;
    _skillPlaying = true;
    _runSlashPlaying = true;
    _attackPlaying = false;
    _skillElapsed = 0;
    size = runSlashAssets.frameSize;
    anchor = runSlashAssets.anchor;
    animation = runSlashAssets.animation.clone();
    animationTicker?.reset();
  }

  void _playRun() {
    animationState = SwordsmanAnimationState.run;
    _skillPlaying = false;
    _runSlashPlaying = false;
    _attackPlaying = false;
    _returnFromX = position.x;
    _returnElapsed = 0;
    size = assets.frameSize;
    anchor = assets.anchor;
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

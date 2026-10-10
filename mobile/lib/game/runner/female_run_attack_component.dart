import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'female_run_attack_assets.dart';
import 'female_skill_assets.dart';

enum FemalePlayerState {
  run,
  runAttack,
  runAttackRecovery,
  skillStartup,
  skillActive,
  skillRecovery
}

/// World-space runner. The existing battle may instead keep its screen anchor
/// fixed and consume onAdvance to scroll scenery/world positions.
class FemaleRunAttackComponent extends SpriteAnimationComponent {
  FemaleRunAttackComponent({
    required this.assets,
    this.skillAssets,
    Vector2? position,
    this.runSpeed = 80,
    this.attackSpeedRatio = .7,
    this.attackReach = 160,
    this.onNormalAttackHit,
    this.onSkillHit,
    this.onSkillActive,
    this.skillReach = 600,
    this.onAdvance,
  }) : super(
          animation: assets.runAnimation(),
          position: position ?? Vector2.zero(),
          size: assets.frameSize.clone(),
          anchor: assets.anchor,
          priority: 5,
        );

  final FemaleRunAttackAssets assets;
  final FemaleSkillAssets? skillAssets;
  final double skillReach;
  final void Function(Rect worldHitArea)? onSkillHit;

  /// Future effect layer hook; currently no effects are created.
  final void Function(Vector2 position)? onSkillActive;
  final double runSpeed;
  final double attackSpeedRatio;
  final double attackReach;

  /// Called exactly once per attack, including when dt skips the active window.
  /// Resolve a target / HP in the existing combat system; null/no enemy is safe.
  final void Function(Rect worldHitArea)? onNormalAttackHit;

  /// When provided, handles travel externally (e.g. fixed-screen runner).
  final void Function(double distance)? onAdvance;
  FemalePlayerState playerState = FemalePlayerState.run;
  double _age = 0;
  bool _hitDispatched = false;
  bool _skillPlaying = false;
  double _skillAge = 0;
  bool _skillHitDispatched = false;
  bool get isSkillPlaying => _skillPlaying;
  bool get isSkillHitActive =>
      _skillPlaying &&
      _skillAge >= skillAssets!.activeStart &&
      _skillAge < skillAssets!.activeEnd;
  int? get currentSkillSourceFrame =>
      _skillPlaying ? skillAssets!.sourceFrameAt(_skillAge) : null;
  bool get isAttacking => playerState != FemalePlayerState.run;
  bool get isHitActive =>
      isAttacking &&
      !_skillPlaying &&
      _age >= assets.hitStart &&
      _age < assets.hitEnd;
  int get currentSourceFrame {
    var end = 0.0;
    for (var i = 0; i < assets.stepTimes.length; i++) {
      end += assets.stepTimes[i];
      if (_age < end) return assets.attackIds[i];
    }
    return assets.attackIds.last;
  }

  bool playRunAttack() {
    if (isAttacking) return false;
    _age = 0;
    _hitDispatched = false;
    playerState = FemalePlayerState.runAttack;
    animation = assets.attackAnimation();
    animationTicker?.reset();
    return true;
  }

  /// A skill interrupts normal attack, but cannot restart an active skill.
  bool playSkill() {
    final skill = skillAssets;
    if (skill == null || _skillPlaying) return false;
    _skillPlaying = true;
    _skillAge = 0;
    _skillHitDispatched = false;
    playerState = FemalePlayerState.skillStartup;
    size = skill.frameSize.clone();
    anchor = skill.anchor;
    animation = skill.animation();
    animationTicker?.reset();
    return true;
  }

  // Piecewise continuous travel: decelerate during the initial 0.24s,
  // carry forward at 25%, lunge at 70%, then recover to running speed.
  double _skillDistanceAt(double age) {
    final skill = skillAssets!;
    final decelEnd = skill.timeAt(4);
    final t = math.min(age, decelEnd);
    var distance = runSpeed * (t - .75 * t * t / (2 * decelEnd));
    if (age > decelEnd) {
      distance +=
          runSpeed * .25 * (math.min(age, skill.activeStart) - decelEnd);
    }
    if (age > skill.activeStart) {
      distance +=
          runSpeed * .7 * (math.min(age, skill.activeEnd) - skill.activeStart);
    }
    if (age > skill.activeEnd) {
      final recovery = skill.duration - skill.activeEnd;
      final r = math.min(age - skill.activeEnd, recovery);
      distance += runSpeed * (.35 * r + .65 * r * r / (2 * recovery));
    }
    return distance;
  }

  void _advanceSkill(double from, double to) {
    final distance = _skillDistanceAt(to) - _skillDistanceAt(from);
    if (onAdvance != null) {
      onAdvance!(distance);
    } else {
      position.x += distance;
    }
  }

  void _updateSkill(double dt) {
    final skill = skillAssets!;
    final previous = _skillAge;
    final end = math.min(previous + dt, skill.duration);
    if (!_skillHitDispatched && end >= skill.activeStart) {
      _advanceSkill(previous, skill.activeStart);
      _skillHitDispatched = true;
      onSkillActive?.call(position.clone());
      onSkillHit
          ?.call(Rect.fromLTWH(position.x, position.y - 180, skillReach, 180));
      _advanceSkill(skill.activeStart, end);
    } else {
      _advanceSkill(previous, end);
    }
    _skillAge = end;
    playerState = end < skill.activeStart
        ? FemalePlayerState.skillStartup
        : end < skill.activeEnd
            ? FemalePlayerState.skillActive
            : FemalePlayerState.skillRecovery;
    super.update(end - previous);
    if (end >= skill.duration) {
      _skillPlaying = false;
      playerState = FemalePlayerState.run;
      size = assets.frameSize.clone();
      anchor = assets.anchor;
      animation = assets.runAnimation();
      animationTicker?.reset();
      final remainder = math.max(0.0, dt - (end - previous));
      _advance(remainder, 1);
      super.update(remainder);
    }
  }

  void _advance(double seconds, double ratio) {
    final distance = runSpeed * ratio * seconds;
    if (onAdvance != null) {
      onAdvance!(distance);
    } else {
      position.x += distance;
    }
  }

  @override
  void update(double dt) {
    if (_skillPlaying) {
      _updateSkill(dt);
      return;
    }
    if (!isAttacking) {
      _advance(dt, 1);
      super.update(dt);
      return;
    }
    final previousAge = _age;
    final endAge = math.min(_age + dt, assets.duration);
    // Dispatch at the actual impact position, even for a long update step.
    if (!_hitDispatched && endAge >= assets.hitStart) {
      _advance(math.max(0.0, assets.hitStart - previousAge), attackSpeedRatio);
      _hitDispatched = true;
      onNormalAttackHit
          ?.call(Rect.fromLTWH(position.x, position.y - 150, attackReach, 150));
      _advance(
          endAge - math.max(previousAge, assets.hitStart), attackSpeedRatio);
    } else {
      _advance(endAge - previousAge, attackSpeedRatio);
    }
    _age = endAge;
    playerState = _age >= assets.recoveryStart
        ? FemalePlayerState.runAttackRecovery
        : FemalePlayerState.runAttack;
    super.update(endAge - previousAge);
    if (_age >= assets.duration) {
      playerState = FemalePlayerState.run;
      animation = assets.runAnimation();
      animationTicker?.reset();
      final remainder = math.max(0.0, dt - (endAge - previousAge));
      _advance(remainder, 1);
      super.update(remainder);
    }
  }
}

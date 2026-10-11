import 'dart:ui';
import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'female_battle_assets.dart';
import 'archer_arrow_projectile.dart';
import 'archer_wind_arrow_component.dart';

/// Observes battle time; all damage is applied by BattleStateController.
class FemaleBattleHeroComponent extends SpriteComponent {
  FemaleBattleHeroComponent(this.state, this.assets)
      : displayScale = assets.characterType == 'ranger' ? .3 : .75,
        super(
            sprite: assets.run.frames.first.sprite,
            position: Vector2(345, 405),
            size: assets.frameSize *
                (assets.characterType == 'ranger' ? .3 : .75),
            anchor: assets.anchor,
            priority: 5,
            paint: Paint()..filterQuality = FilterQuality.none);
  final BattleStateController state;
  final FemaleBattleAssets assets;
  final double displayScale;
  int _arrowSerial = -1, _windSerial = -1;

  @override
  void update(double dt) {
    super.update(dt);
    if (state.isSkillPlaying) {
      size = assets.skillSize * displayScale;
      anchor = assets.skillAnchor;
      sprite = FemaleBattleAssets.poseAt(assets.skill, state.visualSkillAge);
      final skill = assets.archerSkill;
      if (skill != null &&
          _windSerial != state.skillSerial &&
          state.visualSkillAge + 1e-7 >= (skill.data['releaseTime'] as num)) {
        _windSerial = state.skillSerial;
        final wind = ArcherWindArrowComponent(
            frames: skill.windFrames,
            muzzle: position + skill.muzzleOffset * displayScale,
            rightEdge: () => 960,
            displayScale: displayScale * 1.5,
            speed: 700);
        wind.update((state.visualSkillAge - (skill.data['releaseTime'] as num))
            .clamp(0.0, double.infinity)
            .toDouble());
        if (!wind.expired) parent?.add(wind);
      }
    } else {
      size = assets.frameSize * displayScale;
      anchor = assets.anchor;
      if (state.isNormalAttackPlaying) {
        sprite = FemaleBattleAssets.poseAt(assets.attack, state.attackAge);
        final attack = assets.archerAttack;
        if (attack != null &&
            _arrowSerial != state.attackSerial &&
            state.attackAge + 1e-7 >= attack.releaseTime) {
          _arrowSerial = state.attackSerial;
          final arrow = ArcherArrowProjectile(
              sprite: attack.arrow,
              position: position + attack.muzzleOffset * displayScale);
          arrow.size *= displayScale;
          arrow.update((state.attackAge - attack.releaseTime)
              .clamp(0.0, double.infinity)
              .toDouble());
          if (!arrow.expired) parent?.add(arrow);
        }
      } else {
        sprite = FemaleBattleAssets.poseAt(assets.run,
            state.elapsedSeconds % FemaleBattleAssets.duration(assets.run));
      }
    }
  }
}

import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'boxer_normal_attack_sequence.dart';
import 'boxer_run_attack_assets.dart';
import 'boxer_front_kick_assets.dart';
import 'boxer_front_kick_sequence.dart';
import 'boxer_wind_effect_component.dart';

/// Animation observes the simulation; it never applies damage or changes reach.
class BoxerHeroComponent extends SpriteAnimationComponent {
  BoxerHeroComponent(this.state, this.assets, {this.skillAssets})
      : super(
          animation: assets.run.clone(),
          position: Vector2(345, 405),
          size: assets.runAssets.frameSize *
              (assets.runAssets.displayHeight / assets.runAssets.frameSize.y),
          anchor: assets.runAssets.anchor,
          playing: false,
        );
  final BattleStateController state;
  final BoxerRunAttackAssets assets;
  final BoxerFrontKickAssets? skillAssets;
  bool isFrontKickPlaying = false;
  int _skillSerial = -1;
  bool _windShown = false;
  int? get currentSkillSourceFrame => isFrontKickPlaying
      ? BoxerFrontKickSequence
          .frameIds[BoxerFrontKickSequence.indexAt(state.visualSkillAge)]
      : null;
  bool isAttackPlaying = false;
  int _serial = -1;
  double _age = 0;
  int get currentSourceFrame => isFrontKickPlaying
      ? currentSkillSourceFrame!
      : isAttackPlaying
          ? BoxerNormalAttackSequence
              .frameIds[BoxerNormalAttackSequence.indexAt(state.attackAge)]
          : assets.runAssets.frameIds[animationTicker!.currentIndex];

  void _restoreRun() {
    animation = assets.run.clone();
    size = assets.runAssets.frameSize *
        (assets.runAssets.displayHeight / assets.runAssets.frameSize.y);
    anchor = assets.runAssets.anchor;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final kicking = state.isSkillPlaying &&
        state.activeSkill == SwordsmanSkill.frontKick &&
        skillAssets != null;
    if (kicking) {
      if (!isFrontKickPlaying || _skillSerial != state.skillSerial) {
        animation = skillAssets!.animation.clone();
        size = skillAssets!.frameSize.clone();
        anchor = skillAssets!.anchor;
        _skillSerial = state.skillSerial;
        _windShown = false;
      }
      // Select from the shared timeline directly. Repeated float additions
      // must not leave a pose one frame behind at a 24fps hold boundary.
      final index = BoxerFrontKickSequence.indexAt(state.visualSkillAge);
      animationTicker!
        ..currentIndex = index
        ..elapsed = state.visualSkillAge
        ..clock = state.visualSkillAge - BoxerFrontKickSequence.timeAt(index);
      isFrontKickPlaying = true;
      isAttackPlaying = false;
      if (!_windShown &&
          state.visualSkillAge + 1e-7 >= BoxerFrontKickSequence.impactTime) {
        _windShown = true;
        final age = state.visualSkillAge - BoxerFrontKickSequence.impactTime;
        if (skillAssets!.windFrames.isNotEmpty &&
            age < BoxerWindEffectComponent.duration) {
          parent?.add(BoxerWindEffectComponent(
            frames: skillAssets!.windFrames,
            // The extended boot tip in source frame 14, relative to its anchor.
            kickPosition: position + Vector2(93, -109),
            initialAge: age.clamp(0, double.infinity),
          ));
        }
      }
      return;
    }
    if (isFrontKickPlaying) {
      isFrontKickPlaying = false;
      _restoreRun();
    }
    final attacking = state.isNormalAttackPlaying && !state.isSkillPlaying;
    if (attacking) {
      if (!isAttackPlaying || _serial != state.attackSerial) {
        animation = assets.attack.clone();
        size = assets.frameSize * (215 / assets.frameSize.y);
        anchor = assets.anchor;
        _serial = state.attackSerial;
        _age = 0;
      }
      animationTicker!
          .update((state.attackAge - _age).clamp(0, double.infinity));
      _age = state.attackAge;
    } else {
      if (isAttackPlaying) _restoreRun();
      // Use the same simulation clock as scenery, so pausing/replay and large
      // render deltas cannot make the runner move independently of the ground.
      final time = state.backgroundTravelSeconds % assets.runAssets.duration;
      animationTicker!.reset();
      animationTicker!.update(time);
    }
    isAttackPlaying = attacking;
    // Background scroll continues through both punches. No root teleport,
    // camera flip, or fixed-position combat stop is introduced here.
  }
}

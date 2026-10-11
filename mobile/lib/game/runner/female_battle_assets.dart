import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'battle_state_controller.dart';
import 'female_run_attack_assets.dart';
import 'female_skill_assets.dart';
import 'female_archer_attack_assets.dart';
import 'female_archer_skill_assets.dart';

/// Reuses the reviewed original poses in both adventure and focus battles.
class FemaleBattleAssets {
  FemaleBattleAssets(this.characterType, this.run, this.attack, this.skill,
      this.frameSize, this.anchor, this.skillSize, this.skillAnchor,
      {this.archerAttack, this.archerSkill});
  final String characterType;
  final SpriteAnimation run, attack, skill;
  final Vector2 frameSize, skillSize;
  final Anchor anchor, skillAnchor;
  final FemaleArcherAttackAssets? archerAttack;
  final FemaleArcherSkillAssets? archerSkill;

  static bool supports(String type, String appearance) =>
      appearance == 'female' && (type == 'warrior' || type == 'ranger');

  // Match the reviewed hold times: complete each original animation before
  // another attack can start. Damage remains owned by the simulation.
  static RunnerConfig runnerConfig(String type) => type == 'ranger'
      ? const RunnerConfig(
          normalAttackDurationSeconds: 64 / 24,
          normalAttackHitTimes: [25 / 24],
          archerProjectiles: true,
          sousenDurationSeconds: 53 / 24,
          sousenDamageTimeSeconds: 27 / 24,
          enableSousenEffect: false)
      : const RunnerConfig(
          normalAttackDurationSeconds: .855,
          normalAttackHitTimes: [.39],
          sousenDurationSeconds: 1.8,
          sousenDamageTimeSeconds: .86,
          enableSousenEffect: false);

  static Future<FemaleBattleAssets> load(FlameGame game, String type) async {
    if (type == 'ranger') {
      final attack = await FemaleArcherAttackAssets.load(game);
      final skill = await FemaleArcherSkillAssets.load(game);
      return FemaleBattleAssets(
          type,
          attack.runAnimation(),
          attack.attackAnimation(),
          skill.skillAnimation(),
          attack.frameSize,
          attack.anchor,
          skill.frameSize,
          skill.anchor,
          archerAttack: attack,
          archerSkill: skill);
    }
    final attack = await FemaleRunAttackAssets.load(game);
    final skill = await FemaleSkillAssets.load(game);
    return FemaleBattleAssets(
        type,
        attack.runAnimation(),
        attack.attackAnimation(),
        skill.animation(),
        attack.frameSize,
        attack.anchor,
        skill.frameSize,
        skill.anchor);
  }

  static double duration(SpriteAnimation animation) =>
      animation.frames.fold(0, (sum, frame) => sum + frame.stepTime);

  /// Select a complete original; never create an in-between image.
  static Sprite poseAt(SpriteAnimation animation, double age) {
    var end = 0.0;
    for (final frame in animation.frames) {
      end += frame.stepTime;
      if (age + 1e-8 < end) return frame.sprite;
    }
    return animation.frames.last.sprite;
  }
}

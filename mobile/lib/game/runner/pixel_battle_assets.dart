import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import '../../features/playable_stage/domain/playable_character.dart';
import '../../features/playable_stage/presentation/playable_stage_assets.dart';
import 'battle_state_controller.dart';
import 'pixel_battle_timing.dart';
import 'role_skill_effects.dart';

/// The supplied v013 originals, shared with the playable stage.
class PixelBattleAssets {
  PixelBattleAssets(this.character, this.motions, this.effect);
  final PlayableCharacter character;
  final Map<String, StageMotion> motions;
  final RoleSkillEffects effect;
  static const roles = {
    'warrior': '剣士',
    'boxer': '拳闘士',
    'samurai': '侍',
    'guardian': '重騎士',
    'ninja': '忍者',
    'assassin': 'アサシン',
    'ranger': '弓使い',
    'mage': '魔法使い',
    'gunner': 'ガンナー',
    'spellblade': '魔剣士',
  };

  static PlayableCharacter characterFor(String type, String appearance) {
    if (!roles.containsKey(type)) return PlayableCharacters.defaultCharacter;
    return PlayableCharacters.all.firstWhere(
        (c) => c.role == roles[type] && c.female == (appearance == 'female'));
  }

  static final _additionalRoleTiming = {
    for (final type
        in RoleSkillEffects.names.keys.where((t) => !roles.containsKey(t)))
      type: RunnerConfig(
          attackSeconds: pixelBattleTiming['character_01']!.attackSeconds,
          normalAttackDurationSeconds:
              pixelBattleTiming['character_01']!.normalAttackDuration,
          normalAttackHitTimes:
              pixelBattleTiming['character_01']!.normalHitTimes,
          sousenDurationSeconds:
              pixelBattleTiming['character_01']!.sousenDurationSeconds,
          sousenDamageTimeSeconds:
              pixelBattleTiming['character_01']!.sousenDamageTimeSeconds,
          pixelSkillName: RoleSkillEffects.names[type]),
  };
  static RunnerConfig runnerConfig(String type, String appearance) =>
      _additionalRoleTiming[type] ??
      pixelBattleTiming[characterFor(type, appearance).id]!;

  static Future<PixelBattleAssets> load(
      FlameGame game, String type, String appearance) async {
    final character = characterFor(type, appearance);
    final motions = <String, StageMotion>{};
    for (final action in ['run', 'attack', 'skill']) {
      final name = '${character.id}_$action';
      final metadata = jsonDecode(await rootBundle.loadString(
          '${PlayableStageAssets.base}$name.json')) as Map<String, dynamic>;
      final frames = [
        for (final key in metadata['keyframes'] as List<dynamic>)
          await game.images.load(
              'playable_stage/${name}_${(key['index'] as int).toString().padLeft(3, '0')}.png'),
      ];
      motions[action] = StageMotion(metadata, frames);
    }
    final effect = await RoleSkillEffects.load(type,
        (path) => game.images.load(path.replaceFirst('assets/images/', '')));
    return PixelBattleAssets(character, motions, effect);
  }
}

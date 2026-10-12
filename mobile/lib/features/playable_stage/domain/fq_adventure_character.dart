import '../../character/domain/character.dart';
import '../../character/domain/progression_service.dart';
import '../../../game/runner/pixel_battle_assets.dart';
import 'playable_character.dart';
import '../../../game/runner/role_skill_effects.dart';

/// Keep the original combat events/animation identity, adding FQ level growth.
PlayableCharacter fqAdventureCharacter(Character hero) {
  final base =
      PixelBattleAssets.characterFor(hero.characterType, hero.appearance);
  final stats = ProgressionService().stats(hero, const {});
  return PlayableCharacter(
      base.id,
      base.role,
      base.female,
      base.health + stats.hp - hero.baseStats.hp,
      base.power + stats.attack - hero.baseStats.attack,
      base.speed + (stats.speed - hero.baseStats.speed) * 5,
      base.attackEvent,
      base.skillEvent,
      RoleSkillEffects.names[hero.characterType] ?? base.skillName,
      ranged: base.ranged,
      level: hero.level,
      effectType: hero.characterType);
}

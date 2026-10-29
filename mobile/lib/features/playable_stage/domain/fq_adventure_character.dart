import '../../character/domain/character.dart';
import '../../character/domain/progression_service.dart';
import '../../../game/runner/pixel_battle_assets.dart';
import 'playable_character.dart';
import '../../../game/runner/role_skill_effects.dart';

/// Use the same grown stats as the character screen, retaining motion identity.
PlayableCharacter fqAdventureCharacter(Character hero) {
  final base =
      PixelBattleAssets.characterFor(hero.characterType, hero.appearance);
  final stats = ProgressionService().stats(hero, const {});
  return PlayableCharacter(
      base.id,
      base.role,
      base.female,
      stats.hp,
      stats.attack,
      stats.speed,
      base.attackEvent,
      base.skillEvent,
      RoleSkillEffects.names[hero.characterType] ?? base.skillName,
      ranged: base.ranged,
      defense: stats.defense,
      criticalRate: stats.criticalRate,
      attackTimeScale: 10,
      level: hero.level,
      effectType: hero.characterType);
}

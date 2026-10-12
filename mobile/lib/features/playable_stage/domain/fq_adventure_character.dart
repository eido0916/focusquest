import '../../character/domain/character.dart';
import '../../character/domain/progression_service.dart';
import '../../../data/game_catalog.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import 'playable_character.dart';
import '../../../game/runner/role_skill_effects.dart';

/// Keep the original combat events/animation identity, adding FQ growth and gear.
PlayableCharacter fqAdventureCharacter(Character hero) {
  final role = JobPortrait.roleNames[hero.characterType] ?? '剣士';
  const substitutes = {};
  final base = PlayableCharacters.all.firstWhere((character) =>
      character.role == (substitutes[role] ?? role) &&
      character.female == (hero.appearance == 'female'));
  final stats = ProgressionService().stats(hero, GameCatalog.equipment);
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

import '../../character/domain/character.dart';
import '../../character/domain/progression_service.dart';
import '../../../data/game_catalog.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import 'playable_character.dart';

/// Keep the original combat events/animation identity, adding FQ growth and gear.
PlayableCharacter fqAdventureCharacter(Character hero) {
  final role = JobPortrait.roleNames[hero.characterType] ?? '剣士';
  const substitutes = {
    '陰陽師': '魔法使い',
    '鎌使い': 'アサシン',
    '天使': '魔法使い',
    '悪魔': '魔剣士',
    'ドラゴンナイト': '重騎士',
    'バーサーカー': '剣士',
  };
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
      base.skillName,
      ranged: base.ranged);
}

import 'package:focusquest/features/playable_stage/domain/playable_character.dart';

/// A trained hero for route/animation tests, independent of stage difficulty.
PlayableCharacter trainedStageHero([PlayableCharacter? hero]) {
  final base = hero ?? PlayableCharacters.defaultCharacter;
  const growth = 59;
  return PlayableCharacter(
      base.id,
      base.role,
      base.female,
      base.health + growth * 12,
      base.power + growth * 3,
      base.speed + growth * 5,
      base.attackEvent,
      base.skillEvent,
      base.skillName,
      ranged: base.ranged);
}

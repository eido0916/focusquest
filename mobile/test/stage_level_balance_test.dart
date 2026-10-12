import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';

StageMode fight(PlayableStageDefinition stage, int level, int seed,
    [PlayableCharacter? hero]) {
  final base = hero ?? PlayableCharacters.defaultCharacter;
  final growth = level - 1;
  final character = PlayableCharacter(
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
  final battle = PlayableStageBattle(
      stage: stage, character: character, roll: Random(seed).nextDouble)
    ..start();
  for (var i = 0; i < 120 * 300 && battle.active; i++) {
    if (battle.canSkill) {
      battle.skill();
    } else if (battle.canAttack) {
      battle.attack();
    }
    battle.update(1 / 120);
  }
  final mode = battle.mode;
  battle.dispose();
  return mode;
}

void main() {
  test('all untrained jobs face a difficult first boss', () {
    final stage = PlayableStageCatalog.stages[3];
    for (final hero in PlayableCharacters.all) {
      final wins = List.generate(20, (seed) => fight(stage, 1, seed, hero))
          .where((mode) => mode == StageMode.won)
          .length;
      expect(wins, lessThanOrEqualTo(2), reason: hero.name);
    }
  });
  test('untrained heroes lose; trained heroes can clear fixed stages', () {
    for (final stage in PlayableStageCatalog.stages) {
      final low = List.generate(20, (s) => fight(stage, 1, s))
          .where((m) => m == StageMode.won)
          .length;
      final ready =
          List.generate(20, (s) => fight(stage, stage.recommendedLevel, s))
              .where((m) => m == StageMode.won)
              .length;
      expect(low, lessThanOrEqualTo(1), reason: stage.title);
      expect(ready, greaterThanOrEqualTo(12), reason: stage.title);
    }
  });
}

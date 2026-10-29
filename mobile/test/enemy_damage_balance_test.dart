import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/playable_stage/domain/fq_adventure_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';

void main() {
  test('level 16 onmyoji takes meaningful damage in recommended level 20 stage',
      () {
    final type = GameCatalog.types[2]!;
    final hero = Character(
        id: 'test',
        name: 'test',
        characterType: type.typeId,
        baseStats: type.stats,
        level: 16);
    final character = fqAdventureCharacter(hero);
    final stage = PlayableStageCatalog.stages
        .singleWhere((s) => s.recommendedLevel == 20);
    expect(character.health, 270);
    for (var phase = 0; phase < 3; phase++) {
      final battle = PlayableStageBattle(
          stage: stage, character: character, roll: () => .5)
        ..phase = phase
        ..start();
      for (var tick = 0; tick < 1200 && battle.damageNumbers.isEmpty; tick++) {
        battle.update(1 / 120);
      }
      final hit = battle.damageNumbers.firstWhere((hit) => hit.toHero);
      expect(hit.miss, false);
      expect(hit.critical, false);
      expect(hit.amount, [26, 27, 29][phase]);
      expect(battle.hp, character.health - hit.amount);
      battle.dispose();
    }
  });

  test('all catalog enemies cover defense at their recommended level', () {
    for (final stage in PlayableStageCatalog.stages) {
      for (final type in GameCatalog.types.values) {
        final hero = Character(
            id: 'test',
            name: 'test',
            characterType: type.typeId,
            baseStats: type.stats,
            level: stage.recommendedLevel);
        final character = fqAdventureCharacter(hero);
        for (var phase = 0; phase < 3; phase++) {
          for (final enemy in stage.wave(phase)) {
            expect(enemy.damage - character.defense, greaterThan(1),
                reason: '${stage.title} / ${type.job} / ${enemy.name}');
          }
        }
      }
    }
  });

  test(
      'enemy attack follows stage recommendation, not player level or HP difficulty',
      () {
    final source = PlayableStageCatalog.stages[8];
    PlayableStageDefinition stage(int level) => PlayableStageDefinition(
        source.number,
        source.area,
        source.backgroundPath,
        source.groundLine,
        source.opponents,
        recommendedLevel: level,
        difficultyLevel: source.difficultyLevel);
    final lower = stage(16).wave(0).first;
    final higher = stage(20).wave(0).first;
    expect(higher.hp, lower.hp);
    expect(higher.damage, greaterThan(lower.damage));
    final type = GameCatalog.types[2]!;
    int damageAt(int level) =>
        higher.damage -
        fqAdventureCharacter(Character(
                id: 'test',
                name: 'test',
                characterType: type.typeId,
                baseStats: type.stats,
                level: level))
            .defense;
    expect(damageAt(16), greaterThan(damageAt(20)));
    expect(damageAt(20), greaterThan(damageAt(24)));
  });
}

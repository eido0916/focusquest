import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'stage_recommendation_simulation_test.dart' show simulate;

void main() {
  test(
      'all stage recommendations are playable with actual original attack timing',
      () {
    for (final stage in PlayableStageCatalog.stages) {
      final wins = List.generate(
          20,
          (seed) => simulate(stage, PlayableCharacters.defaultCharacter,
              stage.recommendedLevel, seed + 1000)).where((won) => won).length;
      expect(wins, greaterThanOrEqualTo(16), reason: stage.title);
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
  test('training improves early clear rates without altering enemies', () {
    final stage = PlayableStageCatalog.stages.first;
    final novice = List.generate(
            40,
            (seed) =>
                simulate(stage, PlayableCharacters.defaultCharacter, 1, seed))
        .where((won) => won)
        .length;
    final trained = List.generate(
        40,
        (seed) => simulate(stage, PlayableCharacters.defaultCharacter,
            stage.recommendedLevel, seed)).where((won) => won).length;
    expect(trained, greaterThan(novice));
    expect(trained, greaterThanOrEqualTo(32));
  });
}

import 'playable_stage_catalog.dart';

/// One sequential frontier, while every saved clear remains replayable.
class StageProgress {
  StageProgress(Set<int> saved)
      : cleared = Set.unmodifiable(saved.where((n) => n >= 1 && n <= 36));
  final Set<int> cleared;
  int get nextStage {
    for (var n = 1; n <= 36; n++) {
      if (!cleared.contains(n)) return n;
    }
    return 36;
  }

  int get currentArea => (nextStage - 1) ~/ 4;
  bool canChallenge(int number) =>
      number >= 1 &&
      number <= 36 &&
      (cleared.contains(number) || number == nextStage);
  bool areaComplete(int area) =>
      List.generate(4, (i) => area * 4 + i + 1).every(cleared.contains);
  bool areaVisible(int area) => area >= 0 && area <= currentArea;
  int countInArea(int area) =>
      cleared.where((n) => (n - 1) ~/ 4 == area).length;
  PlayableStageDefinition stage(int number) =>
      PlayableStageCatalog.stages[number - 1];
}

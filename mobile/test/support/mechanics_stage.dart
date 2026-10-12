import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';

/// Small fixed enemies for tests of hit timing, charge, sound and death frames.
/// Difficulty/progression tests use the real catalog instead.
PlayableStageDefinition mechanicsStage([PlayableStageDefinition? input]) {
  final stage = input ?? PlayableStageCatalog.stages.first;
  return PlayableStageDefinition(stage.number, stage.area, stage.backgroundPath,
      stage.groundLine, stage.opponents,
      bossEscort: stage.bossEscort);
}

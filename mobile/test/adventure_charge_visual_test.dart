import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('adventure charge renders with both genders and pixel densities',
      (tester) async {
    for (final role in ['剣士', '魔法使い']) {
      for (final female in [false, true]) {
        final character = PlayableCharacters.all
            .firstWhere((c) => c.role == role && c.female == female);
        final stage = PlayableStageCatalog.stages.first;
        final assets = (await tester.runAsync(() =>
            PlayableStageAssets.load(stage: stage, character: character)))!;
        final battle = PlayableStageBattle(stage: stage, character: character)
          ..mode = StageMode.battle
          ..action = HeroAction.skill;
        final motion = assets.motions['hero_skill']!;
        final release = motion.eventTicks(character.skillEvent).first;
        // Last charge original, before the release event.
        battle.actionTime =
            (release - 1) / 24 / motion.duration * battle.skillDuration;
        try {
          for (final density in [1.0, 2.0]) {
            await tester.runAsync(() async {
              final recorder = ui.PictureRecorder();
              final canvas = ui.Canvas(recorder)..scale(density);
              PlayableStagePainter(battle, assets, density)
                  .paint(canvas, const ui.Size(960, 540));
              final picture = recorder.endRecording();
              final image = await picture.toImage(
                  (960 * density).round(), (540 * density).round());
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  '../output/adventure-charge/${character.id}-${density.toInt()}x.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
              picture.dispose();
            });
          }
        } finally {
          battle.dispose();
          assets.dispose();
        }
      }
    }
  });
}

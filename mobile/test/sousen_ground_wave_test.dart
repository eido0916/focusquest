import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/hero_component.dart';
import 'package:focusquest/game/runner/run_slash_assets.dart';
import 'package:focusquest/game/runner/sousen_ground_wave_component.dart';
import 'package:focusquest/game/runner/swordsman_run_attack_assets.dart';
import 'package:focusquest/game/runner/swordsman_sousen_assets.dart';
import 'package:focusquest/game/runner/swordsman_sousen_timing.dart';

void main() {
  testWidgets('ground wave follows the downstroke, plays eight frames and fits',
      (tester) async {
    final game = FlameGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    await tester.runAsync(() async {
      final state = BattleStateController(durationSeconds: 60);
      final sousen = await SwordsmanSousenAssets.load(game);
      final hero = HeroComponent(
        state,
        await SwordsmanRunAttackAssets.load(game),
        sousen,
        await RunSlashAssets.load(game),
      );
      await game.add(hero);
      await game.ready();
      state.advanceTo(10);
      hero.update(SwordsmanSousenTiming.groundWaveTimeSeconds - .001);
      await game.ready();
      expect(game.children.whereType<SousenGroundWaveComponent>(), isEmpty);
      hero.update(.001);
      await game.ready();
      final wave = game.children.whereType<SousenGroundWaveComponent>().single;
      expect(wave.position.x, closeTo(514, .01));
      expect(wave.position.y, 405);
      expect(
          wave.position.x + wave.size.x, SousenGroundWaveComponent.rightEdge);
      expect(wave.position.y - wave.size.y, greaterThan(0));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final scenery =
          Sprite(await game.images.load('ui/forest_meadow_battlefield.png'));
      for (var frame = 0; frame < 8; frame++) {
        if (frame > 0) wave.update(SousenGroundWaveComponent.frameDuration);
        expect(wave.currentFrame, frame);
        canvas.save();
        canvas.translate((frame % 4) * 960.0, (frame ~/ 4) * 540.0);
        scenery.render(canvas, size: Vector2(960, 540));
        hero.renderTree(canvas);
        wave.renderTree(canvas);
        canvas.restore();
      }
      final picture = recorder.endRecording();
      const previewPath = String.fromEnvironment('WAVE_PREVIEW_PATH');
      if (previewPath.isNotEmpty) {
        final image = await picture.toImage(3840, 1080);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }
      picture.dispose();
      wave.update(.4);
      await game.ready();
      expect(game.children.whereType<SousenGroundWaveComponent>(), isEmpty);
    });
  });
}

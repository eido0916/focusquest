import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/boxer_front_kick_assets.dart';
import 'package:focusquest/game/runner/boxer_front_kick_sequence.dart';
import 'package:focusquest/game/runner/boxer_hero_component.dart';
import 'package:focusquest/game/runner/boxer_run_attack_assets.dart';
import 'package:focusquest/game/runner/boxer_wind_effect_component.dart';

void main() {
  testWidgets('wind starts at boot impact, plays once and fits the right edge',
      (tester) async {
    final game = FlameGame();
    await tester.pumpWidget(GameWidget(game: game));
    await tester.runAsync(() => game.loaded);
    await tester.pump();
    await tester.runAsync(() async {
      final state = BattleStateController(
          durationSeconds: 60,
          config: const RunnerConfig(
              normalAttackStyle: NormalAttackStyle.boxer,
              autoSkill: SwordsmanSkill.frontKick,
              spawnSeconds: 100,
              attackSeconds: 100));
      final assets = await BoxerFrontKickAssets.load(game);
      final hero = BoxerHeroComponent(
          state, await BoxerRunAttackAssets.load(game),
          skillAssets: assets);
      await game.add(hero);
      await game.ready();
      state.playFrontKickSkill();
      state.advanceTo(BoxerFrontKickSequence.impactTime - .001);
      hero.update(0);
      await game.ready();
      expect(game.children.whereType<BoxerWindEffectComponent>(), isEmpty);
      state.advanceTo(BoxerFrontKickSequence.impactTime);
      hero.update(0);
      await game.ready();
      final wind = game.children.whereType<BoxerWindEffectComponent>().single;
      expect(wind.position, Vector2(438, 296));
      hero.update(0);
      await game.ready();
      expect(game.children.whereType<BoxerWindEffectComponent>(), hasLength(1));

      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final scenery =
          Sprite(await game.images.load('ui/forest_meadow_battlefield.png'));
      for (var frame = 0; frame < 8; frame++) {
        if (frame > 0) wind.update(BoxerWindEffectComponent.frameDuration);
        expect(wind.currentFrame, frame);
        final rect = BoxerWindEffectComponent.sourceRects[frame];
        expect(wind.position.x + rect.width * wind.displayScale,
            lessThanOrEqualTo(BoxerWindEffectComponent.rightEdge));
        expect(wind.position.y + (rect.top - 373) * wind.displayScale,
            greaterThan(0));
        expect(wind.position.y + (rect.bottom - 373) * wind.displayScale,
            lessThan(540));
        canvas.save();
        canvas.translate((frame % 4) * 960.0, (frame ~/ 4) * 540.0);
        scenery.render(canvas, size: Vector2(960, 540));
        hero.renderTree(canvas);
        wind.renderTree(canvas);
        canvas.restore();
      }
      final picture = recorder.endRecording();
      const previewPath = String.fromEnvironment('WIND_PREVIEW_PATH');
      if (previewPath.isNotEmpty) {
        final image = await picture.toImage(3840, 1080);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      }
      picture.dispose();
      wind.update(BoxerWindEffectComponent.frameDuration);
      await game.ready();
      expect(game.children.whereType<BoxerWindEffectComponent>(), isEmpty);
      state.advanceTo(1.5);
      hero.update(0);
      state.playFrontKickSkill();
      // Late rendering selects the matching source pose, skipping expired holds.
      state.advanceTo(1.5 + BoxerFrontKickSequence.impactTime + .2);
      hero.update(0);
      await game.ready();
      expect(
          game.children
              .whereType<BoxerWindEffectComponent>()
              .single
              .currentFrame,
          2);
    });
  });
}

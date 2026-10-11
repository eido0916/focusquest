import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/female_archer_skill_assets.dart';
import 'package:focusquest/game/runner/archer_wind_arrow_component.dart';
import 'package:focusquest/game/runner/female_archer_skill_component.dart';
import 'package:focusquest/game/runner/female_archer_skill_demo_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
      'reviewed atlas: moving single shot, cancel, long dt and run return',
      (tester) async {
    final game = FemaleArcherSkillDemoGame();
    await tester.runAsync(() async {
      game.onGameResize(Vector2(1280, 900));
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load).timeout(const Duration(seconds: 30));
    });
    await tester.pumpWidget(MaterialApp(
        home:
            SizedBox(width: 1280, height: 900, child: GameWidget(game: game))));
    game.pauseEngine();
    await tester.pump();
    game.update(0);
    final hero = game.archer!;
    expect(hero.assets.skillIds.length, 35);
    expect(hero.assets.skillIds.where((id) => id == 19).length, 1);
    expect(hero.assets.skillAnimation().loop, false);
    expect(game.skill(), true);
    expect(game.skill(), false);
    game.update(hero.controller.releaseTime);
    expect(game.shots, 1);
    expect(hero.controller.currentFrame, 19);
    expect(game.distance, greaterThan(0));
    await tester.pump();
    game.update(0);
    final wind = game.children.whereType<ArcherWindArrowComponent>().single;
    final muzzle = hero.position + hero.assets.muzzleOffset;
    expect(wind.position.x, closeTo(muzzle.x + 100, 1e-6));
    expect(wind.position.y, muzzle.y);
    expect(wind.frameIndex, 0);
    final launchX = wind.position.x;
    game.update(.2);
    expect(wind.position.x, closeTo(launchX, 1e-6));
    expect(wind.position.y, muzzle.y);
    expect(wind.frameIndex, 0);
    expect(game.children.whereType<ArcherWindArrowComponent>().length, 1);
    final previewPath = Platform.environment['ARCHER_SKILL_PREVIEW_PATH'];
    if (previewPath != null) {
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        canvas.drawColor(const Color(0xff344052), BlendMode.src);
        game.render(canvas);
        final image = await recorder.endRecording().toImage(1280, 900);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    game.update(5);
    expect(hero.isUsingSkill, false);
    await tester.pump();
    game.update(0);
    expect(game.children.whereType<ArcherWindArrowComponent>(), isEmpty);
    expect(game.shots, 1);
    expect(hero.assets.runIds.map((id) => hero.assets.frames[id]),
        contains(hero.sprite));
    expect(game.skill(), true);
    hero.cancelSkill();
    game.update(5);
    expect(game.shots, 1);
    expect(hero.paint.filterQuality, ui.FilterQuality.none);
    expect(hero.angle, 0);
    expect(hero.scale, Vector2.all(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('long dt and small steps agree on travel and single release',
      (tester) async {
    final game = FlameGame();
    late FemaleArcherSkillAssets assets;
    await tester.runAsync(() async {
      assets = await FemaleArcherSkillAssets.load(game);
    });
    List<double> simulate(List<double> steps) {
      var travel = 0.0, atShot = -1.0, shots = 0.0;
      final c = assets.createController()..play();
      for (final dt in steps) {
        final rest = c.update(dt, onAdvance: (t, p) {
          travel += 120 * t * FemaleArcherSkillComponent.defaultSpeedRatios[p]!;
        }, onRelease: (_) {
          shots++;
          atShot = travel;
        });
        travel += 120 * rest;
      }
      return [travel, atShot, shots];
    }

    final large = simulate([4]);
    final small = simulate(List.filled(960, 1 / 240));
    for (var i = 0; i < 3; i++) {
      expect(large[i], closeTo(small[i], 1e-7));
    }
    expect(large[2], 1);
  });
}

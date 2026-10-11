import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/archer_attack_animation_controller.dart';
import 'package:focusquest/game/runner/archer_arrow_projectile.dart';
import 'package:focusquest/game/runner/female_archer_attack_component.dart';
import 'package:focusquest/game/runner/female_archer_demo_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<ArcherAttackAnimationController> controller() async {
    final d = jsonDecode(await rootBundle.loadString(
            'assets/images/characters/female_archer/normal_attack/normal_attack.json'))
        as Map;
    return ArcherAttackAnimationController(
        frameIds: (d['attackFrames'] as List).cast<int>(),
        stepTimes: [for (final n in d['holdTicks'] as List) (n as num) / 24],
        phases: (d['phases'] as List).cast<String>(),
        releaseFrame: d['releaseFrame'] as int);
  }

  test('exact release boundary, one shot, completion leftover and restart',
      () async {
    final c = await controller();
    var shots = 0;
    var completed = 0;
    var travelSeconds = 0.0;
    void advance(double t, String phase) {
      travelSeconds += t;
    }

    void release(double remainder) {
      shots++;
    }

    expect(c.play(), isTrue);
    expect(c.play(), isFalse);
    c.update(c.releaseTime, onAdvance: advance, onRelease: release);
    expect(c.currentFrame, 22);
    expect(shots, 1);
    final remaining = c.update(2,
        onAdvance: advance, onRelease: release, onComplete: () => completed++);
    expect(remaining, closeTo(2 + c.releaseTime - c.duration, 1e-9));
    expect(travelSeconds, closeTo(c.duration, 1e-9));
    expect(shots, 1);
    expect(completed, 1);
    expect(c.isPlaying, isFalse);
    expect(c.play(), isTrue);
    c.update(c.duration, onAdvance: advance, onRelease: release);
    expect(shots, 2);
  });
  test('large dt and 240Hz updates produce the same shot position and travel',
      () async {
    Future<List<double>> simulate(bool large) async {
      final c = await controller();
      c.play();
      var travel = 0.0;
      var atShot = -1.0;
      var shots = 0.0;
      for (final dt in large ? [2.0] : List.filled(480, 1 / 240)) {
        final remaining = c.update(dt, onAdvance: (t, phase) {
          travel += 120 *
              t *
              (FemaleArcherAttackComponent.defaultSpeedRatios[phase] ?? 1);
        }, onRelease: (_) {
          atShot = travel;
          shots++;
        });
        travel += 120 * remaining;
      }
      return [travel, atShot, shots];
    }

    final a = await simulate(true);
    final b = await simulate(false);
    for (var i = 0; i < a.length; i++) {
      expect(a[i], closeTo(b[i], 1e-8));
    }
    expect(a[2], 1);
  });
  test('cancel before release emits no late shot; invalid timelines rejected',
      () async {
    final c = await controller();
    c.play();
    c.update(.1, onAdvance: (_, __) {}, onRelease: (_) => fail('early shot'));
    c.cancel();
    expect(
        c.update(5, onAdvance: (_, __) {}, onRelease: (_) => fail('late shot')),
        5);
    expect(() => c.update(-1, onAdvance: (_, __) {}, onRelease: (_) {}),
        throwsArgumentError);
    expect(
        () => ArcherAttackAnimationController(
            frameIds: [1, 2],
            stepTimes: [0, 1],
            phases: ['run', 'release'],
            releaseFrame: 2),
        throwsArgumentError);
  });
  testWidgets('real atlas loads, arrow mounts once and archer returns to run',
      (tester) async {
    final game = FemaleArcherDemoGame();
    await tester.runAsync(() async {
      game.onGameResize(Vector2(1280, 900));
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load).timeout(const Duration(seconds: 30));
    });
    await tester.pumpWidget(MaterialApp(
        home:
            SizedBox(width: 1280, height: 900, child: GameWidget(game: game))));
    await tester.pump();
    game.pauseEngine();
    final hero = game.archer!;
    expect(hero.assets.frames, hasLength(32));
    expect(hero.size, hero.assets.frameSize);
    expect(hero.scale, Vector2.all(1));
    expect(game.attack(), isTrue);
    expect(game.attack(), isFalse);
    game.update(hero.controller.releaseTime + .05);
    await tester.pump();
    game.update(0); // mount the deferred projectile
    final arrow = game.children.whereType<ArcherArrowProjectile>().single;
    expect(game.shots, 1);
    expect(arrow.position.x,
        closeTo(hero.position.x + hero.assets.muzzleOffset.x + 50, 1e-6));
    expect(arrow.position.y, hero.position.y + hero.assets.muzzleOffset.y);
    expect(arrow.angle, 0);
    expect(hero.controller.currentPhase, 'recoil');
    final previewPath = Platform.environment['ARCHER_PREVIEW_PATH'];
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
    game.update(3);
    await tester.pump();
    game.update(0);
    expect(hero.isAttacking, isFalse);
    expect(game.shots, 1);
    expect(game.children.whereType<ArcherArrowProjectile>(), isEmpty);
    expect(hero.paint.filterQuality, FilterQuality.none);
    expect(hero.position.x, 450);
    expect(game.attack(), isTrue);
    hero.cancelAttack();
    expect(hero.isAttacking, isFalse);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

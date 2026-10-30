import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('SunlitSerif')
          ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf')))
        .load();
  });
  for (final female in [false, true]) {
    for (final role in ['魔法使い', '魔剣士', '陰陽師', '天使', '悪魔']) {
      for (final boss in role == '魔法使い' ? [false, true] : [false]) {
        test(
            '$role $female boss $boss: impact appears at collision, never at the caster before arrival',
            () async {
          final hero = PlayableCharacters.all
              .firstWhere((c) => c.role == role && c.female == female);
          final stage = PlayableStageCatalog.stages[boss ? 3 : 0];
          final assets =
              await PlayableStageAssets.load(stage: stage, character: hero);
          final battle =
              PlayableStageBattle(stage: stage, character: hero, roll: () => .5)
                ..phase = boss ? 2 : 0;
          addTearDown(assets.dispose);
          addTearDown(battle.dispose);
          battle.configureHeroTiming(assets.motions['hero_attack']!.metadata,
              assets.motions['hero_skill']!.metadata);
          battle.spriteWorldSide =
              PlayableStagePainter.baseSpriteSide(const ui.Size(960, 540), 1) *
                  1280 /
                  960;
          battle.start();
          for (var i = 0; i < 360; i++) {
            battle.update(1 / 120);
          }
          for (final enemy in battle.enemies) {
            enemy.wait = 100;
          }
          if (boss) {
            for (final enemy
                in battle.enemies.where((e) => !e.definition.isBoss)) {
              enemy.hp = 0;
            }
          }
          battle.target.hp = 10000;
          battle.charge = 3;
          battle.skill();
          while (battle.projectiles.isEmpty) {
            battle.update(1 / 120);
          }
          final shot = battle.projectiles.single;
          expect(shot.resolved, isFalse);
          expect(battle.target.hp, 10000);

          Future<List<int>> render({String? capture}) async {
            final recorder = ui.PictureRecorder();
            PlayableStagePainter(battle, assets, 1)
                .paint(ui.Canvas(recorder), const ui.Size(960, 540));
            final picture = recorder.endRecording();
            final image = await picture.toImage(960, 540);
            final data =
                await image.toByteData(format: ui.ImageByteFormat.rawRgba);
            if (capture != null &&
                const bool.fromEnvironment('CAPTURE_SKILL_IMPACT')) {
              const directory = String.fromEnvironment('SKILL_IMPACT_DIRECTORY',
                  defaultValue: 'build/skill-impact');
              final file = File('$directory/$capture.png');
              await file.parent.create(recursive: true);
              final png =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              await file.writeAsBytes(png!.buffer.asUint8List());
            }
            final result = data!.buffer.asUint8List().toList();
            image.dispose();
            picture.dispose();
            return result;
          }

          int difference(List<int> a, List<int> b, int left, int top, int right,
              int bottom) {
            var count = 0;
            for (var y = top; y < bottom; y++) {
              for (var x = left; x < right; x++) {
                final i = (y * 960 + x) * 4;
                if (a[i] != b[i] ||
                    a[i + 1] != b[i + 1] ||
                    a[i + 2] != b[i + 2]) {
                  count++;
                }
              }
            }
            return count;
          }

          final inFlight =
              await render(capture: '${hero.id}${boss ? '-boss' : ''}-flight');
          final action = battle.action;
          battle.action = null;
          final withoutCasting = await render();
          battle.action = action;
          expect(difference(inFlight, withoutCasting, 260, 200, 450, 500), 0,
              reason:
                  'A remote impact must not appear near the caster before the projectile arrives');
          final savedTime = battle.actionTime;
          battle.projectiles.remove(shot);
          battle.actionTime =
              battle.skillHitFraction * battle.skillDuration - 1e-10;
          final releaseBoundary = await render();
          battle.action = null;
          final boundaryWithoutCasting = await render();
          battle.action = action;
          battle.actionTime = savedTime;
          battle.projectiles.add(shot);
          expect(
              difference(
                  releaseBoundary, boundaryWithoutCasting, 260, 200, 450, 500),
              0,
              reason: '24fps rounding must not flash an impact at the caster');
          while (!shot.resolved) {
            battle.update(1 / 120);
          }
          expect(battle.target.hp, 10000 - hero.skillPower);
          final impact =
              await render(capture: '${hero.id}${boss ? '-boss' : ''}-impact');
          battle.projectiles.remove(shot);
          final withoutImpact = await render();
          battle.projectiles.add(shot);
          final targetX = (shot.endX / 1280 * 960).round();
          expect(
              difference(impact, withoutImpact, targetX - 100, 200,
                  targetX + 100, 520),
              greaterThan(100));
          expect(difference(impact, withoutImpact, 110, 200, 255, 500), 0,
              reason:
                  'The impact is anchored to the collision, not the caster');
          for (var i = 0; i < 240; i++) {
            battle.update(1 / 120);
          }
          expect(battle.target.hp, 10000 - hero.skillPower);
          expect(battle.projectiles, isEmpty);
        });
      }
    }
  }
}

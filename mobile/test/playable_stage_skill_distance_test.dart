import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';
import 'package:focusquest/game/runner/role_skill_effects.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 240).ceil(); i++) {
    battle.update(1 / 240);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final female in [false, true]) {
    for (final boss in [false, true]) {
      test(
          'swordsman $female boss $boss: contact on the drawn release at every scale',
          () async {
        final hero = PlayableCharacters.all
            .firstWhere((c) => c.role == '剣士' && c.female == female);
        final stage = PlayableStageCatalog.stages[boss ? 3 : 0];
        final assets =
            await PlayableStageAssets.load(stage: stage, character: hero);
        addTearDown(assets.dispose);
        for (final size in [
          const ui.Size(390, 520),
          const ui.Size(960, 540),
          const ui.Size(1280, 720)
        ]) {
          final battle =
              PlayableStageBattle(stage: stage, character: hero, roll: () => .5)
                ..phase = boss ? 2 : 0
                ..start();
          battle.configureHeroTiming(assets.motions['hero_attack']!.metadata,
              assets.motions['hero_skill']!.metadata);
          battle.spriteWorldSide =
              PlayableStagePainter.baseSpriteSide(size, 1) * 1280 / size.width;
          advance(battle, 3);
          if (boss) {
            for (final enemy
                in battle.enemies.where((e) => !e.definition.isBoss)) {
              enemy.hp = 0;
            }
          }
          for (final enemy in battle.enemies) {
            enemy.wait = 100;
          }
          final victim = battle.target;
          victim.hp = 10000;
          final initialGap = victim.x - battle.heroX;
          final neededGap = battle.actionContactGap(victim, true);
          battle.charge = 3;
          expect(battle.skill(), isTrue);
          final release = battle.skillHitFraction * battle.skillDuration;
          while (battle.actionTime + 1 / 240 < release - 1e-7) {
            battle.update(1 / 240);
            expect(victim.hp, 10000);
          }
          while (victim.hp == 10000 && battle.action != null) {
            battle.update(1 / 240);
          }
          expect(victim.hp, 10000 - hero.skillPower);
          expect(battle.projectiles, isEmpty,
              reason: 'No invisible homing slash');
          final gap = victim.x - battle.heroX - battle.heroPoseOffset;
          expect(gap, inInclusiveRange(0, neededGap + 1));
          if (initialGap > neededGap + 1) {
            expect(battle.heroX + battle.heroPoseOffset,
                greaterThan(PlayableStageBattle.heroHomeX));
          }
          final motion = assets.motions['hero_skill']!;
          final age =
              battle.actionTime * motion.duration / battle.skillDuration;
          expect(
              RoleSkillEffects.frameIndex(
                  age,
                  motion.duration,
                  motion
                      .eventTicks(hero.skillEvent)
                      .map((t) => t / 24)
                      .toList()),
              3);
          if (const bool.fromEnvironment('CAPTURE_SKILL_DISTANCE')) {
            final recorder = ui.PictureRecorder();
            PlayableStagePainter(battle, assets, 1)
                .paint(ui.Canvas(recorder), size);
            final picture = recorder.endRecording();
            final image =
                await picture.toImage(size.width.toInt(), size.height.toInt());
            final png = await image.toByteData(format: ui.ImageByteFormat.png);
            const directory = String.fromEnvironment(
                'SKILL_DISTANCE_DIRECTORY',
                defaultValue: 'build/skill-distance');
            final file = File(
                '$directory/${female ? 'female' : 'male'}-${boss ? 'boss' : 'mob'}-${size.width.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(png!.buffer.asUint8List());
            image.dispose();
            picture.dispose();
          }
          advance(battle, battle.skillDuration + .5);
          expect(victim.hp, 10000 - hero.skillPower, reason: 'One hit only');
          expect(battle.heroX, PlayableStageBattle.heroHomeX);
          battle.dispose();
        }
      });
    }
  }

  test('finite skills close distance; ranged skills keep their projectiles',
      () {
    for (final hero in PlayableCharacters.all) {
      final battle = PlayableStageBattle(character: hero);
      expect(battle.projectileForAction(false), hero.projectileFor(false));
      expect(
          battle.projectileForAction(true),
          ['剣士', '鎌使い', 'バーサーカー'].contains(hero.role)
              ? isNull
              : hero.projectileFor(true));
      battle.dispose();
    }
  });
}

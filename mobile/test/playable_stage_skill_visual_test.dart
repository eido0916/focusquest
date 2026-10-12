import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';
import 'package:focusquest/game/runner/role_skill_effects.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all demo characters use the shared GitHub skill names', () {
    for (final hero in PlayableCharacters.all) {
      expect(hero.skillName,
          RoleSkillEffects.names[RoleSkillEffects.roleTypes[hero.role]]);
    }
  });

  for (final role in ['剣士', 'バーサーカー']) {
    test('$role renders v002 without legacy skill objects', () async {
      final hero = PlayableCharacters.all
          .firstWhere((hero) => hero.role == role && !hero.female);
      final assets = await PlayableStageAssets.load(character: hero);
      final battle = PlayableStageBattle(character: hero)
        ..mode = StageMode.battle
        ..action = HeroAction.skill;
      addTearDown(assets.dispose);
      addTearDown(battle.dispose);
      final motion = assets.motions['hero_skill']!;
      final release = motion.eventTick(hero.skillEvent, 20) / 24;
      battle.actionTime = (release + 1 / 24) * battle.skillDuration / motion.duration;
      final painter = PlayableStagePainter(battle, assets, 1);
      Future<List<int>> render({String? capture}) async {
        final recorder = ui.PictureRecorder();
        painter.paint(ui.Canvas(recorder), const ui.Size(960, 540));
        final picture = recorder.endRecording();
        final image = await picture.toImage(960, 540);
        final bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        if (capture != null && const bool.fromEnvironment('CAPTURE_STAGE')) {
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final file = File('build/skill-review/$capture.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png.buffer.asUint8List());
        }
        final result = bytes.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return result;
      }

      final shared = await render(capture: assets.effect.type);
      final projectile = StageProjectile(
          hero.projectileFor(true)!, battle.target, battle.heroX, .3, true, 100)
        ..endX = battle.target.x
        ..age = .15;
      battle.projectiles.add(projectile);
      expect(await render(), shared,
          reason: 'Legacy skill projectiles must not cover the v002 originals');
      battle.projectiles.clear();
      battle.action = null;
      expect(await render(), isNot(shared),
          reason: 'The shared skill effect must be visible during the action');
    });
  }
}

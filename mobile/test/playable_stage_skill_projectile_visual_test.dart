import 'dart:ui' as ui;
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final role in ['弓使い', '魔法使い']) {
    test('$role skill flight stays visible after casting ends', () async {
      final hero = PlayableCharacters.all.firstWhere((c) => c.role == role);
      final assets = await PlayableStageAssets.load(
          stage: PlayableStageCatalog.stages.first, character: hero);
      final battle = PlayableStageBattle(character: hero)
        ..mode = StageMode.battle;
      addTearDown(assets.dispose);
      addTearDown(battle.dispose);
      Future<List<int>> pixels() async {
        final recorder = ui.PictureRecorder();
        PlayableStagePainter(battle, assets, 1)
            .paint(ui.Canvas(recorder), const ui.Size(960, 540));
        final picture = recorder.endRecording();
        final image = await picture.toImage(960, 540);
        final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
        final result = data!.buffer.asUint8List().toList();
        image.dispose();
        picture.dispose();
        return result;
      }

      final before = await pixels();
      final shot = StageProjectile(hero.projectileFor(true)!, battle.target,
          300, .3, true, hero.skillPower)
        ..endX = battle.target.x
        ..age = .15;
      battle.projectiles.add(shot);
      final after = await pixels();
      final x = (shot.x / 1280 * 960).round();
      final y = (540 * battle.stage.groundLine -
              PlayableStagePainter.baseSpriteSide(const ui.Size(960, 540), 1) *
                  shot.height)
          .round();
      var changed = 0;
      for (var py = y - 40; py < y + 40; py++) {
        for (var px = x - 40; px < x + 40; px++) {
          final i = (py * 960 + px) * 4;
          if (before[i] != after[i] ||
              before[i + 1] != after[i + 1] ||
              before[i + 2] != after[i + 2]) changed++;
        }
      }
      expect(changed, greaterThan(20),
          reason:
              'The real projectile must be visible at its collision position');
      battle.action = HeroAction.skill;
      battle.heroHurtTime = 0;
      expect(PlayableStagePainter(battle, assets, 1).heroMotion, 'hero_skill',
          reason:
              'An active skill must remain visible when the caster takes damage');
    });
  }
}

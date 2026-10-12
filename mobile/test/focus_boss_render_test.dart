import 'dart:ui' as ui;
import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/enemy_component.dart';
import 'package:focusquest/game/runner/enemy_motion_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all nine bosses render complete originals at the foot anchor',
      () async {
    const bosses = [
      'boss_goblin_king',
      'boss_dullahan',
      'boss_cyclops',
      'boss_fire_dragon',
      'boss_lich',
      'boss_minotaur',
      'boss_stone_golem',
      'boss_cerberus',
      'boss_demon_lord',
    ];
    final game = FlameGame()..images = Images();
    addTearDown(game.images.clearCache);
    final assets = await EnemyMotionAssets.load(game, ids: bosses);
    for (final id in bosses) {
      for (final action in ['locomotion', 'attack', 'defeat']) {
        final motion = assets.motions['${id}_$action']!;
        expect(motion.metadata['coordinate_canvas'], [128, 128]);
        expect(motion.metadata['sprite_anchor_px'], [64, 120]);
        expect(motion.metadata['interpolation'], 'none');
        // Include every held pose and every knockback offset, including the
        // transparent final defeat pose. This exercises the actual renderer.
        final poses = <String>{};
        for (var tick = 0; tick < motion.timeline.length; tick++) {
          final row = motion.timeline[tick];
          if (!poses.add('${row['keyframe']}:${row['root_offset_px']}')) {
            continue;
          }
          final age = (tick + .01) / 24;
          final enemy = RunnerEnemy(0, EnemyData(id, isBoss: true), x: 509)
            ..phase = action == 'defeat' ? EnemyPhase.defeat : EnemyPhase.move
            ..age = action == 'attack' ? 3 + age : age
            ..hitAge = action == 'defeat' ? age : 0;
          final frame = motion.frame(age);
          expect(frame.image.width, 384);
          expect(frame.image.height, 384);
          final actualRecorder = ui.PictureRecorder();
          EnemyComponent(enemy, assets).render(ui.Canvas(actualRecorder));
          final expectedRecorder = ui.PictureRecorder();
          ui.Canvas(expectedRecorder).drawImageRect(
              frame.image,
              const ui.Rect.fromLTWH(0, 0, 384, 384),
              ui.Rect.fromLTWH(381 + frame.offset.dx * 2,
                  173 + frame.offset.dy * 2, 256, 256),
              ui.Paint()
                ..filterQuality = ui.FilterQuality.none
                ..isAntiAlias = false);
          final actualPicture = actualRecorder.endRecording();
          final expectedPicture = expectedRecorder.endRecording();
          final actual = await actualPicture.toImage(960, 540);
          final expected = await expectedPicture.toImage(960, 540);
          try {
            expect((await actual.toByteData())!.buffer.asUint8List(),
                (await expected.toByteData())!.buffer.asUint8List(),
                reason: '$id $action tick $tick must show the entire original');
          } finally {
            actual.dispose();
            expected.dispose();
            actualPicture.dispose();
            expectedPicture.dispose();
          }
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 3)));
}

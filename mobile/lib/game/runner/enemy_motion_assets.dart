import 'dart:convert';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';
import '../../features/playable_stage/presentation/playable_stage_assets.dart';

/// Completed v013 originals; metadata selects held poses and world offsets.
class EnemyMotionAssets {
  EnemyMotionAssets._(this.motions);
  final Map<String, StageMotion> motions;
  static Future<EnemyMotionAssets> load(FlameGame game) async {
    final motions = <String, StageMotion>{};
    for (final id in ['slime', 'goblin', 'boss_goblin_king', 'boss_dullahan']) {
      for (final action in ['locomotion', 'attack', 'defeat']) {
        final name = '${id}_$action';
        final meta = jsonDecode(await rootBundle.loadString(
            'assets/images/playable_stage/$name.json')) as Map<String, dynamic>;
        final frames = [
          for (final key in meta['keyframes'] as List)
            await game.images.load(
                'playable_stage/${name}_${(key['index'] as int).toString().padLeft(3, '0')}.png')
        ];
        motions[name] = StageMotion(meta, frames);
      }
    }
    return EnemyMotionAssets._(motions);
  }

  StageFrame frame(String id, String action, double seconds,
          {bool loop = false}) =>
      motions['${id}_$action']!.frame(seconds, loop: loop);
}

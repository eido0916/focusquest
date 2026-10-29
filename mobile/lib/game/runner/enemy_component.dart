import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';
import 'enemy_motion_assets.dart';

class EnemyComponent extends Component {
  EnemyComponent(this.enemy, this.assets);
  final RunnerEnemy enemy;
  final EnemyMotionAssets assets;
  double _defeatAge = 0;
  @override
  void update(double dt) {
    super.update(dt);
    if (enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat) {
      _defeatAge += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final defeated =
        enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat;
    final attacking = enemy.data.isBoss && !defeated && enemy.age % 4 >= 3;
    final action = defeated
        ? 'defeat'
        : attacking
            ? 'attack'
            : 'locomotion';
    final age = defeated
        ? (_defeatAge > enemy.hitAge ? _defeatAge : enemy.hitAge)
        : attacking
            ? enemy.age % 4 - 3
            : enemy.age;
    final motion = assets.motions['${enemy.data.id}_$action']!;
    final frame = motion.frame(age, loop: !defeated);
    final anchor = motion.metadata['sprite_anchor_px'] as List<dynamic>?;
    final anchorX = anchor == null ? 64.0 : (anchor[0] as num).toDouble();
    final anchorY = anchor == null ? 112.0 : (anchor[1] as num).toDouble();
    // Detailed bosses use 384px PNGs, but anchors and world offsets retain
    // their 128px coordinate units. Display the entire held original.
    final scale = enemy.data.isBoss ? 2.0 : 1.0;
    canvas.drawImageRect(
        frame.image,
        Rect.fromLTWH(
            0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
        Rect.fromLTWH(
            enemy.x + (frame.offset.dx - anchorX) * scale,
            413 + (frame.offset.dy - anchorY) * scale,
            128 * scale,
            128 * scale),
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
  }
}

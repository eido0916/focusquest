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
    final frame = assets.frame(enemy.data.id, action, age, loop: !defeated);
    // Integer enlargement of the complete original. Knockback comes from JSON.
    final scale = enemy.data.isBoss ? 2.0 : 1.0;
    canvas.drawImageRect(
        frame.image,
        const Rect.fromLTWH(0, 0, 128, 128),
        Rect.fromLTWH(enemy.x + (frame.offset.dx - 64) * scale,
            413 + (frame.offset.dy - 112) * scale, 128 * scale, 128 * scale),
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
  }
}

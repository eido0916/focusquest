import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';
import 'enemy_motion_assets.dart';

class EnemyComponent extends Component {
  EnemyComponent(this.enemy, this.assets);
  final RunnerEnemy enemy;
  final EnemyMotionAssets assets;
  double _movementAge = 0;
  Sprite? _defeatSprite;

  bool get _defeated =>
      enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat;

  @override
  void update(double dt) {
    super.update(dt);
    if (_defeated) {
      _defeatSprite ??= assets.frameAt(enemy.data.id, _movementAge);
    } else {
      // Keep hopping / stepping in place even when the combat queue holds X.
      _movementAge += dt;
    }
  }

  @override
  void render(Canvas canvas) {
    final slime = enemy.data.id == 'slime';
    final progress = _defeated ? (enemy.hitAge / .5).clamp(0.0, 1.0) : 0.0;
    final fade =
        _defeated ? (1 - (enemy.hitAge - .10) / .40).clamp(0.0, 1.0) : 1.0;
    final size = slime ? 132.0 : 160.0;
    // Ground baseline is 112/128. Preserve the baked hop/stride instead of
    // adding a second procedural bob on top of the source movement.
    final groundAnchor = size * 112 / 128;
    canvas.save();
    canvas.translate(enemy.x, 413);
    canvas.drawOval(
      Rect.fromCenter(
          center: const Offset(0, 3), width: slime ? 62 : 54, height: 10),
      Paint()..color = Colors.black.withOpacity(.18 * fade),
    );
    if (_defeated) {
      if (slime) {
        canvas.scale(1 + progress * .5, math.max(.12, 1 - progress * .88));
      } else {
        // Tip away from the hero. Combat state already supplies knockback.
        canvas.rotate(progress * 1.25);
        canvas.scale(1 - progress * .12);
      }
    }
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..color = Colors.white.withOpacity(fade);
    if (enemy.damageAge < .08) {
      paint.colorFilter =
          const ColorFilter.mode(Color(0x99ffffff), BlendMode.srcATop);
    }
    final sprite = _defeatSprite ?? assets.frameAt(enemy.data.id, _movementAge);
    sprite.render(canvas,
        position: Vector2(-size / 2, -groundAnchor),
        size: Vector2.all(size),
        overridePaint: paint);
    canvas.restore();
  }
}

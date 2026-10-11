import 'dart:math' as math;
import 'dart:ui';
import 'package:flame/components.dart';

/// A separate right-facing arrow. Position is its tail's centre, in the same
/// parent coordinate space as the archer. Hook collisions into your own game.
class ArcherArrowProjectile extends SpriteComponent {
  ArcherArrowProjectile(
      {required Sprite sprite,
      required Vector2 position,
      this.speed = defaultSpeed,
      this.lifetime = defaultLifetime})
      : super(
            sprite: sprite,
            position: position,
            size: sprite.srcSize.clone(),
            anchor: Anchor.centerLeft,
            priority: 6,
            paint: Paint()..filterQuality = FilterQuality.none) {
    if (!speed.isFinite || speed <= 0 || !lifetime.isFinite || lifetime <= 0) {
      throw ArgumentError('Arrow speed and lifetime must be positive');
    }
  }
  static const defaultSpeed = 1000.0;
  static const defaultLifetime = 1.2;
  final double speed;
  final double lifetime;
  double age = 0;
  bool get expired => age >= lifetime;
  @override
  void update(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    final step = math.min(dt, math.max(0.0, lifetime - age));
    position.x += speed * step;
    age += step;
    super.update(step);
    if (expired) removeFromParent();
  }
}

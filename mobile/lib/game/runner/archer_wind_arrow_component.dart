import 'dart:ui';
import 'archer_shot_timing.dart';
import 'package:flame/components.dart';

/// Eight unchanged wind-arrow originals. Only world x advances; the last
/// drawing is held until the complete projectile clears the viewport edge.
class ArcherWindArrowComponent extends SpriteComponent {
  ArcherWindArrowComponent(
      {required this.frames,
      required Vector2 muzzle,
      required this.rightEdge,
      this.speed = ArcherShotTiming.windSpeed,
      this.displayScale = 1.25})
      : super(
            sprite: frames.first,
            position: muzzle + Vector2(80 * displayScale, 0),
            size: frames.first.srcSize * displayScale,
            anchor: const Anchor(1, 126 / 245),
            priority: 7,
            paint: Paint()..filterQuality = FilterQuality.none) {
    if (frames.length != 8 ||
        !speed.isFinite ||
        speed <= 0 ||
        !displayScale.isFinite ||
        displayScale <= 0) {
      throw ArgumentError('Expected eight wind originals and positive speed');
    }
  }
  final List<Sprite> frames;

  /// Right viewport edge expressed in the same parent coordinates as muzzle.
  final double Function() rightEdge;
  final double speed;
  final double displayScale;
  static const holdTicks = [6, 4, 2, 2, 2, 2, 2, 2];
  static const startupDuration = ArcherShotTiming.windStartup;
  double age = 0;
  bool get expired => position.x - size.x >= rightEdge();
  int get frameIndex {
    var end = 0.0;
    for (var i = 0; i < holdTicks.length; i++) {
      end += holdTicks[i] / 24;
      if (age + 1e-8 < end) return i;
    }
    return 7;
  }

  @override
  void update(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    final previousTravel = (age - startupDuration).clamp(0.0, double.infinity);
    age += dt;
    final travel = (age - startupDuration).clamp(0.0, double.infinity);
    position.x += speed * (travel - previousTravel);
    sprite = frames[frameIndex];
    super.update(dt);
    if (expired) removeFromParent();
  }
}

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';

/// Existing left-facing movement art. No enemy attack assets are loaded.
class EnemyMotionAssets {
  EnemyMotionAssets._(this._movement);
  final Map<String, SpriteAnimation> _movement;
  static const cycleSeconds = .5;

  static Future<EnemyMotionAssets> load(FlameGame game) async {
    final movement = <String, SpriteAnimation>{};
    for (final id in ['slime', 'goblin']) {
      final image = await game.images.load('enemies/${id}_move_sheet.png');
      final sheet = SpriteSheet(image: image, srcSize: Vector2.all(128));
      movement[id] = SpriteAnimation.spriteList(
        [for (var i = 0; i < 6; i++) sheet.getSprite(i ~/ 3, i % 3)],
        stepTime: cycleSeconds / 6,
        loop: true,
      );
    }
    return EnemyMotionAssets._(movement);
  }

  Sprite frameAt(String id, double seconds) {
    final animation = _movement[id];
    if (animation == null) throw StateError('Missing enemy movement art: $id');
    final frame = ((seconds % cycleSeconds) / (cycleSeconds / 6)).floor();
    return animation.frames[frame.clamp(0, 5).toInt()].sprite;
  }
}

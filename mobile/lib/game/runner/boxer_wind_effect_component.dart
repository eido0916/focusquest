import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Eight supplied wind poses, held without morphing or fading.
class BoxerWindEffectComponent extends PositionComponent {
  BoxerWindEffectComponent({
    required this.frames,
    required Vector2 kickPosition,
    double initialAge = 0,
  })  : _age = initialAge,
        super(
          position: kickPosition,
          size: Vector2(math.max(0, rightEdge - kickPosition.x), 0),
          priority: 7,
        ) {
    size.y = sourceHeight * displayScale;
  }

  static const rightEdge = 958.0;
  static const frameDuration = 2 / 24;
  static const duration = 8 * frameDuration;
  static const sourceHeight = 212.0;
  static const sourceAxisY = 373.0;
  // Unequal montage columns. All crops share the same horizontal wind axis.
  static const sourceRects = <Rect>[
    Rect.fromLTRB(0, 252, 168, 464),
    Rect.fromLTRB(168, 252, 410, 464),
    Rect.fromLTRB(410, 252, 699, 464),
    Rect.fromLTRB(699, 252, 1035, 464),
    Rect.fromLTRB(1035, 252, 1388, 464),
    Rect.fromLTRB(1388, 252, 1663, 464),
    Rect.fromLTRB(1663, 252, 1937, 464),
    Rect.fromLTRB(1937, 252, 2172, 464),
  ];
  static const maxSourceWidth = 353.0;

  final List<Sprite> frames;
  double _age;
  int get currentFrame => ((_age + 1e-7) / frameDuration).floor().clamp(0, 7);
  double get displayScale => size.x / maxSourceWidth;

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age + 1e-7 >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_age + 1e-7 >= duration || size.x <= 0) return;
    final sprite = frames[currentFrame];
    sprite.render(
      canvas,
      position: Vector2(0, (252 - sourceAxisY) * displayScale),
      size: sprite.srcSize * displayScale,
      overridePaint: Paint()
        ..blendMode = BlendMode.screen
        ..filterQuality = FilterQuality.none,
    );
  }
}

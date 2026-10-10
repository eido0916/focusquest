import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// The supplied eight unequal-width frames grow from the sword's ground hit.
class SousenGroundWaveComponent extends PositionComponent {
  SousenGroundWaveComponent({
    required this.frames,
    required Vector2 impactPosition,
    this.initialAge = 0,
  }) : super(
          position: impactPosition,
          size: Vector2(math.max(0, rightEdge - impactPosition.x), 0),
          anchor: Anchor.bottomLeft,
          priority: 7,
        ) {
    _age = initialAge;
    size.y = 348 * size.x / 393;
  }

  static const rightEdge = 958.0;
  static const frameDuration = .08;
  static const fadeDuration = .16;
  static const duration = 8 * frameDuration + fadeDuration;

  // The source is a montage, not an evenly spaced atlas. Keep its order and
  // ground baseline while removing the surrounding empty area from each crop.
  static const sourceRects = <Rect>[
    Rect.fromLTRB(46, 458, 216, 547),
    Rect.fromLTRB(255, 430, 426, 547),
    Rect.fromLTRB(460, 409, 639, 547),
    Rect.fromLTRB(655, 388, 853, 547),
    Rect.fromLTRB(868, 358, 1086, 547),
    Rect.fromLTRB(1114, 324, 1407, 547),
    Rect.fromLTRB(1421, 269, 1743, 547),
    Rect.fromLTRB(1758, 199, 2151, 547),
  ];

  final List<Sprite> frames;
  final double initialAge;
  double _age = 0;

  int get currentFrame => (_age / frameDuration).floor().clamp(0, 7);

  @override
  void update(double dt) {
    super.update(dt);
    _age += dt;
    if (_age >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    if (_age >= duration || size.x <= 0) return;
    final sprite = frames[currentFrame];
    final scale = size.x / 393;
    final frameSize = sprite.srcSize * scale;
    final opacity =
        (1 - (_age - 8 * frameDuration) / fadeDuration).clamp(0.0, 1.0);
    sprite.render(
      canvas,
      position: Vector2(0, size.y - frameSize.y),
      size: frameSize,
      // The original RGB artwork has a black background. Screen blending
      // makes black invisible and preserves the supplied blue/white glow.
      overridePaint: Paint()
        ..blendMode = BlendMode.screen
        ..filterQuality = FilterQuality.none
        ..color = Color.fromRGBO(255, 255, 255, opacity),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Short blue-white slash rendered independently from the character sprites.
class SousenSlashEffectComponent extends PositionComponent {
  SousenSlashEffectComponent({required Vector2 impactPosition})
      : super(
          position: impactPosition,
          size: Vector2(205, 145),
          anchor: Anchor.center,
          priority: 7,
        );

  static const _lifetime = .2;
  double _age = 0;

  @override
  void update(double dt) {
    _age += dt;
    if (_age >= _lifetime) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final progress = (_age / _lifetime).clamp(0.0, 1.0);
    final opacity = math.sin(progress * math.pi).clamp(0.0, 1.0);
    final path = Path()
      ..moveTo(13, 126)
      ..quadraticBezierTo(105, 12, 194, 22);
    canvas.save();
    canvas.scale(.92 + progress * .12, .92 + progress * .12);
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(35, 154, 255, .32 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 18,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(116, 224, 255, .78 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 8,
    );
    canvas.drawPath(
      path,
      Paint()
        ..color = Color.fromRGBO(245, 253, 255, .96 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 2.5,
    );
    canvas.restore();
  }
}

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class DamageTextComponent extends Component {
  DamageTextComponent(this.x, this.damage);
  final double x;
  final int damage;
  double age = 0;
  @override
  void update(double dt) {
    age += dt;
    if (age >= .6) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final text = TextPainter(
        text: TextSpan(
            text: '$damage',
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity((1 - age / .6).clamp(0, 1)),
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
        textDirection: TextDirection.ltr)
      ..layout();
    text.paint(canvas, Offset(x - 12, 352 - age * 65));
  }
}

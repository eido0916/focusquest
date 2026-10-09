import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class EnemyComponent extends Component {
  EnemyComponent(this.enemy);
  final RunnerEnemy enemy;
  @override
  void render(Canvas canvas) {
    final c = canvas;
    final opacity = (1 - enemy.hitAge / .5).clamp(0.0, 1.0);
    final p = Paint();
    c.save();
    c.translate(
        enemy.x, 411 - math.sin(enemy.age * 9).abs() * 7 - enemy.hitAge * 45);
    c.drawOval(const Rect.fromLTWH(-25, 15, 50, 10),
        p..color = Colors.black.withOpacity(.15 * opacity));
    p.color = (enemy.phase == EnemyPhase.hit
            ? Colors.white
            : enemy.data.id == 'slime'
                ? const Color(0xff57bcd0)
                : const Color(0xff80a14f))
        .withOpacity(opacity);
    if (enemy.data.id == 'slime') {
      c.drawPath(
          Path()
            ..moveTo(-27, 14)
            ..quadraticBezierTo(-32, -8, 0, -30)
            ..quadraticBezierTo(34, -7, 27, 14)
            ..quadraticBezierTo(0, 29, -27, 14)
            ..close(),
          p);
    } else {
      c.drawRRect(
          RRect.fromRectAndRadius(
              const Rect.fromLTWH(-22, -33, 44, 54), const Radius.circular(10)),
          p);
      c.drawPath(
          Path()
            ..moveTo(-20, -22)
            ..lineTo(-38, -33)
            ..lineTo(-20, -4)
            ..close(),
          p);
      c.drawPath(
          Path()
            ..moveTo(20, -22)
            ..lineTo(38, -33)
            ..lineTo(20, -4)
            ..close(),
          p);
    }
    p.color = const Color(0xff153640).withOpacity(opacity);
    c.drawCircle(const Offset(-8, -5), 3, p);
    c.drawCircle(const Offset(8, -5), 3, p);
    c.restore();
  }
}

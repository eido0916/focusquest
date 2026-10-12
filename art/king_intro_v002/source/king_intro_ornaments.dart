import 'dart:math' as math;
import 'package:flutter/material.dart';

const kingIntroGold = Color(0xffe5ba7c);

void _diamond(Canvas c, Offset o, double r, Paint p) {
  c.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - r)
        ..lineTo(o.dx + r * .7, o.dy)
        ..lineTo(o.dx, o.dy + r)
        ..lineTo(o.dx - r * .7, o.dy)
        ..close(),
      p);
}

class KingTitleRulePainter extends CustomPainter {
  const KingTitleRulePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    final s = size;
    final p = Paint()
      ..color = kingIntroGold
      ..strokeWidth = .8
      ..style = PaintingStyle.stroke;
    final y = s.height / 2;
    c.drawLine(Offset(0, y), Offset(s.width / 2 - 9, y), p);
    c.drawLine(Offset(s.width / 2 + 9, y), Offset(s.width, y), p);
    _diamond(c, Offset(s.width / 2, y), 6, p);
    _diamond(c, Offset(8, y), 2, p);
    _diamond(c, Offset(s.width - 8, y), 2, p);
  }

  @override
  bool shouldRepaint(KingTitleRulePainter oldDelegate) => false;
}

class KingContinuePainter extends CustomPainter {
  const KingContinuePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    final s = size;
    final p = Paint()
      ..color = kingIntroGold
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    for (final y in [3.0, 9.0]) {
      c.drawPath(
          Path()
            ..moveTo(2, y)
            ..lineTo(s.width / 2, y + 7)
            ..lineTo(s.width - 2, y),
          p);
    }
  }

  @override
  bool shouldRepaint(KingContinuePainter oldDelegate) => false;
}

class KingDialogueFramePainter extends CustomPainter {
  const KingDialogueFramePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = canvas;
    final s = size;
    final rect = Offset.zero & s;
    c.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(2), const Radius.circular(11)),
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xf20c1020),
                Color(0xed090c19),
                Color(0xf2161931)
              ]).createShader(rect));
    final cp = Paint()
      ..color = const Color(0x167c694e)
      ..strokeWidth = .65
      ..style = PaintingStyle.stroke;
    final center = Offset(s.width * .86, s.height * .55);
    final r = math.min(s.height * .31, s.width * .13);
    c.drawCircle(center, r, cp);
    c.drawCircle(center, r * .77, cp);
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final tip = center + Offset(math.cos(a), math.sin(a)) * r * 1.2;
      final l = center + Offset(math.cos(a + .5), math.sin(a + .5)) * r * .24;
      final b = center + Offset(math.cos(a - .5), math.sin(a - .5)) * r * .24;
      c.drawPath(
          Path()
            ..moveTo(tip.dx, tip.dy)
            ..lineTo(l.dx, l.dy)
            ..lineTo(center.dx, center.dy)
            ..lineTo(b.dx, b.dy)
            ..close(),
          cp);
    }
    final p = Paint()
      ..color = kingIntroGold
      ..strokeWidth = .9
      ..style = PaintingStyle.stroke;
    final w = s.width, h = s.height;
    c.drawPath(
        Path()
          ..moveTo(12, 2)
          ..lineTo(w - 12, 2)
          ..lineTo(w - 2, 12)
          ..lineTo(w - 2, h - 12)
          ..lineTo(w - 12, h - 2)
          ..lineTo(12, h - 2)
          ..lineTo(2, h - 12)
          ..lineTo(2, 12)
          ..close(),
        p);
    c.drawRRect(
        RRect.fromRectAndRadius(rect.deflate(5), const Radius.circular(8)),
        p..strokeWidth = .5);
    for (final x in [0.0, w]) {
      for (final y in [0.0, h]) {
        final sx = x == 0 ? 1.0 : -1.0, sy = y == 0 ? 1.0 : -1.0;
        c.drawPath(
            Path()
              ..moveTo(x + sx * 2, y + sy * 24)
              ..lineTo(x + sx * 2, y + sy * 10)
              ..lineTo(x + sx * 10, y + sy * 2)
              ..lineTo(x + sx * 24, y + sy * 2)
              ..lineTo(x + sx * 5, y + sy * 21),
            p..strokeWidth = 1);
      }
    }
    for (final y in [2.0, h - 2]) {
      c.drawRect(
          Rect.fromCenter(center: Offset(w / 2, y), width: 24, height: 5),
          Paint()..color = const Color(0xff101326));
      _diamond(c, Offset(w / 2, y), 7, p);
      _diamond(c, Offset(w / 2, y), 3, p);
      c.drawPath(
          Path()
            ..moveTo(w / 2 - 13, y)
            ..lineTo(w / 2 - 8, y - 3)
            ..lineTo(w / 2 - 5, y)
            ..moveTo(w / 2 + 13, y)
            ..lineTo(w / 2 + 8, y + 3)
            ..lineTo(w / 2 + 5, y),
          p);
    }
  }

  @override
  bool shouldRepaint(KingDialogueFramePainter oldDelegate) => false;
}

import 'dart:math' as math;
import 'package:flutter/material.dart';

const sunlitGold = Color(0xffdfbd77);
const sunlitInk = Color(0xff071c3c);

/// Reference-inspired ornament drawn at the actual control size.
class SunlitFrame extends StatelessWidget {
  const SunlitFrame(
      {super.key,
      required this.child,
      this.light = false,
      this.compact = false,
      this.scenery = false,
      this.padding = const EdgeInsets.all(16)});
  final Widget child;
  final bool light;
  final bool compact;
  final bool scenery;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => CustomPaint(
      foregroundPainter: SunlitFramePainter(compact: compact),
      child: ClipPath(
          clipper: const _FrameClipper(),
          child: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: light
                          ? const [Color(0xfffffbec), Color(0xffeee0c0)]
                          : const [Color(0xef071d31), Color(0xf2051628)])),
              child: Stack(alignment: Alignment.center, children: [
                if (scenery)
                  Positioned.fill(
                      child: Opacity(
                          opacity: light ? .10 : .12,
                          child: Image.asset(
                              'assets/images/ui/sunlit_kingdom.png',
                              fit: BoxFit.cover,
                              alignment: const Alignment(1, -.45)))),
                Padding(padding: padding, child: child),
              ]))));
}

Path _outline(Size s, double inset) {
  const cut = 11.0;
  return Path()
    ..moveTo(inset + cut, inset)
    ..lineTo(s.width - inset - cut, inset)
    ..lineTo(s.width - inset, inset + cut)
    ..lineTo(s.width - inset, s.height - inset - cut)
    ..lineTo(s.width - inset - cut, s.height - inset)
    ..lineTo(inset + cut, s.height - inset)
    ..lineTo(inset, s.height - inset - cut)
    ..lineTo(inset, inset + cut)
    ..close();
}

class _FrameClipper extends CustomClipper<Path> {
  const _FrameClipper();
  @override
  Path getClip(Size size) => _outline(size, 0);
  @override
  bool shouldReclip(_FrameClipper oldClipper) => false;
}

class SunlitFramePainter extends CustomPainter {
  const SunlitFramePainter({this.compact = false});
  final bool compact;
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..shader = const LinearGradient(colors: [
        Color(0xffac7a35),
        Color(0xffffe9ad),
        sunlitGold,
        Color(0xffffe7ac)
      ]).createShader(Offset.zero & size);
    for (final inset in compact ? [1.5, 4.5] : [1.5, 4.5, 8.0]) {
      p.strokeWidth = inset == 4.5 ? 2 : .8;
      canvas.drawPath(_outline(size, inset), p);
    }
    if (compact) return;
    p.strokeWidth = .8;
    for (final corner in [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height)
    ]) {
      canvas.save();
      canvas.translate(corner.dx, corner.dy);
      canvas.scale(corner.dx == 0 ? 1 : -1, corner.dy == 0 ? 1 : -1);
      canvas.drawPath(
          Path()
            ..moveTo(3, 28)
            ..lineTo(10, 18)
            ..lineTo(7, 12)
            ..lineTo(18, 10)
            ..lineTo(28, 3)
            ..moveTo(8, 30)
            ..quadraticBezierTo(13, 13, 30, 8)
            ..moveTo(4, 18)
            ..lineTo(18, 4)
            ..lineTo(14, 14)
            ..close(),
          p);
      canvas.restore();
    }
    for (final y in [4.0, size.height - 4]) {
      final x = size.width / 2;
      canvas.drawPath(
          Path()
            ..moveTo(x - 7, y)
            ..lineTo(x, y - 6)
            ..lineTo(x + 7, y)
            ..lineTo(x, y + 6)
            ..close(),
          p);
      canvas.drawPath(
          Path()
            ..moveTo(x - 2, y)
            ..lineTo(x, y - 3)
            ..lineTo(x + 2, y)
            ..lineTo(x, y + 3)
            ..close(),
          p);
    }
  }

  @override
  bool shouldRepaint(SunlitFramePainter oldDelegate) =>
      oldDelegate.compact != compact;
}

class CompassEmblem extends StatelessWidget {
  const CompassEmblem({super.key, this.size = 48});
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: const _CompassPainter());
}

class _CompassPainter extends CustomPainter {
  const _CompassPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * .42;
    final line = Paint()
      ..color = sunlitGold
      ..style = PaintingStyle.stroke
      ..strokeWidth = .9;
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, r * .9, line);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4 - math.pi / 2;
      Offset point(double radius, double a) =>
          c + Offset(math.cos(a) * radius, math.sin(a) * radius);
      final tip = point(i.isEven ? r * 1.2 : r * .78, angle);
      final left = point(r * .18, angle - math.pi / 2);
      final right = point(r * .18, angle + math.pi / 2);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(left.dx, left.dy)
            ..lineTo(tip.dx, tip.dy)
            ..close(),
          Paint()..color = sunlitGold);
      canvas.drawPath(
          Path()
            ..moveTo(c.dx, c.dy)
            ..lineTo(right.dx, right.dy)
            ..lineTo(tip.dx, tip.dy)
            ..close(),
          line);
    }
    canvas.drawCircle(c, 2, Paint()..color = const Color(0xffffebad));
  }

  @override
  bool shouldRepaint(_CompassPainter oldDelegate) => false;
}

class SunlitAction extends StatelessWidget {
  const SunlitAction(
      {super.key,
      required this.label,
      required this.onTap,
      this.light = false});
  final String label;
  final VoidCallback onTap;
  final bool light;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: onTap,
              child: SunlitFrame(
                  light: light,
                  padding: EdgeInsets.zero,
                  child: LayoutBuilder(builder: (context, constraints) {
                    final width = constraints.maxWidth;
                    return ConstrainedBox(
                        constraints: BoxConstraints(minHeight: width * .195),
                        child: Stack(alignment: Alignment.center, children: [
                          Positioned.fill(
                              child: Image.asset(
                                  'assets/images/ui/sunlit_kingdom.png',
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(1, -.4))),
                          Positioned.fill(
                              child: DecoratedBox(
                                  decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                          colors: light
                                              ? const [
                                                  Color(0xfffff9e9),
                                                  Color(0xf4fff9e9),
                                                  Color(0x20fff9e9)
                                                ]
                                              : const [
                                                  Color(0xff084d88),
                                                  Color(0xf5084d88),
                                                  Color(0x20084d88)
                                                ],
                                          stops: const [0, .6, 1])))),
                          Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 15, vertical: 14),
                              child: Row(children: [
                                if (light)
                                  Icon(Icons.map_outlined,
                                      color: const Color(0xffb28b4c),
                                      size: width * .125)
                                else
                                  CompassEmblem(size: width * .16),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Text(label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontFamily: 'SunlitSerif',
                                            fontSize: width * .059,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                            color: light
                                                ? sunlitInk
                                                : Colors.white))),
                                const Icon(Icons.chevron_right_rounded,
                                    color: sunlitGold, size: 28),
                              ])),
                        ]));
                  })))));
}

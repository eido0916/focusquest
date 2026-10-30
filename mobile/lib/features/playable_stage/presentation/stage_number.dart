import 'package:flutter/material.dart';

/// Optical bounds measured from the bundled NotoSerifJP.ttf, relative to the
/// alphabetic baseline at 1em. Font line boxes contain extra space above digits.
const _digitInk = <int, Rect>{
  1: Rect.fromLTRB(0.077, -0.733, 0.425, 0),
  2: Rect.fromLTRB(0.065, -0.737, 0.498, 0),
  3: Rect.fromLTRB(0.048, -0.737, 0.476, 0.014),
  4: Rect.fromLTRB(0.034, -0.734, 0.52, 0.019),
  5: Rect.fromLTRB(0.046, -0.723, 0.486, 0.014),
  6: Rect.fromLTRB(0.06, -0.737, 0.492, 0.014),
  7: Rect.fromLTRB(0.054, -0.723, 0.475, 0),
  8: Rect.fromLTRB(0.058, -0.737, 0.487, 0.014),
  9: Rect.fromLTRB(0.057, -0.737, 0.489, 0.015),
  10: Rect.fromLTRB(0.077, -0.737, 0.966, 0.014),
  11: Rect.fromLTRB(0.077, -0.733, 0.898, 0),
  12: Rect.fromLTRB(0.077, -0.737, 0.971, 0),
  13: Rect.fromLTRB(0.077, -0.737, 0.949, 0.014),
  14: Rect.fromLTRB(0.077, -0.734, 0.993, 0.019),
  15: Rect.fromLTRB(0.077, -0.733, 0.959, 0.014),
  16: Rect.fromLTRB(0.077, -0.737, 0.965, 0.014),
  17: Rect.fromLTRB(0.077, -0.733, 0.948, 0),
  18: Rect.fromLTRB(0.077, -0.737, 0.96, 0.014),
  19: Rect.fromLTRB(0.077, -0.737, 0.962, 0.015),
  20: Rect.fromLTRB(0.065, -0.737, 1.037, 0.014),
  21: Rect.fromLTRB(0.065, -0.737, 0.969, 0),
  22: Rect.fromLTRB(0.065, -0.737, 1.042, 0),
  23: Rect.fromLTRB(0.065, -0.737, 1.02, 0.014),
  24: Rect.fromLTRB(0.065, -0.737, 1.064, 0.019),
  25: Rect.fromLTRB(0.065, -0.737, 1.03, 0.014),
  26: Rect.fromLTRB(0.065, -0.737, 1.036, 0.014),
  27: Rect.fromLTRB(0.065, -0.737, 1.019, 0),
  28: Rect.fromLTRB(0.065, -0.737, 1.031, 0.014),
  29: Rect.fromLTRB(0.065, -0.737, 1.033, 0.015),
  30: Rect.fromLTRB(0.048, -0.737, 1.035, 0.014),
  31: Rect.fromLTRB(0.048, -0.737, 0.967, 0.014),
  32: Rect.fromLTRB(0.048, -0.737, 1.04, 0.014),
  33: Rect.fromLTRB(0.048, -0.737, 1.018, 0.014),
  34: Rect.fromLTRB(0.048, -0.737, 1.062, 0.019),
  35: Rect.fromLTRB(0.048, -0.737, 1.028, 0.014),
  36: Rect.fromLTRB(0.048, -0.737, 1.034, 0.014),
};

class StageNumber extends StatelessWidget {
  const StageNumber({super.key, required this.number, required this.locked});
  final int number;
  final bool locked;

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        final side = bounds.biggest.shortestSide;
        final fontSize = side * (locked ? .37 : .54);
        final ink = _digitInk[number]!;
        final style = TextStyle(
            inherit: false,
            fontFamily: 'SunlitSerif',
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            fontSize: fontSize,
            height: 1,
            color: const Color(0xffffefd0),
            shadows: const [Shadow(color: Color(0xcc00152c), blurRadius: 1)]);
        final text = TextPainter(
            text: TextSpan(text: '$number', style: style),
            textDirection: TextDirection.ltr,
            textScaler: TextScaler.noScaling,
            maxLines: 1)
          ..layout();
        final baseline =
            text.computeDistanceToActualBaseline(TextBaseline.alphabetic);
        final left = side / 2 - ink.center.dx * fontSize;
        final top =
            side * (locked ? .65 : .5) - baseline - ink.center.dy * fontSize;
        final width = text.width + 1;
        final height = text.height + 1;
        text.dispose();
        return Stack(clipBehavior: Clip.none, children: [
          Positioned(
              left: left,
              top: top,
              width: width,
              height: height,
              child: Text('$number',
                  textDirection: TextDirection.ltr,
                  textScaler: TextScaler.noScaling,
                  maxLines: 1,
                  style: style)),
        ]);
      });
}

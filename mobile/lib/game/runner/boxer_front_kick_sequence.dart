import 'dart:ui';

/// Stable source IDs; each hold replays a supplied pose without interpolation.
class BoxerFrontKickSequence {
  static const frameIds = <int>[
    4,
    5,
    6,
    7,
    8,
    9,
    10,
    11,
    12,
    13,
    14,
    21,
    22,
    23,
    24,
    26,
    27
  ];
  static const holdTicks = <int>[
    1,
    1,
    2,
    2,
    2,
    2,
    2,
    1,
    1,
    1,
    2,
    1,
    1,
    2,
    2,
    1,
    1
  ];
  static const impactIndex = 10;
  static const sourcePixelDisplayScale = 215 / 328 / 2;
  static List<double> get stepTimes => [for (final t in holdTicks) t / 24];
  static double timeAt(int index) =>
      holdTicks.take(index).fold(0, (a, b) => a + b) / 24;
  static double get impactTime => timeAt(impactIndex);
  static double get duration => timeAt(holdTicks.length);
  static int indexAt(double age) {
    for (var i = 0; i < frameIds.length; i++) {
      if (age + 1e-7 < timeAt(i + 1)) return i;
    }
    return frameIds.length - 1;
  }

  /// The forward area reaches the right edge of the 960px logical viewport.
  static const attackRightEdge = 960.0;
  static Rect hitArea({double x = 345, double groundY = 405}) =>
      Rect.fromLTRB(x, groundY - 120, attackRightEdge, groundY - 15);

  /// Scroll speed; the sprite keeps its screen anchor throughout the skill.
  static double speedRatioAt(double age) {
    if (age < timeAt(4)) return 1 - .8 * age / timeAt(4);
    if (age < timeAt(9)) return .2;
    if (age < timeAt(11)) return .8;
    if (age < duration) {
      return .35 + .65 * (age - timeAt(11)) / (duration - timeAt(11));
    }
    return 1;
  }
}

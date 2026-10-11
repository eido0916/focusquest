/// Reviewed source numbers remain stable even when a pose is reused.
class BoxerNormalAttackSequence {
  static const frameIds = <int>[
    1,
    2,
    3,
    11,
    12,
    13,
    14,
    13,
    12,
    16,
    21,
    23,
    24,
    25,
    24,
    23,
    22,
    26,
    27,
    28,
    29,
    30,
  ];
  static const stepTimes = <double>[
    .04,
    .04,
    .04,
    .04,
    .055,
    .100,
    .045,
    .035,
    .035,
    .030,
    .025,
    .025,
    .030,
    .045,
    .035,
    .035,
    .040,
    .055,
    .065,
    .065,
    .065,
    .065,
  ];
  static const runFrameIds = <int>[26, 27, 28, 29, 30];
  static const hitFrameIndexes = <int>[6, 13];
  static double get duration => stepTimes.fold(0.0, (a, b) => a + b);
  static double timeAt(int index) =>
      stepTimes.take(index).fold(0.0, (a, b) => a + b);
  static List<double> get hitTimes =>
      [for (final index in hitFrameIndexes) timeAt(index)];
  static int indexAt(double age) {
    var end = 0.0;
    for (var i = 0; i < stepTimes.length; i++) {
      end += stepTimes[i];
      if (age < end - 1e-7) return i;
    }
    return stepTimes.length - 1;
  }
}

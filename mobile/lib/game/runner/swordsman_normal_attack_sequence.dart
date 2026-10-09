/// Normal attack only. This does not change the Sousen skill or its cooldown.
class SwordsmanNormalAttackSequence {
  static const frameIds = <String>[
    'file_01_f1', 'file_01_f2', 'file_01_f3', // Run.
    'file_02_f1', 'file_02_f2', 'file_02_f3', // Brief shoulder-level draw.
    'file_02_f5', 'file_03_f2', // First slash, then follow-through.
    'file_04_f1', 'file_04_f2', // Reset forward, second slash.
    'file_04_f3', 'file_07_f4', 'file_07_f5', // Recover without stopping.
    'file_09_f2', 'file_09_f3', 'file_09_f4', 'file_09_f5', // Run.
  ];

  // Seconds; edit here to change tempo without regenerating the PNG atlas.
  static const stepTimes = <double>[
    .05,
    .05,
    .05,
    .05,
    .055,
    .06,
    .065, // Slower sword motion; keep the running cadence unchanged.
    .08,
    .08,
    .075, // Second slash.
    .08,
    .05,
    .05,
    .05,
    .05,
    .05,
    .05,
  ];
  static const runFrameIds = <String>[
    'file_09_f2',
    'file_09_f3',
    'file_09_f4',
    'file_09_f5',
  ];
  // Zero-based selected indexes, not source sheet indexes.
  static const hitFrameIndexes = <int>[6, 9];
  static double get duration => stepTimes.fold(0.0, (a, b) => a + b);
  static double timeAt(int frameIndex) =>
      stepTimes.take(frameIndex).fold(0.0, (a, b) => a + b);
  static List<double> get hitTimes =>
      [for (final index in hitFrameIndexes) timeAt(index)];
}

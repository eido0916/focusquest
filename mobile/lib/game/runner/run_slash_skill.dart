/// Shared timing and movement data for the 30-frame running two-slash skill.
/// Frame numbers exposed here are one-based, matching the source sheet order.
class RunSlashSkill {
  const RunSlashSkill({this.advanceDistance = 48, this.facing = 1});

  final double advanceDistance;
  final int facing;

  static const frameTimes = <double>[
    .08,
    .08,
    .08,
    .08,
    .08,
    .08,
    .08,
    .09,
    .09,
    .10,
    .09,
    .07,
    .07,
    .12,
    .12,
    .09,
    .09,
    .09,
    .09,
    .10,
    .09,
    .09,
    .09,
    .07,
    .14,
    .12,
    .10,
    .08,
    .08,
    .08,
  ];

  static double get duration => frameTimes.fold(0, (sum, time) => sum + time);

  static double frameStart(int frame) =>
      frameTimes.take(frame - 1).fold(0, (sum, time) => sum + time);

  static int frameAt(double elapsed) {
    var end = 0.0;
    for (var index = 0; index < frameTimes.length; index++) {
      end += frameTimes[index];
      if (elapsed < end) return index + 1;
    }
    return 30;
  }

  static bool isAttackFrame(int frame) =>
      (frame >= 11 && frame <= 15) || (frame >= 21 && frame <= 25);

  // One resolution per swing, even when a long update crosses several frames.
  static final hitTimes = [frameStart(13), frameStart(25)];

  double offsetAt(double elapsed) {
    final recoveryStart = frameStart(26);
    if (elapsed <= recoveryStart) {
      return advanceDistance *
          facing *
          (elapsed / recoveryStart).clamp(0.0, 1.0);
    }
    // Ease back to the runner's screen anchor during the final running poses.
    final progress = ((elapsed - recoveryStart) / (duration - recoveryStart))
        .clamp(0.0, 1.0);
    final eased = progress * progress * (3 - 2 * progress);
    return advanceDistance * facing * (1 - eased);
  }
}

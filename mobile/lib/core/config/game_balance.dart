class GameBalance {
  static const focusPresets = [15, 30, 45, 60];
  static const maximumFocusMinutes = 180;
  static const expPerMinute = 10;

  /// Focus earns EXP by time, independently of the decorative battle's kills.
  static int focusExpForSeconds(double elapsedSeconds,
          {required double durationSeconds}) =>
      (elapsedSeconds.clamp(0.0, durationSeconds) * expPerMinute / 60).floor();

  static const coinsPerThirtyMinutes = 100;
  static int requiredExp(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    return 100 + (level - 1) * 50;
  }
}

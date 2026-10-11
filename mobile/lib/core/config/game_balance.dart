class GameBalance {
  static const focusPresets = [15, 30, 45, 60];
  static const maximumFocusMinutes = 180;
  static const expPerMinute = 10;
  static const coinsPerThirtyMinutes = 100;
  static int requiredExp(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    return 100 + (level - 1) * 50;
  }
}

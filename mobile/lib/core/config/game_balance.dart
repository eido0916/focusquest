class GameBalance {
  static const focusPresets = [15, 30, 45, 60];
  static const maximumFocusMinutes = 180;
  static const focusEnemyExp = 1;
  static const focusBossExp = 100;

  static int focusExpForDefeats(int defeats, int bosses) {
    if (defeats < 0 || bosses < 0 || bosses > defeats) {
      throw ArgumentError('Invalid focus defeat counts');
    }
    return (defeats - bosses) * focusEnemyExp + bosses * focusBossExp;
  }

  static const coinsPerThirtyMinutes = 100;
  static int requiredExp(int level) {
    if (level < 1) throw ArgumentError.value(level, 'level');
    // A first 30-minute solo session reaches around Lv.4, with progressively
    // more focus needed for later levels. Existing earned levels are preserved.
    return 300 + (level - 1) * 150;
  }
}

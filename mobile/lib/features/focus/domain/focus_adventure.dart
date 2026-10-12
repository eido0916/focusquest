import '../../playable_stage/domain/playable_stage_catalog.dart';

/// Each complete 30-minute session cycle has a boss during its last five minutes.
class FocusAdventure {
  static List<int> unlockedAreas(Set<int> cleared) => [
        for (var area = 0; area < 9; area++)
          if (List.generate(4, (i) => area * 4 + i + 1).every(cleared.contains))
            area
      ];

  static const travelSeconds = 25 * 60;
  static const bossSeconds = 5 * 60;
  static const cycleSeconds = travelSeconds + bossSeconds;
  static int cycle(double seconds) => seconds ~/ cycleSeconds;
  static int chapter(double seconds) => seconds < cycleSeconds ? 1 : 2;
  static double age(double seconds) => seconds % cycleSeconds;
  static bool fightingBoss(double seconds) => age(seconds) >= travelSeconds;

  /// Use session elapsed time, never cumulative focus history. Incomplete
  /// trailing cycles keep ordinary enemies instead of starting a partial boss.
  static bool bossActive(double elapsedSeconds,
          {required double durationSeconds}) =>
      elapsedSeconds >= 0 &&
      elapsedSeconds < durationSeconds &&
      cycle(elapsedSeconds) < durationSeconds ~/ cycleSeconds &&
      fightingBoss(elapsedSeconds);
  static int completedBossCycles(double elapsedSeconds,
          {required double durationSeconds}) =>
      elapsedSeconds.clamp(0.0, durationSeconds).toDouble() ~/ cycleSeconds;

  static String bossId(double seconds, {int? areaIndex}) => areaIndex != null
      ? PlayableStageCatalog.bossIds[areaIndex < 0 ? 0 : areaIndex]
      : chapter(seconds) == 1
          ? 'boss_goblin_king'
          : 'boss_dullahan';
  static String bossName(double seconds, {int? areaIndex}) => areaIndex != null
      ? PlayableStageCatalog.bossNames[areaIndex < 0 ? 0 : areaIndex]
      : chapter(seconds) == 1
          ? 'ゴブリンキング'
          : '騎乗デュラハン';
  static String area(double seconds, {int? areaIndex}) => areaIndex == null
      ? (chapter(seconds) == 1 ? '草原' : '幽霊船')
      : areaIndex < 0
          ? '訓練場'
          : PlayableStageCatalog.areas[areaIndex];
  static String background(double seconds, {int? areaIndex}) =>
      areaIndex != null
          ? (areaIndex < 0
              ? 'ui/forest_meadow_pixel_v001.png'
              : PlayableStageCatalog.backgrounds[areaIndex]
                  .replaceFirst('assets/images/', ''))
          : chapter(seconds) == 1
              ? 'ui/forest_meadow_pixel_v001.png'
              : 'stage_backgrounds/ghost_ship_focus_v002.png';
}

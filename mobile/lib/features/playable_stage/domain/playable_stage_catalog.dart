class StageOpponent {
  const StageOpponent(
      this.id, this.name, this.hp, this.damage, this.interval, this.subtitle,
      {this.isBoss = false, this.count = 1});
  final String id, name, subtitle;
  final int hp, damage;
  final double interval;
  final bool isBoss;
  final int count;
}

class PlayableStageDefinition {
  const PlayableStageDefinition(this.number, this.area, this.backgroundPath,
      this.groundLine, this.opponents);
  final int number;
  final String area, backgroundPath;
  final double groundLine;
  final List<StageOpponent> opponents;
  bool get hasBoss => opponents.last.isBoss;
  String get title => 'STAGE $number · $area';
  List<StageOpponent> wave(int phase) {
    final main = opponents[phase];
    return [
      if (main.isBoss)
        ...List.filled(
            2,
            StageOpponent(
                'goblin', 'ゴブリン', 56 + number * 2, 6, 6.5, 'ボスの取り巻き')),
      ...List.filled(main.count, main),
    ];
  }
}

class PlayableStageCatalog {
  static const areas = ['草原', '幽霊船', '火山', '魔王城'];
  static const backgrounds = [
    'assets/images/playable_stage/grassland.png',
    'assets/images/stage_backgrounds/ghost_ship_v001.png',
    'assets/images/stage_backgrounds/volcano_v001.png',
    'assets/images/stage_backgrounds/demon_castle_v001.png',
  ];
  static const bossIds = [
    'boss_goblin_king',
    'boss_dullahan',
    'boss_fire_dragon',
    'boss_cyclops'
  ];
  static const bossNames = ['ゴブリンキング', '騎乗デュラハン', '火竜', 'サイクロプス'];
  static final stages =
      List<PlayableStageDefinition>.unmodifiable(List.generate(16, (index) {
    final area = index ~/ 4;
    final number = index + 1;
    final extra = index * 4;
    final boss = number % 4 == 0;
    return PlayableStageDefinition(
        number,
        areas[area],
        backgrounds[area],
        [0.885, 0.86, 0.82, 0.82][area],
        List.unmodifiable([
          StageOpponent('slime', 'スライム', 56 + extra ~/ 2, 8 + area, 6.8, '先遣隊',
              count: 2),
          StageOpponent('goblin', 'ゴブリン', 70 + extra ~/ 2, 9 + area, 6.5, '見張り',
              count: 3),
          boss
              ? StageOpponent(bossIds[area], bossNames[area], 336 + area * 56,
                  16 + area * 2, 3.8, '${areas[area]}の主', isBoss: true)
              : StageOpponent(
                  'dracula', 'ドラキュラ', 84 + extra ~/ 2, 10 + area, 6.2, '最後の守り手',
                  count: 3),
        ]));
  }));
}

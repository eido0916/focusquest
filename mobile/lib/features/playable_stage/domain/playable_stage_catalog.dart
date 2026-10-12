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
      this.groundLine, this.opponents,
      {this.bossEscort});
  final int number;
  final String area, backgroundPath;
  final double groundLine;
  final List<StageOpponent> opponents;
  final StageOpponent? bossEscort;
  String get floorMaterial => switch (area) {
        '草原' => 'grass',
        '幽霊船' => 'wood',
        '火山' => 'basalt',
        '毒茸の湿地' => 'mud',
        '砂漠の迷宮' => 'sandstone',
        '氷晶洞窟' => 'ice',
        _ => 'stone',
      };
  bool get hasBoss => opponents.last.isBoss;
  String get title => 'STAGE $number · $area';
  List<StageOpponent> wave(int phase) {
    final main = opponents[phase];
    return [
      if (main.isBoss)
        ...List.filled(
            2,
            bossEscort ??
                StageOpponent(
                    'goblin', 'ゴブリン', 56 + number * 2, 6, 6.5, 'ボスの取り巻き')),
      ...List.filled(main.count, main),
    ];
  }
}

class PlayableStageCatalog {
  static const areas = [
    '草原',
    '幽霊船',
    '火山',
    '毒茸の湿地',
    '砂漠の迷宮',
    '氷晶洞窟',
    '月影の墓地',
    '星界の祭壇',
    '魔王城'
  ];
  static const backgrounds = [
    'assets/images/playable_stage/grassland.png',
    'assets/images/stage_backgrounds/ghost_ship_focus_v002.png',
    'assets/images/stage_backgrounds/volcano_v001.png',
    'assets/images/stage_backgrounds/poison_marsh_v001.png',
    'assets/images/stage_backgrounds/desert_labyrinth_v001.png',
    'assets/images/stage_backgrounds/ice_crystal_cavern_v001.png',
    'assets/images/stage_backgrounds/moonlit_graveyard_v001.png',
    'assets/images/stage_backgrounds/astral_altar_v001.png',
    'assets/images/stage_backgrounds/demon_castle_v001.png',
  ];
  static const bossIds = [
    'boss_goblin_king',
    'boss_dullahan',
    'boss_fire_dragon',
    'boss_cerberus',
    'boss_minotaur',
    'boss_stone_golem',
    'boss_lich',
    'boss_cyclops',
    'boss_demon_lord',
  ];
  static const bossNames = [
    'ゴブリンキング',
    '騎乗デュラハン',
    '火竜',
    'ケルベロス',
    'ミノタウロス',
    '石のゴーレム',
    'リッチ',
    'サイクロプス',
    '魔王'
  ];
  static const _newMobIds = [
    ['mob_poison_mushroom', 'mob_bat', 'mob_wolf'],
    ['mob_wolf', 'mob_skeleton', 'mob_bat'],
    ['mob_bat', 'mob_wolf', 'mob_skeleton'],
    ['mob_skeleton', 'mob_bat', 'mob_poison_mushroom'],
    ['mob_imp', 'mob_bat', 'mob_skeleton'],
  ];
  static const _mobNames = {
    'mob_poison_mushroom': '毒キノコ',
    'mob_bat': 'コウモリ',
    'mob_wolf': '狼',
    'mob_skeleton': 'スケルトン',
    'mob_imp': 'インプ'
  };
  static const _escortIds = [
    'mob_poison_mushroom',
    'mob_skeleton',
    'mob_wolf',
    'mob_skeleton',
    'mob_imp'
  ];
  static final stages = List<PlayableStageDefinition>.unmodifiable(
      List.generate(areas.length * 4, (index) {
    final area = index ~/ 4;
    // Original area identity keeps opponents and balance independent of order.
    final sourceArea = [0, 1, 2, 4, 5, 6, 7, 8, 3][area];
    final sourceNumber = sourceArea * 4 + index % 4 + 1;
    final number = index + 1;
    final extra = (sourceNumber - 1) * 4;
    final boss = number % 4 == 0;
    if (sourceArea >= 4) {
      final theme = sourceArea - 4;
      StageOpponent mob(int phase) {
        final id = _newMobIds[theme][phase];
        return StageOpponent(
            id,
            _mobNames[id]!,
            60 + theme * 4 + phase * 12 + index % 4 * 2,
            8 + theme ~/ 2,
            6.8 - phase * .3,
            ['先遣隊', '見張り', '最後の守り手'][phase],
            count: phase == 0 ? 2 : 3);
      }

      final escort = _escortIds[theme];
      return PlayableStageDefinition(
          number,
          areas[area],
          backgrounds[area],
          .82,
          List.unmodifiable([
            mob(0),
            mob(1),
            boss
                ? StageOpponent(bossIds[area], bossNames[area],
                    336 + theme * 42, 16 + theme * 2, 3.8, '${areas[area]}の主',
                    isBoss: true)
                : mob(2)
          ]),
          bossEscort: StageOpponent(
              escort, _mobNames[escort]!, 64 + theme * 4, 6, 6.5, 'ボスの取り巻き'));
    }
    return PlayableStageDefinition(
        number,
        areas[area],
        backgrounds[area],
        [0.885, 0.86, 0.82, 0.82][sourceArea],
        List.unmodifiable([
          StageOpponent(
              'slime', 'スライム', 56 + extra ~/ 2, 8 + sourceArea, 6.8, '先遣隊',
              count: 2),
          StageOpponent(
              'goblin', 'ゴブリン', 70 + extra ~/ 2, 9 + sourceArea, 6.5, '見張り',
              count: 3),
          boss
              ? StageOpponent(
                  bossIds[area],
                  bossNames[area],
                  336 + sourceArea * 56,
                  16 + sourceArea * 2,
                  3.8,
                  '${areas[area]}の主',
                  isBoss: true)
              : StageOpponent('dracula', 'ドラキュラ', 84 + extra ~/ 2,
                  10 + sourceArea, 6.2, '最後の守り手',
                  count: 3),
        ]),
        bossEscort: StageOpponent(
            'goblin', 'ゴブリン', 56 + sourceNumber * 2, 6, 6.5, 'ボスの取り巻き'));
  }));
}

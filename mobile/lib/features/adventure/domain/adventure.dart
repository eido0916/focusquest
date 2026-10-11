import 'dart:math';
import '../../character/domain/stats.dart';

class AdventureEnemy {
  const AdventureEnemy(this.name, this.asset, this.stats, {this.boss = false});
  final String name;
  final String asset;
  final Stats stats;
  final bool boss;
}

class AdventureStage {
  const AdventureStage(this.id, this.name, this.description, this.level,
      this.enemies, this.coins, this.item);
  final String id, name, description, item;
  final int level, coins;
  final List<AdventureEnemy> enemies;
}

class AdventureCatalog {
  static const stages = [
    AdventureStage(
        'forest_1',
        'はじまりの草原',
        '陽光にきらめく草原。旅の第一歩を踏み出そう。',
        1,
        [
          AdventureEnemy(
              'スライム', 'slime', Stats(hp: 24, attack: 9, defense: 2, speed: 7)),
          AdventureEnemy(
              'スライム', 'slime', Stats(hp: 30, attack: 10, defense: 2, speed: 8)),
        ],
        100,
        'wooden_sword'),
    AdventureStage(
        'forest_2',
        '木漏れ日の小道',
        '森の小道に、いたずら好きの魔物が待っている。',
        3,
        [
          AdventureEnemy('スライム', 'slime',
              Stats(hp: 45, attack: 15, defense: 4, speed: 10)),
          AdventureEnemy('ゴブリン', 'goblin',
              Stats(hp: 70, attack: 19, defense: 6, speed: 11)),
        ],
        150,
        'cloth_armor'),
    AdventureStage(
        'forest_3',
        '深緑の森',
        '深い緑の向こうへ。鍛えた力で道を切り開こう。',
        5,
        [
          AdventureEnemy('森のゴブリン', 'goblin',
              Stats(hp: 95, attack: 26, defense: 10, speed: 13)),
          AdventureEnemy('大スライム', 'slime',
              Stats(hp: 130, attack: 29, defense: 12, speed: 12)),
        ],
        200,
        'silver_ring'),
    AdventureStage(
        'forest_4',
        '古き守りの境界',
        '古い石碑のそばで、魔物たちが行く手を阻む。',
        7,
        [
          AdventureEnemy('ゴブリンの斥候', 'goblin',
              Stats(hp: 130, attack: 34, defense: 15, speed: 17)),
          AdventureEnemy('ゴブリンの衛兵', 'goblin',
              Stats(hp: 170, attack: 38, defense: 18, speed: 15)),
        ],
        250,
        'cloth_armor'),
    AdventureStage(
        'forest_5',
        '森の王の玉座',
        '森を覆う影の主。旅で得た力を、いま解き放とう。',
        10,
        [
          AdventureEnemy('玉座の番人', 'goblin',
              Stats(hp: 140, attack: 32, defense: 16, speed: 17)),
          AdventureEnemy('ゴブリンの王', 'goblin',
              Stats(hp: 260, attack: 38, defense: 20, speed: 20),
              boss: true),
        ],
        500,
        'silver_ring'),
  ];
  static AdventureStage stage(String id) =>
      stages.firstWhere((s) => s.id == id);
  static bool unlocked(String id, Set<String> cleared) {
    final index = stages.indexWhere((s) => s.id == id);
    return index >= 0 && (index == 0 || cleared.contains(stages[index - 1].id));
  }
}

/// The saved snapshot makes a resumed battle independent of equipment changes.
class AdventureRun {
  const AdventureRun(
      {required this.id,
      required this.stageId,
      required this.heroName,
      this.characterType,
      this.appearance,
      required this.stats,
      required this.seed,
      required this.startedAt});
  final String id, stageId, heroName;
  // Nullable for adventures saved before appearance was recorded.
  final String? characterType, appearance;
  final Stats stats;
  final int seed;
  final DateTime startedAt;
  Map<String, dynamic> toJson() => {
        'id': id,
        'stageId': stageId,
        'heroName': heroName,
        'characterType': characterType,
        'appearance': appearance,
        'stats': stats.toJson(),
        'seed': seed,
        'startedAt': startedAt.toIso8601String()
      };
  factory AdventureRun.fromJson(Map<String, dynamic> json) => AdventureRun(
      id: json['id'] as String,
      stageId: json['stageId'] as String,
      heroName: json['heroName'] as String,
      characterType: json['characterType'] as String?,
      appearance: json['appearance'] as String?,
      stats: Stats.fromJson(Map<String, dynamic>.from(json['stats'] as Map)),
      seed: json['seed'] as int,
      startedAt: DateTime.parse(json['startedAt'] as String));
}

class AdventureEvent {
  const AdventureEvent(this.enemyIndex, this.heroHp, this.enemyHp, this.message,
      {this.heroAttacks = false, this.damage = 0});
  final int enemyIndex, heroHp, enemyHp, damage;
  final String message;
  final bool heroAttacks;
}

class AdventureBattle {
  const AdventureBattle(this.events, this.won);
  final List<AdventureEvent> events;
  final bool won;
  static const eventDuration = Duration(milliseconds: 850);
  Duration get duration => eventDuration * events.length;
  int revealed(AdventureRun run, DateTime now) =>
      (now.difference(run.startedAt).inMilliseconds ~/
              eventDuration.inMilliseconds)
          .clamp(0, events.length);

  static AdventureBattle simulate(AdventureRun run) {
    final stage = AdventureCatalog.stage(run.stageId);
    final random = Random(run.seed);
    final hero = run.stats;
    var hp = hero.hp;
    final events = <AdventureEvent>[];
    for (var index = 0; index < stage.enemies.length; index++) {
      final enemy = stage.enemies[index];
      var enemyHp = enemy.stats.hp;
      events.add(AdventureEvent(index, hp, enemyHp, '${enemy.name}が あらわれた！'));
      var heroTime = 1 / max(1, hero.speed);
      var enemyTime = 1 / max(1, enemy.stats.speed);
      var turns = 0;
      while (hp > 0 && enemyHp > 0 && turns++ < 160) {
        final heroAttacks = heroTime <= enemyTime;
        final attacker = heroAttacks ? hero : enemy.stats;
        final defender = heroAttacks ? enemy.stats : hero;
        final critical = random.nextDouble() < attacker.criticalRate;
        final damage = max(
            1,
            ((attacker.attack - defender.defense * .6) * (critical ? 1.6 : 1))
                .round());
        if (heroAttacks) {
          enemyHp = max(0, enemyHp - damage);
          heroTime += 1 / max(1, hero.speed);
        } else {
          hp = max(0, hp - damage);
          enemyTime += 1 / max(1, enemy.stats.speed);
        }
        final name = heroAttacks ? run.heroName : enemy.name;
        events.add(AdventureEvent(index, hp, enemyHp,
            '$nameの ${critical ? '会心の一撃' : '攻撃'}！ $damageのダメージ。',
            heroAttacks: heroAttacks, damage: damage));
      }
      if (hp <= 0 || enemyHp > 0) {
        events.add(AdventureEvent(index, hp, enemyHp,
            hp <= 0 ? '${run.heroName}は 力尽きた…。' : '長い戦いに疲れ、引き返した…。'));
        return AdventureBattle(List.unmodifiable(events), false);
      }
      events.add(AdventureEvent(index, hp, 0, '${enemy.name}を たおした！'));
    }
    events.add(AdventureEvent(stage.enemies.length - 1, hp, 0, 'ステージを クリアした！'));
    return AdventureBattle(List.unmodifiable(events), true);
  }
}

class AdventureRecord {
  const AdventureRecord(
      {required this.runId,
      required this.stageId,
      required this.won,
      this.coins = 0,
      this.item});
  final String runId, stageId;
  final bool won;
  final int coins;
  final String? item;
  Map<String, dynamic> toJson() => {
        'runId': runId,
        'stageId': stageId,
        'won': won,
        'coins': coins,
        'item': item
      };
  factory AdventureRecord.fromJson(Map<String, dynamic> json) =>
      AdventureRecord(
          runId: json['runId'] as String,
          stageId: json['stageId'] as String,
          won: json['won'] as bool,
          coins: json['coins'] as int,
          item: json['item'] as String?);
}

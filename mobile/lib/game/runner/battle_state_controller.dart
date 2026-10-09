enum BattlePhase {
  running,
  normalBattle,
  skill,
  bossIntro,
  bossBattle,
  bossDefeat,
  resumeRun,
  finished
}

enum HeroMotion { idle, run, attack, skill, bossAttack, victory }

enum EnemyPhase { spawn, move, hit, defeat }

class EnemyData {
  const EnemyData(this.id, {this.expReward = 10});
  final String id;
  final int expReward;
}

class RunnerConfig {
  const RunnerConfig(
      {this.spawnSeconds = .55,
      this.attackSeconds = .55,
      this.enemySpeed = 230,
      this.enemies = const [EnemyData('slime'), EnemyData('goblin')]});
  final double spawnSeconds;
  final double attackSeconds;
  final double enemySpeed;
  final List<EnemyData> enemies;
}

class RunnerEnemy {
  RunnerEnemy(this.id, this.data, {this.x = 1000});
  final int id;
  final EnemyData data;
  double x;
  double age = 0;
  double hitAge = 0;
  EnemyPhase phase = EnemyPhase.spawn;
}

class BattleResultData {
  const BattleResultData(
      {required this.elapsedTime,
      required this.defeatedCount,
      required this.gainedExp,
      this.bossDefeatedCount = 0,
      this.gachaCount = 0});
  final Duration elapsedTime;
  final int defeatedCount;
  final int gainedExp;
  final int bossDefeatedCount;
  final int gachaCount;
}

/// Fixed-step, deterministic simulation. Rendering never awards player rewards.
/// Replaying elapsed focus time restores identical enemies and counters after sleep.
class BattleStateController {
  BattleStateController(
      {this.config = const RunnerConfig(), required this.durationSeconds}) {
    if (durationSeconds <= 0 ||
        config.spawnSeconds <= 0 ||
        config.attackSeconds <= 0 ||
        config.enemySpeed <= 0 ||
        config.enemies.isEmpty) {
      throw ArgumentError(
          'Battle configuration must be positive and include enemies.');
    }
  }
  final RunnerConfig config;
  final double durationSeconds;
  final List<RunnerEnemy> enemies = [];
  BattlePhase phase = BattlePhase.running;
  double elapsedSeconds = 0;
  int defeatedCount = 0;
  int gainedExp = 0;
  int attackSerial = 0;
  int _spawned = 0;
  int _ticks = 0;
  double _spawnTimer = 0;
  double _attackTimer = 0;
  double attackAge = 1;
  static const step = .05;
  HeroMotion get motion => phase == BattlePhase.finished
      ? HeroMotion.victory
      : attackAge < .22
          ? HeroMotion.attack
          : HeroMotion.run;
  void advanceTo(double seconds) {
    final target = seconds.clamp(elapsedSeconds, durationSeconds).toDouble();
    final targetTicks = (target / step + 1e-7).floor();
    while (_ticks < targetTicks) {
      _tick();
      _ticks++;
    }
    elapsedSeconds = target;
    if (target >= durationSeconds) phase = BattlePhase.finished;
  }

  void _tick() {
    _spawnTimer += step;
    _attackTimer += step;
    attackAge += step;
    if (_spawnTimer + 1e-7 >= config.spawnSeconds) {
      _spawnTimer -= config.spawnSeconds;
      enemies.add(RunnerEnemy(
          _spawned, config.enemies[_spawned % config.enemies.length]));
      _spawned++;
    }
    for (final enemy in enemies) {
      enemy.age += step;
      if (enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat) {
        enemy.hitAge += step;
        enemy.x += step * 150;
        if (enemy.hitAge > .12) enemy.phase = EnemyPhase.defeat;
      } else {
        enemy.phase = EnemyPhase.move;
        enemy.x = (enemy.x - config.enemySpeed * step).clamp(280, 1100);
      }
    }
    if (_attackTimer + 1e-7 >= config.attackSeconds) {
      for (final enemy in enemies) {
        if (enemy.phase == EnemyPhase.move && enemy.x <= 350) {
          enemy.phase = EnemyPhase.hit;
          defeatedCount++;
          gainedExp += enemy.data.expReward;
          attackAge = 0;
          attackSerial++;
          _attackTimer = 0;
          break;
        }
      }
    }
    enemies.removeWhere((enemy) => enemy.hitAge > .5);
    phase = attackAge < .22 ? BattlePhase.normalBattle : BattlePhase.running;
  }

  BattleResultData get result => BattleResultData(
      elapsedTime: Duration(milliseconds: (elapsedSeconds * 1000).round()),
      defeatedCount: defeatedCount,
      gainedExp: gainedExp);
}

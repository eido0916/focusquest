import 'run_slash_skill.dart';
import 'swordsman_normal_attack_sequence.dart';
import 'swordsman_sousen_timing.dart';

enum SwordsmanSkill { sousen, runSlash }

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
  const EnemyData(
    this.id, {
    this.expReward = 10,
    this.maxHp = 1,
    this.isBoss = false,
  });
  final String id;
  final int expReward;
  final int maxHp;
  final bool isBoss;
}

class RunnerConfig {
  const RunnerConfig({
    this.spawnSeconds = .85,
    this.attackSeconds = .55,
    this.enemySpeed = 230,
    this.normalDamage = 1,
    this.normalAttackReach = 80,
    this.enemyStopX = 485,
    this.enemyQueueSpacing = 32,
    this.sousenCooldownSeconds = 10,
    this.sousenDurationSeconds = SwordsmanSousenTiming.durationSeconds,
    this.sousenDamageTimeSeconds = SwordsmanSousenTiming.damageTimeSeconds,
    this.sousenDamageMultiplier = 3,
    // No idle pre-skill gathering window: keep attacking until skill starts.
    this.sousenGatherSeconds = 0,
    this.sousenGatherFrontX = 485,
    this.sousenGatherSpacing = 24,
    this.sousenAttackMaxX = 960,
    this.enableSousenEffect = true,
    this.autoSkill = SwordsmanSkill.sousen,
    this.enemies = const [EnemyData('slime'), EnemyData('goblin')],
  });
  final double spawnSeconds;
  final double attackSeconds;
  final double enemySpeed;
  final int normalDamage;

  /// Additional forward reach measured from the enemy stopping position.
  final double normalAttackReach;
  final double enemyStopX;
  final double enemyQueueSpacing;
  final double sousenCooldownSeconds;
  final double sousenDurationSeconds;
  final double sousenDamageTimeSeconds;
  final double sousenDamageMultiplier;
  final double sousenGatherSeconds;
  final double sousenGatherFrontX;
  final double sousenGatherSpacing;
  final double sousenAttackMaxX;
  final bool enableSousenEffect;
  final SwordsmanSkill autoSkill;
  final List<EnemyData> enemies;
}

class RunnerEnemy {
  RunnerEnemy(this.id, this.data, {this.x = 1000}) : hp = data.maxHp;
  final int id;
  final EnemyData data;
  int hp;
  double x;
  double age = 0;
  double hitAge = 0;
  double damageAge = 1;
  int damageSerial = 0;
  int lastDamage = 0;
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
        config.normalDamage <= 0 ||
        config.normalAttackReach < 10 ||
        config.enemyStopX <= 345 ||
        config.enemyQueueSpacing < 0 ||
        config.sousenCooldownSeconds <= 0 ||
        config.sousenDurationSeconds <= 0 ||
        config.sousenDamageTimeSeconds < 0 ||
        config.sousenDamageTimeSeconds >= config.sousenDurationSeconds ||
        config.sousenDamageMultiplier <= 0 ||
        config.sousenGatherSeconds < 0 ||
        config.sousenGatherSeconds >= config.sousenCooldownSeconds ||
        config.sousenGatherFrontX <= 345 ||
        config.sousenGatherSpacing < 0 ||
        config.sousenAttackMaxX <
            config.sousenGatherFrontX + 4 * config.sousenGatherSpacing ||
        config.enemies.any((enemy) => enemy.maxHp <= 0) ||
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
  int skillSerial = 0;
  int damageSerial = 0;
  int lastDamage = 0;
  double lastDamageX = 350;
  int _spawned = 0;
  int _ticks = 0;
  double _spawnTimer = 0;
  double _attackTimer = 0;
  double _skillTimer = 0;
  double attackAge = 1;
  double skillAge = 1;
  bool _skillPlaying = false;
  bool _skillDamageApplied = false;
  bool _normalAttackPlaying = false;
  int _normalAttackHits = 0;
  SwordsmanSkill activeSkill = SwordsmanSkill.sousen;
  int _runSlashHits = 0;
  final RunSlashSkill runSlashSkill = const RunSlashSkill();
  static const step = .05;

  bool get isSkillPlaying => _skillPlaying;
  bool get isNormalAttackPlaying => _normalAttackPlaying;

  /// Gather ahead of the hero during Sousen's wind-up. The optional pre-skill
  /// window defaults to zero so normal attacks continue until skill starts.
  bool get isGatheringForSousen => _skillPlaying
      ? activeSkill == SwordsmanSkill.sousen && !_skillDamageApplied
      : config.autoSkill == SwordsmanSkill.sousen &&
          secondsUntilSousen <= config.sousenGatherSeconds;

  /// Normal attack entry point; cannot overlap or interrupt an active skill.
  bool playNormalAttack() {
    if (_skillPlaying ||
        isGatheringForSousen ||
        _normalAttackPlaying ||
        phase == BattlePhase.finished) {
      return false;
    }
    _normalAttackPlaying = true;
    _normalAttackHits = 0;
    attackAge = 0;
    attackSerial++;
    _attackTimer = 0;
    phase = BattlePhase.normalBattle;
    return true;
  }

  String get skillName => (_skillPlaying ? activeSkill : config.autoSkill) ==
          SwordsmanSkill.runSlash
      ? '走り斬り'
      : '蒼閃';
  double get activeSkillDuration => activeSkill == SwordsmanSkill.runSlash
      ? RunSlashSkill.duration
      : config.sousenDurationSeconds;
  double get heroAdvanceOffset =>
      _skillPlaying && activeSkill == SwordsmanSkill.runSlash
          ? runSlashSkill.offsetAt(skillAge)
          : 0;
  int get runSlashFrame => RunSlashSkill.frameAt(skillAge);
  bool get isRunSlashAttackActive =>
      _skillPlaying &&
      activeSkill == SwordsmanSkill.runSlash &&
      RunSlashSkill.isAttackFrame(runSlashFrame);

  /// Returns false if another skill is playing or the focus session has ended.
  bool playRunSlashSkill() => _startSkill(SwordsmanSkill.runSlash);

  bool _startSkill(SwordsmanSkill skill) {
    if (_skillPlaying || phase == BattlePhase.finished) return false;
    activeSkill = skill;
    _skillPlaying = true;
    _normalAttackPlaying = false;
    _skillDamageApplied = false;
    _runSlashHits = 0;
    skillAge = 0;
    skillSerial++;
    _attackTimer = 0;
    phase = BattlePhase.skill;
    return true;
  }

  double get secondsUntilSousen => (config.sousenCooldownSeconds - _skillTimer)
      .clamp(0, config.sousenCooldownSeconds);

  HeroMotion get motion => phase == BattlePhase.finished
      ? HeroMotion.victory
      : _skillPlaying
          ? HeroMotion.skill
          : _normalAttackPlaying
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
    // Incoming enemies continue to arrive during Sousen's wind-up. Pause new
    // spawns only after impact so the simultaneous defeats remain readable.
    if (!_skillPlaying ||
        (activeSkill == SwordsmanSkill.sousen && !_skillDamageApplied)) {
      _spawnTimer += step;
    }
    _attackTimer += step;
    _skillTimer += step;
    attackAge += step;
    if (_skillPlaying) skillAge += step;
    if (_spawnTimer + 1e-7 >= config.spawnSeconds) {
      _spawnTimer -= config.spawnSeconds;
      enemies.add(RunnerEnemy(
          _spawned, config.enemies[_spawned % config.enemies.length]));
      _spawned++;
    }
    var queueIndex = 0;
    for (final enemy in enemies) {
      enemy.age += step;
      enemy.damageAge += step;
      if (enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat) {
        enemy.hitAge += step;
        enemy.x += step * 150;
        if (enemy.hitAge > .12) enemy.phase = EnemyPhase.defeat;
      } else {
        enemy.phase = EnemyPhase.move;
        // Stop ahead of the hero during normal combat too. Queue followers
        // behind the front enemy, then tighten the line for Sousen's impact.
        final gathering = isGatheringForSousen;
        final slot = queueIndex.clamp(0, 4).toInt();
        final targetX =
            (gathering ? config.sousenGatherFrontX : config.enemyStopX) +
                slot *
                    (gathering
                        ? config.sousenGatherSpacing
                        : config.enemyQueueSpacing);
        final distance = targetX - enemy.x;
        final movement = config.enemySpeed * step;
        enemy.x += distance.clamp(-movement, movement);
        queueIndex++;
      }
    }

    if (!_skillPlaying && _skillTimer + 1e-7 >= config.sousenCooldownSeconds) {
      _skillTimer -= config.sousenCooldownSeconds;
      _startSkill(config.autoSkill);
    }

    if (_skillPlaying &&
        activeSkill == SwordsmanSkill.sousen &&
        !_skillDamageApplied &&
        skillAge + 1e-7 >= config.sousenDamageTimeSeconds) {
      _skillDamageApplied = true;
      final damage =
          (config.normalDamage * config.sousenDamageMultiplier).round();
      // One impact, one damage application per enemy in the forward area.
      // Bosses use the same HP path; do not force-kill high-HP enemies.
      for (final target in enemies) {
        if (target.phase == EnemyPhase.move &&
            target.x >= 345 &&
            target.x <= config.sousenAttackMaxX) {
          _damage(target, damage);
        }
      }
    }

    if (_skillPlaying && activeSkill == SwordsmanSkill.runSlash) {
      while (_runSlashHits < RunSlashSkill.hitTimes.length &&
          skillAge + 1e-7 >= RunSlashSkill.hitTimes[_runSlashHits]) {
        _runSlashHits++;
        final target = _closestAttackableEnemy(
          maxX: 460 + heroAdvanceOffset,
        );
        if (target != null) {
          _damage(target,
              (config.normalDamage * config.sousenDamageMultiplier).round());
        }
      }
    }

    if (_skillPlaying && skillAge + 1e-7 >= activeSkillDuration) {
      _skillPlaying = false;
      skillAge = activeSkillDuration;
      _attackTimer = 0;
    }

    if (!_skillPlaying && _normalAttackPlaying) {
      final hitTimes = SwordsmanNormalAttackSequence.hitTimes;
      while (_normalAttackHits < hitTimes.length &&
          attackAge + 1e-7 >= hitTimes[_normalAttackHits]) {
        _normalAttackHits++;
        final target = _closestAttackableEnemy(
            maxX: config.enemyStopX + config.normalAttackReach);
        if (target != null) _damage(target, config.normalDamage);
      }
      if (attackAge + 1e-7 >= SwordsmanNormalAttackSequence.duration) {
        _normalAttackPlaying = false;
      }
    }
    if (!_skillPlaying &&
        !isGatheringForSousen &&
        !_normalAttackPlaying &&
        _attackTimer + 1e-7 >= config.attackSeconds &&
        _closestAttackableEnemy(maxX: config.enemyStopX + 10) != null) {
      playNormalAttack();
    }
    enemies.removeWhere((enemy) => enemy.hitAge > .5);
    phase = _skillPlaying
        ? BattlePhase.skill
        : _normalAttackPlaying
            ? BattlePhase.normalBattle
            : BattlePhase.running;
  }

  RunnerEnemy? _closestAttackableEnemy({required double maxX}) {
    RunnerEnemy? target;
    for (final enemy in enemies) {
      if (enemy.phase != EnemyPhase.move || enemy.x > maxX) continue;
      if (target == null || enemy.x < target.x) target = enemy;
    }
    return target;
  }

  void _damage(RunnerEnemy enemy, int damage) {
    if (enemy.phase != EnemyPhase.move || damage <= 0) return;
    enemy.hp = (enemy.hp - damage).clamp(0, enemy.data.maxHp).toInt();
    enemy.damageAge = 0;
    enemy.damageSerial++;
    enemy.lastDamage = damage;
    damageSerial++;
    lastDamage = damage;
    lastDamageX = enemy.x;
    if (enemy.hp > 0) return;
    enemy.phase = EnemyPhase.hit;
    enemy.hitAge = 0;
    defeatedCount++;
    gainedExp += enemy.data.expReward;
  }

  BattleResultData get result => BattleResultData(
      elapsedTime: Duration(milliseconds: (elapsedSeconds * 1000).round()),
      defeatedCount: defeatedCount,
      gainedExp: gainedExp);
}

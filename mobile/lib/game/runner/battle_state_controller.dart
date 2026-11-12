import '../../core/config/game_balance.dart';
import '../../features/playable_stage/domain/playable_stage_catalog.dart';
import '../../features/focus/domain/focus_adventure.dart';
import 'run_slash_skill.dart';
import 'archer_shot_timing.dart';
import 'swordsman_normal_attack_sequence.dart';
import 'boxer_normal_attack_sequence.dart';
import 'boxer_front_kick_sequence.dart';
import 'swordsman_sousen_timing.dart';

enum SwordsmanSkill { sousen, runSlash, frontKick }

enum NormalAttackStyle { swordsman, boxer }

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
    this.expReward = GameBalance.focusEnemyExp,
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
    this.pixelSkillName,
    this.normalAttackStyle = NormalAttackStyle.swordsman,
    this.archerProjectiles = false,
    this.normalAttackDurationSeconds,
    this.normalAttackHitTimes,
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
  final bool archerProjectiles;
  final String? pixelSkillName;
  final double spawnSeconds;
  final NormalAttackStyle normalAttackStyle;
  final double? normalAttackDurationSeconds;
  final List<double>? normalAttackHitTimes;
  List<double> get normalHitTimes =>
      normalAttackHitTimes ??
      (normalAttackStyle == NormalAttackStyle.boxer
          ? BoxerNormalAttackSequence.hitTimes
          : SwordsmanNormalAttackSequence.hitTimes);
  double get normalAttackDuration =>
      normalAttackDurationSeconds ??
      (normalAttackStyle == NormalAttackStyle.boxer
          ? BoxerNormalAttackSequence.duration
          : SwordsmanNormalAttackSequence.duration);
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
      this.bossDefeatedCount = 0});
  final Duration elapsedTime;
  final int defeatedCount;
  final int gainedExp;
  final int bossDefeatedCount;
}

/// Fixed-step, deterministic simulation. Rendering never awards player rewards.
/// Replaying elapsed focus time restores identical enemies and counters after sleep.
class BattleStateController {
  BattleStateController(
      {this.config = const RunnerConfig(),
      required this.durationSeconds,
      this.adventureStartSeconds,
      this.focusAreaIndex}) {
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
  final int? adventureStartSeconds;
  final int? focusAreaIndex;
  List<EnemyData> get spawnEnemies =>
      focusAreaIndex == null || focusAreaIndex! < 0
          ? config.enemies
          : [
              for (final id in {
                for (final stage in PlayableStageCatalog.stages
                    .skip(focusAreaIndex! * 4)
                    .take(4))
                  for (final enemy in stage.opponents)
                    if (!enemy.isBoss) enemy.id
              })
                EnemyData(id)
            ];
  int bossDefeatedCount = 0;
  double get adventureSeconds => (adventureStartSeconds ?? 0) + elapsedSeconds;
  bool get isBossBattle =>
      adventureStartSeconds != null &&
      FocusAdventure.bossActive(elapsedSeconds,
          durationSeconds: durationSeconds);
  double get bossRemainingSeconds => isBossBattle
      ? FocusAdventure.cycleSeconds - FocusAdventure.age(elapsedSeconds)
      : 0;
  String get areaName => adventureStartSeconds == null
      ? '木漏れ日の野原'
      : FocusAdventure.area(adventureSeconds, areaIndex: focusAreaIndex);
  String get bossName =>
      FocusAdventure.bossName(elapsedSeconds, areaIndex: focusAreaIndex);
  RunnerEnemy? _focusBoss;
  int? _bossCycle;
  void _updateFocusBoss(double now) {
    if (adventureStartSeconds == null) return;
    final clock = now;
    final cycle = FocusAdventure.cycle(clock);
    if (_focusBoss != null && _bossCycle != cycle) {
      final boss = _focusBoss!;
      boss.hp = 0;
      boss.phase = EnemyPhase.defeat;
      boss.hitAge = 0;
      defeatedCount++;
      bossDefeatedCount++;
      gainedExp += boss.data.expReward;
      _focusBoss = null;
      _spawnTimer = 0;
    }
    if (FocusAdventure.bossActive(clock, durationSeconds: durationSeconds) &&
        _bossCycle != cycle) {
      enemies.removeWhere(
          (e) => e.phase == EnemyPhase.move || e.phase == EnemyPhase.spawn);
      _arrowFlights.clear();
      _focusBoss = RunnerEnemy(
          _spawned++,
          EnemyData(FocusAdventure.bossId(clock, areaIndex: focusAreaIndex),
              maxHp: 300, expReward: GameBalance.focusBossExp, isBoss: true),
          x: config.enemyStopX + 24);
      enemies.add(_focusBoss!);
      _bossCycle = cycle;
    }
    final boss = _focusBoss;
    if (boss != null) {
      boss.hp = (FocusAdventure.cycleSeconds - FocusAdventure.age(clock))
          .ceil()
          .clamp(1, 300);
    }
  }

  final List<RunnerEnemy> enemies = [];
  BattlePhase phase = BattlePhase.running;
  double elapsedSeconds = 0;
  int defeatedCount = 0;
  int gainedExp = 0;
  int get focusRewardExp => gainedExp;
  int get focusRemainingSeconds =>
      (durationSeconds - elapsedSeconds).clamp(0.0, durationSeconds).ceil();
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
  double _boxerTravelSeconds = 0;
  double get visualSkillAge =>
      skillAge +
      (_skillPlaying ? (elapsedSeconds - _ticks * step).clamp(0.0, step) : 0);
  double get backgroundTravelSeconds =>
      config.normalAttackStyle == NormalAttackStyle.boxer
          ? _boxerTravelSeconds +
              (elapsedSeconds - _ticks * step) *
                  (_skillPlaying && activeSkill == SwordsmanSkill.frontKick
                      ? BoxerFrontKickSequence.speedRatioAt(visualSkillAge)
                      : 1)
          : elapsedSeconds;
  bool _skillPlaying = false;
  bool _skillDamageApplied = false;
  bool _normalAttackPlaying = false;
  int _normalAttackHits = 0;
  SwordsmanSkill activeSkill = SwordsmanSkill.sousen;
  int _runSlashHits = 0;
  final List<_ArcherFlight> _arrowFlights = [];
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

  String get skillName =>
      config.pixelSkillName ??
      ((_skillPlaying ? activeSkill : config.autoSkill) ==
              SwordsmanSkill.frontKick
          ? '前蹴り'
          : (_skillPlaying ? activeSkill : config.autoSkill) ==
                  SwordsmanSkill.runSlash
              ? '走り斬り'
              : '蒼閃');
  double get activeSkillDuration => activeSkill == SwordsmanSkill.frontKick
      ? BoxerFrontKickSequence.duration
      : activeSkill == SwordsmanSkill.runSlash
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
  bool playFrontKickSkill() =>
      config.normalAttackStyle == NormalAttackStyle.boxer &&
      _startSkill(SwordsmanSkill.frontKick);

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

  /// maxTicks bounds UI work after a clock jump; omitted for full offline replay.
  void advanceTo(double seconds, {int? maxTicks}) {
    if (!seconds.isFinite || (maxTicks != null && maxTicks <= 0)) {
      throw ArgumentError('Invalid battle clock or tick budget');
    }
    final target = seconds.clamp(elapsedSeconds, durationSeconds).toDouble();
    final targetTicks = (target / step + 1e-7).floor();
    var processed = 0;
    while (_ticks < targetTicks && (maxTicks == null || processed < maxTicks)) {
      _tick();
      _ticks++;
      processed++;
    }
    final caughtUp = _ticks >= targetTicks;
    elapsedSeconds = caughtUp ? target : _ticks * step;
    if (caughtUp && target >= durationSeconds) phase = BattlePhase.finished;
  }

  void _tick() {
    _updateFocusBoss((_ticks + 1) * step);
    _boxerTravelSeconds += step *
        (_skillPlaying && activeSkill == SwordsmanSkill.frontKick
            ? BoxerFrontKickSequence.speedRatioAt(skillAge + step / 2)
            : 1);
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
    if (_focusBoss == null && _spawnTimer + 1e-7 >= config.spawnSeconds) {
      _spawnTimer -= config.spawnSeconds;
      enemies.add(
          RunnerEnemy(_spawned, spawnEnemies[_spawned % spawnEnemies.length]));
      _spawned++;
    }
    var queueIndex = 0;
    for (final enemy in enemies) {
      enemy.age += step;
      enemy.damageAge += step;
      if (enemy.phase == EnemyPhase.hit || enemy.phase == EnemyPhase.defeat) {
        enemy.hitAge += step;
        // Defeat knockback is supplied by the original animation metadata.
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
      if (config.archerProjectiles) {
        _arrowFlights.add(_ArcherFlight(
          launchedAt: (_ticks + 1) * step -
              (skillAge - config.sousenDamageTimeSeconds).clamp(0.0, step),
          speed: ArcherShotTiming.windSpeed,
          startup: ArcherShotTiming.windStartup,
          tipOffset: ArcherShotTiming.battleWindTipOffset,
          maxHits: null,
          damage: damage,
          maxX: config.sousenAttackMaxX,
        ));
      }
      // One impact, one damage application per enemy in the forward area.
      // Bosses use the same HP path; do not force-kill high-HP enemies.
      for (final target in enemies) {
        if (target.phase == EnemyPhase.move &&
            target.x >= 345 &&
            target.x <= config.sousenAttackMaxX) {
          if (!config.archerProjectiles) _damage(target, damage);
        }
      }
    }

    if (_skillPlaying &&
        activeSkill == SwordsmanSkill.frontKick &&
        !_skillDamageApplied &&
        skillAge + 1e-7 >= BoxerFrontKickSequence.impactTime) {
      // A miss also consumes the one impact; never damage every render frame.
      _skillDamageApplied = true;
      final area = BoxerFrontKickSequence.hitArea();
      final damage =
          (config.normalDamage * config.sousenDamageMultiplier).round();
      for (final enemy in enemies) {
        if (enemy.phase == EnemyPhase.move &&
            enemy.x >= area.left &&
            enemy.x <= area.right) {
          _damage(enemy, damage);
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
      final hitTimes = config.normalHitTimes;
      while (_normalAttackHits < hitTimes.length &&
          attackAge + 1e-7 >= hitTimes[_normalAttackHits]) {
        _normalAttackHits++;
        if (config.archerProjectiles) {
          _arrowFlights.add(_ArcherFlight(
            launchedAt: (_ticks + 1) * step -
                (attackAge - hitTimes[_normalAttackHits - 1]).clamp(0.0, step),
            speed: ArcherShotTiming.normalSpeed,
            startup: 0,
            tipOffset: 0,
            maxHits: 2,
            damage: config.normalDamage,
            maxX: config.sousenAttackMaxX,
          ));
        } else {
          final target = _closestAttackableEnemy(
              maxX: config.enemyStopX + config.normalAttackReach);
          if (target != null) _damage(target, config.normalDamage);
        }
      }
      if (attackAge + 1e-7 >= config.normalAttackDuration) {
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
    _advanceArcherFlights((_ticks + 1) * step);
    enemies
        .removeWhere((enemy) => enemy.hitAge > (enemy.data.isBoss ? 1.25 : .5));
    phase = _skillPlaying
        ? BattlePhase.skill
        : _normalAttackPlaying
            ? BattlePhase.normalBattle
            : BattlePhase.running;
  }

  void _advanceArcherFlights(double now) {
    for (final arrow in _arrowFlights) {
      final flightAge =
          (now - arrow.launchedAt - arrow.startup).clamp(0.0, double.infinity);
      final tip = ArcherShotTiming.battleMuzzleX +
          arrow.tipOffset +
          arrow.speed * flightAge;
      // Sort by current distance: a penetrating shot hits the nearest two,
      // even if enemy insertion order differs. Moving foes cross the swept path.
      final targets = enemies
          .where((e) =>
              e.phase == EnemyPhase.move &&
              !arrow.hitIds.contains(e.id) &&
              e.x >= ArcherShotTiming.battleMuzzleX &&
              e.x <= arrow.maxX &&
              e.x <= tip &&
              e.x + config.enemySpeed * step >= arrow.previousTip)
          .toList()
        ..sort((a, b) => a.x.compareTo(b.x));
      for (final enemy in targets) {
        if (arrow.maxHits != null && arrow.hitIds.length >= arrow.maxHits!) {
          break;
        }
        arrow.hitIds.add(enemy.id);
        _damage(enemy, arrow.damage);
      }
      arrow.previousTip = tip;
    }
    _arrowFlights.removeWhere((a) =>
        a.previousTip > a.maxX + 320 ||
        (a.maxHits != null && a.hitIds.length >= a.maxHits!));
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
    if (enemy != _focusBoss) {
      enemy.hp = (enemy.hp - damage).clamp(0, enemy.data.maxHp).toInt();
    }
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
      gainedExp: gainedExp,
      bossDefeatedCount: bossDefeatedCount);
}

class _ArcherFlight {
  _ArcherFlight(
      {required this.launchedAt,
      required this.speed,
      required this.startup,
      required this.tipOffset,
      required this.maxHits,
      required this.damage,
      required this.maxX});
  final double launchedAt, speed, startup, tipOffset, maxX;
  final int? maxHits;
  final int damage;
  final Set<int> hitIds = {};
  double previousTip = ArcherShotTiming.battleMuzzleX;
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'playable_stage_catalog.dart';
import 'playable_character.dart';

class StageEnemy {
  StageEnemy(this.definition, this.index, this.homeX)
      : hp = definition.hp,
        x = homeX,
        wait = 1.6 + index * .9;
  final StageOpponent definition;
  final int index;
  final double homeX;
  int hp;
  double x, wait, actionTime = 0, deathTime = 0, deathX = 0;
  bool attacking = false, hitResolved = false;
  double attackDuration = 1, defeatDuration = 1.25;
  int hitTick = 11;
  bool get alive => hp > 0;
}

class StageProjectile {
  StageProjectile(this.kind, this.target, this.startX, this.flightSeconds,
      this.skill, this.power);
  final ProjectileKind kind;
  final StageEnemy target;
  final double startX, flightSeconds;
  final bool skill;
  final int power;
  double age = 0, endX = 0;
  bool resolved = false, missed = false;
  double get progress => (age / flightSeconds).clamp(0.0, 1.0);
  double get x => missed && resolved
      ? endX + (age - flightSeconds) * 1600
      : startX + (endX - startX) * progress;
  double get height => kind == ProjectileKind.floor
      ? .4 + math.sin(progress * math.pi) * 1.2
      : .5 + ((target.definition.isBoss ? 1.05 : .3) - .5) * progress;
}

enum StageMode { ready, travel, battle, defeat, won, lost }

enum HeroAction { attack, skill }

enum BattleSound {
  swing,
  skill,
  hit,
  critical,
  miss,
  hurt,
  enemyDefeat,
  victory,
  loss
}

class StageDamage {
  const StageDamage(this.amount, this.x, this.createdAt,
      {this.toHero = false,
      this.skill = false,
      this.miss = false,
      this.critical = false,
      this.targetIsBoss = false});
  final int amount;
  final double x, createdAt;
  final bool toHero, skill;
  final bool miss, critical;
  final bool targetIsBoss;
}

/// Native battle state; movement changes world coordinates, never sprite pixels.
class PlayableStageBattle extends ChangeNotifier {
  PlayableStageBattle(
      {PlayableStageDefinition? stage,
      PlayableCharacter? character,
      double Function()? roll})
      : stage = stage ?? PlayableStageCatalog.stages.first,
        character = character ?? PlayableCharacters.defaultCharacter,
        _roll = roll ?? math.Random().nextDouble {
    hp = this.character.health;
    attackDuration = this.character.attackSeconds;
    skillDuration = this.character.skillSeconds;
    _spawn();
    message = '${this.stage.area}の冒険へようこそ';
  }
  void configureHeroTiming(
      Map<String, dynamic> attack, Map<String, dynamic> skill) {
    double duration(Map<String, dynamic> motion) =>
        (motion['duration_seconds'] as num).toDouble();
    List<double> releases(Map<String, dynamic> motion, String event) => [
          for (final row in motion['events'] as List)
            if (row['event'] == event)
              (row['tick'] as num).toDouble() / (24 * duration(motion))
        ];
    if (int.parse(character.id.split('_')[1]) >= 11) {
      attackDuration = duration(attack);
      skillDuration = duration(skill);
    }
    attackReleaseFractions = releases(attack, character.attackEvent);
    skillReleaseFractions = releases(skill, character.skillEvent);
    attackHitFraction = attackReleaseFractions.isEmpty
        ? 12 / (24 * duration(attack))
        : attackReleaseFractions.first;
    skillHitFraction = skillReleaseFractions.isEmpty
        ? 20 / (24 * duration(skill))
        : skillReleaseFractions.first;
    actionOffsetPx = (isSkill, progress) {
      final timeline = (isSkill ? skill : attack)['timeline'] as List;
      final tick =
          (progress * timeline.length).floor().clamp(0, timeline.length - 1);
      return ((timeline[tick]['root_offset_px'] as List)[0] as num).toDouble();
    };
  }

  final PlayableStageDefinition stage;
  final PlayableCharacter character;
  final List<StageEnemy> enemies = [];
  StageEnemy get target =>
      enemies.firstWhere((enemy) => enemy.alive, orElse: () => enemies.last);
  int get remainingEnemies => enemies.where((enemy) => enemy.alive).length;
  int get waveHp => enemies.fold(0, (sum, enemy) => sum + enemy.hp);
  int get waveMaxHp =>
      enemies.fold(0, (sum, enemy) => sum + enemy.definition.hp);
  int get totalEnemies => List.generate(encounters.length, stage.wave)
      .fold(0, (sum, wave) => sum + wave.length);
  void _spawn() {
    enemies.clear();
    projectiles.clear();
    final wave = stage.wave(phase);
    for (var i = 0; i < wave.length; i++) {
      enemies
          .add(StageEnemy(wave[i], i, wave[i].isBoss ? 980 : 760 + i * 170.0));
    }
  }

  final double Function() _roll;
  static const hitChance = .9, criticalChance = .2, criticalMultiplier = 2;
  static const enemyHitChance = .85,
      enemyCriticalChance = .1,
      enemyCriticalMultiplier = 1.5;
  final _soundEvents = StreamController<BattleSound>.broadcast(sync: true);
  Stream<BattleSound> get soundEvents => _soundEvents.stream;
  void _sound(BattleSound sound) => _soundEvents.add(sound);
  List<StageOpponent> get encounters => stage.opponents;
  static const maxHp = 160,
      attackDamage = 28,
      skillDamage = 112,
      chargeNeeded = 3;
  static const travelDuration = 2.8;
  StageMode mode = StageMode.ready;
  bool paused = false;
  int phase = 0, hp = maxHp, charge = 0;
  int get enemyHp => target.hp;
  set enemyHp(int value) => target.hp = value;
  int hits = 0, skills = 0, cleared = 0;
  int attempts = 0, misses = 0, criticals = 0;
  double clock = 0, modeTime = 0, distance = 0;
  double heroX = 250;
  static const heroHomeX = 250.0;
  double spriteWorldSide = 200;
  double contactGap(StageEnemy enemy) =>
      spriteWorldSide * (enemy.definition.isBoss ? 1.2 : .45);
  double Function(bool skill, double progress)? actionOffsetPx;
  StageEnemy? _actionTarget;
  StageEnemy? get actionTarget => _actionTarget;
  double heroPoseOffset = 0;
  double get enemyX => target.x;
  double get deathX => target.deathX;
  HeroAction? action;
  double actionTime = 0;
  bool _heroHit = false;
  double get enemyActionTime => target.actionTime;
  double get enemyWait => target.wait;
  bool get enemyAttacking => target.attacking;
  String message = '草原の冒険へようこそ';
  double _messageUntil = 0;
  final List<StageDamage> damageNumbers = [];
  final List<StageProjectile> projectiles = [];
  List<double> attackReleaseFractions = [], skillReleaseFractions = [];
  int _releasedShots = 0;
  double attackDuration = 1, skillDuration = 1.75;
  double heroHurtDuration = .5, heroDefeatDuration = 1.25;
  double heroHurtTime = .5, heroDefeatTime = 0;
  bool get heroHurt =>
      mode == StageMode.battle && hp > 0 && heroHurtTime < heroHurtDuration;
  bool get heroDefeatFinished =>
      mode == StageMode.lost && heroDefeatTime >= heroDefeatDuration;
  double attackHitFraction = 13 / 24, skillHitFraction = 31 / 42;

  StageOpponent get opponent => encounters[phase];
  bool get isBoss => opponent.isBoss;
  bool get isFinalPhase => phase == encounters.length - 1;
  bool get active =>
      [StageMode.travel, StageMode.battle, StageMode.defeat].contains(mode);
  bool get canAttack => mode == StageMode.battle && !paused && action == null;
  bool get canSkill => canAttack && charge >= chargeNeeded;

  void _message(String text, [double duration = 2.2]) {
    message = text;
    _messageUntil = clock + duration;
  }

  void reset() {
    mode = StageMode.ready;
    paused = false;
    phase = 0;
    hp = character.health;
    _spawn();
    charge = 0;
    hits = 0;
    skills = 0;
    cleared = 0;
    attempts = 0;
    misses = 0;
    criticals = 0;
    clock = 0;
    modeTime = 0;
    distance = 0;
    heroX = 250;
    action = null;
    _actionTarget = null;
    heroPoseOffset = 0;
    actionTime = 0;
    heroHurtTime = heroHurtDuration;
    heroDefeatTime = 0;
    _heroHit = false;
    message = '${stage.area}の冒険へようこそ';
    _messageUntil = 0;
    damageNumbers.clear();
    projectiles.clear();
    _releasedShots = 0;
    notifyListeners();
  }

  void start() {
    if (mode != StageMode.ready) return;
    _travel();
    notifyListeners();
  }

  void restart() {
    reset();
    start();
  }

  void _travel() {
    mode = StageMode.travel;
    modeTime = 0;
    heroX = 250;
    _spawn();
    _message(phase == 0 ? '最初の戦いへ' : '次のフェーズへ走行中', travelDuration);
  }

  void pause() {
    if (!active || paused) return;
    paused = true;
    notifyListeners();
  }

  void resume() {
    if (!active || !paused) return;
    paused = false;
    notifyListeners();
  }

  bool attack() {
    if (!canAttack) return false;
    action = HeroAction.attack;
    _actionTarget = target;
    actionTime = 0;
    _heroHit = false;
    _releasedShots = 0;
    attempts++;
    _sound(BattleSound.swing);
    notifyListeners();
    return true;
  }

  bool skill() {
    if (!canSkill) return false;
    charge = 0;
    skills++;
    action = HeroAction.skill;
    _actionTarget = target;
    actionTime = 0;
    _heroHit = false;
    _releasedShots = 0;
    _message('${character.skillName}！', skillDuration + .15);
    _sound(BattleSound.skill);
    notifyListeners();
    return true;
  }

  bool _damageEnemy(bool skill, {StageEnemy? victim, int? basePower}) {
    if (mode != StageMode.battle) return false;
    final enemy = victim ?? _actionTarget ?? target;
    if (!enemy.alive) return false;
    if (!skill && _roll() >= hitChance) {
      misses++;
      damageNumbers.add(StageDamage(0, enemy.x, clock,
          miss: true, targetIsBoss: enemy.definition.isBoss));
      _sound(BattleSound.miss);
      return false;
    }
    final critical = _roll() < character.criticalRate;
    if (critical) criticals++;
    final damage =
        (basePower ?? (skill ? character.skillPower : character.power)) *
            (critical ? criticalMultiplier : 1);
    enemy.hp = math.max(0, enemy.hp - damage);
    if (!skill) {
      hits++;
      charge = math.min(chargeNeeded, charge + 1);
    }
    damageNumbers.add(StageDamage(damage, enemy.x, clock,
        skill: skill,
        critical: critical,
        targetIsBoss: enemy.definition.isBoss));
    _sound(critical ? BattleSound.critical : BattleSound.hit);
    if (enemy.hp == 0) {
      enemy.deathX = enemy.x;
      enemy.deathTime = 0;
      enemy.attacking = false;
      cleared++;
      _message('${enemy.definition.name}を倒した！ 残り$remainingEnemies体', 1.8);
      _sound(BattleSound.enemyDefeat);
      if (remainingEnemies == 0) {
        mode = StageMode.defeat;
        modeTime = 0;
      }
    }
    return true;
  }

  void update(double elapsed) {
    if (paused) return;
    final dt = elapsed.clamp(0.0, 0.1).toDouble();
    // HP-zero is already a loss; keep ticking only the drawn kneeling motion.
    // No combat, movement, healing or projectile hits continue after defeat.
    if (mode == StageMode.lost) {
      if (!heroDefeatFinished) {
        heroDefeatTime = math.min(heroDefeatDuration, heroDefeatTime + dt);
        notifyListeners();
      }
      return;
    }
    if (!active) return;
    heroHurtTime = math.min(heroHurtDuration, heroHurtTime + dt);
    clock += dt;
    modeTime += dt;
    for (final enemy in enemies.where((enemy) => !enemy.alive)) {
      enemy.deathTime += dt;
    }
    damageNumbers.removeWhere((number) => clock - number.createdAt > 1);
    if (_messageUntil > 0 && clock > _messageUntil) {
      message = '';
      _messageUntil = 0;
    }
    if (action != null) {
      actionTime += dt;
      final skill = action == HeroAction.skill;
      final hitTime = (skill
          ? skillHitFraction * skillDuration
          : attackHitFraction * attackDuration);
      final duration = skill ? skillDuration : attackDuration;
      final progress = actionTime / duration;
      final projectile = character.projectileFor(skill);
      if (projectile != null) {
        heroX = heroHomeX;
        heroPoseOffset = 0;
        final configured =
            skill ? skillReleaseFractions : attackReleaseFractions;
        final releases = configured.isEmpty ? [hitTime / duration] : configured;
        while (_releasedShots < releases.length &&
            progress >= releases[_releasedShots]) {
          final enemy = _actionTarget!;
          final startX = heroHomeX + spriteWorldSide * .2;
          final endX =
              enemy.x - spriteWorldSide * (enemy.definition.isBoss ? .6 : .08);
          final seconds = projectile == ProjectileKind.floor
              ? ((endX - startX).abs() / 700).clamp(.3, 1.5)
              : ((endX - startX).abs() / 2400).clamp(.06, .28);
          final total = skill ? character.skillPower : character.power;
          final power = total ~/ releases.length +
              (_releasedShots < total % releases.length ? 1 : 0);
          projectiles.add(
              StageProjectile(projectile, enemy, startX, seconds, skill, power)
                ..endX = endX);
          _releasedShots++;
        }
      } else {
        final excursion = _approach(progress, hitTime / duration);
        final enemy = _actionTarget!;
        final enemyPosition = enemy.alive ? enemy.x : enemy.deathX;
        heroPoseOffset = (actionOffsetPx?.call(skill, progress) ?? 0) *
            spriteWorldSide /
            128;
        final destination =
            math.max(heroHomeX, enemyPosition - contactGap(enemy));
        heroX =
            (heroHomeX + (destination - heroHomeX) * excursion - heroPoseOffset)
                .roundToDouble();
        if (skill &&
            character.role == 'ドラゴンナイト' &&
            skillReleaseFractions.isNotEmpty) {
          while (_releasedShots < skillReleaseFractions.length &&
              progress >= skillReleaseFractions[_releasedShots]) {
            final count = skillReleaseFractions.length;
            _damageEnemy(true,
                basePower: character.skillPower ~/ count +
                    (_releasedShots < character.skillPower % count ? 1 : 0));
            _releasedShots++;
          }
        } else if (!_heroHit && actionTime >= hitTime) {
          _heroHit = true;
          _damageEnemy(skill);
        }
      }
      if (actionTime >= duration) {
        action = null;
        _actionTarget = null;
        heroPoseOffset = 0;
        heroX = heroHomeX;
      }
    }
    switch (mode) {
      case StageMode.travel:
        distance += dt * 105;
        heroX = 250;
        for (final enemy in enemies) {
          enemy.x =
              enemy.homeX + (1 - math.min(1, modeTime / travelDuration)) * 650;
        }
        if (modeTime >= travelDuration) {
          mode = StageMode.battle;
          modeTime = 0;
          _message(isBoss
              ? 'BOSS · ${opponent.name}が現れた！'
              : 'PHASE ${phase + 1} · ${opponent.name}が現れた！');
        }
      case StageMode.battle:
        for (final enemy in enemies.where((enemy) => enemy.alive)) {
          if (mode == StageMode.lost) break;
          if (!enemy.attacking) {
            enemy.wait -= dt;
            if (enemy.wait <= 0) {
              enemy.attacking = true;
              enemy.actionTime = 0;
              enemy.hitResolved = false;
            }
          } else {
            enemy.actionTime += dt;
            final progress = enemy.actionTime / enemy.attackDuration;
            final excursion = _approach(
                progress, enemy.hitTick / (24 * enemy.attackDuration));
            final destination = heroX + heroPoseOffset + contactGap(enemy);
            enemy.x = math
                .max(destination,
                    enemy.homeX + (destination - enemy.homeX) * excursion)
                .roundToDouble();
            if (!enemy.hitResolved && enemy.actionTime >= enemy.hitTick / 24) {
              enemy.hitResolved = true;
              final missed = _roll() >= enemyHitChance;
              final critical = !missed && _roll() < enemyCriticalChance;
              final damage = missed
                  ? 0
                  : math.max(
                      1,
                      (enemy.definition.damage *
                                  (critical ? enemyCriticalMultiplier : 1))
                              .round() -
                          character.defense);
              hp = math.max(0, hp - damage);
              damageNumbers.add(StageDamage(
                  damage, heroX + heroPoseOffset, clock,
                  toHero: true, miss: missed, critical: critical));
              _sound(missed
                  ? BattleSound.miss
                  : critical
                      ? BattleSound.critical
                      : BattleSound.hurt);
              if (hp == 0) {
                mode = StageMode.lost;
                action = null;
                _actionTarget = null;
                heroPoseOffset = 0;
                heroDefeatTime = 0;
                _sound(BattleSound.loss);
              } else if (damage > 0) {
                heroHurtTime = 0;
              }
            }
            if (enemy.actionTime >= enemy.attackDuration) {
              enemy.attacking = false;
              enemy.x = enemy.homeX;
              enemy.wait = enemy.definition.interval;
            }
          }
        }
      case StageMode.defeat:
        if (enemies.every((enemy) => enemy.deathTime >= enemy.defeatDuration) &&
            action == null) {
          if (isFinalPhase) {
            mode = StageMode.won;
            _sound(BattleSound.victory);
          } else {
            phase++;
            _travel();
          }
        }
      case StageMode.ready:
      case StageMode.won:
      case StageMode.lost:
        break;
    }
    for (final projectile in projectiles) {
      projectile.age += dt;
      if (!projectile.resolved) {
        // All targeted ranged skills land at the moving enemy. Display scale
        // must not determine whether a launched attack can deal damage.
        projectile.endX = projectile.target.x -
            spriteWorldSide * (projectile.target.definition.isBoss ? .6 : .08);
        if (projectile.age >= projectile.flightSeconds) {
          projectile.resolved = true;
          projectile.missed = !_damageEnemy(projectile.skill,
              victim: projectile.target, basePower: projectile.power);
        }
      }
    }
    projectiles.removeWhere(
        (projectile) => projectile.age > projectile.flightSeconds + .14);
    notifyListeners();
  }

  @override
  void dispose() {
    unawaited(_soundEvents.close());
    super.dispose();
  }

  // Arrive before the original hit frame, hold contact, then return home.
  static double _approach(double progress, double hitFraction) {
    final arrive = (hitFraction * .7).clamp(.02, .2);
    final retreat = math.max(.78, hitFraction + .1).clamp(.78, .97);
    if (progress < arrive) return (progress / arrive).clamp(0.0, 1.0);
    if (progress > retreat) {
      return ((1 - progress) / (1 - retreat)).clamp(0.0, 1.0);
    }
    return 1;
  }
}

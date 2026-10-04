import 'dart:math';
import '../../core/assets/asset_catalog.dart';
import '../../features/character/domain/stats.dart';

enum BattleOutcome { running, victory, defeat }

class Fighter {
  Fighter(this.name, this.stats) : hp = stats.hp;
  final String name;
  final Stats stats;
  int hp;
  ActorPose pose = ActorPose.idle;
}

class DamageEvent {
  const DamageEvent(this.playerAttacks, this.damage, this.critical);
  final bool playerAttacks;
  final int damage;
  final bool critical;
}

/// Pure simulation: Flame will render events and actor states.
class BattleEngine {
  BattleEngine(
      {required this.player,
      required this.enemy,
      required this.random,
      this.battleId});
  final String? battleId;
  final Fighter player;
  final Fighter enemy;
  final Random random;
  double _playerClock = 0;
  double _enemyClock = 0;
  BattleOutcome get outcome => player.hp <= 0
      ? BattleOutcome.defeat
      : enemy.hp <= 0
          ? BattleOutcome.victory
          : BattleOutcome.running;
  static int damage(Stats attacker, Stats defender, {bool critical = false}) =>
      max(1,
          (attacker.attack * (critical ? 1.5 : 1)).round() - defender.defense);
  List<DamageEvent> update(double dt) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt);
    final events = <DamageEvent>[];
    if (outcome != BattleOutcome.running) return events;
    // Avoid an invisible burst of attacks when resuming from background.
    final step = min(dt, 0.25);
    _playerClock += step;
    _enemyClock += step;
    player.pose = ActorPose.idle;
    enemy.pose = ActorPose.idle;
    if (_playerClock >= 12 / max(1, player.stats.speed)) {
      _playerClock = 0;
      events.add(_attack(player, enemy, true));
    }
    if (outcome == BattleOutcome.running &&
        _enemyClock >= 12 / max(1, enemy.stats.speed)) {
      _enemyClock = 0;
      events.add(_attack(enemy, player, false));
    }
    return events;
  }

  DamageEvent _attack(Fighter attacker, Fighter defender, bool playerAttacks) {
    final critical = random.nextDouble() < attacker.stats.criticalRate;
    final amount = damage(attacker.stats, defender.stats, critical: critical);
    attacker.pose = ActorPose.attack;
    defender.hp = max(0, defender.hp - amount);
    defender.pose = defender.hp == 0 ? ActorPose.death : ActorPose.damage;
    return DamageEvent(playerAttacks, amount, critical);
  }
}

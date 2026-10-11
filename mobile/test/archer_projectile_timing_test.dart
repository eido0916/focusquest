import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';

void main() {
  const foe = EnemyData('target');
  BattleStateController battle(
          {double cooldown = 100, double skillDuration = 53 / 24}) =>
      BattleStateController(
          durationSeconds: 120,
          config: RunnerConfig(
              archerProjectiles: true,
              spawnSeconds: 100,
              attackSeconds: 100,
              enemySpeed: 1,
              sousenCooldownSeconds: cooldown,
              normalAttackDurationSeconds: 64 / 24,
              normalAttackHitTimes: const [25 / 24],
              sousenDurationSeconds: skillDuration,
              sousenDamageTimeSeconds: 27 / 24,
              enableSousenEffect: false));

  test('one normal arrow penetrates nearest two, third stays alive', () {
    final s = battle();
    s.enemies.addAll([
      RunnerEnemy(1, foe, x: 485),
      RunnerEnemy(2, foe, x: 517),
      RunnerEnemy(3, foe, x: 549)
    ]);
    expect(s.playNormalAttack(), true);
    s.advanceTo(1.04);
    expect(s.defeatedCount, 0);
    s.advanceTo(1.15);
    expect(s.defeatedCount, 1);
    s.advanceTo(1.25);
    expect(s.defeatedCount, 2);
    expect(s.enemies.singleWhere((e) => e.id == 3).hp, 1);
    s.advanceTo(3);
    expect(s.defeatedCount, 2);
    expect(s.gainedExp, 20);
  });
  test('wind startup shows before impact; far target dies after near target',
      () {
    final s = battle(cooldown: 1);
    s.enemies
        .addAll([RunnerEnemy(1, foe, x: 500), RunnerEnemy(2, foe, x: 800)]);
    s.advanceTo(2.4);
    expect(s.defeatedCount, 0);
    s.advanceTo(2.55);
    expect(s.defeatedCount, 1);
    expect(s.enemies.singleWhere((e) => e.id == 2).hp, 1);
    s.advanceTo(3.05);
    expect(s.defeatedCount, 2);
    expect(s.gainedExp, 20);
    expect(s.damageSerial, 2);
  });
  test('flight hits survive skill completion and agree across clock jumps', () {
    List<int> simulate(bool jump) {
      final s = battle(cooldown: 1, skillDuration: 1.4);
      s.enemies
          .addAll([RunnerEnemy(1, foe, x: 500), RunnerEnemy(2, foe, x: 900)]);
      if (jump) {
        s.advanceTo(4);
      } else {
        for (var i = 1; i <= 240; i++) {
          s.advanceTo(i / 60);
        }
      }
      return [s.defeatedCount, s.gainedExp, s.damageSerial];
    }

    expect(simulate(true), simulate(false));
    expect(simulate(true), [2, 20, 2]);
  });
}

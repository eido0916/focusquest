import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';

void main() {
  test('enemies enter from the right, die in one hit, award configured EXP',
      () {
    final state = BattleStateController(durationSeconds: 60);
    state.advanceTo(1);
    expect(state.enemies.first.x, greaterThan(800));
    state.advanceTo(10);
    expect(state.defeatedCount, greaterThan(5));
    expect(state.gainedExp, state.defeatedCount * 10);
    expect(state.enemies.length, lessThan(15));
  });
  test('frame rate and screen-off gaps produce identical results', () {
    final frames = BattleStateController(durationSeconds: 600);
    for (var i = 1; i <= 3600; i++) {
      frames.advanceTo(i / 60);
    }
    final restored = BattleStateController(durationSeconds: 600)..advanceTo(60);
    expect(frames.defeatedCount, restored.defeatedCount);
    expect(frames.gainedExp, restored.gainedExp);
    expect(frames.enemies.map((e) => e.x), restored.enemies.map((e) => e.x));
  });
  test('session end clamps simulation and cannot award twice', () {
    final state = BattleStateController(durationSeconds: 60)..advanceTo(90);
    final count = state.defeatedCount;
    state.advanceTo(100);
    expect(state.phase, BattlePhase.finished);
    expect(state.result.elapsedTime, const Duration(minutes: 1));
    expect(state.defeatedCount, count);
  });
  test('custom enemy reward and long run remain bounded', () {
    final state = BattleStateController(
        durationSeconds: 10800,
        config: const RunnerConfig(enemies: [EnemyData('test', expReward: 3)]))
      ..advanceTo(10800);
    expect(state.gainedExp, state.defeatedCount * 3);
    expect(state.enemies.length, lessThan(15));
  });

  test('蒼閃 starts every ten seconds and applies exactly one hit', () {
    final state = BattleStateController(
      durationSeconds: 60,
      config: const RunnerConfig(
        spawnSeconds: .1,
        autoSkill: SwordsmanSkill.sousen,
        attackSeconds: 100,
        enemySpeed: 1000,
        enemies: [EnemyData('boss', maxHp: 5, isBoss: true)],
      ),
    );

    state.advanceTo(9.95);
    expect(state.skillSerial, 0);
    state.advanceTo(10);
    expect(state.skillSerial, 1);
    expect(state.isSkillPlaying, isTrue);
    expect(state.damageSerial, 0);

    state.advanceTo(11.9);
    expect(state.damageSerial, 1);
    expect(state.lastDamage, 3);
    expect(state.enemies.first.hp, 2);

    state.advanceTo(13.2);
    expect(state.damageSerial, 1);
    expect(state.isSkillPlaying, isFalse);
    state.advanceTo(20);
    expect(state.skillSerial, 2);
  });

  test('蒼閃 is safe when no enemy is present', () {
    final state = BattleStateController(
      durationSeconds: 20,
      config: const RunnerConfig(
        spawnSeconds: 100,
        autoSkill: SwordsmanSkill.sousen,
        attackSeconds: 100,
      ),
    )..advanceTo(12);

    expect(state.skillSerial, 1);
    expect(state.damageSerial, 0);
    expect(state.defeatedCount, 0);
  });
}

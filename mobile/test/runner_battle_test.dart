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
}

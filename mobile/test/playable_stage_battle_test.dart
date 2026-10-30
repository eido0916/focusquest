import 'support/mechanics_stage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

void main() {
  test('3 attacks unlock one skill and repeated taps cannot double charge', () {
    final battle = PlayableStageBattle(stage: mechanicsStage(), roll: () => .5);
    addTearDown(battle.dispose);
    battle.start();
    advance(battle, 3);
    expect(battle.skill(), false);
    for (var i = 0; i < 3; i++) {
      expect(battle.attack(), true);
      expect(battle.attack(), false);
      expect(battle.charge, i + 1);
      advance(battle, 1.1);
    }
    expect(battle.charge, 3);
    expect(battle.hits, 3);
    expect(battle.skill(), true);
    expect(battle.charge, 0);
    expect(battle.skill(), false);
    advance(battle, 1.9);
    expect(battle.cleared, 2);
    expect(battle.skills, 1);
  });
  test('missed attacks fill charge, capped at three, and skill resets it', () {
    final battle =
        PlayableStageBattle(stage: mechanicsStage(), roll: () => .99);
    addTearDown(battle.dispose);
    battle.start();
    advance(battle, 3);
    for (var i = 0; i < 4; i++) {
      expect(battle.attack(), true);
      advance(battle, 1.1);
      expect(battle.charge, (i + 1).clamp(0, 3));
    }
    expect(battle.hits, 0);
    expect(battle.misses, 4);
    expect(battle.skill(), true);
    expect(battle.charge, 0);
  });
  test('three phases have running transitions and finish in boss victory', () {
    final battle = PlayableStageBattle(stage: mechanicsStage(), roll: () => .5);
    addTearDown(battle.dispose);
    battle.start();
    final travels = <int>{};
    for (var i = 0; i < 120 * 90 && battle.active; i++) {
      if (battle.mode == StageMode.travel) {
        travels.add(battle.phase);
        expect(battle.attack(), false);
      }
      if (battle.canSkill) {
        battle.skill();
      } else if (battle.canAttack) {
        battle.attack();
      }
      battle.update(1 / 120);
      expect(battle.heroX < battle.enemyX || battle.mode == StageMode.defeat,
          true);
    }
    expect(battle.mode, StageMode.won);
    expect(battle.cleared, battle.totalEnemies);
    expect(travels, {0, 1, 2});
    expect(battle.hp, greaterThan(0));
    expect(battle.hits, greaterThanOrEqualTo(12));
    expect(battle.skills, greaterThanOrEqualTo(3));
  });
  test('pause freezes action, HP and world position; restart clears counters',
      () {
    final battle = PlayableStageBattle(stage: mechanicsStage(), roll: () => .5);
    addTearDown(battle.dispose);
    battle.start();
    advance(battle, 3);
    battle.attack();
    advance(battle, .3);
    battle.pause();
    final time = battle.clock, x = battle.heroX, hp = battle.hp;
    advance(battle, 30);
    expect(battle.clock, time);
    expect(battle.heroX, x);
    expect(battle.hp, hp);
    expect(battle.attack(), false);
    battle.resume();
    advance(battle, 1);
    expect(battle.hits, 1);
    battle.restart();
    expect(battle.mode, StageMode.travel);
    expect(battle.phase, 0);
    expect(battle.hits, 0);
    expect(battle.charge, 0);
    expect(battle.hp, PlayableStageBattle.maxHp);
  });
  test('inactive input can lose and a fresh attempt recovers', () {
    final battle = PlayableStageBattle(stage: mechanicsStage(), roll: () => .5);
    addTearDown(battle.dispose);
    battle.start();
    advance(battle, 140);
    expect(battle.mode, StageMode.lost);
    expect(battle.hp, 0);
    expect(battle.attack(), false);
    battle.restart();
    advance(battle, 3);
    expect(battle.canAttack, true);
  });
}

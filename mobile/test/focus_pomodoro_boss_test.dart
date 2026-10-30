import 'package:focusquest/features/certificate/focus_defeat_counter.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/domain/stats.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/config/game_balance.dart';
import 'package:focusquest/features/focus/domain/focus_adventure.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'sessions below 30 minutes have no boss regardless of earlier focus history',
      () {
    for (final minutes in [1, 5, 15, 25, 29]) {
      for (final history in [0, 1500, 1799, 3300]) {
        final battle = BattleStateController(
            durationSeconds: minutes * 60.0, adventureStartSeconds: history)
          ..advanceTo(minutes * 60.0);
        expect(battle.bossDefeatedCount, 0,
            reason: '$minutes minutes / history $history');
        expect(battle.enemies.where((enemy) => enemy.data.isBoss), isEmpty);
      }
    }
  });
  test('a full cycle starts its boss at 25 minutes and finishes it at 30', () {
    final battle = BattleStateController(
        durationSeconds: 1800, adventureStartSeconds: 1739, focusAreaIndex: 0);
    battle.advanceTo(1499.95);
    expect(battle.isBossBattle, false);
    battle.advanceTo(1500);
    expect(battle.isBossBattle, true);
    expect(battle.bossRemainingSeconds, 300);
    expect(battle.enemies.single.data.isBoss, true);
    final beforeBoss = battle.gainedExp;
    battle.advanceTo(1799.95);
    expect(battle.enemies.single.hp, 1);
    expect(battle.bossDefeatedCount, 0);
    expect(battle.gainedExp, beforeBoss);
    battle.advanceTo(1800);
    expect(battle.bossDefeatedCount, 1);
    expect(battle.gainedExp, beforeBoss + GameBalance.focusBossExp);
    battle.advanceTo(1800);
    expect(battle.gainedExp, beforeBoss + GameBalance.focusBossExp);
    expect(battle.isBossBattle, false);
  });
  test(
      '60 minutes repeats at 55, while incomplete trailing cycles stay ordinary',
      () {
    final full =
        BattleStateController(durationSeconds: 3600, adventureStartSeconds: 0);
    full.advanceTo(3299.95);
    expect(full.bossDefeatedCount, 1);
    expect(full.isBossBattle, false);
    full.advanceTo(3300);
    expect(full.isBossBattle, true);
    full.advanceTo(3600);
    expect(full.bossDefeatedCount, 2);
    for (final minutes in [45, 59]) {
      final partial = BattleStateController(
          durationSeconds: minutes * 60.0, adventureStartSeconds: 3300)
        ..advanceTo(minutes * 60.0);
      expect(partial.bossDefeatedCount, 1);
      expect(partial.enemies.where((enemy) => enemy.data.isBoss), isEmpty);
    }
  });
  test(
      'party rendering and stored defeat counts share the session-based schedule',
      () {
    expect(FocusAdventure.bossActive(1500, durationSeconds: 29 * 60), false);
    expect(FocusAdventure.bossActive(1499.99, durationSeconds: 1800), false);
    expect(FocusAdventure.bossActive(1500, durationSeconds: 1800), true);
    expect(FocusAdventure.bossActive(1799.99, durationSeconds: 1800), true);
    expect(FocusAdventure.bossActive(1800, durationSeconds: 1800), false);
    expect(FocusAdventure.bossActive(3300, durationSeconds: 3600), true);
    expect(FocusAdventure.bossActive(3300, durationSeconds: 59 * 60), false);
    expect(FocusAdventure.completedBossCycles(9999, durationSeconds: 1800), 1);
    expect(FocusAdventure.completedBossCycles(1799, durationSeconds: 1800), 0);
    expect(FocusAdventure.completedBossCycles(3600, durationSeconds: 3600), 2);
  });
  test(
      'party defeat ledger excludes bosses for short sessions and counts one for a full cycle',
      () async {
    final started = DateTime(2026, 10, 12);
    final hero = Character(
        id: 'hero',
        name: '冒険者',
        characterType: 'warrior',
        baseStats: const Stats());
    const members = [
      PartyMember(
          id: 'a',
          name: 'A',
          characterType: 'warrior',
          appearance: 'male',
          level: 1),
      PartyMember(
          id: 'b',
          name: 'B',
          characterType: 'warrior',
          appearance: 'male',
          level: 1),
    ];
    for (final minutes in [25, 29, 30]) {
      final session = FocusSession(
          id: '$minutes',
          startedAt: started,
          durationMinutes: minutes,
          adventureStartSeconds: 1500,
          partyMembers: members);
      final defeats = await FocusDefeatCounter.count(
          session, hero, started.add(Duration(minutes: minutes)));
      expect(defeats, minutes == 30 ? 501 : minutes * 20);
    }
  });
}

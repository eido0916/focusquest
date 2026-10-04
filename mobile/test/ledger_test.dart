import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/domain/stats.dart';
import 'package:focusquest/features/focus/domain/focus_ledger.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/domain/reward_service.dart';

void main() {
  final hero = Character(
      id: 'hero',
      name: '勇者',
      characterType: 'warrior',
      baseStats: const Stats());
  final initial = PlayerState(
      uid: 'test-user', activeCharacterId: 'hero', characters: {'hero': hero});
  final session = FocusSession(
      id: 's1', startedAt: DateTime(2026, 10, 1, 9), durationMinutes: 30);
  const reward = Reward(
      exp: 300, coins: 100, adventureProgress: 30, items: ['wooden_sword']);
  final ledger = FocusLedger();
  test(
      'atomic focus settlement awards growth, money, progress and inventory once',
      () {
    final active = ledger.begin(initial, session);
    final settled = ledger.settle(active, 's1', FocusStatus.succeeded, reward);
    expect(settled.activeCharacter!.level, 3);
    expect(settled.activeCharacter!.currentExp, 50);
    expect(settled.coins, 100);
    expect(settled.adventureProgress, 30);
    expect(settled.inventory['wooden_sword'], 1);
    final restored = PlayerState.fromJson(settled.toJson());
    final retried =
        ledger.settle(restored, 's1', FocusStatus.succeeded, reward);
    expect(retried.toJson(), settled.toJson());
    expect(initial.coins, 0);
  });
  test('cancelled/failed sessions ignore any supplied rewards', () {
    for (final status in [FocusStatus.cancelled, FocusStatus.failed]) {
      final result =
          ledger.settle(ledger.begin(initial, session), 's1', status, reward);
      expect(result.coins, 0);
      expect(result.activeCharacter!.level, 1);
      expect(result.inventory, isEmpty);
      expect(
          ledger.settle(result, 's1', FocusStatus.succeeded, reward).coins, 0);
    }
  });
  test('cannot open concurrent sessions or settle unknown sessions', () {
    final active = ledger.begin(initial, session);
    expect(() => ledger.begin(active, session), throwsStateError);
    expect(
        () => ledger.settle(initial, 'missing', FocusStatus.succeeded, reward),
        throwsStateError);
    expect(() => ledger.settle(active, 's1', FocusStatus.active, reward),
        throwsStateError);
  });
}

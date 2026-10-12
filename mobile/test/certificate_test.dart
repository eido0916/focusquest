import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/certificate/certificate_catalog.dart';
import 'package:focusquest/features/certificate/certificate_data.dart';
import 'package:focusquest/features/certificate/focus_defeat_counter.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'support/memory_repository.dart';

void main() {
  test('all 16 roles unlock exact titles at levels 1..8 and cap above 8', () {
    expect(CertificateCatalog.titles.length, 16);
    for (final role in CertificateCatalog.titles.keys) {
      final list = CertificateCatalog.titles[role]!;
      expect(list.length, 8);
      for (var level = 1; level <= 8; level++) {
        expect(CertificateCatalog.title(role, level), list[level - 1]);
      }
      expect(CertificateCatalog.title(role, 99), list[7]);
    }
    expect(CertificateCatalog.title('warrior', 8), '剣聖');
  });
  test('first play and stable number survive reload; defeats are idempotent',
      () async {
    final repo = MemoryRepository();
    final first = DateTime(2026, 10, 1, 12);
    final c = GameController(repo, clock: () => first, random: Random(1));
    await c.load();
    final number = c.state!.adventurerNumber;
    expect(c.state!.firstPlayedAt, first);
    await c.onboard(GameCatalog.types[15]!, name: 'アオイ');
    await c.recordAdventureDefeats('battle-1', 3);
    await c.recordAdventureDefeats('battle-1', 3);
    await c.recordAdventureDefeats('battle-2', 2);
    await c.recordPlayableClear(1);
    await c.recordPlayableClear(3);
    await c.recordPlayableClear(3);
    final state = c.state!.copyWith(sessions: {
      'done': FocusSession(
          id: 'done',
          startedAt: first,
          durationMinutes: 90,
          status: FocusStatus.succeeded),
      'failed': FocusSession(
          id: 'failed',
          startedAt: first,
          durationMinutes: 60,
          status: FocusStatus.failed),
    });
    final restored = PlayerState.fromJson(state.toJson());
    final data = CertificateData.fromState(restored, DateTime(2026, 10, 11));
    expect(data.number, number);
    expect(data.issuedAt, first);
    expect(data.defeats, 5);
    expect(data.stages, 2);
    expect(data.days, 11);
    expect(data.focusMinutes, 90);
    expect(data.name, 'アオイ');
    await c.load();
    expect(c.state!.adventurerNumber, number);
    c.dispose();
  });
  test('legacy saves retain progress and leave unknown first-play date unknown',
      () {
    final json = PlayerState(uid: 'old', clearedPlayableStages: {1, 2}).toJson()
      ..remove('firstPlayedAt')
      ..remove('adventurerNumber')
      ..remove('totalDefeats');
    final state = PlayerState.fromJson(json);
    expect(state.firstPlayedAt, isNull);
    expect(state.totalDefeats, 0);
    expect(state.clearedPlayableStages, {1, 2});
  });
  test('focus defeats match the on-screen simulation and settle only once',
      () async {
    var now = DateTime(2026, 10, 11, 9);
    final c =
        GameController(MemoryRepository(), clock: () => now, random: Random(3));
    await c.load();
    await c.onboard(GameCatalog.types[15]!);
    await c.startFocus(1);
    final session = c.activeFocus!;
    final hero = c.state!.activeCharacter!;
    now = now.add(const Duration(minutes: 1));
    final battle = BattleStateController(
        config:
            PixelBattleAssets.runnerConfig(hero.characterType, hero.appearance),
        durationSeconds: 60)
      ..advanceTo(60);
    expect(await FocusDefeatCounter.count(session, hero, now),
        battle.defeatedCount);
    expect(battle.defeatedCount, greaterThan(0));
    await c.finishFocus();
    expect(c.state!.totalDefeats, battle.defeatedCount);
    await c.finishFocus();
    expect(c.state!.totalDefeats, battle.defeatedCount);
    c.dispose();
  });
}

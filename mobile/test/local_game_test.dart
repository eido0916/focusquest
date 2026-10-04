import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/local_player_repository.dart';
import 'package:focusquest/features/focus/data/usage_monitor.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/game/battle/battle_engine.dart';
import 'support/memory_repository.dart';

class TestUsage extends UsageMonitor {
  bool access = true;
  bool used = false;
  @override
  Future<bool> hasAccess() async => access;
  @override
  Future<UsageEvidence> evidence(FocusSession session, DateTime now) async =>
      UsageEvidence(available: access, targetUsed: used);
}

void main() {
  test(
      'continuous adventure reserves next enemy and rejects old battle callback',
      () async {
    var now = DateTime(2026, 10, 3, 9);
    final controller =
        GameController(MemoryRepository(), clock: () => now, random: Random(2));
    await controller.load();
    await controller.onboard(GameCatalog.types[3]!);
    await controller.startFocus(30);
    now = now.add(const Duration(minutes: 30));
    await controller.finishFocus();
    await controller.beginBattle();
    final first = controller.battleEngine();
    while (first.outcome == BattleOutcome.running) {
      first.update(0.1);
    }
    await controller.finishBattle(first, continueAdventure: true);
    expect(controller.state!.pendingBattle, isNotNull);
    expect(controller.state!.pendingBattle!['id'], isNot(first.battleId));
    final before = controller.state!.toJson();
    await controller.finishBattle(first, continueAdventure: true);
    expect(controller.state!.toJson(), before);
  });
  test(
      'disk persisted complete loop: diagnosis, focus, growth, battle, summon, restart',
      () async {
    final directory = await Directory.systemTemp.createTemp('focusquest-test-');
    addTearDown(() => directory.delete(recursive: true));
    var now = DateTime(2026, 10, 3, 9);
    final controller = GameController(LocalPlayerRepository(directory),
        clock: () => now, random: Random(42));
    await controller.load();
    await controller.onboard(GameCatalog.types[3]!);
    await controller.startFocus(30);
    now = now.add(const Duration(minutes: 30));
    final result = await controller.finishFocus();
    expect(result!.status, FocusStatus.succeeded);
    expect(controller.state!.activeCharacter!.level, 3);
    expect(controller.state!.coins, 100);
    expect(await controller.finishFocus(), isNull);
    await controller.beginBattle();
    final engine = controller.battleEngine();
    for (var i = 0; i < 10000 && engine.outcome == BattleOutcome.running; i++) {
      engine.update(0.1);
    }
    expect(engine.outcome, BattleOutcome.victory);
    await controller.finishBattle(engine);
    expect(controller.state!.stage, 2);
    final coins = controller.state!.coins;
    await controller.finishBattle(engine);
    expect(controller.state!.coins, coins);
    final summon = await controller.summon(1);
    expect(summon.prizes.length, 1);
    expect(controller.state!.gachaHistory.length, 1);
    final restored = GameController(LocalPlayerRepository(directory));
    await restored.load();
    expect(restored.state!.toJson(), controller.state!.toJson());
    expect(restored.state!.onboardingComplete, isTrue);
    await restored.startFocus(15);
    expect(restored.activeFocus, isNotNull);
  });
  test(
      'repository serializes concurrent updates, rejects corrupt data without resetting',
      () async {
    final directory = await Directory.systemTemp.createTemp('focusquest-test-');
    addTearDown(() => directory.delete(recursive: true));
    final repo = LocalPlayerRepository(directory);
    await Future.wait(List.generate(
        10,
        (_) => repo.transact(
            'local-player', (s) => s.copyWith(coins: s.coins + 1))));
    expect((await repo.load('local-player')).coins, 10);
    final file = File('${directory.path}/player-v1.json');
    await file.writeAsString('{corrupt');
    await expectLater(repo.load('local-player'), throwsFormatException);
    expect(await file.readAsString(), '{corrupt');
  });
  test(
      'permission denial, target app use, revoked permission and timer-only focus',
      () async {
    var now = DateTime(2026, 10, 3, 9);
    final usage = TestUsage();
    final controller =
        GameController(MemoryRepository(), monitor: usage, clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    await controller.configureMonitoring(true, ['example.app']);
    usage.access = false;
    await expectLater(controller.startFocus(1), throwsStateError);
    expect(controller.activeFocus, isNull);
    usage.access = true;
    await controller.startFocus(1);
    usage.used = true;
    now = now.add(const Duration(minutes: 1));
    expect((await controller.finishFocus())!.status, FocusStatus.failed);
    expect(controller.state!.coins, 0);
    await controller.startFocus(1);
    usage.access = false;
    now = now.add(const Duration(minutes: 1));
    expect((await controller.finishFocus())!.status, FocusStatus.failed);
    await controller.configureMonitoring(false, []);
    await controller.startFocus(1);
    now = now.add(const Duration(minutes: 1));
    expect((await controller.finishFocus())!.status, FocusStatus.succeeded);
  });
  test(
      'save failure retains active session and can retry without duplicate reward',
      () async {
    var now = DateTime(2026, 10, 3, 9);
    final repo = MemoryRepository();
    final controller = GameController(repo, clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[1]!);
    await controller.startFocus(30);
    now = now.add(const Duration(minutes: 30));
    repo.fail = true;
    await expectLater(controller.finishFocus(), throwsStateError);
    expect(controller.activeFocus, isNotNull);
    expect(controller.state!.coins, 0);
    repo.fail = false;
    await controller.finishFocus();
    expect(controller.state!.coins, 100);
    expect(controller.state!.sessions.length, 1);
  });
  test(
      'interrupted focus and battle restore and 10 summons persist every result',
      () async {
    final repo = MemoryRepository();
    var now = DateTime(2026, 10, 3, 9);
    var controller = GameController(repo, clock: () => now, random: Random(5));
    await controller.load();
    await controller.onboard(GameCatalog.types[3]!);
    for (var i = 0; i < 2; i++) {
      await controller.startFocus(150);
      controller = GameController(repo, clock: () => now, random: Random(5));
      await controller.load();
      now = now.add(const Duration(minutes: 150));
      await controller.finishFocus();
    }
    expect(controller.state!.coins, 1000);
    await controller.beginBattle();
    final before = jsonEncode(controller.state!.pendingBattle);
    controller = GameController(repo, clock: () => now, random: Random(5));
    await controller.load();
    expect(jsonEncode(controller.state!.pendingBattle), before);
    final engine = controller.battleEngine();
    while (engine.outcome == BattleOutcome.running) {
      engine.update(0.1);
    }
    await controller.finishBattle(engine);
    final result = await controller.summon(10);
    expect(result.prizes.length, 10);
    expect(controller.state!.gachaHistory.single['prizes'], hasLength(10));
    expect(controller.state!.coins, 10);
  });
}

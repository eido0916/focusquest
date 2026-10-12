import 'dart:io';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/local_player_repository.dart';
import 'package:focusquest/features/focus/data/usage_monitor.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'support/memory_repository.dart';

class TestUsage extends UsageMonitor {
  bool access = true;
  bool used = false;
  bool overlay = true;
  int starts = 0;
  int stops = 0;
  @override
  Future<Map<String, bool>?> guardPermissions() async =>
      {'usage': access, 'overlay': overlay};
  @override
  Future<void> startGuard(FocusSession session) async {
    starts++;
  }

  @override
  Future<void> stopGuard() async {
    stops++;
  }

  @override
  Future<bool> hasAccess() async => access;
  @override
  Future<UsageEvidence> evidence(FocusSession session, DateTime now) async =>
      UsageEvidence(available: access, targetUsed: used);
}

void main() {
  test(
      'disk persisted complete loop: diagnosis, focus, growth, equipment, restart',
      () async {
    final directory = await Directory.systemTemp.createTemp('focusquest-test-');
    addTearDown(() => directory.delete(recursive: true));
    var now = DateTime(2026, 10, 3, 9);
    final controller = GameController(LocalPlayerRepository(directory),
        clock: () => now, random: Random(42));
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!,
        name: 'アオイ', appearance: 'female');
    await controller.startFocus(30);
    now = now.add(const Duration(minutes: 30));
    final result = await controller.finishFocus();
    expect(result!.status, FocusStatus.succeeded);
    expect(controller.state!.activeCharacter!.level, 3);
    expect(controller.state!.coins, 0);
    await controller.recordPlayableClear(1);
    await controller.repository.transact(GameController.uid,
        (s) => s.copyWith(coins: 100, inventory: {'wooden_sword': 1}));
    await controller.load();
    expect(await controller.finishFocus(), isNull);
    await controller.equip('wooden_sword');
    expect(controller.state!.activeCharacter!.equippedItems.values,
        contains('wooden_sword'));
    final saveFile = File('${directory.path}/player-v1.json');
    final legacy = controller.state!.toJson()
      ..['gachaHistory'] = [
        {'id': 'legacy-summon', 'cost': 100, 'prizes': []}
      ];
    await saveFile.writeAsString(jsonEncode(legacy));
    final restored = GameController(LocalPlayerRepository(directory));
    await restored.load();
    expect(restored.state!.toJson(), controller.state!.toJson());
    expect(restored.state!.onboardingComplete, isTrue);
    expect(restored.state!.activeCharacter!.name, 'アオイ');
    expect(restored.state!.activeCharacter!.appearance, 'female');
    expect(restored.state!.coins, 100);
    expect(restored.state!.inventory['wooden_sword'], 1);
    expect(restored.state!.toJson().containsKey('gachaHistory'), isFalse);
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
      'guard requires both permissions and app warning does not fail new focus',
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
    usage.overlay = false;
    await expectLater(controller.startFocus(1), throwsStateError);
    expect(controller.activeFocus, isNull);
    expect(usage.starts, 0);
    usage.overlay = true;
    await controller.startFocus(1);
    expect(usage.starts, 1);
    expect(controller.activeFocus!.verification, FocusVerification.timerOnly);
    usage.used = true;
    now = now.add(const Duration(minutes: 1));
    expect((await controller.finishFocus())!.status, FocusStatus.succeeded);
    expect(usage.stops, 2); // Initial load, then settlement.
    expect(controller.state!.coins, 0);
    await controller.startFocus(1);
    usage.access = false;
    now = now.add(const Duration(minutes: 1));
    expect((await controller.finishFocus())!.status, FocusStatus.succeeded);
    usage.access = true;
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
    expect(controller.state!.coins, 0);
    expect(controller.state!.activeCharacter!.level, 3);
    expect(controller.state!.sessions.length, 1);
  });
  test('interrupted focus and current adventure clears restore', () async {
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
    expect(controller.state!.coins, 0);
    for (var stage = 1; stage <= 5; stage++) {
      await controller.recordPlayableClear(stage);
    }
    final savedInventory = controller.state!.inventory;
    final savedEquipment = controller.state!.activeCharacter!.equippedItems;
    controller = GameController(repo, clock: () => now, random: Random(5));
    await controller.load();
    expect(controller.state!.coins, 0);
    expect(controller.state!.clearedPlayableStages, hasLength(5));
    expect(controller.state!.inventory, savedInventory);
    expect(controller.state!.activeCharacter!.equippedItems, savedEquipment);
  });
}

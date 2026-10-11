import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/focus/data/usage_monitor.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/presentation/focus_screen.dart';
import 'support/memory_repository.dart';

class GuardMonitor extends UsageMonitor {
  bool usage = true;
  bool overlay = true;
  bool failStart = false;
  int starts = 0;
  int stops = 0;
  String? requested;
  @override
  Future<Map<String, bool>?> guardPermissions() async =>
      {'usage': usage, 'overlay': overlay};
  @override
  Future<void> startGuard(FocusSession session) async {
    if (failStart) throw StateError('service unavailable');
    starts++;
  }

  @override
  Future<void> stopGuard() async {
    stops++;
  }

  @override
  Future<void> requestAccess() async {
    requested = 'usage';
  }

  @override
  Future<void> requestOverlay() async {
    requested = 'overlay';
  }
}

void main() {
  test(
      'failed save stops guard; cancel stops guard; load restores active guard',
      () async {
    final repo = MemoryRepository();
    final monitor = GuardMonitor();
    final now = DateTime(2026, 10, 11);
    final controller = GameController(repo, monitor: monitor, clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    repo.fail = true;
    await expectLater(controller.startFocus(5), throwsStateError);
    expect(controller.activeFocus, isNull);
    expect(monitor.starts, 1);
    expect(monitor.stops, 2);
    repo.fail = false;
    await controller.startFocus(5);
    final restored = GameController(repo, monitor: monitor, clock: () => now);
    await restored.load();
    expect(monitor.starts, 3);
    await restored.finishFocus(cancel: true);
    expect(monitor.stops, 3);
    expect(restored.activeFocus, isNull);
    final expired = GameController(repo,
        monitor: monitor, clock: () => now.add(const Duration(minutes: 6)));
    await expired.load();
    expect(monitor.starts, 3);
    expect(monitor.stops, 4);
  });

  test('service failure never saves a new session or hides loaded progress',
      () async {
    final repo = MemoryRepository();
    final monitor = GuardMonitor();
    final controller = GameController(repo, monitor: monitor);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    monitor.failStart = true;
    await expectLater(controller.startFocus(5), throwsStateError);
    expect(controller.activeFocus, isNull);
    monitor.failStart = false;
    await controller.startFocus(5);
    monitor.failStart = true;
    final restored = GameController(repo, monitor: monitor);
    await restored.load();
    expect(restored.startupError, isNull);
    expect(restored.activeFocus, isNotNull);
  });

  for (final missing in ['usage', 'overlay']) {
    testWidgets('start guides $missing permission without starting a session',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final monitor = GuardMonitor()
        ..usage = missing != 'usage'
        ..overlay = missing != 'overlay';
      final controller = GameController(MemoryRepository(), monitor: monitor);
      await controller.load();
      await controller.onboard(GameCatalog.types[0]!);
      await tester
          .pumpWidget(MaterialApp(home: FocusScreen(controller: controller)));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('集中を開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('集中を開始'));
      await tester.pumpAndSettle();
      expect(find.text('アプリ警告の許可'), findsOneWidget);
      expect(controller.activeFocus, isNull);
      expect(monitor.starts, 0);
      await tester.tap(find.text('設定を開く'));
      await tester.pumpAndSettle();
      expect(monitor.requested, missing);
      expect(controller.activeFocus, isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

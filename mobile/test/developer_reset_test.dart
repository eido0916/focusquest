import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/local_player_repository.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/diagnosis/presentation/diagnosis_screen.dart';
import 'package:focusquest/features/focus/data/usage_monitor.dart';
import 'support/memory_repository.dart';

class _TestUsageMonitor extends UsageMonitor {
  @override
  Future<bool> hasAccess() async => true;
}

void main() {
  test('developer reset persists initial state and allows a new role',
      () async {
    final directory = await Directory.systemTemp.createTemp('fq-reset-');
    addTearDown(() => directory.delete(recursive: true));
    final controller = GameController(LocalPlayerRepository(directory),
        monitor: _TestUsageMonitor());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!, name: '以前の冒険者');
    await controller.configureMonitoring(true, ['example.app']);
    await controller.startFocus(30);
    await controller.resetForDevelopment();
    expect(controller.activeFocus, isNull);
    final restored = GameController(LocalPlayerRepository(directory));
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.state!.toJson(),
        PlayerState(uid: GameController.uid).toJson());
    await restored.onboard(GameCatalog.types[3]!, name: '新しい冒険者');
    expect(restored.state!.activeCharacter!.name, '新しい冒険者');
    expect(restored.state!.activeCharacter!.characterType,
        GameCatalog.types[3]!.typeId);
  });

  test('failed reset preserves state and permits retry', () async {
    final repository = MemoryRepository();
    final controller = GameController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    await controller.startAdventure('forest_1');
    final before = controller.state!.toJson();
    repository.fail = true;
    await expectLater(controller.resetForDevelopment(), throwsStateError);
    expect(controller.state!.toJson(), before);
    expect(controller.busy, isFalse);
    repository.fail = false;
    await controller.resetForDevelopment();
    expect(controller.state!.toJson(),
        PlayerState(uid: GameController.uid).toJson());
  });

  testWidgets('settings reset can cancel or return to initial role setup',
      (tester) async {
    final controller = GameController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('設定')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('アプリをリセット'), 300);
    await tester.ensureVisible(find.text('アプリをリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('アプリをリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(controller.state!.onboardingComplete, isTrue);
    await tester.tap(find.text('アプリをリセット'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('リセットする'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(DiagnosisScreen), findsOneWidget);
    expect(find.byType(QuestNavigation), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

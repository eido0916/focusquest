import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'support/memory_repository.dart';

void main() {
  testWidgets(
      'phone UI: focus -> reward -> Flame battles -> summon -> inventory',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = DateTime(2026, 10, 3, 9);
    final controller = GameController(MemoryRepository(),
        clock: () => now, random: Random(21));
    await controller.load();
    await controller.onboard(GameCatalog.types[3]!);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('集中をはじめる'));
    await tester.tap(find.text('集中をはじめる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('集中を開始'));
    await tester.pump();
    await tester.pump();
    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('集中クエスト達成！'), findsOneWidget);
    expect(controller.state!.coins, 100);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('冒険'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('自動戦闘へ • 進行度5'));
    await tester.pump();
    await tester.pump();
    expect(find.byWidgetPredicate((widget) => widget is GameWidget),
        findsOneWidget);
    for (var i = 0; i < 400 && controller.state!.battleHistory.isEmpty; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(controller.state!.battleHistory, isNotEmpty);
    // Leaving the battle pauses visual execution; persisted pending battle remains.
    await tester.tap(find.text('召喚'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1回召喚 • 100ポイント'));
    await tester.tap(find.text('1回召喚 • 100ポイント'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(controller.state!.gachaHistory, hasLength(1));
    expect(find.text('召喚結果'), findsOneWidget);
    await tester.tap(find.text('仲間'));
    await tester.pumpAndSettle();
    expect(find.text('所持アイテム'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

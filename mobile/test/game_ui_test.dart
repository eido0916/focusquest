import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'support/memory_repository.dart';

void main() {
  testWidgets('phone UI: focus battle -> reward -> summon -> inventory',
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
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('タイマーに戻る'), findsOneWidget);
    await tester.tap(find.text('タイマーに戻る'));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('集中クエスト達成！'), findsOneWidget);
    expect(controller.state!.coins, 100);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('召喚')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('1回召喚 • 100ポイント'));
    await tester.tap(find.text('1回召喚 • 100ポイント'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(controller.state!.gachaHistory, hasLength(1));
    expect(find.text('召喚結果'), findsOneWidget);
    await tester.tap(find.text('キャラクター'));
    await tester.pumpAndSettle();
    expect(find.text('所持アイテム'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

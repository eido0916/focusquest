import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'support/memory_repository.dart';

void main() {
  testWidgets('phone UI: focus EXP -> adventure reward -> equipment',
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
    final navigation = find.byType(QuestNavigation);
    for (final label in ['ホーム', 'キャラクター', '設定', '冒険']) {
      expect(find.descendant(of: navigation, matching: find.text(label)),
          findsOneWidget);
    }
    expect(find.text('召喚'), findsNothing);
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
    expect(find.text('戦いの様子を見る'), findsOneWidget);
    await tester.ensureVisible(find.text('戦いの様子を見る'));
    await tester.tap(find.text('戦いの様子を見る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('タイマーに戻る'), findsOneWidget);
    expect(controller.state!.coins, 0);
    await tester.tap(find.text('タイマーに戻る'));
    await tester.pumpAndSettle();
    expect(controller.state!.adventureRun, isNull);
    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('集中クエスト達成！'), findsOneWidget);
    expect(controller.state!.coins, 0);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('冒険に出発する'));
    await tester.tap(find.text('冒険に出発する'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('冒険に出発する').first);
    await tester.tap(find.text('冒険に出発する').first);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('勝利！'), findsOneWidget);
    expect(controller.state!.coins, 100);
    await tester.ensureVisible(find.text('冒険の書へ戻る'));
    await tester.tap(find.text('冒険の書へ戻る'));
    await tester.pumpAndSettle();
    expect(find.text('召喚'), findsNothing);
    expect(controller.state!.coins, 100);
    expect(controller.state!.inventory['wooden_sword'], 1);
    await tester.tap(find.text('キャラクター'));
    await tester.pumpAndSettle();
    expect(find.text('所持アイテム'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

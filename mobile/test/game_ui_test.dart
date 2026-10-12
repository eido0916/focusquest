import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'support/memory_repository.dart';
import 'package:focusquest/features/focus/presentation/focus_screen.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';

void main() {
  testWidgets('phone UI: focus EXP -> current adventure -> growth',
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
    expect(find.text('集中メニュー'), findsOneWidget);
    await tester.tap(find.text('集中メニュー'));
    await tester.pumpAndSettle();
    expect(find.text('戦闘画面に戻る'), findsOneWidget);
    await tester.ensureVisible(find.text('戦闘画面に戻る'));
    await tester.tap(find.text('戦闘画面に戻る'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('集中メニュー'), findsOneWidget);
    expect(controller.state!.coins, 0);
    await tester.tap(find.text('集中メニュー'));
    await tester.pumpAndSettle();
    now = now.add(const Duration(minutes: 30));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(find.text('集中クエスト達成！'), findsOneWidget);
    expect(controller.state!.coins, 0);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('LEVEL UP!'), findsOneWidget);
    await tester.tap(find.text('成長した力で冒険へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('focus-back')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('冒険に出発する'));
    await tester.tap(find.text('冒険に出発する'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('select-stage-1')), findsOneWidget);
    expect(find.text('以前の冒険の書'), findsNothing);
    expect(controller.state!.coins, 0);
    await tester.tap(find.text('キャラクター'));
    await tester.pumpAndSettle();
    expect(find.text('所持アイテム'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('focus menu returns home without interrupting the saved session',
      (tester) async {
    var now = DateTime(2026, 10, 12, 12);
    final controller = GameController(MemoryRepository(), clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await controller.startFocus(5);
    final sessionId = controller.activeFocus!.id;
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('集中へ戻る'));
    await tester.tap(find.text('集中へ戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(FocusScreen), findsOneWidget);
    await tester.tap(find.byKey(const Key('focus-return-home')));
    await tester.pumpAndSettle();
    expect(find.byType(FocusScreen), findsNothing);
    expect(find.text('集中へ戻る'), findsOneWidget);
    expect(controller.activeFocus!.id, sessionId);
    expect(controller.activeFocus!.status, FocusStatus.active);
    now = now.add(const Duration(minutes: 1));
    expect(controller.activeFocus!.remaining(now), const Duration(minutes: 4));
    expect(controller.state!.activeCharacter!.currentExp, 0);
    await tester.ensureVisible(find.text('集中へ戻る'));
    await tester.tap(find.text('集中へ戻る'));
    await tester.pumpAndSettle();
    expect(find.text('戦闘画面に戻る'), findsOneWidget);
    expect(controller.activeFocus!.id, sessionId);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}

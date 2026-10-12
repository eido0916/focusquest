import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/adventure/domain/adventure.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    const fontPath = String.fromEnvironment('QA_FONT');
    if (fontPath.isEmpty) return;
    final bytes = await File(fontPath).readAsBytes();
    for (final family in ['Ahem', 'Roboto', 'serif']) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    testWidgets('adventure list, resume and result fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026, 10, 10);
      final controller = GameController(MemoryRepository(), clock: () => now);
      await controller.load();
      await controller.onboard(GameCatalog.types[15]!, name: 'アオイ');
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary, child: FocusQuestApp(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(QuestNavigation), matching: find.text('冒険')));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
          find.byKey(const Key('legacy-adventure')), 500);
      await tester.pumpAndSettle();
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('legacy-adventure')));
      await tester.pumpAndSettle();
      expect(find.text('踏破 0 / 5'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 300)));
      await tester.pumpAndSettle();
      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_ADVENTURE')) return;
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('../output/adventure/${size.width.toInt()}-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      await capture('stages');
      await tester.scrollUntilVisible(find.text('冒険に出発する'), 150);
      await tester.pumpAndSettle();
      await tester.tap(find.text('冒険に出発する').first);
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      final run = controller.state!.adventureRun!;
      now = now.add(const Duration(milliseconds: 850));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await capture('battle');
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('進行中の冒険へ戻る'), -150);
      await tester.pumpAndSettle();
      expect(find.text('進行中の冒険へ戻る'), findsOneWidget);
      await tester.tap(find.text('進行中の冒険へ戻る'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      now = run.startedAt.add(AdventureBattle.simulate(run).duration);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 500));
      expect(controller.state!.clearedStages, {'forest_1'});
      await tester.scrollUntilVisible(find.text('勝利！'), 150);
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('勝利！'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await capture('victory');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
  testWidgets('large text adventure commands remain reachable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('冒険')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
        find.byKey(const Key('legacy-adventure')), 500);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('legacy-adventure')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('冒険に出発する'), 150);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

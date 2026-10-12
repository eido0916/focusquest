import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final serif = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(serif))).load();
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
    for (final scale in [1.0, 1.6]) {
      testWidgets('home fits $size at text scale $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final controller = GameController(MemoryRepository());
        await controller.load();
        await controller.onboard(GameCatalog.types[3]!, name: '守護者');
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary, child: FocusQuestApp(controller: controller)));
        await tester.pumpAndSettle();
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('今日の集中'), findsOneWidget);
        if (const bool.fromEnvironment('CAPTURE_HOME') && scale == 1) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File('../output/home/${size.width.toInt()}-home.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.text('冒険に出発する'));
        await tester.tap(find.text('冒険に出発する'));
        await tester.pumpAndSettle();
        expect(find.text('冒険の書'), findsOneWidget);
        await tester.scrollUntilVisible(
            find.byKey(const Key('select-stage-1')), 150);
        await tester.pumpAndSettle();
        expect(find.byKey(const Key('select-stage-1')), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}

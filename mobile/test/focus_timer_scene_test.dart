import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/focus/presentation/focus_timer_scene.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(568, 320),
    const Size(1024, 768),
    const Size(844, 390)
  ]) {
    testWidgets('timer fits $size and retains live controls', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      var battles = 0;
      var cancels = 0;
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              home: FocusTimerScene(
                  characterName: 'まさし',
                  characterType: 'warrior',
                  level: 3,
                  chapter: 2,
                  seconds: 1791,
                  progress: .38,
                  onBattle: () => battles++,
                  onCancel: () => cancels++,
                  onSound: () {},
                  onBack: () {}))));
      await tester.pumpAndSettle();
      for (final element in find.byType(Image).evaluate()) {
        await tester.runAsync(
            () => precacheImage((element.widget as Image).image, element));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('29:51'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.byKey(const Key('focus-timer-scroll')), findsOneWidget);
      expect(find.byKey(const Key('focus-landscape-layout')), findsNothing);
      expect(find.text('第2章 · 集中クエスト進行中'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_FOCUS_PORTRAIT')) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('build/focus-portrait/timer-$size.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.text('戦いの様子を見る'));
      await tester.tap(find.text('戦いの様子を見る'));
      await tester.pump();
      expect(battles, 1);
      await tester.ensureVisible(find.text('集中を中断'));
      await tester.tap(find.text('集中を中断'));
      await tester.pump();
      expect(cancels, 1);
      expect(tester.takeException(), isNull);
    });
  }
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/diagnosis/presentation/diagnosis_screen.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    const fontPath = String.fromEnvironment('QA_FONT');
    if (fontPath.isEmpty) return;
    final bytes = await File(fontPath).readAsBytes();
    for (final family in ['Ahem', 'Roboto', 'serif', 'SunlitSerif']) {
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(800, 1280),
    const Size(844, 390)
  ]) {
    testWidgets('onboarding to saved home fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final controller = GameController(MemoryRepository());
      await controller.load();
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary, child: FocusQuestApp(controller: controller)));
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder);
        await tester.pumpAndSettle();
        await tester.tap(finder);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }

      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_DIAGNOSIS')) return;
        final scrollable = find.byType(Scrollable).first;
        tester.state<ScrollableState>(scrollable).position.jumpTo(0);
        await tester.pumpAndSettle();
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          const output = String.fromEnvironment('DIAGNOSIS_OUTPUT',
              defaultValue: '../output/diagnosis');
          final file = File('$output/${size.width.toInt()}-$name.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }

      await tester.tap(find.byKey(const Key('magic-stone')));
      await tester.pump(const Duration(milliseconds: 750));
      await tester.pumpAndSettle();
      await capture('identity');
      if (size.width == 800) {
        final nameField = find.byKey(const Key('adventurer-name'));
        expect(tester.getSize(nameField).width, greaterThan(600));
        final voice = find.text('まばゆい光の中から、声が響く。\n「そなたの名と、望む姿を教えておくれ。」');
        final text = tester.widget<Text>(voice);
        expect(
            MediaQuery.textScalerOf(tester.element(voice))
                .scale(text.style!.fontSize!),
            greaterThanOrEqualTo(24));
      }
      await tester.enterText(find.byKey(const Key('adventurer-name')), 'アオイ');
      await tap(find.byKey(const Key('appearance-female')));
      await tap(find.text('石の問いに答える'));
      await capture('questions');
      for (var i = 1; i <= 10; i++) {
        await tap(find.byKey(Key('q$i-2')));
        if (i == 1) await capture('question-selected');
        await tap(find.text(i < 10 ? 'この答えで進む' : '診断結果を見る'));
      }
      expect(find.text('魔法使い'), findsOneWidget);
      await capture('result');
      await tap(find.byKey(const Key('begin-adventure')));
      expect(find.byType(DiagnosisScreen), findsNothing);
      expect(controller.state!.activeCharacter!.name, 'アオイ');
      expect(controller.state!.activeCharacter!.appearance, 'female');
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
  testWidgets('large text identity remains scrollable', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(1.5)),
            child: child!),
        home: DiagnosisScreen(onComplete: (type, name, appearance) async {})));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('石の問いに答える'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}

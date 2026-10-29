import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/diagnosis/presentation/king_intro_scene.dart';
import 'package:focusquest/features/diagnosis/presentation/king_intro_ornaments.dart';

void main() {
  setUpAll(() async {
    final font = FontLoader('SunlitSerif')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf'));
    await font.load();
    if (const bool.fromEnvironment('CAPTURE_KING')) {
      for (final entry in <String, (CustomPainter, Size)>{
        'dialogue_frame': (
          const KingDialogueFramePainter(),
          const Size(840, 270)
        ),
        'title_rule': (const KingTitleRulePainter(), const Size(400, 30)),
        'continue_arrow': (const KingContinuePainter(), const Size(24, 24)),
      }.entries) {
        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        entry.value.$1.paint(canvas, entry.value.$2);
        final picture = recorder.endRecording();
        final image = await picture.toImage(
            entry.value.$2.width.toInt(), entry.value.$2.height.toInt());
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../art/king_intro_v002/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(data!.buffer.asUint8List());
        image.dispose();
        picture.dispose();
      }
    }
  });
  testWidgets('dialogue reveals on tap and stone starts only once',
      (tester) async {
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: KingIntroScene(onTouchStone: () => starts++)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(starts, 0);
    await tester.tap(find.byKey(const Key('king-dialogue')));
    await tester.pump();
    expect(find.text(KingIntroScene.dialogue), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('magic-stone')));
    expect(starts, 0);
    await tester.pump(const Duration(milliseconds: 750));
    expect(starts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    testWidgets('scene fits ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: KingIntroScene(onTouchStone: () {}))));
      await tester.runAsync(() async {
        final context = tester.element(find.byType(KingIntroScene));
        for (final name in [
          'cathedral',
          'old_king',
          'magic_crystal',
          'touch_hand'
        ]) {
          await precacheImage(
              AssetImage('${KingIntroScene.assetRoot}/$name.png'), context);
        }
      });
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
      expect(find.byKey(const Key('king-continue')), findsOneWidget);
      final stone = tester.getRect(find.byKey(const Key('magic-stone')));
      final panel = tester.getRect(find.byKey(const Key('king-dialogue')));
      expect(stone.overlaps(panel), isFalse, reason: 'stone=$stone panel=$panel');
      if (const bool.fromEnvironment('CAPTURE_KING')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              '../art/king_intro_v002/preview-${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('leaving during light transition cancels diagnosis launch',
      (tester) async {
    var starts = 0;
    await tester.pumpWidget(
        MaterialApp(home: KingIntroScene(onTouchStone: () => starts++)));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(starts, 0);
    expect(tester.takeException(), isNull);
  });
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/diagnosis/domain/diagnosis_service.dart';
import 'package:focusquest/features/diagnosis/presentation/job_reveal_screen.dart';

void main() {
  const service = DiagnosisService(
      questions: GameCatalog.questions, types: GameCatalog.types);
  setUpAll(() async {
    const fontPath = String.fromEnvironment('QA_FONT');
    if (fontPath.isEmpty) return;
    final bytes = await File(fontPath).readAsBytes();
    for (final family in ['Ahem', 'Roboto', 'SunlitSerif']) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });
  for (final role in GameCatalog.types.values) {
    for (final sex in ['male', 'female']) {
      testWidgets('role reveal ${role.typeId} $sex', (tester) async {
        tester.view.physicalSize = const Size(390, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final scroll = ScrollController();
        addTearDown(scroll.dispose);
        final boundary = GlobalKey();
        var began = false;
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.dark,
            home: RepaintBoundary(
                key: boundary,
                child: JobRevealScreen(
                    result: role,
                    name: 'フォーカス',
                    appearance: sex,
                    scroll: scroll,
                    code: service.codeFor(role),
                    onBegin: () => began = true,
                    onReview: () {}))));
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(role.job), findsOneWidget);
        expect(find.text(service.codeFor(role)), findsOneWidget);
        if (const bool.fromEnvironment('CAPTURE_JOB_REVEAL')) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            const output = String.fromEnvironment('JOB_REVEAL_OUTPUT');
            final file = File('$output/${role.typeId}_$sex.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.byKey(const Key('begin-adventure')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('begin-adventure')));
        expect(began, isTrue);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

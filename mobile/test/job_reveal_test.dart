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
    for (final family in ['Ahem', 'Roboto', 'serif', 'SunlitSerif']) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });
  test('all roles have unique four-axis codes', () {
    expect(GameCatalog.types.values.map(service.codeFor).toSet().length, 16);
    expect(service.codeFor(GameCatalog.types[12]!), 'SHIR');
    expect(service.codeFor(GameCatalog.types[15]!), 'DFIR');
    expect(service.codeFor(GameCatalog.types[0]!), 'SHTV');
  });
  test('all 16 codes match the supplied role table', () {
    const expected = {
      'warrior': 'DFIR',
      'boxer': 'DFTR',
      'samurai': 'SHIR',
      'guardian': 'DHTR',
      'ninja': 'SFIR',
      'assassin': 'SFIV',
      'ranger': 'SHTR',
      'gunner': 'SFTR',
      'mage': 'SHTV',
      'spellblade': 'DFIV',
      'onmyoji': 'SFTV',
      'reaper': 'SHIV',
      'angel': 'DHTV',
      'devil': 'DHIV',
      'dragon_knight': 'DFTV',
      'berserker': 'DHIR'
    };
    expect({
      for (final type in GameCatalog.types.values)
        type.typeId: service.codeFor(type)
    }, expected);
  });
  test('all 32 supplied transparent portraits exist', () {
    for (final role in GameCatalog.types.values) {
      for (final sex in ['male', 'female']) {
        final prefix = sex == 'female' ? 'female/' : '';
        final path = role.typeId == 'gunner' && sex == 'female'
            ? 'assets/images/lobby/portraits/female/gunner_dark_brown_transparent_v002.png'
            : 'assets/images/lobby/portraits/$prefix${role.typeId}.png';
        expect(File(path).existsSync(), isTrue, reason: path);
      }
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(941, 1672),
    const Size(844, 390)
  ]) {
    testWidgets('result and controls fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      final boundary = GlobalKey();
      var begun = 0, reviewed = 0;
      final role = GameCatalog.types[15]!;
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: RepaintBoundary(
              key: boundary,
              child: JobRevealScreen(
                  result: role,
                  name: 'きんぐ',
                  appearance: 'male',
                  scroll: scroll,
                  code: service.codeFor(role),
                  onBegin: () => begun++,
                  onReview: () => reviewed++))));
      for (final element in find.byType(Image).evaluate()) {
        await tester.runAsync(
            () => precacheImage((element.widget as Image).image, element));
      }
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('DFIR'), findsOneWidget);
      if (const bool.fromEnvironment('CAPTURE_JOB_REVEAL')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          const output = String.fromEnvironment('JOB_REVEAL_OUTPUT');
          final file = File('$output/${size.width.toInt()}-warrior.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.byKey(const Key('begin-adventure')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('begin-adventure')));
      expect(begun, 1);
      await tester.ensureVisible(find.text('答えを見直す'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('答えを見直す'));
      expect(reviewed, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

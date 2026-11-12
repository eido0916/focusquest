import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/presentation/character_screen.dart';
import 'package:focusquest/features/character/presentation/character_pixel_portrait.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'package:focusquest/features/home/home_screen.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
  });
  for (final appearance in ['male', 'female']) {
    for (final type in GameCatalog.types.values) {
      testWidgets(
          '$appearance ${type.job}: correct supplied home art and pixel standing art',
          (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GameController(MemoryRepository());
        await controller.load();
        await controller.onboard(type, name: '立ち絵確認', appearance: appearance);
        for (final entry in {
          'home': HomeScreen(
              controller: controller, onFocus: () {}, onNavigate: (_) {}),
          'character': CharacterScreen(controller: controller),
        }.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(MaterialApp(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              home: Scaffold(
                  body: RepaintBoundary(key: boundary, child: entry.value))));
          await tester.pumpAndSettle();
          if (entry.key == 'character') {
            final portrait = tester.widget<CharacterPixelPortrait>(
                find.byType(CharacterPixelPortrait));
            expect(portrait.role, type.typeId);
            expect(portrait.appearance, appearance);
            final image = tester.widget<Image>(find.descendant(
                of: find.byType(CharacterPixelPortrait),
                matching: find.byType(Image)));
            expect((image.image as AssetImage).assetName,
                'assets/images/character_ui_v008/standing/$appearance/${type.typeId}.png');
            expect(image.filterQuality, FilterQuality.none);
          } else {
            final portrait =
                tester.widget<JobPortrait>(find.byType(JobPortrait));
            expect(portrait.typeId, type.typeId);
            expect(portrait.appearance, appearance);
            final image = tester.widget<Image>(find.descendant(
                of: find.byType(JobPortrait), matching: find.byType(Image)));
            expect(
                (image.image as AssetImage).assetName,
                type.typeId == 'gunner' && appearance == 'female'
                    ? 'assets/images/lobby/portraits/female/gunner_dark_brown_transparent_v002.png'
                    : 'assets/images/lobby/portraits/${appearance == 'female' ? 'female/' : ''}${type.typeId}.png');
            expect(image.fit, BoxFit.contain);
          }
          for (final element in find.byType(Image).evaluate()) {
            await tester.runAsync(
                () => precacheImage((element.widget as Image).image, element));
          }
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull,
              reason: '${type.job} ${entry.key}');
          if (type.typeId == 'ranger' &&
              const bool.fromEnvironment('CAPTURE_ROLE_REVIEW')) {
            await tester.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              final captured = await render.toImage();
              final bytes =
                  await captured.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  '../output/portraits/role-review/$appearance-ranger-${entry.key}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              captured.dispose();
            });
          }
        }
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
    }
  }
}

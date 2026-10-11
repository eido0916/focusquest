import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/adventure/presentation/adventure_screen.dart';
import 'package:focusquest/features/character/presentation/character_screen.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'package:focusquest/features/focus/presentation/focus_screen.dart';
import 'package:focusquest/features/home/home_screen.dart';

import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    const fontPath = String.fromEnvironment('QA_FONT');
    if (fontPath.isEmpty) return;
    final bytes = await File(fontPath).readAsBytes();
    for (final family in ['Ahem', 'Roboto', 'serif']) {
      await (FontLoader(family)
            ..addFont(Future.value(ByteData.sublistView(bytes))))
          .load();
    }
  });

  for (final appearance in ['male', 'female']) {
    for (final width in [390.0, 320.0]) {
      testWidgets('supplied $appearance portraits outside adventure at $width',
          (tester) async {
        tester.view.physicalSize = Size(width, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = GameController(MemoryRepository());
        await controller.load();
        final role = appearance == 'male'
            ? GameCatalog.types[15]!
            : GameCatalog.types[0]!;
        await controller.onboard(role, name: 'アオイ', appearance: appearance);
        for (final entry in {
          'home': HomeScreen(
              controller: controller, onFocus: () {}, onNavigate: (_) {}),
          'character': CharacterScreen(controller: controller),
          'focus': FocusScreen(controller: controller),
        }.entries) {
          final boundary = GlobalKey();
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  theme: AppTheme.dark, home: Scaffold(body: entry.value))));
          await tester.pumpAndSettle();
          expect(find.byType(PixelHero), findsNothing);
          expect(find.byType(PixelSprite), findsNothing);
          {
            final portrait =
                tester.widget<JobPortrait>(find.byType(JobPortrait));
            expect(portrait.typeId, role.typeId);
            expect(portrait.appearance, appearance);
            final imageFinder = find.descendant(
                of: find.byType(JobPortrait), matching: find.byType(Image));
            final image = tester.widget<Image>(imageFinder);
            expect(
                (image.image as AssetImage).assetName,
                entry.key != 'focus'
                    ? 'assets/images/lobby/portraits/${appearance == 'female' ? 'female/' : ''}${role.typeId}.png'
                    : 'assets/images/portraits/$appearance/${role.typeId}.webp');
          }
          for (final element in find.byType(Image).evaluate()) {
            await tester.runAsync(
                () => precacheImage((element.widget as Image).image, element));
          }
          await tester.pump();
          expect(tester.takeException(), isNull,
              reason: '${entry.key} at $width');
          if (const bool.fromEnvironment('CAPTURE_PORTRAITS')) {
            await tester.runAsync(() async {
              final render = boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
              final image = await render.toImage();
              final bytes =
                  await image.toByteData(format: ui.ImageByteFormat.png);
              final file = File(
                  '../output/portraits/${width.toInt()}-$appearance-${entry.key}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/presentation/character_screen.dart';
import 'package:focusquest/features/certificate/certificate_screen.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  for (final size in [
    const Size(390, 844),
    const Size(390, 690),
    const Size(390, 1150),
    const Size(320, 568),
    const Size(800, 1280),
    const Size(866, 1280),
    const Size(844, 390)
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('equipment-free character lobby at $size scale $scale',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final repo = MemoryRepository();
        final controller = GameController(repo);
        await controller.load();
        await controller.onboard(
            GameCatalog.types[16] ??
                GameCatalog.types.values
                    .firstWhere((t) => t.typeId == 'berserker'),
            name: 'まさし');
        final hero = repo.state.activeCharacter!;
        repo.state = repo.state.copyWith(characters: {
          hero.id: hero.copyWith(level: 3, currentExp: 50)
        }, inventory: {
          'wooden_sword': 11,
          'silver_ring': 3,
          'cloth_armor': 3
        });
        await controller.load();
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
                theme: AppTheme.dark,
                debugShowCheckedModeBanner: false,
                home: AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) => Scaffold(
                        body: CharacterScreen(controller: controller),
                        bottomNavigationBar:
                            QuestNavigation(selected: 1, onSelect: (_) {}))))));
        await tester.pumpAndSettle();
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Lv. 3'), findsOneWidget);
        expect(find.text('称号変更'), findsOneWidget);
        expect(find.byKey(const ValueKey('character-stats')), findsOneWidget);
        expect(find.byKey(const ValueKey('character-equipment')), findsNothing);
        await tester.ensureVisible(find.text('冒険者証を見る'));
        await tester.pumpAndSettle();
        expect(find.text('冒険者証を見る').hitTestable(), findsOneWidget);
        expect(find.text('所持アイテム'), findsNothing);
        expect(find.textContaining('現在の称号'), findsNothing);
        if (const bool.fromEnvironment('CAPTURE_LOBBY') && scale == 1) {
          await tester.drag(find.byKey(const ValueKey('character-scroll')),
              const Offset(0, 1800));
          await tester.pumpAndSettle();
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '../art/character_ui_v004/previews/character-${size.width.toInt()}x${size.height.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.ensureVisible(find.byKey(const ValueKey('change-title')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('change-title')));
        await tester.pumpAndSettle();
        for (final element in find.byType(Image).evaluate()) {
          await tester.runAsync(
              () => precacheImage((element.widget as Image).image, element));
        }
        await tester.pumpAndSettle();
        expect(find.text('称号一覧'), findsOneWidget);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_LOBBY') &&
            size.width == 390 &&
            scale == 1) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '../art/character_ui_v004/previews/titles-${size.height.toInt()}.png');
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.byTooltip('閉じる'));
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('冒険者証を見る'));
        await tester.pumpAndSettle();
        if (size == const Size(390, 844) && scale == 1) {
          await tester.runAsync(() async {
            await tester.tap(find.byKey(const ValueKey('view-certificate')));
            await tester.pump(const Duration(seconds: 1));
            for (var i = 0;
                i < 100 &&
                    find
                        .descendant(
                            of: find.byType(CertificateScreen),
                            matching: find.byType(Image))
                        .evaluate()
                        .isEmpty;
                i++) {
              await Future<void>.delayed(const Duration(milliseconds: 100));
              await tester.pump();
            }
          });
          await tester.pump();
          expect(find.byType(CertificateScreen), findsOneWidget);
          expect(
              find.descendant(
                  of: find.byType(CertificateScreen),
                  matching: find.byType(Image)),
              findsOneWidget);
          expect(tester.takeException(), isNull);
        }
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}

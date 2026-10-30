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

const captureDirectory = String.fromEnvironment('LOBBY_CAPTURE_DIRECTORY',
    defaultValue: '../art/character_ui_v006/previews');

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  for (final size in [
    const Size(375, 662),
    const Size(390, 844),
    const Size(390, 690),
    const Size(390, 1150),
    const Size(320, 568),
    const Size(800, 1280),
    const Size(866, 1280),
    const Size(844, 390),
    const Size(1280, 800),
    const Size(1086, 1448)
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
        final reference = size == const Size(1086, 1448);
        await controller.onboard(
            GameCatalog.types.values.firstWhere((t) => t.typeId == 'warrior'),
            name: reference ? 'a' : 'まさし');
        final hero = repo.state.activeCharacter!;
        repo.state = repo.state.copyWith(characters: {
          hero.id: hero.copyWith(
              level: reference ? 1 : 3, currentExp: reference ? 0 : 50)
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
        expect(find.byKey(const ValueKey('character-continuous-background')),
            findsOneWidget);
        expect(
            tester.widgetList<Image>(find.byType(Image)).where((image) =>
                image.image is AssetImage &&
                (image.image as AssetImage)
                    .assetName
                    .endsWith('hero_courtyard.png')),
            isEmpty);
        if (size == const Size(375, 662) && scale == 1) {
          expect(
              tester
                  .getBottomRight(
                      find.byKey(const ValueKey('view-certificate')))
                  .dy,
              lessThanOrEqualTo(
                  tester.getTopLeft(find.byType(QuestNavigation)).dy));
        }
        expect(find.text(reference ? 'Lv. 1' : 'Lv. 3'), findsOneWidget);
        final expFill =
            tester.getSize(find.byKey(const ValueKey('character-exp-fill')));
        expect(expFill.height, greaterThan(0));
        expect(expFill.width, reference ? 0 : greaterThan(0));
        expect(find.text('称号変更'), findsOneWidget);
        expect(find.byKey(const ValueKey('character-stats')), findsOneWidget);
        for (final heading in [
          ('能力値', 'character-stats'),
          ('冒険者情報', 'adventurer-information')
        ]) {
          expect(
              tester.getCenter(find.text(heading.$1)).dx,
              closeTo(
                  tester.getCenter(find.byKey(ValueKey(heading.$2))).dx, .5));
        }
        // Narrow screens must reflow, keeping live labels readable.
        for (final text in tester.widgetList<Text>(find.descendant(
            of: find.byType(CharacterScreen), matching: find.byType(Text)))) {
          expect(text.style?.fontSize ?? 16, greaterThanOrEqualTo(13));
        }
        expect(
            find.descendant(
                of: find.byType(CharacterScreen),
                matching: find.byType(Scrollable)),
            findsNothing);
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
            final image =
                await render.toImage(pixelRatio: size.width >= 1000 ? 1 : 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '$captureDirectory/character-${size.width.toInt()}x${size.height.toInt()}.png');
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
            final file =
                File('$captureDirectory/titles-${size.height.toInt()}.png');
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

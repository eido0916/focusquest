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
    const Size(320, 568),
    const Size(800, 1280),
    const Size(866, 1280),
    const Size(844, 390)
  ]) {
    for (final scale in [1.0, 1.6]) {
      testWidgets('lobby inventory equips at $size scale $scale',
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
        await controller.onboard(GameCatalog.types[9]!, name: '守護者');
        final hero = repo.state.activeCharacter!;
        repo.state = repo.state.copyWith(characters: {
          hero.id: hero.copyWith(level: 12, currentExp: 370)
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
        final headerImage = find
            .byWidgetPredicate((widget) =>
                widget is Image &&
                widget.image is AssetImage &&
                (widget.image as AssetImage).assetName ==
                    'assets/images/lobby/equipment_slot.png')
            .first;
        expect(tester.getSize(headerImage).width, lessThanOrEqualTo(640));
        expect(tester.getTopLeft(find.text('Lv. 12　重騎士')).dy,
            greaterThan(tester.getBottomLeft(find.text('キャラクター').first).dy));
        expect(find.text('仲間'), findsNothing);
        expect(find.text('編成中'), findsNothing);
        expect(
            find.descendant(
                of: find.byType(CharacterScreen),
                matching: find.byType(FittedBox)),
            findsNothing);
        if (size.width >= 600 && size.height >= 1000 && scale == 1) {
          expect(find.byType(Scrollable), findsNothing);
          final panel =
              tester.getRect(find.byKey(const ValueKey('character-stats')));
          final title = tester.getRect(find.text('Lv. 12　重騎士'));
          expect(title.left - panel.left, greaterThanOrEqualTo(30));
          expect(title.right, lessThan(panel.right - 30));
          expect((tester.widget<Text>(find.text('攻撃力')).style!).fontSize,
              greaterThanOrEqualTo(20));
        }
        expect(find.text('所持アイテム').hitTestable(), findsOneWidget);
        if (const bool.fromEnvironment('CAPTURE_LOBBY') && scale == 1) {
          await tester.runAsync(() async {
            final render = boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
            final image = await render.toImage(pixelRatio: 2);
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            final file = File(
                '../output/character_lobby/character-${size.width.toInt()}x${size.height.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        await tester.tap(find.text('所持アイテム'));
        await tester.pumpAndSettle();
        final item = find.byKey(const ValueKey('inventory-wooden_sword'));
        await tester
            .tap(find.descendant(of: item, matching: find.text('装備する')));
        await tester.pumpAndSettle();
        expect(controller.state!.activeCharacter!.equippedItems['weapon'],
            'wooden_sword');
        expect(controller.state!.inventory['wooden_sword'], 11);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        controller.dispose();
      });
    }
  }
}

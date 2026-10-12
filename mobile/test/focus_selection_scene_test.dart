import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/core/widgets/role_logo.dart';
import 'package:focusquest/features/focus/presentation/focus_screen.dart';
import 'package:focusquest/features/focus/presentation/focus_selection_scene.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });

  testWidgets('focus navigation returns to each shell tab in home order',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[3]!);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    const labels = ['ホーム', 'キャラクター', '冒険', '設定'];
    for (var tab = 0; tab < labels.length; tab++) {
      await tester.tap(find.descendant(
          of: find.byType(QuestNavigation), matching: find.text('ホーム')));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('集中をはじめる'));
      await tester.tap(find.text('集中をはじめる'));
      await tester.pumpAndSettle();
      final navigation = find.descendant(
          of: find.byType(FocusSelectionScene),
          matching: find.byType(QuestNavigation));
      expect(navigation, findsOneWidget);
      final positions = labels
          .map((label) => tester
              .getCenter(
                  find.descendant(of: navigation, matching: find.text(label)))
              .dx)
          .toList();
      expect(positions, orderedEquals([...positions]..sort()));
      await tester.tap(
          find.descendant(of: navigation, matching: find.text(labels[tab])));
      await tester.pumpAndSettle();
      expect(find.byType(FocusSelectionScene), findsNothing);
      expect(
          tester.widget<QuestNavigation>(find.byType(QuestNavigation)).selected,
          tab);
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('presets, validated custom time and portrait mapping',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await tester
        .pumpWidget(MaterialApp(home: FocusScreen(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsNothing);
    expect(tester.widget<RoleLogo>(find.byType(RoleLogo)).role,
        controller.state!.activeCharacter!.characterType);
    expect(find.text(controller.state!.activeCharacter!.name), findsOneWidget);
    await tester.tap(find.text('45分'));
    await tester.pump();
    expect(
        tester
            .widget<FocusSelectionScene>(find.byType(FocusSelectionScene))
            .minutes,
        45);
    await tester.tap(find.text('カスタム（1〜180分）'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '181');
    await tester.pump();
    expect(
        tester
            .widget<FilledButton>(find.widgetWithText(FilledButton, '決定'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), '72');
    await tester.pump();
    await tester.tap(find.text('決定'));
    await tester.pumpAndSettle();
    expect(find.text('カスタム · 72分'), findsOneWidget);
    expect(
        tester
            .widget<FocusSelectionScene>(find.byType(FocusSelectionScene))
            .minutes,
        72);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(1024, 1536)
  ]) {
    testWidgets('illustrated scene fits $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final key = GlobalKey();
      final role = size.width == 1024 ? 'ninja' : 'warrior';
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(
              key: key,
              child: FocusSelectionScene(
                  typeId: role,
                  appearance: 'male',
                  minutes: 30,
                  stage: 1,
                  onMinutes: (_) {},
                  onCustom: () {},
                  onParty: () {},
                  onStart: () {},
                  onNavigate: (_) {},
                  onBack: () {}))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = key.currentContext!;
        for (final asset in [
          'background',
          'stage_banner',
          'parchment_panel',
          'party_panel',
          'custom_strip',
          'blue_button',
          'avatar_frame',
          'time_button',
          'time_selected',
          'navigation_panel',
          'back_button',
          'icon_hourglass',
          'icon_party',
          'icon_compass',
          'icon_bag',
          'icon_book',
          'icon_gear',
          'icon_chevron',
          'icon_divider',
          'icon_back',
          'icon_list',
          'avatars/male/$role',
        ]) {
          await precacheImage(
              AssetImage('assets/images/focus_selection_v001/$asset.png'),
              context);
        }
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('集中を開始'), findsOneWidget);
      if (size.width == 390 || size.width == 1024) {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              '../art/focus_selection_v001/preview_${size.width.toInt()}.png');
          file.parent.createSync(recursive: true);
          file.writeAsBytesSync(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

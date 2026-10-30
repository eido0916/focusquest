import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_display.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/home/home_screen.dart';
import 'package:focusquest/features/character/presentation/character_screen.dart';
import 'package:focusquest/features/adventure/presentation/adventure_screen.dart';
import 'package:focusquest/features/settings/settings_screen.dart';
import 'package:focusquest/features/focus/presentation/focus_timer_scene.dart';
import 'support/memory_repository.dart';

Future<void> loadImages(WidgetTester tester) async {
  await tester.pumpAndSettle();
  for (final element in find.byType(Image).evaluate()) {
    await tester.runAsync(
        () => precacheImage((element.widget as Image).image, element));
  }
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() async {
    await (FontLoader('SunlitSerif')
          ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf')))
        .load();
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });

  for (final size in [
    const Size(280, 653),
    const Size(320, 568),
    const Size(360, 640),
    const Size(430, 932),
    const Size(412, 915),
    const Size(600, 960),
    const Size(768, 1024),
    const Size(800, 1280),
    const Size(1024, 1366),
    const Size(1031, 1792),
    const Size(1280, 720),
    const Size(390, 844)
  ]) {
    testWidgets('four menu pages use portrait units at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = double.parse(
          const String.fromEnvironment('DISPLAY_TEXT_SCALE',
              defaultValue: '1'));
      tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final controller = GameController(MemoryRepository());
      await controller.load();
      await controller.onboard(
          GameCatalog.types.values
              .firstWhere((type) => type.typeId == 'warrior'),
          name: 'a');
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary, child: FocusQuestApp(controller: controller)));
      Rect? fixedNavigationBounds;
      List<Rect>? fixedTabBounds;
      const labels = ['ホーム', 'キャラクター', '冒険', '設定'];
      for (var tab = 0; tab < 4; tab++) {
        if (tab > 0) {
          await tester.tap(find.descendant(
              of: find.byType(QuestNavigation),
              matching: find.text(labels[tab])));
        }
        await loadImages(tester);
        final page = find.byType([
          HomeScreen,
          CharacterScreen,
          AdventureScreen,
          SettingsScreen
        ][tab]);
        final navigation = find.byType(QuestNavigation);
        expect(navigation, findsOneWidget);
        expect(tester.widget<QuestNavigation>(navigation).selected, tab);
        final barBounds = tester.getRect(navigation);
        final tabBounds = List.generate(
            4,
            (index) =>
                tester.getRect(find.byKey(ValueKey('quest-tab-$index'))));
        fixedNavigationBounds ??= barBounds;
        fixedTabBounds ??= tabBounds;
        expect(barBounds, fixedNavigationBounds,
            reason: 'Navigation must stay fixed when changing pages');
        expect(tabBounds, fixedTabBounds,
            reason: 'Tab hit targets must not move or resize');
        expect(barBounds.bottom, closeTo(size.height, .1));
        for (final label in labels) {
          expect(find.descendant(of: navigation, matching: find.text(label)),
              findsOneWidget);
        }
        final media = MediaQuery.of(tester.element(page));
        final availableWidth =
            size.width > size.height ? size.height * 390 / 844 : size.width;
        final displayScale = math.min(availableWidth / 390, size.height / 844);
        expect(media.size.width, closeTo(availableWidth / displayScale, .01));
        expect(media.size.height, greaterThanOrEqualTo(844 - .01));
        expect(media.size.height, greaterThan(media.size.width));
        final canvas =
            tester.getRect(find.byKey(const Key('quest-display-canvas')));
        expect(canvas.height, closeTo(size.height, .1));
        expect(
            canvas.width,
            closeTo(
                size.width > size.height ? size.height * 390 / 844 : size.width,
                .1));
        expect(find.descendant(of: page, matching: find.byType(Scrollable)),
            findsNothing);
        final fitted =
            find.descendant(of: page, matching: find.byType(QuestScreenFit));
        expect(fitted, findsOneWidget);
        final fitBounds = tester.getRect(fitted);
        final fitWidget = tester.widget<QuestScreenFit>(fitted);
        final contentBounds = tester.getRect(find.byWidget(fitWidget.child));
        expect(contentBounds.left, greaterThanOrEqualTo(fitBounds.left - .1));
        expect(contentBounds.top, greaterThanOrEqualTo(fitBounds.top - .1));
        expect(contentBounds.right, lessThanOrEqualTo(fitBounds.right + .1));
        expect(contentBounds.bottom, lessThanOrEqualTo(fitBounds.bottom + .1));
        final beforeDrag = contentBounds;
        await tester.drag(fitted, const Offset(0, -180));
        await tester.pumpAndSettle();
        expect(tester.getRect(find.byWidget(fitWidget.child)), beforeDrag);
        expect(QuestDisplay.orientation.value, Orientation.portrait);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_DISPLAY')) {
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            const root = String.fromEnvironment('DISPLAY_CAPTURE_DIRECTORY');
            final file = File(
                '$root/menu-$tab-${size.width.toInt()}x${size.height.toInt()}.png');
            await file.parent.create(recursive: true);
            await file.writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      controller.dispose();
    });
  }

  testWidgets('timer stays portrait; only battle rotates and restores portrait',
      (tester) async {
    List<String>? requestedOrientations;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        requestedOrientations = List<String>.from(call.arguments as List);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
        navigatorKey: navigator,
        navigatorObservers: [QuestDisplayObserver()],
        builder: (context, child) => QuestAppViewport(child: child!),
        home: const Scaffold(body: Text('home'))));
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => FocusTimerScene(
            characterName: 'a',
            characterType: 'warrior',
            level: 25,
            chapter: 1,
            seconds: 1785,
            progress: 15 / 1800,
            onBattle: () {},
            onCancel: () {},
            onSound: () {},
            onBack: () => navigator.currentState!.pop())));
    await loadImages(tester);
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    expect(find.byKey(const Key('focus-timer-scroll')), findsOneWidget);
    expect(find.byKey(const Key('focus-landscape-layout')), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('29:45'), findsOneWidget);
    expect(MediaQuery.of(tester.element(find.byType(FocusTimerScene))).size,
        const Size(390, 844));
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const QuestOrientationScope(
            child: Scaffold(body: Text('battle')))));
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.landscape);
    expect(requestedOrientations, [
      'DeviceOrientation.landscapeLeft',
      'DeviceOrientation.landscapeRight'
    ]);
    expect(MediaQuery.of(tester.element(find.text('battle'))).size,
        const Size(844, 390));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    expect(requestedOrientations, ['DeviceOrientation.portraitUp']);
    navigator.currentState!.push(MaterialPageRoute<void>(
        builder: (_) => const Scaffold(body: Text('party'))));
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(QuestDisplay.orientation.value, Orientation.portrait);
    expect(requestedOrientations, ['DeviceOrientation.portraitUp']);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

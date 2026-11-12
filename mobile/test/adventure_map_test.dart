import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/playable_stage/domain/stage_progress.dart';
import 'package:focusquest/features/playable_stage/presentation/adventure_map_scene.dart';
import 'package:focusquest/features/playable_stage/presentation/stage_number.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_selection_page.dart';
import 'support/memory_repository.dart';

Future<void> loadImages(WidgetTester tester) async {
  for (var pass = 0; pass < 2; pass++) {
    for (final element in find.byType(Image).evaluate()) {
      await tester.runAsync(
          () => precacheImage((element.widget as Image).image, element));
    }
    await tester.pumpAndSettle();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final family in ['SunlitSerif', 'Roboto', 'Ahem']) {
      await (FontLoader(family)
            ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf')))
          .load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('all 36 frontiers unlock one next stage and preserve every replay', () {
    for (var completed = 0; completed <= 36; completed++) {
      final progress = StageProgress({for (var n = 1; n <= completed; n++) n});
      for (var n = 1; n <= 36; n++) {
        expect(progress.canChallenge(n), n <= completed + 1);
      }
      expect(progress.currentArea, (completed.clamp(0, 35)) ~/ 4);
    }
    final legacy = StageProgress({4, 9, 36, 0, 77});
    expect(legacy.nextStage, 1);
    expect(legacy.canChallenge(4), true);
    expect(legacy.canChallenge(5), false);
    expect(legacy.canChallenge(36), true);
  });

  testWidgets(
      'digit ink is optically centered for every stage, with and without locks',
      (tester) async {
    final boundary = GlobalKey();
    for (var n = 1; n <= 36; n++) {
      for (final locked in [false, true]) {
        await tester.pumpWidget(MaterialApp(
            theme: AppTheme.dark,
            home: Center(
                child: RepaintBoundary(
                    key: boundary,
                    child: SizedBox(
                        width: 100,
                        height: 100,
                        child: DefaultTextStyle(
                            // Material typography must not change measured ink.
                            style: const TextStyle(
                                letterSpacing: 5,
                                height: 2,
                                fontWeight: FontWeight.bold),
                            child: StageNumber(number: n, locked: locked)))))));
        await tester.pump();
        final bounds = await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final data =
              (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                  .buffer
                  .asUint8List();
          var x0 = 100, y0 = 100, x1 = -1, y1 = -1;
          for (var y = 0; y < 100; y++) {
            for (var x = 0; x < 100; x++) {
              final p = (y * 100 + x) * 4;
              if (data[p + 3] > 150 &&
                  data[p] > 230 &&
                  data[p + 1] > 200 &&
                  data[p + 2] > 150) {
                if (x < x0) x0 = x;
                if (x > x1) x1 = x;
                if (y < y0) y0 = y;
                if (y > y1) y1 = y;
              }
            }
          }
          image.dispose();
          return Rect.fromLTRB(x0.toDouble(), y0.toDouble(),
              (x1 + 1).toDouble(), (y1 + 1).toDouble());
        });
        expect(bounds!.width, greaterThan(5));
        expect(bounds.center.dx, closeTo(50, 1.2),
            reason: 'Stage $n horizontal alignment');
        expect(bounds.center.dy, closeTo(locked ? 65 : 50, 1.2),
            reason: 'Stage $n vertical alignment');
      }
    }
    await tester.pumpWidget(const SizedBox());
  });

  for (final entry in [
    (const Size(470, 836), 1.0, 1),
    (const Size(760, 1360), 1.0, 0),
    (const Size(760, 1360), 1.0, 1),
    (const Size(390, 844), 1.0, 0),
    (const Size(320, 568), 1.6, 1),
    (const Size(844, 390), 1.0, 1),
    for (var area = 1; area < 9; area++) (const Size(390, 844), 1.0, area * 4),
    (const Size(390, 844), 1.0, 36),
  ]) {
    final (size, scale, completed) = entry;
    testWidgets('map layout $size scale $scale clears $completed',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repo = MemoryRepository();
      repo.state = repo.state.copyWith(
          clearedPlayableStages: {for (var n = 1; n <= completed; n++) n});
      final controller = GameController(repo);
      await controller.load();
      await controller.onboard(GameCatalog.types[1]!);
      if (size.width == 760 && completed == 0) {
        await controller.startFocus(30);
      }
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key, child: FocusQuestApp(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(find.descendant(
          of: find.byType(QuestNavigation), matching: find.text('冒険')));
      await loadImages(tester);
      expect(find.byKey(const Key('adventure-continuous-background')),
          findsOneWidget);
      expect(
          tester
              .widget<Image>(
                  find.byKey(const Key('adventure-continuous-background')))
              .fit,
          BoxFit.cover,
          reason: 'Landscape proportions must survive every chapter and size');
      final landscapeRect = tester
          .getRect(find.byKey(const Key('adventure-continuous-background')));
      expect(landscapeRect.left, greaterThanOrEqualTo(-.5));
      expect(landscapeRect.right, lessThanOrEqualTo(size.width + .5));
      expect(landscapeRect.top, greaterThanOrEqualTo(-.5));
      expect(landscapeRect.bottom, lessThanOrEqualTo(size.height + .5));
      expect(
          find.descendant(
              of: find.byKey(const Key('stage-selection-list')),
              matching: find.byType(Scrollable)),
          findsNothing);
      final landscapes = find.byType(Image).evaluate().where((e) {
        final provider = (e.widget as Image).image;
        return provider is AssetImage &&
            provider.assetName ==
                adventureMapBackground(completed.clamp(0, 35) ~/ 4);
      });
      expect(landscapes.length, 1,
          reason: 'Landscape must be painted once in scroll coordinates');
      final area = completed.clamp(0, 35) ~/ 4;
      expect(find.byKey(Key('select-stage-${area * 4 + 1}')), findsOneWidget);
      expect(find.byKey(Key('select-stage-${area * 4 + 5}')), findsNothing);
      if (size.width >= 470 && size.height > size.width && scale == 1) {
        final panel =
            tester.getRect(find.byKey(const Key('selected-stage-panel')));
        final button =
            tester.getRect(find.byKey(const Key('map-stage-challenge')));
        expect(button.right, lessThanOrEqualTo(panel.right));
        expect(button.left, greaterThanOrEqualTo(panel.left));
        final thumbnail =
            tester.getRect(find.byKey(const Key('selected-stage-thumbnail')));
        expect(thumbnail.left - panel.left, greaterThanOrEqualTo(12));
        expect(thumbnail.top - panel.top, greaterThanOrEqualTo(12));
        expect(panel.bottom - thumbnail.bottom, greaterThanOrEqualTo(12));
        expect(button.width / button.height, inInclusiveRange(3.8, 7.2));
        final header =
            tester.getRect(find.byKey(const Key('adventure-map-header')));
        final title =
            tester.getRect(find.byKey(const Key('adventure-map-title')));
        expect(title.center.dx, closeTo(header.center.dx, .5));
        final map =
            tester.getRect(find.byKey(const Key('adventure-map-surface')));
        const anchors = [
          Offset(184 / 941, 563 / 750),
          Offset(466 / 941, 480 / 750),
          Offset(767 / 941, 315 / 750),
          Offset(663 / 941, 135 / 750)
        ];
        for (var i = 0; i < 4; i++) {
          final n = area * 4 + i + 1;
          final medal = tester.getRect(find.byKey(Key('stage-medallion-$n')));
          final label = tester.getRect(find.byKey(Key('stage-status-$n')));
          expect(medal.center.dx,
              closeTo(map.left + anchors[i].dx * map.width, .5));
          expect(medal.center.dy,
              closeTo(map.top + anchors[i].dy * map.height, .5));
          expect(label.center.dx, closeTo(medal.center.dx, .5));
        }
      }
      if (const bool.fromEnvironment('CAPTURE_ADVENTURE_MAP')) {
        await tester.runAsync(() async {
          final render =
              key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              'build/adventure-map-review/map-$completed-${size.width.toInt()}-$scale.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    });
  }

  testWidgets(
      'locked nodes never challenge; cleared stages open replay details',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[1]!);
    await controller.recordPlayableClear(1);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: PlayableStageSelectionPage(controller: controller)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-stage-3')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage-details')), findsNothing);
    expect(find.text('Stage 2をクリアすると解放'), findsOneWidget);
    expect(
        tester
            .widget<MapAction>(find.byKey(const Key('map-stage-challenge')))
            .onTap,
        isNull);
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('challenge-stage-1')), findsOneWidget);
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('もう一度挑戦'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const Key('cleared-chapters')));
    await tester.tap(find.byKey(const Key('cleared-chapters')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('history-area-0')), findsOneWidget);
    expect(find.byKey(const Key('history-area-1')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'completed chapter reveals next area and older chapters remain reachable',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[1]!);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: PlayableStageSelectionPage(controller: controller)));
    for (var n = 1; n <= 4; n++) {
      await controller.recordPlayableClear(n);
    }
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('next-chapter')));
    await tester.tap(find.byKey(const Key('next-chapter')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('select-stage-5')));
    expect(find.byKey(const Key('select-stage-5')), findsOneWidget);
    expect(find.byKey(const Key('select-stage-9')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('cleared-chapters')));
    await tester.tap(find.byKey(const Key('cleared-chapters')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('history-area-0')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('select-stage-1')), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(430, 932),
    const Size(768, 1024)
  ]) {
    testWidgets('ghost ship keeps proportions with focus notice at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                  body: SafeArea(
                      child: AdventureMapScene(
                    progress: StageProgress({1, 2, 3, 4}),
                    area: 1,
                    selected: 5,
                    blocked: true,
                    onSelect: (_) {},
                    onChallenge: () {},
                    onHistory: () {},
                    onNext: () {},
                    notices: const [
                      MapPlate(
                          asset: 'details',
                          child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('いまは集中の時間。終了後に冒険へ出発できます。')))
                    ],
                  )),
                  bottomNavigationBar:
                      QuestNavigation(selected: 2, onSelect: (_) {})))));
      await loadImages(tester);
      expect(tester.takeException(), isNull);
      final background =
          find.byKey(const Key('adventure-continuous-background'));
      expect(tester.widget<Image>(background).fit, BoxFit.cover);
      expect(find.byType(Scrollable), findsNothing);
      expect(find.byKey(const Key('select-stage-5')).hitTestable(),
          findsOneWidget);
      final rect = tester.getRect(background);
      expect(rect.left, closeTo(0, .1));
      expect(rect.width, closeTo(size.width, .1));
      expect(rect.top, greaterThanOrEqualTo(0));
      expect(rect.bottom, lessThanOrEqualTo(size.height));
      if (const bool.fromEnvironment('CAPTURE_ADVENTURE_MAP')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final data = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              'build/adventure-map-review/ghost-ship-notice-${size.width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(data!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}

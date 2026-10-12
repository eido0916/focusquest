import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/presentation/growth_celebration.dart';
import 'package:focusquest/features/focus/domain/focus_adventure.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  test(
      'focus area needs four clears and persists through the session lifecycle',
      () async {
    final controller = GameController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    expect(controller.unlockedFocusAreas, isEmpty);
    expect(() => controller.selectFocusArea(0), throwsStateError);
    for (final stage in [1, 2, 3]) {
      await controller.recordPlayableClear(stage);
    }
    expect(controller.unlockedFocusAreas, isEmpty);
    await controller.recordPlayableClear(4);
    expect(controller.unlockedFocusAreas, [0]);
    controller.selectFocusArea(0);
    await controller.startFocus(30);
    final session = controller.activeFocus!;
    expect(session.focusAreaIndex, 0);
    expect(FocusSession.fromJson(session.toJson()).focusAreaIndex, 0);
    expect(session.finish(FocusStatus.succeeded).focusAreaIndex, 0);
    expect(FocusAdventure.area(7200, areaIndex: session.focusAreaIndex), '草原');
    await controller.finishFocus(cancel: true);
    expect(FocusAdventure.unlockedAreas({5, 6, 7, 8}), [1]);
  });
  test('recommendations do not alter fixed enemy difficulty', () {
    final stage = PlayableStageCatalog.stages.first;
    final changed = PlayableStageDefinition(stage.number, stage.area,
        stage.backgroundPath, stage.groundLine, stage.opponents,
        recommendedLevel: 99, difficultyLevel: stage.difficultyLevel);
    expect(changed.wave(0).map((e) => e.hp), stage.wave(0).map((e) => e.hp));
    expect(changed.wave(0).map((e) => e.damage),
        stage.wave(0).map((e) => e.damage));
  });
  testWidgets(
      'growth compares saved stats and celebrates every crossed title milestone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    final hero = controller.state!.activeCharacter!;
    final boundary = GlobalKey();
    Future<void> capture(String name) async {
      if (!const bool.fromEnvironment('CAPTURE_GROWTH')) return;
      for (final element in find.byType(Image).evaluate()) {
        await tester.runAsync(
            () => precacheImage((element.widget as Image).image, element));
      }
      await tester.pump(const Duration(milliseconds: 400));
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/experience-review/$name.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: Builder(
                builder: (context) => TextButton(
                    onPressed: () => showGrowthCelebration(context,
                        hero.copyWith(level: 9), hero.copyWith(level: 21)),
                    child: const Text('成長'))))));
    await tester.tap(find.text('成長'));
    await tester.pumpAndSettle();
    expect(find.text('Lv. 9 → Lv. 21'), findsOneWidget);
    await capture('level-up');
    final increased = find.textContaining('(+144)');
    expect(increased, findsOneWidget);
    expect(
        tester.widget<Text>(increased).style!.color, const Color(0xff80ed9c));
    await tester.tap(find.text('成長した力で冒険へ'));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('新たな称号を獲得！'), findsOneWidget);
    expect(find.text('見習い剣士'), findsOneWidget);
    await capture('title-unlock');
    await tester.tap(find.text('冒険を続ける').last);
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('一人前の剣士'), findsOneWidget);
    await tester.tap(find.text('冒険を続ける').last);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}

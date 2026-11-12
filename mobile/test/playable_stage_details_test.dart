import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_details_dialog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_selection_page.dart';
import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
  });
  test('encounters survive saving, copyWith, legacy loading and failed writes',
      () async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    final legacy = controller.state!.toJson()..remove('encounteredEnemyIds');
    expect(PlayerState.fromJson(legacy).encounteredEnemyIds, isEmpty);
    await controller.recordPlayableEncounters({'slime'});
    await controller.recordPlayableEncounters({'slime', 'goblin'});
    final saved = PlayerState.fromJson(repo.state.toJson());
    expect(saved.copyWith(coins: 1).encounteredEnemyIds, {'slime', 'goblin'});
    repo.fail = true;
    await expectLater(controller.recordPlayableEncounters({'boss_goblin_king'}),
        throwsStateError);
    expect(controller.state!.encounteredEnemyIds, {'slime', 'goblin'});
    controller.dispose();
  });

  testWidgets('stage cards open details before starting a challenge',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark, home: const PlayableStageSelectionPage()));
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    final card = find.byKey(const Key('select-stage-1'));
    expect(find.descendant(of: card, matching: find.byType(Text)),
        findsNWidgets(2));
    expect(find.descendant(of: card, matching: find.text('1')), findsOneWidget);
    await tester.tap(card);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('stage-details')), findsOneWidget);
    expect(find.byKey(const Key('challenge-stage-1')), findsOneWidget);
    expect(find.text('推奨レベル Lv.5'), findsOneWidget);
    expect(find.byKey(const Key('unknown-enemy-mark')), findsWidgets);
    await tester.tap(find.byTooltip('閉じる'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('stage-details')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 568),
    const Size(643, 840),
    const Size(844, 390)
  ]) {
    testWidgets(
        'boss details hide unknown identities and include escorts at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stage = PlayableStageCatalog.stages[3];
      final firstId = stage.opponents.first.id;
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: Scaffold(
                  body: PlayableStageDetailsDialog(
                      stage: stage, encounteredEnemyIds: {firstId})))));
      final enemies = {
        for (var phase = 0; phase < stage.opponents.length; phase++)
          for (final enemy in stage.wave(phase)) enemy.id: enemy,
      };
      await tester.runAsync(() async {
        for (final enemy in enemies.values) {
          await precacheImage(
              AssetImage(
                  'assets/images/playable_stage/${enemy.id}_locomotion_000.png'),
              tester.element(find.byType(Scaffold)));
        }
      });
      await tester.pump();
      expect(find.byKey(const Key('unknown-enemy-mark')),
          findsNWidgets(enemies.length - 1));
      expect(find.text(stage.opponents.last.name), findsNothing);
      for (final enemy in enemies.values) {
        final tile = find.byKey(Key('stage-enemy-${enemy.id}'));
        expect(tile, findsOneWidget);
        final image = tester.widget<Image>(
            find.descendant(of: tile, matching: find.byType(Image)));
        expect(image.color, enemy.id == firstId ? isNull : Colors.black);
        expect(image.filterQuality, FilterQuality.none);
      }
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_STAGE')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          final file = File(
              'build/stage-ui-review/details-${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(png.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.ensureVisible(find.byKey(const Key('challenge-stage-4')));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  }
}

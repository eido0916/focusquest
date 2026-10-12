import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_selection_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlayableStageAssets assets;
  setUpAll(() async {
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    final data = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(data))).load();
    }
    assets = await PlayableStageAssets.load();
  });
  tearDownAll(() => assets.dispose());
  test('every area loads its background and only its selected enemies',
      () async {
    for (final number in [1, 4, 8, 12, 16, 20, 24, 28, 32, 36]) {
      final stage = PlayableStageCatalog.stages[number - 1];
      final loaded = await PlayableStageAssets.load(stage: stage);
      try {
        expect(loaded.background.width, 1672);
        expect(loaded.background.height, 941);
        for (final enemy in stage.opponents) {
          expect(loaded.motions.containsKey('${enemy.id}_locomotion'), true);
          expect(loaded.motions.containsKey('${enemy.id}_attack'), true);
          expect(loaded.motions.containsKey('${enemy.id}_defeat'), true);
        }
        for (final boss in PlayableStageCatalog.bossIds) {
          expect(loaded.motions.containsKey('${boss}_attack'),
              stage.opponents.any((enemy) => enemy.id == boss));
        }
      } finally {
        loaded.dispose();
      }
    }
  });
  test('36 stages have nine backgrounds and exactly nine final-phase bosses',
      () {
    final stages = PlayableStageCatalog.stages;
    expect(
        stages.map((stage) => stage.number), List.generate(36, (i) => i + 1));
    expect(stages.map((stage) => stage.area), [
      ...List.filled(4, '草原'),
      ...List.filled(4, '幽霊船'),
      ...List.filled(4, '火山'),
      ...List.filled(4, '毒茸の湿地'),
      ...List.filled(4, '砂漠の迷宮'),
      ...List.filled(4, '氷晶洞窟'),
      ...List.filled(4, '月影の墓地'),
      ...List.filled(4, '星界の祭壇'),
      ...List.filled(4, '魔王城'),
    ]);
    expect(stages.where((stage) => stage.hasBoss).map((stage) => stage.number),
        [4, 8, 12, 16, 20, 24, 28, 32, 36]);
    expect(
        stages
            .where((stage) => stage.hasBoss)
            .map((stage) => stage.opponents.last.id),
        [
          'boss_goblin_king',
          'boss_dullahan',
          'boss_fire_dragon',
          'boss_cerberus',
          'boss_minotaur',
          'boss_stone_golem',
          'boss_lich',
          'boss_cyclops',
          'boss_demon_lord',
        ]);
    for (final stage in stages) {
      expect(stage.opponents.length, 3);
      expect(stage.opponents.take(2).every((enemy) => !enemy.isBoss), true);
      final battle = PlayableStageBattle(stage: stage, roll: () => .5)..start();
      final phases = <int>{};
      for (var tick = 0; tick < 120 * 120 && battle.active; tick++) {
        if (battle.mode == StageMode.travel) phases.add(battle.phase);
        if (battle.canSkill) {
          battle.skill();
        } else if (battle.canAttack) {
          battle.attack();
        }
        battle.update(1 / 120);
      }
      expect(battle.mode, StageMode.won, reason: stage.title);
      expect(phases, {0, 1, 2});
      expect(battle.isBoss, stage.number % 4 == 0);
      battle.dispose();
    }
  });

  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390)
  ]) {
    testWidgets('selection exposes all 36 stages without overflow at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final preview = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: preview,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.dark,
              home: const PlayableStageSelectionPage())));
      await tester.pump();
      if (const bool.fromEnvironment('CAPTURE_STAGE')) {
        await tester.runAsync(() async {
          for (final path in PlayableStageCatalog.backgrounds) {
            await precacheImage(
                AssetImage(path), tester.element(find.byType(Scaffold)));
          }
        });
        await tester.pump();
        await tester.runAsync(() async {
          final render = preview.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              '../output/playable-stage/selection-${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      for (final number in [
        1,
        4,
        5,
        8,
        9,
        12,
        13,
        16,
        17,
        20,
        21,
        24,
        25,
        28,
        29,
        32,
        33,
        36
      ]) {
        await tester.scrollUntilVisible(
            find.byKey(Key('select-stage-$number')), 180,
            scrollable: find.byType(Scrollable).first);
        expect(find.byKey(Key('select-stage-$number')), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets(
      'clearing a boss stage returns automatically and marks the selected stage',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: PlayableStageSelectionPage(
            assets: assets,
            audioOutput: SilentStageAudioOutput(),
            battleFactory: (stage) =>
                PlayableStageBattle(stage: stage, roll: () => .5))));
    await tester.scrollUntilVisible(
        find.byKey(const Key('select-stage-4')), 150,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('select-stage-4')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final page =
        tester.widget<PlayableStagePage>(find.byType(PlayableStagePage));
    final battle = page.battle!;
    expect(battle.stage.number, 4);
    await tester.tap(find.byKey(const Key('stage-start')));
    await tester.pump();
    expect(battle.mode, StageMode.travel);
    for (var tick = 0; tick < 120 * 120 && battle.active; tick++) {
      if (battle.canSkill) {
        battle.skill();
      } else if (battle.canAttack) {
        battle.attack();
      }
      battle.update(1 / 120);
    }
    expect(battle.mode, StageMode.won);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(find.byType(PlayableStagePage), findsNothing);
    expect(find.text('ステージ選択'), findsOneWidget);
    expect(
        find.descendant(
            of: find.byKey(const Key('select-stage-4')),
            matching: find.text('✓ CLEAR')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
    // A new stage starts with its own phase, HP and charge.
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final next = tester
        .widget<PlayableStagePage>(find.byType(PlayableStagePage))
        .battle!;
    expect(next.stage.number, 1);
    expect(next.phase, 0);
    expect(next.hp, PlayableStageBattle.maxHp);
    expect(next.charge, 0);
    // Close the route before tearing down; selection owns the battle notifier.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

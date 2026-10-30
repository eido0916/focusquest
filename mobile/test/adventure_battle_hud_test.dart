import 'support/trained_stage_hero.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/core/widgets/game_ui.dart';
import 'package:focusquest/features/playable_stage/presentation/adventure_stage_layout.dart';
import 'package:focusquest/features/playable_stage/presentation/adventure_battle_hud.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    for (final family in ['Ahem', 'Roboto', 'SunlitSerif']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
  });
  test('all terrain ground baselines leave a clear control band', () {
    for (final size in [
      const Size(844, 390),
      const Size(1920, 1080),
      const Size(390, 844)
    ]) {
      final layout = AdventureStageLayout(size);
      for (final stage in PlayableStageCatalog.stages) {
        final world = PlayableStagePainter.worldSize(
            size, layout.bottomInset(stage.groundLine));
        expect(world.height * stage.groundLine, closeTo(layout.groundY, .001));
        expect(
            layout.groundY, lessThan(size.height - 14 - layout.controlHeight));
      }
    }
  });
  for (final size in [
    const Size(740, 360),
    const Size(844, 390),
    const Size(320, 568)
  ]) {
    testWidgets('readable HUD fits $size with buttons below actors',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final battle =
          PlayableStageBattle(character: PlayableCharacters.all.first);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
              body: AdventureBattleHud(
                  battle: battle,
                  utilities: const SizedBox(width: 150, height: 44)))));
      await tester.pump();
      final buttons =
          tester.getRect(find.byKey(const Key('stage-floating-controls')));
      expect(buttons.top, greaterThan(AdventureStageLayout(size).groundY));
      expect(buttons.right, lessThanOrEqualTo(size.width));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      battle.dispose();
    });
  }
  for (final size in [const Size(844, 390), const Size(390, 844)]) {
    testWidgets('boss stage scene keeps enemies above controls at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stage = PlayableStageCatalog.stages[3];
      final assets = (await tester
          .runAsync(() => PlayableStageAssets.load(stage: stage)))!;
      final battle = PlayableStageBattle(
          stage: stage, character: trainedStageHero(), roll: () => .5)
        ..start();
      while (battle.phase < 2 && battle.active) {
        if (battle.canSkill) {
          battle.skill();
        } else if (battle.canAttack) {
          battle.attack();
        }
        battle.update(1 / 120);
      }
      for (var i = 0; i < 360; i++) {
        battle.update(1 / 120);
      }
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              theme: AppTheme.dark,
              debugShowCheckedModeBanner: false,
              home: PlayableStagePage(
                  battle: battle,
                  assets: assets,
                  audioOutput: SilentStageAudioOutput()))));
      await tester.runAsync(() async {
        for (final widget in tester.widgetList<Image>(find.byType(Image))) {
          await precacheImage(
              widget.image, tester.element(find.byType(Scaffold)));
        }
      });
      await tester.pump();
      final controls =
          tester.getRect(find.byKey(const Key('stage-floating-controls')));
      for (final enemy in battle.enemies) {
        expect(
            tester.getRect(find.byKey(Key('enemy-hp-${enemy.index}'))).bottom,
            lessThan(controls.top));
      }
      expect(tester.takeException(), isNull);
      if (const bool.fromEnvironment('CAPTURE_STAGE')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file =
              File('build/adventure-layout/boss-${size.width.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
      battle.dispose();
      assets.dispose();
    });
  }
  testWidgets('reference layout keeps attacks and skills manual',
      (tester) async {
    tester.view.physicalSize = const Size(1672, 941);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['Roboto', 'SunlitSerif']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    final hero =
        PlayableCharacters.all.firstWhere((h) => h.role == '忍者' && !h.female);
    final assets = (await tester.runAsync(() => PlayableStageAssets.load(
        stage: PlayableStageCatalog.stages.first, character: hero)))!;
    final battle = PlayableStageBattle(character: hero, roll: () => .5);
    final boundary = GlobalKey();
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(SizedBox).first);
      for (final panel in [
        'identity_panel',
        'header_banner',
        'equipment_row'
      ]) {
        await precacheImage(AssetImage('$gameUiAssets$panel.png'), context);
      }
      for (final name in [
        'status_panel',
        'stage_banner',
        'phase_panel',
        'attack_button',
        'skill_button',
        'utility_button',
        'caption_frame',
        'portrait_frame',
        'hp_frame'
      ]) {
        await precacheImage(
            AssetImage('assets/images/adventure_ui_v001/$name.png'), context);
      }
      await precacheImage(
          const AssetImage('assets/images/lobby/portraits/ninja.png'), context);
    });
    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark,
            home: PlayableStagePage(
                battle: battle,
                assets: assets,
                audioOutput: SilentStageAudioOutput()))));
    await tester.pump();
    await tester.tap(find.byKey(const Key('stage-start')));
    await tester.pump();
    for (var i = 0; i < 80; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(find.text('忍者'), findsOneWidget);
    expect(find.text('Lv. 1'), findsOneWidget);
    expect(find.text('HP  120 / 120'), findsOneWidget);
    await tester.runAsync(() async {
      for (final widget in tester.widgetList<Image>(find.byType(Image))) {
        await precacheImage(
            widget.image, tester.element(find.byType(Scaffold)));
      }
    });
    await tester.pump();
    if (const bool.fromEnvironment('CAPTURE_STAGE')) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../art/adventure_ui_v001/adventure_preview.png');
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(find.byKey(const Key('stage-auto')), findsNothing);
    expect(find.textContaining('オート'), findsNothing);
    advance(battle, 3);
    for (final enemy in battle.enemies) {
      enemy.wait = 100;
    }
    battle.charge = PlayableStageBattle.chargeNeeded;
    await tester.pump();
    for (var i = 0; i < 800; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(battle.attempts, 0);
    expect(battle.skills, 0);
    expect(battle.charge, PlayableStageBattle.chargeNeeded);
    await tester.tap(find.byKey(const Key('stage-skill')));
    await tester.pump();
    expect(battle.skills, 1);
    expect(battle.charge, 0);
    advance(battle, battle.skillDuration + .5);
    await tester.pump();
    await tester.tap(find.byKey(const Key('stage-attack')));
    await tester.pump();
    expect(battle.attempts, 1);
    battle.pause();
    final attempts = battle.attempts, clock = battle.clock;
    await tester.pump(const Duration(seconds: 2));
    expect(battle.attempts, attempts);
    expect(battle.clock, clock);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    battle.dispose();
    assets.dispose();
  });
}

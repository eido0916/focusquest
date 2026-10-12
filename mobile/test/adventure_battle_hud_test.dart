import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';

void main() {
  testWidgets('reference layout and auto combat use live battle values',
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
      for (final name in [
        'status_panel',
        'stage_banner',
        'phase_panel',
        'attack_button',
        'skill_button',
        'auto_button',
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
    await tester.tap(find.byKey(const Key('stage-auto')));
    for (var i = 0; i < 800; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(battle.attempts, greaterThan(0));
    expect(battle.skills, greaterThan(0));
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

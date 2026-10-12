import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlayableStageAssets assets;
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    assets = await PlayableStageAssets.load();
  });
  tearDownAll(() => assets.dispose());

  testWidgets('battle requests landscape and restores portrait on return',
      (tester) async {
    final orientations = <List<dynamic>>[];
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemChrome.setPreferredOrientations') {
        orientations.add(call.arguments as List<dynamic>);
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    final battle = PlayableStageBattle();
    addTearDown(battle.dispose);
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => PlayableStagePage(
                                battle: battle,
                                assets: assets,
                                audioOutput: SilentStageAudioOutput()))),
                    child: const Text('select stage'))))));
    await tester.tap(find.text('select stage'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(orientations, [
      ['DeviceOrientation.landscapeLeft', 'DeviceOrientation.landscapeRight']
    ]);
    await tester.pageBack();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('select stage'), findsOneWidget);
    expect(orientations.last, ['DeviceOrientation.portraitUp']);
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390),
    const Size(1672, 941)
  ]) {
    testWidgets('native stage controls, pause and rendering fit $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final battle = PlayableStageBattle(roll: () => .5);
      addTearDown(battle.dispose);
      final boundary = GlobalKey();
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
      expect(find.text('冒険をはじめる'), findsOneWidget);
      expect(find.text(battle.stage.title), findsNothing);
      await tester.tap(find.byKey(const Key('stage-start')));
      await tester.pump();
      expect(battle.mode, StageMode.travel);
      advance(battle, 3);
      await tester.pump();
      final canvasRect = tester.getRect(find.byKey(const Key('stage-canvas')));
      final controlsRect =
          tester.getRect(find.byKey(const Key('stage-floating-controls')));
      expect(canvasRect.contains(controlsRect.topLeft), true);
      expect(canvasRect.contains(controlsRect.bottomRight), true);
      expect(find.text('次のフェーズへ走行中'), findsNothing);
      expect(find.byKey(const Key('enemy-health-strip')), findsNothing);
      final initialEnemyHp = battle.enemies.map((enemy) => enemy.hp).toList();
      for (final enemy in battle.enemies) {
        expect(find.byKey(Key('enemy-hp-${enemy.index}')), findsOneWidget);
        expect(tester.getSize(find.byKey(Key('enemy-hp-${enemy.index}'))).width,
            lessThanOrEqualTo(64));
        expect(
            canvasRect.contains(tester
                .getRect(find.byKey(Key('enemy-hp-${enemy.index}')))
                .center),
            true);
      }
      expect(tester.getSize(find.byKey(const Key('player-hp'))),
          const Size(96, 3));
      final heroHpBeforeAttack =
          tester.getRect(find.byKey(const Key('player-hp'))).center.dx;
      await tester.tap(find.byKey(const Key('stage-attack')));
      await tester.pump();
      advance(battle, .2);
      await tester.pump();
      expect(tester.getRect(find.byKey(const Key('player-hp'))).center.dx,
          greaterThan(heroHpBeforeAttack));
      advance(battle, .9);
      expect(battle.hits, 1);
      await tester.pump();
      expect(battle.enemies.first.hp, lessThan(initialEnemyHp.first));
      for (final enemy in battle.enemies) {
        expect(
            tester
                .widget<LinearProgressIndicator>(
                    find.byKey(Key('enemy-hp-${enemy.index}')))
                .value,
            enemy.hp / enemy.definition.hp);
        if (enemy.index > 0) {
          expect(enemy.hp, initialEnemyHp[enemy.index]);
        }
      }
      for (var i = 0; i < 2; i++) {
        battle.attack();
        advance(battle, 1.1);
      }
      await tester.pump();
      expect(
          tester
              .widget<FilledButton>(find.byKey(const Key('stage-skill')))
              .onPressed,
          isNotNull);
      await tester.tap(find.byKey(const Key('stage-skill')));
      await tester.pump();
      expect(battle.charge, 0);
      expect(battle.skills, 1);
      advance(battle, 2.2);
      await tester.pump();
      await tester.tap(find.byKey(const Key('stage-pause')));
      await tester.pump();
      expect(battle.paused, true);
      final time = battle.clock;
      await tester.pump(const Duration(seconds: 20));
      expect(battle.clock, time);
      await tester.tap(find.text('冒険を再開'));
      await tester.pump();
      expect(battle.paused, false);
      advance(battle, 3);
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final key in ['stage-attack', 'stage-skill']) {
        final rect = tester.getRect(find.byKey(Key(key)));
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(size.width));
        expect(rect.bottom, lessThanOrEqualTo(size.height));
      }
      if (const bool.fromEnvironment('CAPTURE_STAGE')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
              '../output/playable-stage/flutter-${size.width.toInt()}x${size.height.toInt()}.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('backgrounding pauses the native battle', (tester) async {
    final battle = PlayableStageBattle(roll: () => .5);
    addTearDown(battle.dispose);
    await tester.pumpWidget(MaterialApp(
        home: PlayableStagePage(
            battle: battle,
            assets: assets,
            audioOutput: SilentStageAudioOutput())));
    battle.start();
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    expect(battle.paused, true);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(battle.paused, true);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

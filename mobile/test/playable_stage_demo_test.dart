import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/playable_stage/demo/demo_character_selection_page.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_selection_page.dart';

Future<void> capture(
    WidgetTester tester, GlobalKey key, String filename) async {
  if (!const bool.fromEnvironment('CAPTURE_STAGE')) return;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('../output/playable-stage/$filename')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PlayableStageAssets bossAssets, ninjaAssets;
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    final icons = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
    await (FontLoader('MaterialIcons')..addFont(Future.value(icons))).load();
    bossAssets =
        await PlayableStageAssets.load(stage: PlayableStageCatalog.stages[3]);
    ninjaAssets = await PlayableStageAssets.load(
        stage: PlayableStageCatalog.stages.first,
        character: PlayableCharacters.all[4]);
  });
  tearDownAll(() {
    bossAssets.dispose();
    ninjaAssets.dispose();
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390)
  ]) {
    testWidgets('demo hero stats and selection fit $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      PlayableCharacter? confirmed;
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              theme: AppTheme.dark,
              home: DemoCharacterSelectionPage(
                  onSelected: (hero) => confirmed = hero))));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        for (final hero in PlayableCharacters.all) {
          await precacheImage(
              AssetImage(
                  'assets/images/playable_stage/${hero.id}_attack_000.png'),
              tester.element(find.byType(Scaffold)));
        }
      });
      await tester.pump();
      expect(find.byKey(const Key('character-stat-体力')), findsOneWidget);
      await tester.scrollUntilVisible(
          find.byKey(const Key('character-character_04')), 80,
          scrollable: find.byType(Scrollable).first);
      await tester.tap(find.byKey(const Key('character-character_04')));
      await tester.pump();
      expect(find.text('250'), findsOneWidget);
      expect(find.text('通常攻撃 1.67秒 / 回'), findsOneWidget);
      await tester.tap(find.byKey(const Key('character-gender-female')));
      await tester.pumpAndSettle();
      expect(find.text('重騎士 · 女性'), findsOneWidget);
      await capture(tester, boundary,
          'characters-${size.width.toInt()}x${size.height.toInt()}.png');
      await tester.tap(find.byKey(const Key('character-confirm')));
      await tester.pump();
      expect(confirmed?.id, 'character_04_female');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
        'boss and escorts fit with round red and blue controls at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final stage = PlayableStageCatalog.stages[3];
      final assets = bossAssets;
      final battle = PlayableStageBattle(stage: stage, roll: () => .5)..start();
      while (battle.phase < 2) {
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
              home: PlayableStagePage(
                  battle: battle,
                  assets: assets,
                  audioOutput: SilentStageAudioOutput()))));
      await tester.pump();
      final red =
          tester.widget<FilledButton>(find.byKey(const Key('stage-attack')));
      final blue =
          tester.widget<FilledButton>(find.byKey(const Key('stage-skill')));
      expect(red.style!.shape!.resolve({}), isA<CircleBorder>());
      expect(blue.style!.shape!.resolve({}), isA<CircleBorder>());
      expect(red.style!.backgroundColor!.resolve({}), const Color(0xffe43c46));
      expect(blue.style!.backgroundColor!.resolve({}), const Color(0xff247ce8));
      expect(tester.getSize(find.byKey(const Key('stage-attack'))),
          const Size(84, 84));
      expect(tester.takeException(), isNull);
      await capture(tester, boundary,
          'boss-party-${size.width.toInt()}x${size.height.toInt()}.png');
      await tester.pumpWidget(const SizedBox.shrink());
      battle.dispose();
    });
  }
  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    testWidgets(
        'player and monster impacts make contact with normal enemies and bosses at $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final boss in [false, true]) {
        for (final playerAttack in [true, false]) {
          final battle = PlayableStageBattle(
              stage: PlayableStageCatalog.stages[3], roll: () => .5);
          final boundary = GlobalKey();
          await tester.pumpWidget(RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  theme: AppTheme.dark,
                  home: PlayableStagePage(
                      battle: battle,
                      assets: bossAssets,
                      audioOutput: SilentStageAudioOutput()))));
          await tester.pump();
          battle.phase = boss ? 2 : 0;
          battle.start();
          for (var i = 0; i < 360; i++) {
            battle.update(1 / 120);
          }
          if (boss) {
            for (final enemy in battle.enemies.take(2)) {
              enemy.hp = 0;
              enemy.deathTime = 99;
            }
          }
          for (final enemy in battle.enemies) {
            enemy.wait = 100;
          }
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));
          final opponent = battle.target;
          if (playerAttack) {
            battle.attack();
            final hit = battle.attackDuration * battle.attackHitFraction;
            for (var i = 0; i < (hit * 120).ceil() + 1; i++) {
              battle.update(1 / 120);
            }
          } else {
            opponent.wait = 0;
            for (var i = 0; i < opponent.hitTick * 5 + 2; i++) {
              battle.update(1 / 120);
            }
          }
          await tester.pump();
          expect(opponent.x - battle.heroX - battle.heroPoseOffset,
              closeTo(battle.contactGap(opponent), 1));
          expect(tester.takeException(), isNull);
          await capture(tester, boundary,
              'contact-${playerAttack ? 'player' : 'monster'}-${boss ? 'boss' : 'normal'}-${size.width.toInt()}x${size.height.toInt()}.png');
          await tester.pumpWidget(const SizedBox.shrink());
          battle.dispose();
        }
      }
    });
  }
  testWidgets(
      'portraits stay on an integer pixel grid at 150 percent display scale',
      (tester) async {
    tester.view.physicalSize = const Size(480, 852);
    tester.view.devicePixelRatio = 1.5;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: DemoCharacterSelectionPage(onSelected: (_) {})));
    await tester.pumpAndSettle();
    final portrait = tester.getSize(find.byType(Image).first);
    expect(portrait.width * 1.5, closeTo(64, .001));
    expect(portrait.height * 1.5, closeTo(64, .001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('production selection omits demo picker and accepts chosen hero',
      (tester) async {
    final hero = PlayableCharacters.all[4];
    await tester.pumpWidget(MaterialApp(
        home: PlayableStageSelectionPage(
            character: hero,
            assets: ninjaAssets,
            audioOutput: SilentStageAudioOutput())));
    expect(find.byKey(const Key('demo-change-character')), findsNothing);
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final battle = tester
        .widget<PlayableStagePage>(find.byType(PlayableStagePage))
        .battle!;
    expect(battle.character, same(hero));
    expect(battle.hp, hero.health);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

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

void advance(PlayableStageBattle b, double seconds) {
  for (var i = 0; i < (seconds * 240).ceil(); i++) {
    b.update(1 / 240);
  }
}

PlayableStageBattle ready(
    PlayableCharacter hero, PlayableStageDefinition stage) {
  final b = PlayableStageBattle(character: hero, stage: stage, roll: () => .5)
    ..start();
  advance(b, 3);
  for (final e in b.enemies) {
    e.wait = 100;
    e.hp = 1000;
  }
  return b;
}

Future<void> capture(GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_STAGE')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = await boundary.toImage();
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final file = File('../output/playable-stage/v016/$name.png');
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes!.buffer.asUint8List());
  image.dispose();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final heroes = PlayableCharacters.all
      .where((h) => ['ドラゴンナイト', 'バーサーカー'].contains(h.role))
      .toList();
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  test('32 identities and stage materials are explicit', () {
    expect(PlayableCharacters.all.length, 32);
    expect(heroes.length, 4);
    expect(PlayableStageCatalog.stages.map((s) => s.floorMaterial).toSet(),
        {'grass', 'wood', 'basalt', 'mud', 'sandstone', 'ice', 'stone'});
  });
  testWidgets('new male hero changes to same female role and is selectable',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    PlayableCharacter? selected;
    final key = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: key,
        child: MaterialApp(
            theme: AppTheme.dark,
            home: DemoCharacterSelectionPage(
                initial: heroes.first, onSelected: (h) => selected = h))));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('character-gender-female')));
    await tester.pumpAndSettle();
    expect(find.text('ドラゴンナイト · 女性'), findsOneWidget);
    await tester.scrollUntilVisible(
        find.byKey(const Key('character-character_16_female')), 100,
        scrollable: find.byType(Scrollable).first);
    await tester.tap(find.byKey(const Key('character-character_16_female')));
    await tester.pumpAndSettle();
    await tester.runAsync(() => capture(key, 'selection-female'));
    await tester.tap(find.byKey(const Key('character-confirm')));
    expect(selected?.id, 'character_16_female');
    expect(tester.takeException(), isNull);
  });
  for (final hero in heroes) {
    test('all new PNG motions and action events load for ${hero.id}', () async {
      final assets = await PlayableStageAssets.load(
          character: hero, stage: PlayableStageCatalog.stages.first);
      try {
        expect(assets.motions['hero_run']!.images.length, 8);
        expect(assets.motions['hero_attack']!.images.length, 8);
        expect(assets.motions['hero_skill']!.images.length, 12);
        expect(assets.motions['hero_attack']!.eventTicks(hero.attackEvent),
            isNotEmpty);
        expect(assets.motions['hero_skill']!.eventTicks(hero.skillEvent),
            isNotEmpty);
        for (final motion in assets.motions.values) {
          expect(motion.metadata['interpolation'], 'none');
          expect(motion.metadata['part_transforms'], false);
        }
      } finally {
        assets.dispose();
      }
    });
  }
  test('dragon flurry deals three impacts with the total skill power', () {
    final h = heroes.firstWhere((h) => h.role == 'ドラゴンナイト');
    final b = ready(h, PlayableStageCatalog.stages.first);
    addTearDown(b.dispose);
    b.skillReleaseFractions = [20 / 36, 22 / 36, 24 / 36];
    b.charge = 3;
    b.skill();
    var impacts = 0;
    final sub = b.soundEvents.listen((e) {
      if (e == BattleSound.hit) impacts++;
    });
    addTearDown(sub.cancel);
    advance(b, b.skillDuration + .01);
    expect(impacts, 3);
    expect(b.target.hp, 1000 - h.skillPower);
  });
  test('floor throw waits for landing and follows a moving target', () {
    for (final moves in [false, true]) {
      final h = heroes.firstWhere((h) => h.role == 'バーサーカー');
      final b = ready(h, PlayableStageCatalog.stages.first);
      addTearDown(b.dispose);
      b.charge = 3;
      b.skill();
      while (b.projectiles.isEmpty) {
        b.update(1 / 240);
      }
      final shot = b.projectiles.single;
      expect(shot.kind, ProjectileKind.floor);
      expect(b.target.hp, 1000);
      expect(b.heroX, PlayableStageBattle.heroHomeX);
      final end = shot.endX;
      if (moves) {
        b.target.x += 500;
      }
      advance(b, shot.flightSeconds);
      expect(shot.endX, moves ? end + 500 : end);
      expect(b.target.hp, 1000 - h.skillPower);
      advance(b, .3);
      expect(b.target.hp, 1000 - h.skillPower);
    }
  });
  for (final h in heroes.where((h) => h.role == 'バーサーカー')) {
    for (final side in [96.0, 200.0, 384.0]) {
      test('floor hits attacking enemy once: ${h.id}, sprite side $side', () {
        final b = ready(h, PlayableStageCatalog.stages.first);
        addTearDown(b.dispose);
        b.spriteWorldSide = side;
        b.attackDuration = 1;
        b.skillDuration = 1.5;
        b.skillReleaseFractions = [24 / 36];
        b.charge = 3;
        b.skill();
        while (b.projectiles.isEmpty) {
          b.update(1 / 240);
        }
        final shot = b.projectiles.single;
        final victim = shot.target;
        final initialX = victim.x;
        victim.wait = 0;
        advance(b, shot.flightSeconds * .5);
        expect(victim.x, isNot(initialX));
        expect(victim.hp, 1000);
        advance(b, shot.flightSeconds * .5 + .01);
        expect(shot.resolved, isTrue);
        expect(shot.missed, isFalse);
        expect(shot.endX, closeTo(victim.x - side * .08, 1));
        expect(victim.hp, 1000 - h.skillPower);
        advance(b, .3);
        expect(victim.hp, 1000 - h.skillPower);
      });
    }
  }
  for (final material in [
    'grass',
    'wood',
    'basalt',
    'mud',
    'sandstone',
    'ice',
    'stone'
  ]) {
    testWidgets('floor material $material renders in held and flight poses',
        (tester) async {
      tester.view.physicalSize = const Size(1000, 650);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final h = heroes.firstWhere((h) => h.id == 'character_16_female');
      final stage = PlayableStageCatalog.stages
          .firstWhere((s) => s.floorMaterial == material);
      final assets = (await tester.runAsync(
          () => PlayableStageAssets.load(character: h, stage: stage)))!;
      final b = ready(h, stage);
      final key = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: key,
          child: MaterialApp(
              theme: AppTheme.dark,
              home: PlayableStagePage(
                  battle: b,
                  assets: assets,
                  audioOutput: SilentStageAudioOutput()))));
      await tester.pump();
      b.charge = 3;
      b.skill();
      advance(b, 18 / 24);
      await tester.pump();
      expect(b.projectiles, isEmpty);
      await tester.runAsync(() => capture(key, 'held-$material'));
      expect(tester.takeException(), isNull);
      advance(b, 8 / 24);
      await tester.pump();
      expect(b.projectiles, isNotEmpty);
      await tester.runAsync(() => capture(key, 'throw-$material'));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      b.dispose();
      assets.dispose();
    });
  }
}

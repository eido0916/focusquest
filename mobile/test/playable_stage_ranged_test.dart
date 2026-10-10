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

void advance(PlayableStageBattle battle, double seconds) {
  for (var tick = 0; tick < (seconds * 240).ceil(); tick++) {
    battle.update(1 / 240);
  }
}

void configure(PlayableStageBattle battle, PlayableStageAssets assets) {
  final attack = assets.motions['hero_attack']!,
      skill = assets.motions['hero_skill']!;
  battle.attackReleaseFractions = attack
      .eventTicks(battle.character.attackEvent)
      .map((tick) => tick / (24 * attack.duration))
      .toList();
  battle.skillReleaseFractions = skill
      .eventTicks(battle.character.skillEvent)
      .map((tick) => tick / (24 * skill.duration))
      .toList();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final heroes = PlayableCharacters.all.where((hero) => hero.ranged).toList();
  final assets = <String, PlayableStageAssets>{};
  setUpAll(() async {
    for (final hero in heroes) {
      assets[hero.id] = await PlayableStageAssets.load(
          stage: PlayableStageCatalog.stages.first, character: hero);
    }
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
  });
  tearDownAll(() {
    for (final value in assets.values) {
      value.dispose();
    }
  });

  PlayableStageBattle ready(PlayableCharacter hero, {double Function()? roll}) {
    final battle = PlayableStageBattle(character: hero, roll: roll ?? () => .5)
      ..start();
    configure(battle, assets[hero.id]!);
    advance(battle, 3);
    for (final enemy in battle.enemies) {
      enemy.wait = 100;
      enemy.hp = 1000;
    }
    addTearDown(battle.dispose);
    return battle;
  }

  test(
      'all eight ranged heroes fire in place; damage and charge wait for arrival',
      () async {
    for (final hero in heroes) {
      final battle = ready(hero);
      final victim = battle.target;
      battle.attack();
      while (battle.projectiles.isEmpty) {
        battle.update(1 / 240);
      }
      final shot = battle.projectiles.single;
      expect(victim.hp, 1000, reason: hero.name);
      expect(battle.charge, 0);
      expect(shot.x, greaterThan(shot.startX));
      expect(shot.x, lessThan(shot.endX));
      while (!shot.resolved) {
        expect(battle.heroX, PlayableStageBattle.heroHomeX, reason: hero.name);
        battle.update(1 / 240);
      }
      expect(victim.hp, 1000 - hero.power);
      expect(battle.charge, 1);
      advance(battle, 2);
      expect(battle.hits, 1);
      expect(battle.projectiles, isEmpty);
    }
  });
  test(
      'archer and gunner skills fire three shots with the existing total power',
      () async {
    for (final hero
        in heroes.where((hero) => ['弓使い', 'ガンナー'].contains(hero.role))) {
      final battle = ready(hero)..charge = 3;
      var impacts = 0;
      final subscription = battle.soundEvents.listen((sound) {
        if (sound == BattleSound.hit) impacts++;
      });
      expect(battle.skillReleaseFractions.length, 3);
      battle.skill();
      for (var tick = 0; tick < (battle.skillDuration + .5) * 240; tick++) {
        battle.update(1 / 240);
        expect(battle.heroX, PlayableStageBattle.heroHomeX);
      }
      expect(battle.target.hp, 1000 - hero.skillPower);
      expect(impacts, 3);
      expect(battle.charge, 0);
      expect(battle.skills, 1);
      await subscription.cancel();
    }
  });
  test('pause freezes a projectile, resume impacts once, reset clears it', () {
    final battle = ready(heroes.firstWhere((hero) => hero.role == '弓使い'));
    battle.attack();
    while (battle.projectiles.isEmpty) {
      battle.update(1 / 240);
    }
    final shot = battle.projectiles.single;
    final x = shot.x;
    battle.pause();
    advance(battle, 4);
    expect(shot.x, x);
    expect(battle.target.hp, 1000);
    battle.resume();
    advance(battle, 1);
    expect(battle.hits, 1);
    battle.attack();
    while (battle.projectiles.isEmpty) {
      battle.update(1 / 240);
    }
    battle.reset();
    expect(battle.projectiles, isEmpty);
    expect(battle.hits, 0);
  });
  test(
      'projectile keeps its victim after action ends and another action starts',
      () {
    final battle = ready(heroes.firstWhere((hero) => hero.role == 'ガンナー'));
    battle.attackReleaseFractions = [.99];
    final victim = battle.target;
    battle.attack();
    advance(battle, battle.attackDuration + .01);
    final shot = battle.projectiles.single;
    expect(battle.action, isNull);
    expect(victim.hp, 1000);
    victim.hp = 1;
    battle.attack();
    advance(battle, shot.flightSeconds);
    expect(victim.alive, false);
    expect(battle.target, isNot(same(victim)));
    expect(battle.target.hp, 1000);
    expect(battle.cleared, 1);
  });
  test('miss and critical resolve on arrival; a missed shot flies past', () {
    for (final critical in [false, true]) {
      final rolls = critical ? <double>[.5, .1] : <double>[.95];
      final battle = ready(heroes.firstWhere((hero) => hero.role == '忍者'),
          roll: () => rolls.removeAt(0));
      battle.attack();
      while (battle.projectiles.isEmpty) {
        battle.update(1 / 240);
      }
      final shot = battle.projectiles.single;
      expect(rolls, isNotEmpty);
      while (!shot.resolved) {
        battle.update(1 / 240);
      }
      expect(battle.target.hp, critical ? 960 : 1000);
      expect(battle.charge, critical ? 1 : 0);
      expect(shot.missed, !critical);
      if (!critical) {
        advance(battle, .05);
        expect(shot.x, greaterThan(shot.endX));
      }
    }
  });
  test('mage ice follows a moving distant boss while caster stays in place',
      () {
    final hero = heroes.firstWhere((hero) => hero.role == '魔法使い');
    final battle = PlayableStageBattle(
        stage: PlayableStageCatalog.stages[3], character: hero, roll: () => .5)
      ..phase = 2
      ..start();
    addTearDown(battle.dispose);
    configure(battle, assets[hero.id]!);
    advance(battle, 3);
    for (final enemy in battle.enemies) {
      enemy.wait = 100;
    }
    battle.enemies[0].hp = 0;
    battle.enemies[1].hp = 0;
    final boss = battle.target;
    final hp = boss.hp;
    battle.charge = 3;
    battle.skill();
    while (battle.projectiles.isEmpty) {
      battle.update(1 / 240);
    }
    final shot = battle.projectiles.single;
    expect(shot.kind, ProjectileKind.ice);
    boss.x -= 100;
    while (!shot.resolved) {
      battle.update(1 / 240);
      expect(battle.heroX, PlayableStageBattle.heroHomeX);
    }
    expect(shot.endX, closeTo(boss.x - battle.spriteWorldSide * .6, .01));
    expect(boss.hp, hp - hero.skillPower);
  });

  for (final role in ['弓使い', 'ガンナー', '魔法使い', '忍者']) {
    testWidgets(
        '$role projectile renders between stationary hero and distant target',
        (tester) async {
      tester.view.physicalSize = const Size(844, 390);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final hero = heroes.firstWhere((hero) => hero.role == role);
      final battle = ready(hero);
      for (final enemy in battle.enemies) { enemy.hp = enemy.definition.hp; }
      final before = battle.target.hp;
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.dark,
              home: PlayableStagePage(
                  battle: battle,
                  assets: assets[hero.id]!,
                  audioOutput: SilentStageAudioOutput()))));
      await tester.pump();
      battle.attack();
      while (battle.projectiles.isEmpty) {
        battle.update(1 / 240);
      }
      advance(battle, battle.projectiles.single.flightSeconds * .5);
      await tester.pump();
      expect(battle.heroX, PlayableStageBattle.heroHomeX);
      expect(battle.target.hp, before);
      if (const bool.fromEnvironment('CAPTURE_STAGE')) {
        await tester.runAsync(() async {
          final image = await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File('../output/playable-stage/ranged-${hero.id}-v005.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
}

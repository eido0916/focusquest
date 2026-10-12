import 'support/trained_stage_hero.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final assets = <int, PlayableStageAssets>{};
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    for (final family in ['SunlitSerif', 'Roboto', 'serif', 'Ahem']) {
      await (FontLoader(family)..addFont(Future.value(font))).load();
    }
    await (FontLoader('MaterialIcons')
          ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf')))
        .load();
    for (final number in [16, 20, 24, 28, 32, 36]) {
      assets[number] = await PlayableStageAssets.load(
          stage: PlayableStageCatalog.stages[number - 1]);
    }
  });
  tearDownAll(() {
    for (final value in assets.values) {
      value.dispose();
    }
  });

  test(
      'each new area uses its monsters for waves and boss escorts; all 20 stages clear',
      () {
    final newIds = <String>{};
    for (final stage in PlayableStageCatalog.stages
        .where((stage) => stage.number >= 13 && stage.number <= 32)) {
      for (var phase = 0; phase < 3; phase++) {
        final wave = stage.wave(phase);
        newIds.addAll(wave.map((unit) => unit.id));
        expect(
            wave.every((unit) =>
                unit.id.startsWith('mob_') || unit.id.startsWith('boss_')),
            true);
        if (phase == 2 && stage.hasBoss) {
          expect(wave.length, 3);
          expect(wave.where((unit) => unit.isBoss).length, 1);
          expect(wave.first.id, stage.bossEscort!.id);
        }
      }
      final battle = PlayableStageBattle(
          stage: stage, character: trainedStageHero(), roll: () => .5)
        ..start();
      for (var tick = 0; tick < 120 * 120 && battle.active; tick++) {
        if (battle.canSkill) {
          battle.skill();
        } else if (battle.canAttack) {
          battle.attack();
        }
        battle.update(1 / 120);
      }
      expect(battle.mode, StageMode.won, reason: stage.title);
      expect(battle.cleared, 8);
      battle.dispose();
    }
    expect(newIds.length, 10);
    expect(PlayableStageCatalog.backgrounds.toSet().length, 9);
  });

  for (final size in [const Size(390, 844), const Size(844, 390)]) {
    for (final number in [16, 20, 24, 28, 32, 36]) {
      testWidgets('new stage $number boss and background fit $size',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final stage = PlayableStageCatalog.stages[number - 1];
        final battle = PlayableStageBattle(
            stage: stage, character: trainedStageHero(), roll: () => .5)
          ..phase = 2
          ..start();
        addTearDown(battle.dispose);
        for (var tick = 0; tick < 360; tick++) {
          battle.update(1 / 120);
        }
        final boundary = GlobalKey();
        await tester.pumpWidget(RepaintBoundary(
            key: boundary,
            child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: AppTheme.dark,
                home: PlayableStagePage(
                    battle: battle,
                    assets: assets[number]!,
                    audioOutput: SilentStageAudioOutput()))));
        await tester.pump();
        expect(find.text(stage.title), findsNothing);
        expect(battle.remainingEnemies, 3);
        expect(battle.enemies.last.definition.id,
            PlayableStageCatalog.bossIds[number ~/ 4 - 1]);
        expect(tester.takeException(), isNull);
        if (const bool.fromEnvironment('CAPTURE_STAGE')) {
          await tester.runAsync(() async {
            final image = await (boundary.currentContext!.findRenderObject()!
                    as RenderRepaintBoundary)
                .toImage();
            final bytes =
                await image.toByteData(format: ui.ImageByteFormat.png);
            await File(
                    '../output/playable-stage/expansion-$number-${size.width.toInt()}x${size.height.toInt()}-v006.png')
                .writeAsBytes(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
        // Original hit event and defeat motion for the new boss are playable.
        for (final enemy in battle.enemies) {
          enemy.wait = 100;
        }
        battle.enemies[0].hp = 0;
        battle.enemies[1].hp = 0;
        final boss = battle.target;
        boss.hp = 1;
        boss.wait = 0;
        for (var tick = 0; tick < 100; tick++) {
          battle.update(1 / 120);
        }
        expect(battle.damageNumbers.any((number) => number.toHero), true);
        battle.attack();
        for (var tick = 0; tick < 360; tick++) {
          battle.update(1 / 120);
        }
        expect(battle.mode, StageMode.won);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}

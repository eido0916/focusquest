import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_painter.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'support/mechanics_stage.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

void hit(PlayableStageBattle battle) {
  for (final enemy in battle.enemies) {
    enemy.wait = 100;
  }
  final enemy = battle.enemies.first;
  enemy.attacking = true;
  enemy.actionTime = enemy.hitTick / 24 - .01;
  enemy.hitResolved = false;
  battle.update(.02);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('damage triggers recovery, a miss does not, defeat freezes combat', () {
    for (final roll in [.5, .99]) {
      final battle =
          PlayableStageBattle(stage: mechanicsStage(), roll: () => roll)
            ..start();
      advance(battle, 3);
      hit(battle);
      expect(battle.heroHurt, roll == .5);
      advance(battle, .6);
      expect(battle.heroHurt, false);
      if (roll == .5) {
        battle.hp = 1;
        hit(battle);
        expect(battle.mode, StageMode.lost);
        expect(battle.heroDefeatFinished, false);
        final clock = battle.clock, x = battle.heroX;
        advance(battle, 2);
        expect(battle.heroDefeatFinished, true);
        expect(battle.heroDefeatTime, battle.heroDefeatDuration);
        expect(battle.clock, clock);
        expect(battle.heroX, x);
        expect(battle.attack(), false);
        expect(battle.skill(), false);
        battle.restart();
        expect(battle.heroDefeatTime, 0);
        expect(battle.heroHurt, false);
        expect(battle.hp, battle.character.health);
      }
      battle.dispose();
    }
  });

  test('all 32 actors load visible, non-looping drawn hurt and kneeling poses',
      () async {
    for (final hero in PlayableCharacters.all) {
      final assets = await PlayableStageAssets.load(
          character: hero, stage: PlayableStageCatalog.stages.first);
      try {
        final hurt = assets.motions['hero_hurt']!;
        final defeat = assets.motions['hero_defeat']!;
        for (final motion in [hurt, defeat]) {
          expect(motion.metadata['asset'], hero.id);
          expect(motion.images.length, 4);
          expect(motion.metadata['loop_in_game'], false);
          expect(motion.metadata['direction'], 'right');
          expect(motion.metadata['interpolation'], 'none');
          for (final image in motion.images) {
            expect(image.width, 128);
            expect(image.height, 128);
          }
        }
        final last = defeat.frame(100).image;
        expect(last, same(defeat.images.last));
        final rgba = await last.toByteData(format: ui.ImageByteFormat.rawRgba);
        var visible = false;
        for (var i = 3; i < rgba!.lengthInBytes; i += 4) {
          if (rgba.getUint8(i) != 0) {
            visible = true;
            break;
          }
        }
        expect(visible, true, reason: hero.id);
        expect(defeat.topPixels.last, greaterThan(hurt.topPixels.first),
            reason: hero.id);
        final battle = PlayableStageBattle(character: hero)
          ..mode = StageMode.lost;
        final painter = PlayableStagePainter(battle, assets, 1);
        expect(painter.heroMotion, 'hero_defeat');
        expect(painter.heroLoop, false);
        battle.dispose();
      } finally {
        assets.dispose();
      }
    }
  });

  testWidgets('defeat animation stays unobscured then exposes retry',
      (tester) async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
    final assets = (await tester.runAsync(() => PlayableStageAssets.load()))!;
    final battle = PlayableStageBattle(stage: mechanicsStage(), roll: () => .5)
      ..start();
    advance(battle, 3);
    await tester.pumpWidget(MaterialApp(
        home: PlayableStagePage(
            battle: battle,
            assets: assets,
            audioOutput: SilentStageAudioOutput())));
    await tester.pump();
    battle.hp = 1;
    hit(battle);
    await tester.pump();
    expect(find.text('もう一度、挑もう。'), findsNothing);
    advance(battle, 1.4);
    await tester.pump();
    expect(find.text('もう一度、挑もう。'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
    battle.dispose();
    assets.dispose();
  });
}

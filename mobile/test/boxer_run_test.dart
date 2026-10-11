import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/boxer_hero_component.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('supplied run loops with scenery and restores after attack/skill',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var seconds = 0.0;
    final state = BattleStateController(
      config: const RunnerConfig(
        normalAttackStyle: NormalAttackStyle.boxer,
        autoSkill: SwordsmanSkill.frontKick,
        spawnSeconds: 100,
        attackSeconds: 100,
        sousenCooldownSeconds: 100,
      ),
      durationSeconds: 20,
    );
    final game = FocusQuestBattleGame(
        state: state, elapsed: () => seconds, onFinished: (_) {});
    await tester.runAsync(() async {
      game.onGameResize(Vector2(960, 540));
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load).timeout(const Duration(seconds: 20));
    });
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(width: 960, height: 540, child: GameWidget(game: game)),
    ));
    for (var i = 0;
        i < 100 && game.children.whereType<BoxerHeroComponent>().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    final hero = game.children.whereType<BoxerHeroComponent>().single;
    game.pauseEngine();
    final runSize = hero.size.clone();
    final runAnchor = hero.anchor;
    final data = await tester.runAsync(() async => jsonDecode(
        await rootBundle.loadString(
            'assets/images/characters/boxer/run_from_skill/run.json')) as Map);
    expect(data!['frameIds'], [1, 2, 3, 4]);
    expect(hero.animation!.frames, hasLength(4));
    expect(hero.assets.runAssets.duration, closeTo(4 / 12, 1e-9));
    expect(hero.scale, Vector2.all(1));
    expect(hero.size, hero.skillAssets!.frameSize);
    expect(hero.anchor, hero.skillAssets!.anchor);
    final seen = <int>[];
    final output = Platform.environment['BOXER_RUN_PREVIEW_DIR'];
    Future<void> capture(String name) async {
      if (output == null) return;
      await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final image = await recorder.endRecording().toImage(960, 540);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('$output/$name.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }

    for (var i = 0; i < 8; i++) {
      seconds = (i + .1) / 12;
      game.update(1 / 12);
      seen.add(hero.currentSourceFrame);
      expect(hero.position, Vector2(345, 405));
      expect(hero.size, runSize);
      expect(hero.anchor, runAnchor);
      await capture('run_${i.toString().padLeft(2, '0')}');
    }
    expect(seen, [1, 2, 3, 4, 1, 2, 3, 4]);
    final index = hero.animationTicker!.currentIndex;
    game.update(1); // Frozen simulation clock must also freeze the runner.
    expect(hero.animationTicker!.currentIndex, index);

    state.enemies
        .add(RunnerEnemy(0, const EnemyData('goblin', maxHp: 20), x: 485));
    expect(state.playNormalAttack(), isTrue);
    seconds += .35;
    game.update(.35);
    expect(hero.isAttackPlaying, isTrue);
    await capture('attack');
    seconds += .75;
    game.update(.75);
    expect(hero.isAttackPlaying, isFalse);
    expect(hero.size, runSize);
    expect(hero.anchor, runAnchor);
    expect(state.damageSerial, 2);
    expect(state.playNormalAttack(), isTrue);
    expect(state.playFrontKickSkill(), isTrue);
    seconds += .65;
    game.update(.65);
    expect(hero.isFrontKickPlaying, isTrue);
    expect(hero.isAttackPlaying, isFalse);
    expect(state.playNormalAttack(), isFalse);
    await capture('skill');
    seconds += .45;
    game.update(.45);
    expect(hero.isFrontKickPlaying, isFalse);
    expect(hero.animation!.loop, isTrue);
    expect(hero.size, runSize);
    expect(hero.anchor, runAnchor);
    expect(hero.position, Vector2(345, 405));
    expect(state.damageSerial, 3);
    await capture('return_to_run');
    expect(tester.takeException(), isNull);
    await tester.runAsync(game.ready);
    await tester.pumpWidget(const SizedBox());
  });
}

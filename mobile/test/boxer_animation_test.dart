import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/boxer_hero_component.dart';
import 'package:focusquest/game/runner/boxer_normal_attack_sequence.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const config = RunnerConfig(
    normalAttackStyle: NormalAttackStyle.boxer,
    spawnSeconds: 100,
    sousenCooldownSeconds: 100,
  );
  test('reviewed metadata and simulation preserve the existing damage budget',
      () async {
    final metadata = jsonDecode(await rootBundle.loadString(
            'assets/images/characters/boxer/normal_attack/normal_attack.json'))
        as Map;
    expect(metadata['attackFrames'], BoxerNormalAttackSequence.frameIds);
    expect(metadata['stepTimes'], BoxerNormalAttackSequence.stepTimes);
    expect(BoxerNormalAttackSequence.duration, closeTo(1.01, 1e-9));
    expect(config.normalAttackDuration,
        closeTo(const RunnerConfig().normalAttackDuration, 1e-9));
    for (var i = 0; i < 2; i++) {
      expect(config.normalHitTimes[i],
          closeTo(const RunnerConfig().normalHitTimes[i], 1e-9));
    }
    final state = BattleStateController(config: config, durationSeconds: 10);
    final enemy = RunnerEnemy(0, const EnemyData('goblin', maxHp: 2), x: 485);
    state.enemies.add(enemy);
    expect(state.playNormalAttack(), isTrue);
    expect(state.playNormalAttack(), isFalse);
    state.advanceTo(.30);
    expect(enemy.hp, 2);
    state.advanceTo(.35);
    expect(enemy.hp, 1);
    state.advanceTo(.55);
    expect(enemy.hp, 0);
    expect(state.damageSerial, 2);
    state.advanceTo(1.05);
    expect(state.isNormalAttackPlaying, isFalse);
    expect(state.attackSerial, 1);
    expect(state.motion, HeroMotion.run);
  });

  testWidgets('real battle loads boxer assets, punches once and returns to run',
      (tester) async {
    var seconds = 0.0;
    final state = BattleStateController(config: config, durationSeconds: 10);
    final game = FocusQuestBattleGame(
      state: state,
      elapsed: () => seconds,
      onFinished: (_) {},
    );
    await tester.runAsync(() async {
      game.onGameResize(Vector2(960, 540));
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load).timeout(const Duration(seconds: 20));
    });
    await tester.pumpWidget(MaterialApp(
        home: SizedBox(
      width: 960,
      height: 540,
      child: GameWidget(game: game),
    )));
    // Hero addition finishes at a mount tick; keep pumping during preload.
    for (var i = 0;
        i < 100 && game.children.whereType<BoxerHeroComponent>().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    game.pauseEngine();
    final hero = game.children.whereType<BoxerHeroComponent>().single;
    expect(hero.isAttackPlaying, isFalse);
    expect(hero.scale.x, greaterThan(0));
    state.enemies
        .add(RunnerEnemy(0, const EnemyData('goblin', maxHp: 2), x: 485));
    state.playNormalAttack();
    seconds = .35;
    game.update(.35);
    expect(hero.isAttackPlaying, isTrue);
    expect(hero.currentSourceFrame, 14);
    expect(hero.animationTicker!.currentIndex, 6);
    expect(state.playNormalAttack(), isFalse);
    seconds = .55;
    game.update(.20);
    expect(hero.currentSourceFrame, 25);
    expect(hero.animationTicker!.currentIndex, 13);
    // Optional evidence image renders the actual integrated battle components.
    final previewPath = Platform.environment['BOXER_PREVIEW_PATH'];
    if (previewPath != null) {
      await tester.runAsync(() async {
        game.onGameResize(Vector2(960, 540));
        final recorder = ui.PictureRecorder();
        game.render(Canvas(recorder));
        final image = await recorder.endRecording().toImage(960, 540);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    seconds = 1.05;
    game.update(.50);
    expect(hero.isAttackPlaying, isFalse);
    expect(hero.animation!.loop, isTrue);
    expect(hero.position.x, 345);
    expect(hero.position.y, 405);
    expect(tester.takeException(), isNull);
    await tester.runAsync(game.ready);
    await tester.pumpWidget(const SizedBox());
  });
}

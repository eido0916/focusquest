import 'dart:io';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/boxer_front_kick_sequence.dart';
import 'package:focusquest/game/runner/boxer_hero_component.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';

const config = RunnerConfig(
    normalAttackStyle: NormalAttackStyle.boxer,
    autoSkill: SwordsmanSkill.frontKick,
    spawnSeconds: 100,
    attackSeconds: 100,
    sousenCooldownSeconds: 10);

void main() {
  test('front kick covers the visible forward range once, including boundaries',
      () {
    final state = BattleStateController(
        durationSeconds: 20,
        config: const RunnerConfig(
            normalAttackStyle: NormalAttackStyle.boxer,
            autoSkill: SwordsmanSkill.frontKick,
            spawnSeconds: 100,
            attackSeconds: 100,
            sousenCooldownSeconds: 100,
            enemySpeed: 1e-15)); // Positive speed below coordinate precision.
    final targets = [
      for (final x in [344.0, 345.0, 485.0, 800.0, 960.0, 961.0])
        RunnerEnemy(x.toInt(), const EnemyData('goblin', maxHp: 20), x: x)
    ];
    state.enemies.addAll(targets);
    state.playFrontKickSkill();
    state.advanceTo(.60);
    expect(targets.map((e) => e.hp), everyElement(20));
    state.advanceTo(.65);
    expect(targets.map((e) => e.hp).toList(), [20, 17, 17, 17, 17, 20]);
    expect(state.damageSerial, 4);
    final late = RunnerEnemy(999, const EnemyData('goblin', maxHp: 20), x: 700);
    state.enemies.add(late);
    state.advanceTo(1.05);
    expect(state.damageSerial, 4);
    expect(late.hp, 20);
    expect(targets.map((e) => e.hp).toList(), [20, 17, 17, 17, 17, 20]);
  });

  test('area kill awards each reward once and preserves surviving boss HP', () {
    final state = BattleStateController(
        durationSeconds: 20,
        config: const RunnerConfig(
            normalAttackStyle: NormalAttackStyle.boxer,
            autoSkill: SwordsmanSkill.frontKick,
            spawnSeconds: 100,
            attackSeconds: 100,
            sousenCooldownSeconds: 100,
            enemySpeed: 1e-15));
    final enemy =
        RunnerEnemy(1, const EnemyData('goblin', expReward: 17), x: 700);
    final boss = RunnerEnemy(
        2, const EnemyData('boss', maxHp: 10, isBoss: true),
        x: 800);
    state.enemies.addAll([enemy, boss]);
    state.playFrontKickSkill();
    state.advanceTo(.65);
    expect(enemy.hp, 0);
    expect(boss.hp, 7);
    expect(state.gainedExp, 17);
    expect(state.defeatedCount, 1);
    state.advanceTo(1.05);
    expect(boss.hp, 7);
    expect(state.damageSerial, 2);
    expect(state.gainedExp, 17);
  });

  test(
      'full extension hits every forward enemy once, recovery allows next skill',
      () {
    final state = BattleStateController(config: config, durationSeconds: 60);
    final enemy = RunnerEnemy(0, const EnemyData('goblin', maxHp: 20), x: 485);
    final follower =
        RunnerEnemy(1, const EnemyData('goblin', maxHp: 20), x: 517);
    state.enemies.addAll([enemy, follower]);
    expect(state.playNormalAttack(), isTrue);
    expect(state.playFrontKickSkill(), isTrue);
    expect(state.isNormalAttackPlaying, isFalse);
    expect(state.playNormalAttack(), isFalse);
    expect(state.playFrontKickSkill(), isFalse);
    state.advanceTo(.60);
    expect(enemy.hp, 20);
    state.advanceTo(.65);
    expect(enemy.hp, 17);
    expect(follower.hp, 17);
    expect(state.damageSerial, 2);
    expect(
        BoxerFrontKickSequence
            .frameIds[BoxerFrontKickSequence.indexAt(state.skillAge)],
        14);
    state.advanceTo(1.05);
    expect(state.damageSerial, 2);
    expect(state.motion, HeroMotion.run);
    expect(state.backgroundTravelSeconds, lessThan(state.elapsedSeconds));
    expect(state.playFrontKickSkill(), isTrue);
    state.advanceTo(1.70);
    expect(enemy.hp, 14);
    expect(follower.hp, 14);
    expect(state.damageSerial, 4);
  });

  test('miss recovers, ten-second cooldown and replay remain deterministic',
      () {
    final state = BattleStateController(config: config, durationSeconds: 60);
    state.advanceTo(10);
    expect(state.skillSerial, 1);
    expect(state.skillName, '前蹴り');
    state.advanceTo(11.05);
    expect(state.isSkillPlaying, isFalse);
    expect(state.damageSerial, 0);
    state.advanceTo(20);
    expect(state.skillSerial, 2);
    final frames = BattleStateController(config: config, durationSeconds: 60);
    for (var i = 1; i <= 1200; i++) {
      frames.advanceTo(i / 60);
    }
    expect(frames.skillSerial, state.skillSerial);
    expect(frames.backgroundTravelSeconds,
        closeTo(state.backgroundTravelSeconds, 1e-7));
  });

  testWidgets('battle renders kick, blocks punch, returns to existing run',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var seconds = 0.0;
    final state = BattleStateController(config: config, durationSeconds: 60);
    final game = FocusQuestBattleGame(
        state: state, elapsed: () => seconds, onFinished: (_) {});
    // Start I/O outside the widget test's fake clock before mounting the game.
    await tester.runAsync(() async {
      game.onGameResize(Vector2(960, 540));
      // Direct preload is needed only in this fixture to avoid fake-clock I/O.
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load).timeout(const Duration(seconds: 20));
    });
    await tester.pumpWidget(MaterialApp(
        home:
            SizedBox(width: 960, height: 540, child: GameWidget(game: game))));
    // add() completes after a mount tick; do not await it while pumps are paused.
    for (var i = 0;
        i < 100 && game.children.whereType<BoxerHeroComponent>().isEmpty;
        i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.children.whereType<BoxerHeroComponent>(), hasLength(1));
    game.pauseEngine();
    final hero = game.children.whereType<BoxerHeroComponent>().single;
    final originalSize = hero.size.clone();
    final originalAnchor = hero.anchor;
    state.enemies
        .add(RunnerEnemy(0, const EnemyData('goblin', maxHp: 20), x: 485));
    expect(state.playFrontKickSkill(), isTrue);
    final output = Platform.environment['FRONT_KICK_PREVIEW_DIR'];
    for (var i = 0; i <= 24; i++) {
      seconds = i * .05;
      game.update(i == 0 ? 0 : .05);
      if (seconds <= 1) {
        expect(hero.isFrontKickPlaying, isTrue);
        expect(hero.isAttackPlaying, isFalse);
        expect(
            hero.currentSkillSourceFrame,
            BoxerFrontKickSequence
                .frameIds[BoxerFrontKickSequence.indexAt(state.skillAge)]);
        expect(hero.animationTicker!.currentIndex,
            BoxerFrontKickSequence.indexAt(state.skillAge));
      }
      expect(hero.position, Vector2(345, 405));
      if (output != null) {
        game.renderBox.markNeedsPaint();
        await tester.pump();
        await expectLater(
            find.byType(GameWidget<FocusQuestBattleGame>),
            matchesGoldenFile(Uri.file(
                '$output/battle_${i.toString().padLeft(3, '0')}.png')));
      }
    }
    expect(state.damageSerial, 1);
    expect(hero.isFrontKickPlaying, isFalse);
    expect(hero.animation!.loop, isTrue);
    expect(hero.size, originalSize);
    expect(hero.anchor, originalAnchor);
    expect(state.playFrontKickSkill(), isTrue);
    seconds = 1.85;
    game.update(.65);
    expect(hero.currentSkillSourceFrame, 14);
    expect(state.damageSerial, 2);
    seconds = 2.30;
    game.update(.45);
    expect(hero.isFrontKickPlaying, isFalse);
    // Sub-tick rendering must visit every selected pose, including 1/24s holds.
    expect(state.playFrontKickSkill(), isTrue);
    final seen = <int>{};
    for (var i = 0; i <= 124; i++) {
      seconds = 2.30 + i / 120;
      game.update(i == 0 ? 0 : 1 / 120);
      seen.add(hero.currentSkillSourceFrame!);
      expect(hero.animationTicker!.currentIndex,
          BoxerFrontKickSequence.indexAt(state.visualSkillAge));
    }
    expect(seen, BoxerFrontKickSequence.frameIds.toSet());
    expect(tester.takeException(), isNull);
    await tester.runAsync(game.ready);
    await tester.pumpWidget(const SizedBox());
  });
}

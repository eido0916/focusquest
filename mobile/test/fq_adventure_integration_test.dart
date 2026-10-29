import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/character/domain/progression_service.dart';
import 'package:focusquest/features/playable_stage/domain/fq_adventure_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_page.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_selection_page.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'support/memory_repository.dart';

void main() {
  late PlayableStageAssets assets;
  setUpAll(() async {
    assets = await PlayableStageAssets.load(
        stage: PlayableStageCatalog.stages.first);
  });
  tearDownAll(() => assets.dispose());
  test('all sixteen FQ roles resolve an original animation for both genders',
      () async {
    final controller = GameController(MemoryRepository());
    await controller.load();
    for (final type in GameCatalog.types.values) {
      for (final appearance in ['male', 'female']) {
        await controller.resetForDevelopment();
        await controller.onboard(type, appearance: appearance);
        final combat = fqAdventureCharacter(controller.state!.activeCharacter!);
        expect(combat.female, appearance == 'female', reason: type.typeId);
        expect(combat.role, JobPortrait.roleNames[type.typeId],
            reason: type.typeId);
        for (final level in [1, 8, 30]) {
          final hero =
              controller.state!.activeCharacter!.copyWith(level: level);
          final stats = ProgressionService().stats(hero, const {});
          final grown = fqAdventureCharacter(hero);
          expect(grown.health, stats.hp, reason: '${type.typeId} Lv.$level');
          expect(grown.power, stats.attack);
          expect(grown.speed, stats.speed);
          expect(grown.defense, stats.defense);
          expect(grown.criticalRate, stats.criticalRate);
        }
      }
    }
    controller.dispose();
  });
  test('adventure uses character defense and critical rate in combat',
      () async {
    final controller = GameController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    final character = fqAdventureCharacter(controller.state!.activeCharacter!);
    final battle = PlayableStageBattle(character: character, roll: () => .1);
    addTearDown(battle.dispose);
    battle.start();
    for (var tick = 0; tick < 1200 && battle.damageNumbers.isEmpty; tick++) {
      battle.update(1 / 120);
    }
    final incoming = battle.damageNumbers.firstWhere((hit) => hit.toHero);
    expect(incoming.critical, false);
    expect(
        incoming.amount,
        (battle.enemies.first.definition.damage - character.defense)
            .clamp(1, 99999));
    for (final enemy in battle.enemies) {
      enemy.attacking = false;
      enemy.wait = 100;
    }
    expect(battle.attack(), true);
    for (var tick = 0; tick < 180; tick++) {
      battle.update(1 / 120);
    }
    final outgoing = battle.damageNumbers.firstWhere((hit) => !hit.toHero);
    expect(outgoing.critical, false); // 10% roll exceeds the warrior's 5% rate.
    expect(outgoing.amount, character.power);
  });

  test(
      'legacy save compatibility, permanent clear records, retry and battle locks',
      () async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    await controller.onboard(GameCatalog.types[8]!, appearance: 'female');
    final legacy = controller.state!.toJson()..remove('clearedPlayableStages');
    expect(PlayerState.fromJson(legacy).clearedPlayableStages, isEmpty);
    await controller.beginPlayableAdventure();
    await expectLater(controller.startFocus(30), throwsStateError);
    await expectLater(controller.beginPlayableAdventure(), throwsStateError);
    await expectLater(controller.selectCharacter('starter'), throwsStateError);
    controller.endPlayableAdventure();
    repo.fail = true;
    await expectLater(controller.recordPlayableClear(1), throwsStateError);
    expect(controller.state!.clearedPlayableStages, isEmpty);
    repo.fail = false;
    await controller.recordPlayableClear(1);
    await controller.recordPlayableClear(1);
    final restored = PlayerState.fromJson(repo.state.toJson());
    expect(restored.clearedPlayableStages, {1});
    expect(restored.coins, 0);
    await controller.startFocus(15);
    await expectLater(controller.beginPlayableAdventure(), throwsStateError);
    controller.dispose();
  });

  test('FQ growth retains female ranged animation identity', () async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    await controller.onboard(GameCatalog.types[8]!, appearance: 'female');
    final hero = controller.state!.activeCharacter!;
    final level1 = fqAdventureCharacter(hero);
    final leveled = fqAdventureCharacter(
        hero.copyWith(level: 8, equippedItems: {'weapon': 'wooden_sword'}));
    expect(leveled.id, 'character_07_female');
    expect(leveled.ranged, true);
    expect(leveled.health, level1.health + 84);
    expect(leveled.power, level1.power + 21);
    expect(leveled.speed, level1.speed + 7);
    controller.dispose();
  });

  testWidgets(
      'FQ adventure tab directly opens stages using the saved female archer',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[8]!,
        name: 'アオイ', appearance: 'female');
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('冒険')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('select-stage-1')), findsOneWidget);
    expect(find.text('冒険の書'), findsOneWidget);
    expect(find.text('以前の冒険の書'), findsNothing);
    expect(find.byKey(const Key('legacy-adventure')), findsNothing);
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('challenge-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final page =
        tester.widget<PlayableStagePage>(find.byType(PlayableStagePage));
    expect(page.battle!.character.id, 'character_07_female');
    expect(controller.playableAdventureActive, true);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(controller.playableAdventureActive, false);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets(
      'win survives recreating the selection screen and reloading the app',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    final character = fqAdventureCharacter(
        controller.state!.activeCharacter!.copyWith(level: 60));
    await tester.pumpWidget(MaterialApp(
        home: PlayableStageSelectionPage(
            controller: controller,
            assets: assets,
            audioOutput: SilentStageAudioOutput(),
            battleFactory: (stage) => PlayableStageBattle(
                stage: stage, character: character, roll: () => .5))));
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('challenge-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final battle = tester
        .widget<PlayableStagePage>(find.byType(PlayableStagePage))
        .battle!;
    battle.start();
    for (var tick = 0; tick < 120 * 120 && battle.active; tick++) {
      if (battle.canSkill) {
        battle.skill();
      } else if (battle.canAttack) {
        battle.attack();
      }
      battle.update(1 / 120);
    }
    expect(battle.mode, StageMode.won);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(repo.state.clearedPlayableStages, {1});
    final encountered = {
      for (var phase = 0; phase < 3; phase++)
        for (final enemy in PlayableStageCatalog.stages.first.wave(phase))
          enemy.id,
    };
    expect(repo.state.encounteredEnemyIds, encountered);
    await tester.pumpWidget(const SizedBox());
    await controller.load();
    await tester.pumpWidget(
        MaterialApp(home: PlayableStageSelectionPage(controller: controller)));
    await tester.pump();
    expect(controller.state!.encounteredEnemyIds, encountered);
    expect(
        find.descendant(
            of: find.byKey(const Key('select-stage-1')),
            matching: find.text('Stage 1')),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  testWidgets('home adventure uses the shared controller and returns to focus',
      (tester) async {
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[8]!,
        name: 'アオイ', appearance: 'female');
    await controller.recordPlayableClear(1);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('冒険に出発する'));
    await tester.tap(find.text('冒険に出発する'));
    await tester.pumpAndSettle();
    final selection = tester.widget<PlayableStageSelectionPage>(
        find.byType(PlayableStageSelectionPage));
    expect(selection.controller, same(controller));
    expect(selection.embedded, true);
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    expect(
        find.descendant(
            of: find.byKey(const Key('select-stage-1')),
            matching: find.text('Stage 1')),
        findsOneWidget);
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('ホーム')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('集中をはじめる'));
    await tester.tap(find.text('集中をはじめる'));
    await tester.pumpAndSettle();
    expect(find.text('集中を開始'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('selection reacts to focus and exposes failed clear save retry',
      (tester) async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await tester.pumpWidget(MaterialApp(
        home: PlayableStageSelectionPage(
            controller: controller,
            assets: assets,
            audioOutput: SilentStageAudioOutput(),
            battleFactory: (stage) => PlayableStageBattle(
                stage: stage,
                character: fqAdventureCharacter(
                    controller.state!.activeCharacter!.copyWith(level: 60)),
                roll: () => .5))));
    await tester.pumpAndSettle();
    await controller.startFocus(15);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    expect(
        tester.widget<InkWell>(find.byKey(const Key('select-stage-1'))).onTap,
        isNull);
    await controller.finishFocus(cancel: true);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('select-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(find.byKey(const Key('challenge-stage-1')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final battle = tester
        .widget<PlayableStagePage>(find.byType(PlayableStagePage))
        .battle!;
    battle.start();
    for (var tick = 0; tick < 120 * 120 && battle.active; tick++) {
      if (battle.canSkill) {
        battle.skill();
      } else if (battle.canAttack) {
        battle.attack();
      }
      battle.update(1 / 120);
    }
    expect(battle.mode, StageMode.won);
    repo.fail = true;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(controller.playableAdventureActive, false);
    expect(repo.state.clearedPlayableStages, isEmpty);
    await tester.ensureVisible(find.byKey(const Key('select-stage-1')));
    expect(
        tester.widget<InkWell>(find.byKey(const Key('select-stage-1'))).onTap,
        isNull);
    repo.fail = false;
    await tester.scrollUntilVisible(
        find.byKey(const Key('retry-stage-clear')), -150);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('retry-stage-clear')));
    await tester.pumpAndSettle();
    expect(repo.state.clearedPlayableStages, {1});
    expect(find.byKey(const Key('retry-stage-clear')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}

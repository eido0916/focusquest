import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/adventure/domain/adventure.dart';
import 'package:focusquest/features/character/domain/progression_service.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/domain/stats.dart';
import 'support/memory_repository.dart';

void main() {
  AdventureRun run(Stats stats, {String stage = 'forest_1'}) => AdventureRun(
      id: 'run',
      stageId: stage,
      heroName: 'アオイ',
      stats: stats,
      seed: 42,
      startedAt: DateTime(2026, 10, 10));

  test('all jobs can start; growth changes defeat into victory', () {
    for (final type in GameCatalog.types.values) {
      final hero = Character(
          id: type.typeId,
          name: type.job,
          characterType: type.typeId,
          baseStats: type.stats);
      final low = ProgressionService().stats(hero, GameCatalog.equipment);
      expect(AdventureBattle.simulate(run(low)).won, isTrue, reason: type.job);
      expect(
          AdventureBattle.simulate(run(low, stage: 'forest_5')).won, isFalse);
      final grown = ProgressionService()
          .stats(hero.copyWith(level: 15), GameCatalog.equipment);
      expect(
          AdventureBattle.simulate(run(grown, stage: 'forest_5')).won, isTrue,
          reason: type.job);
    }
  });
  test('saved snapshot restores identical damage, HP and outcome', () {
    final original =
        run(const Stats(hp: 200, attack: 30, defense: 15, speed: 12));
    final restored = AdventureRun.fromJson(original.toJson());
    final a = AdventureBattle.simulate(original);
    final b = AdventureBattle.simulate(restored);
    expect(a.won, b.won);
    expect(a.events.map((e) => [e.message, e.heroHp, e.enemyHp]),
        b.events.map((e) => [e.message, e.heroHp, e.enemyHp]));
    expect(
        a.revealed(
            original, original.startedAt.subtract(const Duration(seconds: 1))),
        0);
    expect(a.revealed(original, original.startedAt.add(a.duration)),
        a.events.length);
  });
  test(
      'speed and critical rate affect combat and damage never becomes negative',
      () {
    final slow = AdventureBattle.simulate(
        run(const Stats(hp: 500, attack: 10, speed: 2, criticalRate: 0)));
    final fast = AdventureBattle.simulate(
        run(const Stats(hp: 500, attack: 10, speed: 30, criticalRate: 0)));
    expect(fast.events.last.heroHp, greaterThan(slow.events.last.heroHp));
    final crit = AdventureBattle.simulate(
        run(const Stats(hp: 500, attack: 10, speed: 30, criticalRate: 1)));
    expect(crit.events.length, lessThan(fast.events.length));
    expect(fast.events.every((e) => e.heroHp >= 0 && e.enemyHp >= 0), isTrue);
  });
  test('legacy saves initialize adventure progress without losing focus data',
      () {
    final old = PlayerState(uid: 'local-player', coins: 35).toJson()
      ..remove('clearedStages')
      ..remove('adventureRun')
      ..remove('lastAdventure');
    final restored = PlayerState.fromJson(old);
    expect(restored.clearedStages, isEmpty);
    expect(restored.adventureRun, isNull);
    expect(restored.coins, 35);
  });
  test(
      'locked stages, concurrent focus, early settlement and mutation are rejected',
      () async {
    final controller = GameController(MemoryRepository(), random: Random(1));
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await expectLater(controller.startAdventure('forest_2'), throwsStateError);
    await controller.startFocus(1);
    await expectLater(controller.startAdventure('forest_1'), throwsStateError);
    await controller.finishFocus(cancel: true);
    await controller.startAdventure('forest_1');
    final active = controller.state!.adventureRun!;
    await expectLater(controller.startAdventure('forest_1'), throwsStateError);
    await expectLater(controller.finishAdventure(active.id), throwsStateError);
    await expectLater(controller.startFocus(1), throwsStateError);
    await expectLater(controller.selectCharacter('starter'), throwsStateError);
    await expectLater(controller.equip('wooden_sword'), throwsStateError);
    controller.dispose();
  });
  test(
      'restart, failed save, retry and repeated victory cannot duplicate first rewards',
      () async {
    var now = DateTime(2026, 10, 10);
    final repo = MemoryRepository();
    var controller = GameController(repo, clock: () => now, random: Random(3));
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await controller.startAdventure('forest_1');
    final snapshot = controller.state!.adventureRun!;
    repo.state = PlayerState.fromJson(repo.state.toJson());
    controller.dispose();
    controller = GameController(repo, clock: () => now);
    await controller.load();
    expect(controller.state!.adventureRun!.toJson(), snapshot.toJson());
    now = now.add(AdventureBattle.simulate(snapshot).duration);
    repo.fail = true;
    await expectLater(
        controller.finishAdventure(snapshot.id), throwsStateError);
    expect(controller.state!.adventureRun, isNotNull);
    expect(controller.state!.coins, 0);
    repo.fail = false;
    expect((await controller.finishAdventure(snapshot.id)).won, isTrue);
    await controller.finishAdventure(snapshot.id);
    expect(controller.state!.coins, 100);
    expect(controller.state!.inventory['wooden_sword'], 1);
    expect(controller.state!.activeCharacter!.level, 1);
    expect(controller.state!.activeCharacter!.currentExp, 0);
    expect(
        AdventureCatalog.unlocked('forest_2', controller.state!.clearedStages),
        isTrue);
    await controller.startAdventure('forest_1');
    final repeated = controller.state!.adventureRun!;
    now = now.add(AdventureBattle.simulate(repeated).duration);
    final result = await controller.finishAdventure(repeated.id);
    expect(result.coins, 0);
    expect(result.item, isNull);
    expect(controller.state!.coins, 100);
    expect(controller.state!.inventory['wooden_sword'], 1);
    controller.dispose();
  });
  test(
      'defeat preserves possessions, locks next stage and permits retry at full HP',
      () async {
    var now = DateTime(2026, 10, 10);
    final repo = MemoryRepository();
    final hero = Character(
        id: 'hero',
        name: 'アオイ',
        characterType: 'warrior',
        baseStats: const Stats(hp: 1, attack: 1, defense: 0, speed: 1));
    repo.state = PlayerState(
        uid: 'local-player',
        activeCharacterId: hero.id,
        characters: {hero.id: hero},
        coins: 60,
        inventory: {'cloth_armor': 1});
    final controller = GameController(repo, clock: () => now);
    await controller.load();
    await controller.startAdventure('forest_1');
    final active = controller.state!.adventureRun!;
    now = now.add(AdventureBattle.simulate(active).duration);
    expect((await controller.finishAdventure(active.id)).won, isFalse);
    expect(controller.state!.coins, 60);
    expect(controller.state!.inventory, {'cloth_armor': 1});
    expect(controller.state!.clearedStages, isEmpty);
    await controller.startAdventure('forest_1');
    expect(controller.state!.adventureRun!.stats.hp, 1);
    controller.dispose();
  });
}

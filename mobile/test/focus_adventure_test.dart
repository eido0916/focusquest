import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:focusquest/features/focus/domain/focus_adventure.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/enemy_motion_assets.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'boss appears at 25 minutes, survives attacks, dies at 30; ship boss at 55',
      () {
    final b = BattleStateController(
        durationSeconds: 3600,
        adventureStartSeconds: 0,
        config: const RunnerConfig(
            normalDamage: 10000, sousenDamageMultiplier: 100));
    b.advanceTo(1499.95);
    expect(b.enemies.where((e) => e.data.isBoss), isEmpty);
    b.advanceTo(1500);
    expect(b.enemies.single.data.id, 'boss_goblin_king');
    expect(b.isBossBattle, isTrue);
    b.advanceTo(1799.95);
    expect(b.enemies.single.hp, 1);
    expect(b.bossDefeatedCount, 0);
    b.advanceTo(1800);
    expect(b.bossDefeatedCount, 1);
    expect(FocusAdventure.chapter(b.adventureSeconds), 2);
    expect(b.enemies.first.hp, 0);
    b.advanceTo(3300);
    expect(
        b.enemies.where((e) => e.data.isBoss).single.data.id, 'boss_dullahan');
    b.advanceTo(3600);
    expect(b.bossDefeatedCount, 2);
    expect(b.phase, BattlePhase.finished);
    b.advanceTo(4000);
    expect(b.bossDefeatedCount, 2);
  });
  test('bounded replay and reopening a session preserve the local cycle', () {
    final full =
        BattleStateController(durationSeconds: 1800, adventureStartSeconds: 0)
          ..advanceTo(1800);
    final bounded =
        BattleStateController(durationSeconds: 1800, adventureStartSeconds: 0);
    while (bounded.elapsedSeconds < 1800) {
      bounded.advanceTo(1800, maxTicks: 120);
    }
    expect(bounded.defeatedCount, full.defeatedCount);
    expect(bounded.bossDefeatedCount, full.bossDefeatedCount);
    final resumed = BattleStateController(
        durationSeconds: 1800, adventureStartSeconds: 1500);
    resumed.advanceTo(1499.95);
    expect(resumed.enemies.where((e) => e.data.isBoss), isEmpty);
    resumed.advanceTo(1500);
    expect(resumed.isBossBattle, isTrue);
    resumed.advanceTo(1800);
    expect(resumed.bossDefeatedCount, 1);
    final short =
        BattleStateController(durationSeconds: 300, adventureStartSeconds: 1500)
          ..advanceTo(300);
    expect(short.bossDefeatedCount, 0);
    expect(short.enemies.where((e) => e.data.isBoss), isEmpty);
  });
  test(
      'successful sessions persist the clock and settle once; cancellation does not advance',
      () async {
    var now = DateTime(2026, 10, 11);
    final repo = MemoryRepository();
    final controller = GameController(repo, clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await controller.startFocus(25);
    now = now.add(const Duration(minutes: 25));
    await controller.finishFocus();
    expect(controller.state!.focusAdventureSeconds, 1500);
    await controller.finishFocus();
    expect(controller.state!.focusAdventureSeconds, 1500);
    final saved = PlayerState.fromJson(controller.state!.toJson());
    expect(saved.focusAdventureSeconds, 1500);
    await controller.startFocus(5);
    expect(controller.activeFocus!.adventureStartSeconds, 1500);
    expect(
        FocusSession.fromJson(controller.activeFocus!.toJson())
            .adventureStartSeconds,
        1500);
    now = now.add(const Duration(minutes: 5));
    await controller.finishFocus();
    expect(controller.state!.focusAdventureSeconds, 1800);
    await controller.startFocus(30);
    await controller.finishFocus(cancel: true);
    expect(controller.state!.focusAdventureSeconds, 1800);
    final legacy = saved.toJson()..remove('focusAdventureSeconds');
    expect(PlayerState.fromJson(legacy).focusAdventureSeconds, 0);
  });
  test('bosses load original movement, attack and transparent defeat frames',
      () async {
    final assets = await EnemyMotionAssets.load(FlameGame());
    for (final id in PlayableStageCatalog.bossIds) {
      for (final action in ['locomotion', 'attack', 'defeat']) {
        final motion = assets.motions['${id}_$action']!;
        expect(motion.metadata['interpolation'], 'none');
        expect(motion.metadata['direction'], 'left');
        expect(motion.frame(0).image.width,
            (motion.metadata['canvas'] as List).first);
      }
      final defeat = assets.motions['${id}_defeat']!;
      final rgba = await defeat.frame(defeat.duration).image.toByteData();
      expect(rgba!.buffer.asUint8List().every((v) => v == 0), isTrue);
    }
  });
}

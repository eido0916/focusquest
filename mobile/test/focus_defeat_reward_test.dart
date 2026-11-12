import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/certificate/focus_defeat_counter.dart';
import 'package:focusquest/features/character/domain/progression_service.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';
import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each defeat changes EXP; time without a defeat does not', () {
    final battle = BattleStateController(durationSeconds: 60);
    var defeats = 0;
    var exp = 0;
    for (var tick = 1; tick <= 1200; tick++) {
      battle.advanceTo(tick * .05);
      expect(battle.gainedExp - exp, battle.defeatedCount - defeats);
      defeats = battle.defeatedCount;
      exp = battle.gainedExp;
    }
    expect(defeats, greaterThan(0));
  });

  test('offline rewards match visible kills and are saved exactly once',
      () async {
    var now = DateTime(2026, 10, 29);
    final controller = GameController(MemoryRepository(), clock: () => now);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    final hero = controller.state!.activeCharacter!;
    await controller.startFocus(30);
    final session = controller.activeFocus!;
    final visible = BattleStateController(
        durationSeconds: 1800,
        adventureStartSeconds: session.adventureStartSeconds,
        focusAreaIndex: session.focusAreaIndex,
        config:
            PixelBattleAssets.runnerConfig(hero.characterType, hero.appearance))
      ..advanceTo(1800);
    now = now.add(const Duration(minutes: 30));
    final replay = await FocusDefeatCounter.result(session, hero, now);
    expect(replay.gainedExp, visible.gainedExp);
    expect(replay.bossDefeatedCount, 1);
    final finished = (await controller.finishFocus())!;
    final expected = ProgressionService().addExp(hero, visible.gainedExp);
    expect(finished.earnedExp, visible.gainedExp);
    expect(controller.state!.activeCharacter!.level, expected.level);
    expect(controller.state!.activeCharacter!.currentExp, expected.currentExp);
    final saved = PlayerState.fromJson(controller.state!.toJson());
    expect(saved.sessions[session.id]!.earnedExp, visible.gainedExp);
    await controller.finishFocus();
    expect(controller.state!.toJson(), saved.toJson());
    final legacy = session.toJson()..remove('earnedExp');
    expect(FocusSession.fromJson(legacy).earnedExp, 0);
  });
}

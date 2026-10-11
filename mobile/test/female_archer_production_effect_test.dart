import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/archer_wind_arrow_component.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/female_battle_assets.dart';
import 'package:focusquest/game/runner/female_battle_hero_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('production archer holds startup at bow and enlarges effect',
      (tester) async {
    final game = FlameGame();
    late FemaleBattleAssets assets;
    await tester.runAsync(() async {
      assets = await FemaleBattleAssets.load(game, 'ranger');
    });
    final state = BattleStateController(
        config: FemaleBattleAssets.runnerConfig('ranger'),
        durationSeconds: 120);
    final hero = FemaleBattleHeroComponent(state, assets);
    await tester.runAsync(() async {
      game.onGameResize(Vector2(960, 540));
      // ignore: invalid_use_of_internal_member
      await Future<void>.sync(game.load);
      await game.add(hero);
    });
    await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
    game.pauseEngine();
    await tester.pump();
    game.update(0);
    expect(FemaleBattleAssets.duration(assets.attack), closeTo(64 / 24, 1e-7));
    expect(FemaleBattleAssets.duration(assets.run), closeTo(.5, 1e-7));
    state.advanceTo(10);
    state.advanceTo(10 + 27 / 24);
    game.update(0);
    await tester.pump();
    game.update(0);
    final wind = game.children.whereType<ArcherWindArrowComponent>().single;
    final muzzle =
        hero.position + assets.archerSkill!.muzzleOffset * hero.displayScale;
    expect(wind.size.x, closeTo(318 * .45, 1e-7));
    expect(wind.position.x, closeTo(muzzle.x + 80 * .45, 1e-5));
    expect(wind.position.y, closeTo(muzzle.y, 1e-7));
    wind.update(.1);
    expect(wind.frameIndex, 0);
    expect(wind.position.x, closeTo(muzzle.x + 36, 1e-5));
    wind.update(.20);
    expect(wind.frameIndex, 1);
    expect(wind.position.x, greaterThan(muzzle.x + 36));
    wind.update(2);
    await tester.pump();
    game.update(0);
    expect(game.children.whereType<ArcherWindArrowComponent>(), isEmpty);
    await tester.pumpWidget(const SizedBox());
  });
}

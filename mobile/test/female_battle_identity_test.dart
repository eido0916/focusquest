import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/game/runner/female_battle_assets.dart';
import 'package:focusquest/game/runner/pixel_battle_hero_component.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';
import 'package:focusquest/game/runner/hero_component.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';
import 'support/memory_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Cached bundle/image futures from a previous widget test belong to its
  // fake async clock. Start each route with fresh loads, as replay tests do.
  setUp(() {
    rootBundle.clear();
    Flame.images.clearCache();
  });
  for (final type in ['warrior', 'ranger', 'onmyoji', 'berserker']) {
    if (type == 'warrior' || type == 'ranger') {
      test('$type female originals match combat timing and frame selection',
          () async {
        final assets = await FemaleBattleAssets.load(FlameGame(), type);
        final config = FemaleBattleAssets.runnerConfig(type);
        expect(FemaleBattleAssets.duration(assets.attack),
            closeTo(config.normalAttackDuration, 1e-7));
        expect(FemaleBattleAssets.duration(assets.skill),
            closeTo(config.sousenDurationSeconds, 1e-7));
        for (final animation in [assets.run, assets.attack, assets.skill]) {
          var age = 0.0;
          for (final frame in animation.frames) {
            expect(
                FemaleBattleAssets.poseAt(animation, age), same(frame.sprite));
            age += frame.stepTime;
          }
        }
      });
    }

    testWidgets('$type female focus passes gender through the real start route',
        (tester) async {
      final now = DateTime(2026, 10, 10);
      final controller = GameController(MemoryRepository(), clock: () => now);
      await controller.load();
      await controller.onboard(
          GameCatalog.types.values.firstWhere((t) => t.typeId == type),
          appearance: 'female');
      await tester.pumpWidget(FocusQuestApp(controller: controller));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('集中をはじめる'));
      await tester.tap(find.text('集中をはじめる'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('集中を開始'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('集中を開始'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final game = tester
          .widget<GameWidget>(find.byWidgetPredicate((w) => w is GameWidget))
          .game as FocusQuestBattleGame;
      expect(game.appearance, 'female');
      expect(game.characterType, type);
      var ready = false;
      game.loaded.then((_) async {
        await game.heroLoaded;
        ready = true;
      });
      for (var i = 0; i < 600 && !ready; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        await tester.pump();
      }
      expect(ready, isTrue);
      game.update(0);
      await tester.pump();
      expect(
          game.children
              .whereType<PixelBattleHeroComponent>()
              .single
              .assets
              .character
              .id,
          PixelBattleAssets.characterFor(type, 'female').id);
      expect(game.children.whereType<HeroComponent>(), isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    });
  }
}

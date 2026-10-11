import 'dart:async';
import 'dart:math' as math;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'background_component.dart';
import 'fantasy_battle_hud.dart';
import 'battle_state_controller.dart';
import 'hero_component.dart';
import 'swordsman_run_attack_assets.dart';
import 'swordsman_sousen_assets.dart';
import 'enemy_spawner.dart';
import 'enemy_motion_assets.dart';
import 'run_slash_assets.dart';
import 'boxer_run_attack_assets.dart';
import 'boxer_hero_component.dart';
import 'boxer_front_kick_assets.dart';
import 'female_battle_assets.dart';
import 'female_battle_hero_component.dart';

class FocusQuestBattleGame extends FlameGame {
  FocusQuestBattleGame(
      {required this.state,
      required this.elapsed,
      required this.onFinished,
      this.heroLevel = 1,
      this.characterType = 'warrior',
      this.appearance = 'male',
      this.jobName = '戦士',
      this.levelLogoAsset = BattleUiAssets.levelLogo});
  final BattleStateController state;
  final int heroLevel;
  final String characterType, appearance;
  final String jobName;
  final String? levelLogoAsset;
  FantasyBattleHud? hud;
  final double Function() elapsed;
  final ValueChanged<BattleResultData> onFinished;
  bool _reported = false;
  Future<void>? heroLoaded;
  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    final scenery = await images.load('ui/forest_meadow_battlefield.png');
    hud = FantasyBattleHud(
        window: await images.load(BattleUiAssets.window),
        orb: await images.load(BattleUiAssets.skillOrb),
        logo:
            levelLogoAsset == null ? null : await images.load(levelLogoAsset!));
    final enemyAssets = await EnemyMotionAssets.load(this);
    await addAll([
      BackgroundComponent(state, image: scenery),
      EnemySpawner(state, enemyAssets),
    ]);
    // Image decoding can take more than one frame on a physical device. Keep
    // the battle clock responsive while the visual asset finishes loading.
    heroLoaded = _loadHero();
    unawaited(heroLoaded!);
  }

  Future<void> _loadHero() async {
    if (FemaleBattleAssets.supports(characterType, appearance)) {
      await add(FemaleBattleHeroComponent(
          state, await FemaleBattleAssets.load(this, characterType)));
      return;
    }
    if (state.config.normalAttackStyle == NormalAttackStyle.boxer) {
      await add(BoxerHeroComponent(state, await BoxerRunAttackAssets.load(this),
          skillAssets: await BoxerFrontKickAssets.load(this)));
      return;
    }
    final assets = await Future.wait([
      SwordsmanRunAttackAssets.load(this),
      SwordsmanSousenAssets.load(this),
      RunSlashAssets.load(this),
    ]);
    await add(
      HeroComponent(
        state,
        assets[0] as SwordsmanRunAttackAssets,
        assets[1] as SwordsmanSousenAssets,
        assets[2] as RunSlashAssets,
      ),
    );
  }

  @override
  void update(double dt) {
    state.advanceTo(elapsed(), maxTicks: 120);
    super.update(dt);
    if (!_reported && state.phase == BattlePhase.finished) {
      _reported = true;
      onFinished(state.result);
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.scale(size.x / 960, size.y / 540);
    canvas.save();
    if (state.attackAge < .08) {
      canvas.translate(math.sin(state.attackAge * 150) * 1.5, 0);
    }
    super.render(canvas);
    canvas.restore();
    hud?.paint(canvas, state, heroLevel, jobName);
    canvas.restore();
  }
}

import '../../features/focus/domain/focus_adventure.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:flame/cache.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'background_component.dart';
import 'fantasy_battle_hud.dart';
import 'battle_state_controller.dart';
import 'pixel_battle_assets.dart';
import 'pixel_battle_hero_component.dart';
import 'enemy_spawner.dart';
import 'enemy_motion_assets.dart';
import '../../features/focus/presentation/focus_audio.dart';

class FocusQuestBattleGame extends FlameGame {
  FocusQuestBattleGame(
      {required this.state,
      required this.elapsed,
      required this.onFinished,
      this.onAudioFrame,
      this.heroLevel = 1,
      this.characterType = 'warrior',
      this.appearance = 'male',
      this.jobName = '戦士',
      this.heroName,
      this.levelLogoAsset = BattleUiAssets.levelLogo}) {
    // Keep large effect textures local to this battle instead of retaining
    // every role's textures and pending loads in Flame's global cache.
    images = Images();
  }
  final void Function(double time,
      {required bool boss,
      required bool active,
      required List<FocusSoundPose> poses})? onAudioFrame;
  PixelBattleAssets? _audioAssets;
  final BattleStateController state;
  final int heroLevel;
  final String characterType, appearance;
  final String jobName;
  final String? heroName;
  final String? levelLogoAsset;
  String get heroAvatarAsset =>
      levelLogoAsset ?? BattleUiAssets.avatar(characterType, appearance);
  FantasyBattleHud? hud;
  final double Function() elapsed;
  final ValueChanged<BattleResultData> onFinished;
  bool _reported = false;
  double _finishDelay = 0;
  Future<void>? heroLoaded;
  @override
  Color backgroundColor() => Colors.transparent;
  @override
  Future<void> onLoad() async {
    final scenery = await images.load(FocusAdventure.background(
        state.adventureSeconds,
        areaIndex: state.focusAreaIndex));
    hud = FantasyBattleHud(
        window: await images.load(BattleUiAssets.window),
        orb: await images.load(BattleUiAssets.skillOrb),
        logo: await images.load(heroAvatarAsset),
        avatarFrame: await images.load(BattleUiAssets.avatarFrame));
    final ghostShip =
        await images.load('stage_backgrounds/ghost_ship_focus_v002.png');
    final enemyAssets = await EnemyMotionAssets.load(this,
        ids: EnemyMotionAssets.idsForArea(state.focusAreaIndex));
    await addAll([
      BackgroundComponent(state, image: scenery, ghostShip: ghostShip),
      EnemySpawner(state, enemyAssets),
    ]);
    // Image decoding can take more than one frame on a physical device. Keep
    // the battle clock responsive while the visual asset finishes loading.
    heroLoaded = _loadHero();
    unawaited(heroLoaded!);
  }

  Future<void> _loadHero() async {
    final assets =
        await PixelBattleAssets.load(this, characterType, appearance);
    _audioAssets = assets;
    await add(PixelBattleHeroComponent(state, assets));
  }

  @override
  void update(double dt) {
    state.advanceTo(elapsed(), maxTicks: 120);
    super.update(dt);
    final assets = _audioAssets;
    final skill = state.isSkillPlaying;
    final action = skill ? 'skill' : 'attack';
    final motion = assets?.motions[action];
    final duration =
        skill ? state.activeSkillDuration : state.config.normalAttackDuration;
    final times = motion == null
        ? <double>[]
        : focusSoundTimes(
            motion.metadata,
            skill
                ? assets!.character.skillEvent
                : assets!.character.attackEvent,
            playbackDuration: duration);
    onAudioFrame?.call(state.elapsedSeconds,
        boss: state.isBossBattle,
        active: elapsed() >= 0 && state.phase != BattlePhase.finished,
        poses: assets == null || (!skill && !state.isNormalAttackPlaying)
            ? []
            : [
                FocusSoundPose(
                    'hero',
                    characterType,
                    skill ? state.skillSerial : state.attackSerial,
                    skill,
                    skill ? state.skillAge : state.attackAge,
                    times),
              ]);
    if (state.phase == BattlePhase.finished) _finishDelay += dt;
    final finalBossDefeat =
        state.enemies.any((e) => e.data.isBoss && e.hp == 0);
    if (!_reported &&
        state.phase == BattlePhase.finished &&
        (!finalBossDefeat || _finishDelay >= 1.3)) {
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
    hud?.paint(canvas, state, heroLevel, jobName, name: heroName);
    canvas.restore();
  }
}

import 'dart:async';
import '../../../core/game_controller.dart';
import 'focus_audio.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/runner/battle_state_controller.dart';
import '../../../game/runner/background_component.dart';
import '../../../game/runner/focus_quest_battle_game.dart';
import '../../../game/runner/fantasy_battle_hud.dart';
import '../../../game/runner/pixel_battle_assets.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../domain/focus_session.dart';

class BattleReplayPage extends StatefulWidget {
  const BattleReplayPage(
      {super.key,
      this.controller,
      required this.session,
      required this.clock,
      this.characterType = 'warrior',
      this.appearance = 'male',
      this.heroLevel = 1,
      this.characterName = '冒険者',
      this.levelLogoAsset = BattleUiAssets.levelLogo});
  final GameController? controller;
  final String characterType;
  final String appearance;
  final int heroLevel;
  final String characterName;
  final String? levelLogoAsset;
  final FocusSession session;
  final DateTime Function() clock;
  @override
  State<BattleReplayPage> createState() => _BattleReplayPageState();
}

class _BattleReplayPageState extends State<BattleReplayPage> {
  late final FocusQuestBattleGame _game;
  late final FocusAudio _audio;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _audio = FocusAudio(controller: widget.controller);
    _game = FocusQuestBattleGame(
        onAudioFrame: _audio.update,
        characterType: widget.characterType,
        appearance: widget.appearance,
        heroLevel: widget.heroLevel,
        heroName: widget.characterName,
        jobName: JobPortrait.roleNames[widget.characterType] ?? '戦士',
        levelLogoAsset:
            widget.levelLogoAsset ?? 'role_logos/${widget.characterType}.png',
        state: BattleStateController(
            adventureStartSeconds: widget.session.adventureStartSeconds,
            focusAreaIndex: widget.session.focusAreaIndex,
            config: PixelBattleAssets.runnerConfig(
                widget.characterType, widget.appearance),
            durationSeconds: widget.session.durationMinutes * 60.0),
        elapsed: () =>
            widget.session
                .focusNow(widget.clock())
                .difference(widget.session.startedAt)
                .inMilliseconds /
            1000,
        onFinished: (result) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_returned) {
              _returned = true;
              Navigator.of(context).pop(result);
            }
          });
        });
  }

  @override
  void dispose() {
    _game.pauseEngine();
    unawaited(_audio.close());
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(child: LayoutBuilder(builder: (context, constraints) {
        // Android tablets may ignore orientation locks. Rotate the surface as a fallback.
        final portrait = constraints.maxHeight > constraints.maxWidth;
        return RotatedBox(
          quarterTurns: portrait ? 1 : 0,
          child: Center(
              child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: LayoutBuilder(builder: (context, surface) {
                    final unit = surface.maxWidth / 960;
                    return Stack(fit: StackFit.expand, children: [
                      Image.asset('assets/images/${BackgroundComponent.asset}',
                          fit: BoxFit.cover, filterQuality: FilterQuality.none),
                      GameWidget(game: _game),
                      if (widget.controller != null)
                        Positioned(
                            right: 185 * unit,
                            top: 0,
                            child: IconButton(
                                tooltip: 'サウンド設定',
                                icon: const Icon(Icons.volume_up,
                                    color: Colors.white),
                                onPressed: () => showFocusSoundSettings(
                                    context, widget.controller!))),
                      Positioned(
                          left: FantasyBattleHud.menuRect.left * unit,
                          top: FantasyBattleHud.menuRect.top * unit,
                          width: FantasyBattleHud.menuRect.width * unit,
                          height: FantasyBattleHud.menuRect.height * unit,
                          child: TextButton(
                              key: const Key('focus-battle-menu'),
                              style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16 * unit),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap),
                              onPressed: () {
                                if (!_returned) {
                                  _returned = true;
                                  Navigator.pop(context, _game.state.result);
                                }
                              },
                              child: const FittedBox(
                                  child: Row(children: [
                                Icon(Icons.undo_rounded,
                                    color: FantasyBattleHud.gold, size: 25),
                                SizedBox(width: 7),
                                Text('タイマーに戻る',
                                    style: TextStyle(
                                        fontFamily: 'SunlitSerif',
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                              ])))),
                    ]);
                  }))),
        );
      })));
}

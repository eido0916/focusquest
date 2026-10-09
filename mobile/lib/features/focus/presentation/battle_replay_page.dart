import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game/runner/battle_state_controller.dart';
import '../../../game/runner/focus_quest_battle_game.dart';
import '../domain/focus_session.dart';

class BattleReplayPage extends StatefulWidget {
  const BattleReplayPage(
      {super.key, required this.session, required this.clock});
  final FocusSession session;
  final DateTime Function() clock;
  @override
  State<BattleReplayPage> createState() => _BattleReplayPageState();
}

class _BattleReplayPageState extends State<BattleReplayPage> {
  late final FocusQuestBattleGame _game;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(
        [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    _game = FocusQuestBattleGame(
        state: BattleStateController(
            durationSeconds: widget.session.durationMinutes * 60.0),
        elapsed: () =>
            widget.clock().difference(widget.session.startedAt).inMilliseconds /
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
            child: Stack(children: [
              Center(
                  child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Stack(fit: StackFit.expand, children: [
                        Image.asset('assets/images/ui/sunlit_battlefield.png',
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high),
                        GameWidget(game: _game),
                      ]))),
              Positioned(
                  right: 12,
                  top: 8,
                  child: TextButton(
                      style: TextButton.styleFrom(
                          backgroundColor: const Color(0xcc102b43),
                          foregroundColor: Colors.white),
                      onPressed: () {
                        if (!_returned) {
                          _returned = true;
                          Navigator.pop(context, _game.state.result);
                        }
                      },
                      child: const Text('タイマーに戻る'))),
            ]));
      })));
}

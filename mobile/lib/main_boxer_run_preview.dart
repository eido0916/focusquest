import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'game/runner/battle_state_controller.dart';
import 'game/runner/focus_quest_battle_game.dart';

/// Non-persistent preview: uses the production battle and supplied boxer run.
void main() => runApp(const MaterialApp(home: BoxerRunPreview()));

class BoxerRunPreview extends StatefulWidget {
  const BoxerRunPreview({super.key});
  @override
  State<BoxerRunPreview> createState() => _BoxerRunPreviewState();
}

class _BoxerRunPreviewState extends State<BoxerRunPreview> {
  final clock = Stopwatch()..start();
  late final state = BattleStateController(
    config: const RunnerConfig(
      normalAttackStyle: NormalAttackStyle.boxer,
      autoSkill: SwordsmanSkill.frontKick,
      attackSeconds: 7,
      sousenCooldownSeconds: 10,
    ),
    durationSeconds: 3600,
  );
  late final game = FocusQuestBattleGame(
    state: state,
    elapsed: () => clock.elapsedMicroseconds / 1000000,
    onFinished: (_) {},
    characterType: 'fighter',
    jobName: '拳闘士',
  );

  @override
  void dispose() {
    clock.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff15241c),
        body: SafeArea(
            child: Center(
                child: AspectRatio(
          aspectRatio: 960 / 540,
          child: GameWidget(game: game),
        ))),
      );
}

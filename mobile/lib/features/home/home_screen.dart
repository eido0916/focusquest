import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import '../focus/domain/streak_service.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen(
      {super.key,
      required this.controller,
      required this.onFocus,
      required this.onNavigate});
  final GameController controller;
  final VoidCallback onFocus;
  final ValueChanged<int> onNavigate;
  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final hero = state.activeCharacter!;
    final summary =
        StreakService().summarize(state.sessions.values, controller.clock());
    return QuestStage(
      hud: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: QuestCard(
                caption: hero.name,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lv. ${hero.level}    ${hero.rarity}'),
                      const SizedBox(height: 8),
                      Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 5),
                      LinearProgressIndicator(
                          value: hero.currentExp / hero.requiredExp),
                    ]))),
        const SizedBox(width: 10),
        Expanded(
            child: QuestCard(
                caption: '森の小道',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('STAGE  ${state.stage}'),
                      const SizedBox(height: 8),
                      Text('${state.coins} ポイント'),
                      Text('冒険進行度  ${state.adventureProgress}',
                          style: const TextStyle(fontSize: 12)),
                    ]))),
      ]),
      figure: Align(
          alignment: const Alignment(-.35, .6),
          child:
              AdventurerFigure(type: 'hero.${hero.characterType}', size: 150)),
      commands: Column(children: [
        QuestCard(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('木々の間を、風が通り抜けていく。\n次の冒険に向けて、力をたくわえよう。',
              style: TextStyle(height: 1.7)),
          const SizedBox(height: 8),
          Text('今日 ${summary.todayMinutes}分　累計 ${summary.totalMinutes}分',
              style: const TextStyle(fontSize: 12, color: Color(0xffb5c8be))),
        ])),
        QuestCard(
            child: Column(children: [
          QuestCommand(
              label: controller.activeFocus == null ? '集中をはじめる' : '集中タイマーに戻る',
              onTap: onFocus),
          Row(children: [
            Expanded(
                child: QuestCommand(label: '旅に出る', onTap: () => onNavigate(1))),
            Expanded(
                child:
                    QuestCommand(label: 'そうびを整える', onTap: () => onNavigate(2))),
          ]),
        ])),
      ]),
    );
  }
}

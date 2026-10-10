import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/quest_widgets.dart';
import '../focus/domain/streak_service.dart';
import '../diagnosis/presentation/job_portrait.dart';

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
    return ListView(
        padding: const EdgeInsets.fromLTRB(14, 18, 14, 22),
        children: [
          Row(children: [
            Expanded(
                flex: 4,
                child: JobPortrait(
                    typeId: hero.characterType,
                    appearance: hero.appearance,
                    height: 280)),
            Expanded(
                flex: 6,
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                          child: QuestCard(
                        caption: '旅の記録',
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('陽光の王道',
                                  style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text('累計 ${summary.totalMinutes}分'),
                              Text('${state.coins} ポイント'),
                            ]),
                      )),
                      SizedBox(
                          child: QuestCard(
                        caption: hero.name,
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Lv. ${hero.level}　${hero.rarity}',
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Text(
                                  'EXP  ${hero.currentExp} / ${hero.requiredExp}',
                                  style: const TextStyle(fontSize: 12)),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                  value: hero.currentExp / hero.requiredExp),
                            ]),
                      )),
                    ])),
          ]),
          const QuestCard(
              parchment: true,
              child: Text(
                '木々の間を、風が通り抜けていく。\n集中するほど、仲間の旅は遠くへ続く。',
                style:
                    TextStyle(color: AppTheme.ink, height: 1.55, fontSize: 15),
              )),
          QuestCard(
              child: Row(children: [
            const Icon(Icons.hourglass_bottom_rounded, size: 30),
            const SizedBox(width: 12),
            Expanded(
                child:
                    _Metric(label: '今日の集中', value: '${summary.todayMinutes}分')),
            Container(width: 1, height: 44, color: AppTheme.gold),
            const SizedBox(width: 14),
            Expanded(
                child:
                    _Metric(label: '累計の集中', value: '${summary.totalMinutes}分')),
          ])),
          const SizedBox(height: 4),
          QuestActionButton(
            label: controller.activeFocus == null ? '集中をはじめる' : '集中へ戻る',
            icon: Icons.explore_rounded,
            onTap: onFocus,
          ),
          const SizedBox(height: 12),
          QuestActionButton(
            label: controller.state!.adventureRun == null ? '冒険に出発する' : '冒険へ戻る',
            icon: Icons.map_outlined,
            onTap: () => onNavigate(4),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: QuestActionButton(
                    label: '装備',
                    icon: Icons.shield_rounded,
                    compact: true,
                    onTap: () => onNavigate(1))),
            const SizedBox(width: 10),
            Expanded(
                child: QuestActionButton(
                    label: '召喚',
                    icon: Icons.diamond_rounded,
                    compact: true,
                    onTap: () => onNavigate(2))),
          ]),
        ]);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      ]);
}

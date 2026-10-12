import '../diagnosis/presentation/job_portrait.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/sunlit_widgets.dart';
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
    return LayoutBuilder(builder: (context, constraints) {
      final w = constraints.maxWidth;
      final scale = MediaQuery.textScalerOf(context).scale(1);
      final stageHeight = math.max(w * .79,
              math.min(w * 1.02, constraints.maxHeight - w * .87 - 64)) +
          math.max(0, scale - 1) * 130;
      return SingleChildScrollView(
          child: Column(children: [
        SizedBox(
            height: stageHeight,
            child: ClipRect(
                child: Stack(children: [
              Positioned(
                  top: 12,
                  left: w * .22,
                  right: w * .22,
                  child: const Row(children: [
                    Expanded(child: Divider(color: sunlitGold, thickness: .7)),
                    CompassEmblem(size: 25),
                    Expanded(child: Divider(color: sunlitGold, thickness: .7)),
                  ])),
              Positioned(
                  left: w * .015,
                  top: 38,
                  width: w * .70,
                  child: JobPortrait(
                      typeId: hero.characterType,
                      appearance: hero.appearance,
                      lobby: true,
                      height: stageHeight - 38)),
              Positioned(
                  left: w * .49,
                  right: w * .04,
                  bottom: 16,
                  child: SunlitFrame(
                      scenery: true,
                      padding: EdgeInsets.all(w * .033),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('旅の記録',
                                style: TextStyle(
                                    color: sunlitGold,
                                    fontFamily: 'SunlitSerif',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            Text('陽光の王道',
                                style: TextStyle(
                                    fontFamily: 'SunlitSerif',
                                    fontSize: w * .041,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 10),
                            Text('累計 ${summary.totalMinutes}分',
                                style: const TextStyle(
                                    fontFamily: 'SunlitSerif', fontSize: 12)),
                            Text('${state.coins} ポイント',
                                style: const TextStyle(
                                    fontFamily: 'SunlitSerif', fontSize: 13)),
                            const Divider(
                                color: sunlitGold, height: 22, thickness: .6),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.shield_outlined,
                                      color: sunlitGold, size: 32),
                                  const SizedBox(width: 7),
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                        Text(hero.name,
                                            style: const TextStyle(
                                                color: sunlitGold,
                                                fontFamily: 'SunlitSerif',
                                                fontSize: 12)),
                                        Text('Lv. ${hero.level}',
                                            style: TextStyle(
                                                fontFamily: 'SunlitSerif',
                                                fontSize: w * .043,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 6),
                                        Text(
                                            'EXP ${hero.currentExp} / ${hero.requiredExp}',
                                            style: const TextStyle(
                                                fontFamily: 'SunlitSerif',
                                                fontSize: 10)),
                                        const SizedBox(height: 4),
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            child: LinearProgressIndicator(
                                                minHeight: 7,
                                                value: (hero.currentExp /
                                                        hero.requiredExp)
                                                    .clamp(0.0, 1.0),
                                                color: const Color(0xff42cdf5),
                                                backgroundColor:
                                                    const Color(0xff224762))),
                                      ])),
                                ]),
                          ]))),
            ]))),
        Padding(
            padding: EdgeInsets.fromLTRB(w * .04, 0, w * .04, 14),
            child: Column(children: [
              SunlitFrame(
                  light: true,
                  scenery: true,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                  child: Row(children: [
                    const Icon(Icons.history_edu,
                        color: Color(0xffb89a61), size: 27),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text('木々の間を、風が通り抜けていく。\n集中するほど、仲間の旅は遠くへ続く。',
                            style: TextStyle(
                                fontFamily: 'SunlitSerif',
                                color: const Color(0xff302517),
                                fontSize: w * .0325,
                                fontWeight: FontWeight.w600,
                                height: 1.7))),
                  ])),
              const SizedBox(height: 10),
              SunlitFrame(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  child: Row(children: [
                    Expanded(
                        child: _Metric(
                            icon: Icons.hourglass_bottom_rounded,
                            label: '今日の集中',
                            value: '${summary.todayMinutes}分',
                            width: w)),
                    Container(width: .7, height: 38, color: sunlitGold),
                    const SizedBox(width: 16),
                    Expanded(
                        child: _Metric(
                            icon: Icons.bar_chart_rounded,
                            label: '累計の集中',
                            value: '${summary.totalMinutes}分',
                            width: w)),
                  ])),
              const SizedBox(height: 12),
              SunlitAction(
                  label: controller.activeFocus == null ? '集中をはじめる' : '集中へ戻る',
                  onTap: onFocus),
              const SizedBox(height: 12),
              SunlitAction(
                  light: true, label: '冒険に出発する', onTap: () => onNavigate(2)),
            ])),
      ]));
    });
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.icon,
      required this.label,
      required this.value,
      required this.width});
  final IconData icon;
  final String label;
  final String value;
  final double width;
  @override
  Widget build(BuildContext context) => Row(children: [
        Icon(icon, color: sunlitGold, size: width * .075),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style:
                  TextStyle(fontFamily: 'SunlitSerif', fontSize: width * .029)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'SunlitSerif',
                  fontSize: width * .054,
                  height: 1.25,
                  fontWeight: FontWeight.bold)),
        ])),
      ]);
}

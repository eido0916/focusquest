import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/reference_game_art.dart';
import '../diagnosis/presentation/job_portrait.dart';
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
  Widget _identity(BuildContext context) {
    final hero = controller.state!.activeCharacter!;
    final role = JobPortrait.roleNames.containsKey(hero.characterType)
        ? hero.characterType
        : 'warrior';
    final sex = hero.appearance == 'female' ? 'female' : 'male';
    return ReferenceFrame(
        key: const Key('home-identity'),
        child: Row(children: [
          SizedBox(
              width: 56,
              height: 56,
              child: Stack(fit: StackFit.expand, children: [
                Padding(
                    padding: const EdgeInsets.all(3),
                    child: Image.asset(
                        'assets/images/focus_selection_v001/avatars/$sex/$role.png',
                        filterQuality: FilterQuality.none,
                        semanticLabel: '${JobPortrait.roleNames[role]}の顔')),
                Image.asset('$referenceArtPath/portrait_frame.png',
                    excludeFromSemantics: true)
              ])),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                LayoutBuilder(builder: (context, box) {
                  final name = Text(hero.name,
                      key: const Key('home-character-name'),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: referenceText(21));
                  final level = Text('Lv. ${hero.level}',
                      style: referenceText(21, color: referenceGold));
                  if (box.maxWidth < 280 &&
                      MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [name, level]);
                  }
                  return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: name),
                        const SizedBox(width: 12),
                        level
                      ]);
                }),
                Text(JobPortrait.roleNames[role]!, style: referenceText(14)),
                const SizedBox(height: 6),
                LayoutBuilder(builder: (context, box) {
                  final label = Text(
                      'EXP ${hero.currentExp} / ${hero.requiredExp}',
                      style: referenceText(12));
                  final gauge = ReferenceGauge(
                      value: hero.currentExp / hero.requiredExp,
                      fillKey: const Key('home-exp-fill'));
                  if (box.maxWidth < 260 ||
                      MediaQuery.textScalerOf(context).scale(1) > 1.2) {
                    return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [label, const SizedBox(height: 4), gauge]);
                  }
                  return Row(children: [
                    label,
                    const SizedBox(width: 8),
                    Expanded(child: gauge)
                  ]);
                })
              ]))
        ]));
  }

  @override
  Widget build(BuildContext context) {
    final hero = controller.state!.activeCharacter!;
    final summary = StreakService()
        .summarize(controller.state!.sessions.values, controller.clock());
    return ReferenceBackdrop(
        name: 'home_background',
        child: LayoutBuilder(builder: (context, box) {
          final width = math.min(box.maxWidth, 620.0);
          final textGrowth =
              math.max(0.0, MediaQuery.textScalerOf(context).scale(1) - 1);
          final heroHeight = (box.maxHeight - 350 - textGrowth * 160)
              .clamp(180.0, math.max(180.0, width * 1.08))
              .toDouble();
          return QuestScreenFit(
              key: const Key('home-scroll'),
              child: Center(
                  child: SizedBox(
                      width: width,
                      child: Padding(
                          padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Stack(clipBehavior: Clip.none, children: [
                                  Positioned.fill(
                                      child: OverflowBox(
                                          minWidth: width,
                                          maxWidth: width,
                                          child: Image.asset(
                                              '$referenceArtPath/home_stage.png',
                                              fit: BoxFit.cover,
                                              alignment: Alignment.bottomCenter,
                                              filterQuality: FilterQuality.none,
                                              excludeFromSemantics: true))),
                                  Column(children: [
                                    _identity(context),
                                    SizedBox(
                                        key: const Key('home-showcase'),
                                        height: heroHeight,
                                        child: Padding(
                                            padding:
                                                const EdgeInsets.only(top: 6),
                                            child: JobPortrait(
                                                typeId: hero.characterType,
                                                appearance: hero.appearance,
                                                lobby: true,
                                                height: heroHeight - 6,
                                                fit: BoxFit.contain,
                                                alignment:
                                                    Alignment.bottomCenter))),
                                  ]),
                                ]),
                                ReferenceFrame(
                                    asset: 'metrics_frame',
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18, vertical: 14),
                                    child: Row(children: [
                                      Expanded(
                                          child: _Metric('hourglass', '今日の集中',
                                              '${summary.todayMinutes}分')),
                                      Container(
                                          width: 1,
                                          height: 40,
                                          color:
                                              referenceGold.withOpacity(.65)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: _Metric('chart', '累計の集中',
                                              '${summary.totalMinutes}分'))
                                    ])),
                                const SizedBox(height: 8),
                                ReferenceAction(
                                    key: const Key('home-start-focus'),
                                    icon: 'compass',
                                    label: controller.activeFocus == null
                                        ? '集中をはじめる'
                                        : '集中へ戻る',
                                    onTap: onFocus),
                                const SizedBox(height: 8),
                                ReferenceAction(
                                    key: const Key('home-adventure'),
                                    icon: 'map',
                                    light: true,
                                    label: '冒険に出発する',
                                    onTap: () => onNavigate(2))
                              ])))));
        }));
  }
}

class _Metric extends StatelessWidget {
  const _Metric(this.icon, this.label, this.value);
  final String icon, label, value;
  @override
  Widget build(BuildContext context) => Row(children: [
        ReferenceIcon(icon, size: 28),
        const SizedBox(width: 10),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(label, style: referenceText(13)),
              Text(value, style: referenceText(25))
            ]))
      ]);
}

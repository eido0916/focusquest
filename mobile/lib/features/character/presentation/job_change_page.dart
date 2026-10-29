import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../../focus/domain/focus_task.dart';
import '../domain/job_progression.dart';

class JobChangePage extends StatelessWidget {
  const JobChangePage({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(title: const Text('成長パラメータ・ジョブチェンジ')),
      body: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final hero = controller.state!.activeCharacter!;
            final blocked = controller.busy ||
                controller.activeFocus != null ||
                controller.playableAdventureActive ||
                controller.party.connected;
            return ListView(padding: const EdgeInsets.all(20), children: [
              const Text('タスクの集中成功で分野ごとの力が育ちます。すべての必要値を満たすと転職できます。'),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 8, children: [
                for (final p in FocusTask.parameters.entries)
                  Chip(
                      label: Text(
                          '${p.value}  ${hero.trainingPoints[p.key] ?? 0}pt')),
              ]),
              const Text('転職後もレベル・経験値・成長ポイント・性別を引き継ぎます。解放した職業にはいつでも戻れます。'),
              if (blocked) const Text('集中・冒険・パーティーの終了後に転職できます。'),
              for (final type in GameCatalog.types.values)
                Card(
                    child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.job,
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              for (final req in JobProgression
                                  .requirements[type.typeId]!.entries)
                                Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              '${FocusTask.parameters[req.key]}  ${hero.trainingPoints[req.key] ?? 0} / ${req.value}pt'),
                                          LinearProgressIndicator(
                                              value: ((hero.trainingPoints[
                                                              req.key] ??
                                                          0) /
                                                      req.value)
                                                  .clamp(0.0, 1.0)),
                                        ])),
                              const SizedBox(height: 8),
                              FilledButton(
                                  onPressed: blocked ||
                                          hero.characterType == type.typeId ||
                                          !JobProgression.canChange(
                                              hero, type.typeId)
                                      ? null
                                      : () => runAction(context, () async {
                                            await controller
                                                .changeJob(type.typeId);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(SnackBar(
                                                      content: Text(
                                                          '${type.job}にジョブチェンジしました')));
                                            }
                                          }),
                                  child: Text(hero.characterType == type.typeId
                                      ? '現在の職業'
                                      : JobProgression.canChange(
                                              hero, type.typeId)
                                          ? 'ジョブチェンジ'
                                          : '条件未達成')),
                            ]))),
            ]);
          }));
}

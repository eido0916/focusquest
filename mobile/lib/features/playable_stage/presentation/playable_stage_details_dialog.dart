import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import '../domain/playable_stage_catalog.dart';

class PlayableStageDetailsDialog extends StatelessWidget {
  const PlayableStageDetailsDialog({
    super.key,
    required this.stage,
    required this.encounteredEnemyIds,
    this.cleared = false,
    this.canChallenge = true,
  });
  final PlayableStageDefinition stage;
  final Set<String> encounteredEnemyIds;
  final bool cleared, canChallenge;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 450;
    final enemies = <String, StageOpponent>{
      for (var phase = 0; phase < stage.opponents.length; phase++)
        for (final enemy in stage.wave(phase)) enemy.id: enemy,
    }.values;
    return Dialog(
        key: const Key('stage-details'),
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 520,
                maxHeight: MediaQuery.sizeOf(context).height - 80),
            child: SunlitFrame(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Row(children: [
                    Expanded(
                        child: Text('Stage ${stage.number}',
                            style: const TextStyle(
                                fontFamily: 'SunlitSerif',
                                fontSize: 26,
                                color: Color(0xffffe5b2),
                                fontWeight: FontWeight.bold))),
                    IconButton(
                        tooltip: '閉じる',
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close, color: sunlitGold)),
                  ]),
                  if (!compact)
                    Text(stage.area,
                        style: const TextStyle(color: Color(0xffd1dfee))),
                  if (cleared)
                    const Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text('✓ CLEAR',
                            style: TextStyle(color: Color(0xffb4e8ca)))),
                  const SizedBox(height: 12),
                  const Text('登場する敵',
                      style: TextStyle(color: sunlitGold, fontSize: 14)),
                  const SizedBox(height: 14),
                  Flexible(
                      child: SingleChildScrollView(
                          child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 12,
                              runSpacing: 14,
                              children: [
                        for (final enemy in enemies)
                          _enemyIcon(enemy, compact: compact),
                      ]))),
                  const SizedBox(height: 16),
                  Text('推奨レベル Lv.${stage.recommendedLevel}',
                      key: const Key('stage-recommended-level'),
                      style: const TextStyle(
                          color: sunlitGold,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          key: Key('challenge-stage-${stage.number}'),
                          style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xffe8cd85),
                              foregroundColor: sunlitInk,
                              minimumSize: const Size(0, 50)),
                          onPressed: canChallenge
                              ? () => Navigator.of(context).pop(true)
                              : null,
                          child: const Text('ステージに挑戦する',
                              style: TextStyle(fontFamily: 'SunlitSerif')))),
                ]))));
  }

  Widget _enemyIcon(StageOpponent enemy, {bool compact = false}) {
    final known = encounteredEnemyIds.contains(enemy.id);
    return Semantics(
        key: Key('stage-enemy-${enemy.id}'),
        label: known ? enemy.name : '未遭遇の敵',
        child: ExcludeSemantics(
            child: SizedBox(
                width: compact ? 88 : 112,
                child: Column(children: [
                  Container(
                      width: compact ? 64 : 100,
                      height: compact ? 64 : 100,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: const Color(0xff718294),
                          border: Border.all(color: sunlitGold),
                          borderRadius: BorderRadius.circular(8)),
                      child: Stack(alignment: Alignment.center, children: [
                        Image.asset(
                            'assets/images/playable_stage/${enemy.id}_locomotion_000.png',
                            filterQuality: FilterQuality.none,
                            fit: BoxFit.contain,
                            color: known ? null : Colors.black,
                            colorBlendMode: known ? null : BlendMode.srcIn),
                        if (!known)
                          const Text('?',
                              key: Key('unknown-enemy-mark'),
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(color: Colors.black, blurRadius: 3)
                                  ])),
                      ])),
                  const SizedBox(height: 7),
                  Text(known ? enemy.name : '未遭遇',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Color(0xffe2edf5), fontSize: 12)),
                ]))));
  }
}

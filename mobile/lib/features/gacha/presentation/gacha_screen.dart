import 'package:flutter/material.dart';
import '../../../core/config/game_balance.dart';
import '../../../core/game_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../domain/gacha_service.dart';

class GachaScreen extends StatefulWidget {
  const GachaScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<GachaScreen> createState() => _GachaScreenState();
}

class _GachaScreenState extends State<GachaScreen> {
  bool _revealing = false;
  GachaResult? _result;

  Future<void> _draw(int count) => runAction(context, () async {
        setState(() {
          _revealing = true;
          _result = null;
        });
        try {
          final result = await widget.controller.summon(count);
          await Future<void>.delayed(const Duration(milliseconds: 900));
          if (mounted) setState(() => _result = result);
        } finally {
          if (mounted) setState(() => _revealing = false);
        }
      });

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final state = controller.state!;
    return ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        children: [
          Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                decoration: BoxDecoration(
                    color: const Color(0xee082744),
                    border: Border.all(color: AppTheme.gold),
                    borderRadius: BorderRadius.circular(22)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.diamond_rounded, color: Color(0xff7ceaff)),
                  const SizedBox(width: 8),
                  Text('${state.coins}',
                      style: const TextStyle(
                          fontSize: 19, fontWeight: FontWeight.bold)),
                ]),
              )),
          const SizedBox(height: 8),
          SizedBox(
              height: 285,
              child: Stack(alignment: Alignment.center, children: [
                Container(
                    width: 245,
                    height: 245,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                          colors: _revealing
                              ? const [
                                  Colors.white,
                                  Color(0xff72eaff),
                                  Color(0x0067dfff)
                                ]
                              : const [
                                  Color(0xffaeefff),
                                  Color(0xff366bd8),
                                  Color(0x00112163)
                                ]),
                    )),
                AnimatedScale(
                    duration: const Duration(milliseconds: 500),
                    scale: _revealing ? 1.35 : 1,
                    child: const Icon(Icons.diamond_rounded,
                        size: 135, color: Colors.white)),
                const Positioned(
                    left: 18,
                    top: 52,
                    child: Icon(Icons.shield_rounded,
                        size: 82, color: AppTheme.gold)),
                const Positioned(
                    right: 18,
                    top: 55,
                    child: Icon(Icons.auto_fix_high_rounded,
                        size: 82, color: AppTheme.gold)),
                const Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: QuestCard(
                      child: Column(children: [
                        Text('光導の装備召喚',
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 24,
                                color: AppTheme.gold,
                                fontWeight: FontWeight.bold)),
                        Text('旅を照らす、英雄の装備たち'),
                      ]),
                    )),
              ])),
          QuestCard(
              caption: 'ピックアップ装備',
              child: SizedBox(
                  height: 108,
                  child: Row(children: [
                    for (final item in const [
                      (Icons.gavel_rounded, '聖剣'),
                      (Icons.shield_rounded, '天盾'),
                      (Icons.auto_fix_high_rounded, '星杖'),
                      (Icons.diamond_outlined, '指輪'),
                    ])
                      Expanded(
                          child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Color(0xff154f7c), Color(0xff071d34)]),
                            border: Border.all(color: AppTheme.gold)),
                        child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(item.$1, size: 38, color: AppTheme.gold),
                              const Text('★★★★★',
                                  style: TextStyle(
                                      fontSize: 9, color: AppTheme.gold)),
                              Text(item.$2,
                                  style: const TextStyle(fontSize: 11)),
                            ]),
                      )),
                  ]))),
          if (_result != null)
            QuestCard(
                caption: '召喚結果',
                child: Wrap(spacing: 8, runSpacing: 8, children: [
                  for (final prize in _result!.prizes)
                    Chip(
                        avatar: const Icon(Icons.auto_awesome, size: 17),
                        label: Text('${prize.rarity} ${prize.name}')),
                ])),
          Row(children: [
            Expanded(
                child: QuestActionButton(
              label: '1回召喚 • 100ポイント',
              icon: Icons.auto_awesome_rounded,
              compact: true,
              onTap: _revealing || controller.busy || state.coins < 100
                  ? null
                  : () => _draw(1),
            )),
            const SizedBox(width: 10),
            Expanded(
                child: QuestActionButton(
              label: '10回召喚 • 1000ポイント',
              icon: Icons.auto_awesome_rounded,
              compact: true,
              onTap: _revealing || controller.busy || state.coins < 1000
                  ? null
                  : () => _draw(10),
            )),
          ]),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.info_outline),
            label: const Text('召喚の記録・排出率'),
            onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                      title: const Text('召喚の記録・排出率'),
                      content: SizedBox(
                          width: 380,
                          child: ListView(shrinkWrap: true, children: [
                            Text(GameBalance.rarityWeights.entries
                                .map((e) => '${e.key} ${e.value}%')
                                .join(' / ')),
                            const Text('10回召喚の確定枠はありません。'),
                            const SizedBox(height: 16),
                            for (final entry
                                in state.gachaHistory.reversed.take(30))
                              Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: Text(
                                      '${(entry['prizes'] as List).map((p) => "${p['rarity']} ${p['name']}").join('、')}\n${entry['cost']}ポイント')),
                          ])),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('閉じる'))
                      ],
                    )),
          ),
        ]);
  }
}

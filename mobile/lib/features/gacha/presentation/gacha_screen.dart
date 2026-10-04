import 'package:flutter/material.dart';
import '../../../core/config/game_balance.dart';
import '../../../core/game_controller.dart';
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
    return QuestStage(
      hud: QuestCard(caption: '星灯りの祭壇', child: Text('所持 ${state.coins}ポイント')),
      figure: Container(
          width: 180,
          height: 180,
          decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xffd5b574), width: 2),
              gradient: const RadialGradient(
                  colors: [Color(0xaa60aa99), Color(0x00142e2b)])),
          child: Icon(_revealing ? Icons.auto_awesome : Icons.diamond_outlined,
              size: 78, color: const Color(0xffffe4a6))),
      commands: QuestCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(_revealing ? '祭壇に、光が集まっていく……。' : '星の光に願いを託そう。',
            style: const TextStyle(height: 1.7)),
        if (_result != null) ...[
          const Text('召喚結果', style: TextStyle(color: Color(0xffd5b574))),
          ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 100),
              child: SingleChildScrollView(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    for (final prize in _result!.prizes)
                      Text('${prize.rarity}　${prize.name}'),
                  ]))),
        ],
        QuestCommand(
            label: '1回召喚 • 100ポイント',
            onTap: _revealing || controller.busy || state.coins < 100
                ? null
                : () => _draw(1)),
        QuestCommand(
            label: '10回召喚 • 1000ポイント',
            onTap: _revealing || controller.busy || state.coins < 1000
                ? null
                : () => _draw(10)),
        QuestCommand(
            label: '召喚の記録・排出率',
            onTap: () => showDialog<void>(
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
                        ]))),
      ])),
    );
  }
}

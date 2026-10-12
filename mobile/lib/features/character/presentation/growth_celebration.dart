import 'package:flutter/material.dart';
import '../../../core/widgets/game_ui.dart';
import '../domain/character.dart';
import '../domain/progression_service.dart';
import '../../certificate/certificate_catalog.dart';

Future<void> showGrowthCelebration(
    BuildContext context, Character before, Character after) async {
  if (after.level <= before.level) return;
  final old = ProgressionService().stats(before, const {});
  final next = ProgressionService().stats(after, const {});
  final rows = [
    ('HP', old.hp, next.hp),
    ('攻撃力', old.attack, next.attack),
    ('防御力', old.defense, next.defense),
    ('素早さ', old.speed, next.speed),
    ('会心率', (old.criticalRate * 100).round(), (next.criticalRate * 100).round())
  ];
  await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: GamePanel(
                  asset: 'identity_panel',
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.auto_awesome, color: gameGold, size: 56),
                    const Text('LEVEL UP!',
                        style: TextStyle(
                            color: gameGold,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                    Text('Lv. ${before.level} → Lv. ${after.level}',
                        style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 20),
                    const Row(children: [
                      Expanded(child: Text('能力')),
                      Expanded(
                          child: Text('これまで', textAlign: TextAlign.center)),
                      Expanded(child: Text('成長後', textAlign: TextAlign.center))
                    ]),
                    for (final row in rows)
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(children: [
                            Expanded(child: Text(row.$1)),
                            Expanded(
                                child: Text(
                                    '${row.$2}${row.$1 == '会心率' ? '%' : ''}',
                                    textAlign: TextAlign.center)),
                            Expanded(
                                child: Text(
                                    '${row.$3}${row.$1 == '会心率' ? '%' : ''}${row.$3 > row.$2 ? ' (+${row.$3 - row.$2})' : ''}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: row.$3 > row.$2
                                            ? const Color(0xff80ed9c)
                                            : gameWhite,
                                        fontWeight: FontWeight.bold)))
                          ])),
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('成長した力で冒険へ')),
                  ]))))));
  final titles = CertificateCatalog.titles[after.characterType]!;
  for (var index = 1; index < titles.length; index++) {
    final level = CertificateCatalog.unlockLevel(index);
    if (before.level >= level || after.level < level || !context.mounted) {
      continue;
    }
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
            backgroundColor: Colors.transparent,
            child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: GamePanel(
                    asset: 'identity_panel',
                    child: SingleChildScrollView(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      const _TitleLight(),
                      const Text('新たな称号を獲得！',
                          style: TextStyle(color: gameGold, fontSize: 26)),
                      const SizedBox(height: 18),
                      Text(titles[index],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: gameGold,
                              fontSize: 34,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 14),
                      Text('Lv. $level 達成 — 冒険者としての新たな一歩'),
                      const Text('キャラクター画面の「称号変更」から選べます。',
                          textAlign: TextAlign.center),
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('冒険を続ける')),
                    ]))))));
  }
}

class _TitleLight extends StatefulWidget {
  const _TitleLight();
  @override
  State<_TitleLight> createState() => _TitleLightState();
}

class _TitleLightState extends State<_TitleLight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _light = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _light.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _light,
      builder: (context, _) => Container(
          margin: const EdgeInsets.all(20),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [
            BoxShadow(
                color: gameGold.withOpacity(.2 + _light.value * .35),
                blurRadius: 35 + _light.value * 20,
                spreadRadius: _light.value * 12)
          ]),
          child:
              const Icon(Icons.workspace_premium, color: gameGold, size: 80)));
}

import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../domain/progression_service.dart';
import '../../diagnosis/presentation/job_portrait.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key, required this.controller});
  final GameController controller;

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final hero = state.activeCharacter!;
    final stats = ProgressionService().stats(hero, GameCatalog.equipment);
    return ListView(
        padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
        children: [
          QuestCard(
              child: Row(children: [
            const Icon(Icons.person_rounded),
            const SizedBox(width: 10),
            const Text('キャラクター',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Spacer(),
            Text('${hero.rarity}  Lv.${hero.level}',
                style: const TextStyle(color: AppTheme.gold)),
          ])),
          Column(children: [
            JobPortrait(
                typeId: hero.characterType,
                appearance: hero.appearance,
                height: 320),
            QuestCard(
              caption: hero.name,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'Lv. ${hero.level}　${GameCatalog.types.values.firstWhere((type) => type.typeId == hero.characterType, orElse: () => GameCatalog.types[15]!).job}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                        style: const TextStyle(fontSize: 12)),
                    LinearProgressIndicator(
                        value: hero.currentExp / hero.requiredExp),
                    const Divider(),
                    for (final row in [
                      (Icons.favorite_rounded, 'HP', '${stats.hp}'),
                      (Icons.flash_on_rounded, '攻撃力', '${stats.attack}'),
                      (Icons.shield_rounded, '防御力', '${stats.defense}'),
                      (Icons.directions_run_rounded, '素早さ', '${stats.speed}'),
                      (
                        Icons.auto_awesome_rounded,
                        '会心率',
                        '${(stats.criticalRate * 100).round()}%'
                      ),
                    ])
                      Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(children: [
                            Icon(row.$1, size: 17, color: AppTheme.gold),
                            const SizedBox(width: 8),
                            Expanded(child: Text(row.$2)),
                            Text(row.$3,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                          ])),
                  ]),
            ),
          ]),
          QuestCard(
              caption: '装備',
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final slot in {
                      'weapon': '武器',
                      'armor': '防具',
                      'accessory': 'アクセサリー'
                    }.entries)
                      Container(
                        margin: const EdgeInsets.only(bottom: 7),
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                            color: const Color(0x80204464),
                            border: Border.all(color: const Color(0xff876e3b))),
                        child: Row(children: [
                          Icon(slot.key == 'weapon'
                              ? Icons.gavel_rounded
                              : slot.key == 'armor'
                                  ? Icons.shield_rounded
                                  : Icons.diamond_outlined),
                          const SizedBox(width: 12),
                          Expanded(child: Text(slot.value)),
                          Text(GameCatalog
                                  .equipment[hero.equippedItems[slot.key]]
                                  ?.item
                                  .name ??
                              '未装備'),
                        ]),
                      ),
                    const SizedBox(height: 6),
                    const Text('所持アイテム',
                        style: TextStyle(
                            color: AppTheme.gold, fontWeight: FontWeight.bold)),
                    if (state.inventory.isEmpty)
                      const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text('集中や召喚で装備を集めよう。')),
                    for (final entry in state.inventory.entries)
                      Row(children: [
                        Expanded(
                            child: Text(
                                '${GameCatalog.equipment[entry.key]?.item.name ?? entry.key}　×${entry.value}')),
                        TextButton(
                          onPressed: controller.busy
                              ? null
                              : () => runAction(
                                  context, () => controller.equip(entry.key)),
                          child: const Text('装備する'),
                        ),
                      ]),
                  ])),
          QuestCard(
              caption: '仲間',
              child: Column(children: [
                for (final character in state.characters.values)
                  Row(children: [
                    const CircleAvatar(
                        backgroundColor: Color(0xff174c78),
                        child: Icon(Icons.person_rounded)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text('${character.name}　Lv.${character.level}')),
                    if (character.id == hero.id)
                      const Text('編成中', style: TextStyle(color: AppTheme.gold))
                    else
                      TextButton(
                          onPressed: controller.busy
                              ? null
                              : () => runAction(
                                  context,
                                  () =>
                                      controller.selectCharacter(character.id)),
                          child: const Text('編成')),
                  ]),
              ])),
        ]);
  }
}

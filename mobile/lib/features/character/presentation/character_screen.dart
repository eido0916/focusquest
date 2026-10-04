import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../domain/progression_service.dart';

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final hero = state.activeCharacter!;
    final stats = ProgressionService().stats(hero, GameCatalog.equipment);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
            child: QuestCard(
                caption: 'つよさ',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(hero.name, style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 6),
                      Text('${hero.rarity}　Lv. ${hero.level}'),
                      const SizedBox(height: 14),
                      for (final entry in {
                        'HP': '${stats.hp}',
                        'こうげき': '${stats.attack}',
                        'しゅび': '${stats.defense}',
                        'すばやさ': '${stats.speed}',
                        '会心': '${(stats.criticalRate * 100).round()}%'
                      }.entries)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(children: [
                              Expanded(child: Text(entry.key)),
                              Text(entry.value),
                            ])),
                      const SizedBox(height: 10),
                      Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                          style: const TextStyle(fontSize: 12)),
                    ]))),
        Expanded(
            child: Padding(
                padding: const EdgeInsets.only(top: 36),
                child: AdventurerFigure(
                    type: 'hero.${hero.characterType}', size: 230))),
      ]),
      QuestCard(
          caption: 'そうび',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            for (final slot
                in {'weapon': 'ぶき', 'armor': 'よろい', 'accessory': 'かざり'}.entries)
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Text(
                      '${slot.value}　 ${GameCatalog.equipment[hero.equippedItems[slot.key]]?.item.name ?? 'なし'}')),
          ])),
      QuestCard(
          caption: 'なかま',
          child: Column(children: [
            for (final character in state.characters.values)
              Row(children: [
                Expanded(
                    child: Text('${character.name}　Lv.${character.level}')),
                if (character.id == hero.id)
                  const Padding(
                      padding: EdgeInsets.all(14),
                      child: Text('編成中',
                          style: TextStyle(color: Color(0xffd5b574))))
                else
                  TextButton(
                      onPressed: controller.busy
                          ? null
                          : () => runAction(context,
                              () => controller.selectCharacter(character.id)),
                      child: const Text('編成')),
              ]),
          ])),
      QuestCard(
          caption: '所持アイテム',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            if (state.inventory.isEmpty)
              const Text('どうぐぶくろは、まだ空だ。\n集中や召喚で装備を集めよう。'),
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
                    child: const Text('装備')),
              ]),
          ])),
    ]);
  }
}

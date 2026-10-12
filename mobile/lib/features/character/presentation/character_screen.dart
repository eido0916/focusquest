import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../domain/progression_service.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../../certificate/certificate_screen.dart';

const _gold = Color(0xffffd58b);
const _white = Color(0xfffff8e9);

/// Image-backed windows; labels and controls remain live widgets.
class LobbyWindow extends StatelessWidget {
  const LobbyWindow(
      {super.key,
      required this.child,
      this.strip = false,
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final bool strip;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset(
                'assets/images/lobby/${strip ? 'equipment_slot' : 'ornate_window'}.png',
                fit: BoxFit.fill,
                excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key, required this.controller});
  final GameController controller;

  Widget _itemIcon(String slot, {double size = 26}) =>
      Image.asset('assets/images/lobby/icon_$slot.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          excludeFromSemantics: true);

  Widget _button(String label, VoidCallback? action) => LobbyWindow(
      strip: true,
      padding: EdgeInsets.zero,
      child: TextButton(
          onPressed: action,
          style: TextButton.styleFrom(
              foregroundColor: _white,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 12)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(label,
                style:
                    const TextStyle(fontFamily: 'SunlitSerif', fontSize: 13)),
            const Icon(Icons.chevron_right, color: _gold, size: 18),
          ])));

  void _openInventory(BuildContext context) {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxWidth: 560,
                    maxHeight: MediaQuery.sizeOf(dialogContext).height * .78),
                child: DefaultTextStyle(
                    style: const TextStyle(
                        fontFamily: 'SunlitSerif', color: _white),
                    child: LobbyWindow(
                        child: Column(children: [
                      Row(children: [
                        const Icon(Icons.shopping_bag_outlined, color: _gold),
                        const SizedBox(width: 8),
                        const Expanded(
                            child:
                                Text('所持アイテム', style: TextStyle(fontSize: 18))),
                        IconButton(
                            tooltip: '閉じる',
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close, color: _gold)),
                      ]),
                      Expanded(
                          child: AnimatedBuilder(
                              animation: controller,
                              builder: (context, _) {
                                final inventory = controller.state!.inventory;
                                if (inventory.isEmpty) {
                                  return const Center(
                                      child: Text('冒険の初回クリアで装備を集めよう。',
                                          textAlign: TextAlign.center));
                                }
                                return ListView(children: [
                                  for (final entry in inventory.entries)
                                    Padding(
                                        key: ValueKey('inventory-${entry.key}'),
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 6),
                                        child: Row(children: [
                                          _itemIcon(GameCatalog
                                                  .equipment[entry.key]
                                                  ?.slot
                                                  .name ??
                                              'weapon'),
                                          const SizedBox(width: 8),
                                          Expanded(
                                              child: Text(
                                                  '${GameCatalog.equipment[entry.key]?.item.name ?? entry.key}  ×${entry.value}',
                                                  style: const TextStyle(
                                                      fontSize: 13))),
                                          _button(
                                              '装備する',
                                              controller.busy ||
                                                      !GameCatalog.equipment
                                                          .containsKey(
                                                              entry.key)
                                                  ? null
                                                  : () => runAction(
                                                      context,
                                                      () => controller
                                                          .equip(entry.key))),
                                        ])),
                                ]);
                              })),
                    ]))))));
  }

  Widget _stats({required bool large}) {
    final hero = controller.state!.activeCharacter!;
    final stats = ProgressionService().stats(hero, GameCatalog.equipment);
    final job = JobPortrait.roleNames[hero.characterType] ?? '剣士';
    final font = large ? 20.0 : 16.0;
    final rows = [
      (Icons.favorite, 'HP', '${stats.hp}'),
      (Icons.bolt, '攻撃力', '${stats.attack}'),
      (Icons.shield, '防御力', '${stats.defense}'),
      (Icons.directions_run, '素早さ', '${stats.speed}'),
      (Icons.auto_awesome, '会心率', '${(stats.criticalRate * 100).round()}%'),
    ];
    Widget statRow((IconData, String, String) row) => Row(children: [
          Icon(row.$1, size: large ? 24 : 20, color: _gold),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(row.$2, style: TextStyle(fontSize: font, height: 1.3))),
          Text(row.$3, style: TextStyle(fontSize: font, height: 1.3)),
        ]);
    return LobbyWindow(
        key: const ValueKey('character-stats'),
        padding: EdgeInsets.symmetric(
            horizontal: large ? 44 : 28, vertical: large ? 32 : 24),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(hero.name,
                  style: TextStyle(
                      color: _gold, fontSize: large ? 18 : 16, height: 1.3)),
              const SizedBox(height: 6),
              Text('Lv. ${hero.level}　$job',
                  style: TextStyle(
                      fontSize: large ? 28 : 22,
                      height: 1.3,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                  style: TextStyle(fontSize: large ? 17 : 14, height: 1.3)),
              const SizedBox(height: 8),
              ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                      value:
                          (hero.currentExp / hero.requiredExp).clamp(0.0, 1.0),
                      minHeight: 8,
                      color: const Color(0xff6aeeee),
                      backgroundColor: const Color(0xff244965))),
              const SizedBox(height: 12),
              if (large)
                for (final row in rows) ...[
                  const Divider(color: Color(0xff997842), height: 1),
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: statRow(row)),
                ]
              else
                for (var i = 0; i < rows.length; i += 2)
                  Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Expanded(child: statRow(rows[i])),
                        const SizedBox(width: 16),
                        Expanded(
                            child: i + 1 < rows.length
                                ? statRow(rows[i + 1])
                                : const SizedBox()),
                      ])),
            ]));
  }

  Widget _equipment(BuildContext context,
      {required bool large, bool inventory = true}) {
    final hero = controller.state!.activeCharacter!;
    return LobbyWindow(
        key: const ValueKey('character-equipment'),
        padding: EdgeInsets.symmetric(
            horizontal: large ? 40 : 24, vertical: large ? 30 : 20),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(children: [
                Icon(Icons.handyman_outlined,
                    color: _gold, size: large ? 26 : 22),
                const SizedBox(width: 10),
                Text('装備',
                    style: TextStyle(
                        color: _gold, fontSize: large ? 23 : 18, height: 1.3)),
              ]),
              const SizedBox(height: 12),
              for (final slot in {
                'weapon': '武器',
                'armor': '防具',
                'accessory': 'アクセサリー',
              }.entries)
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: LobbyWindow(
                        strip: true,
                        padding: EdgeInsets.symmetric(
                            horizontal: large ? 32 : 22,
                            vertical: large ? 14 : 10),
                        child: Row(children: [
                          _itemIcon(slot.key, size: large ? 30 : 24),
                          const SizedBox(width: 10),
                          if (large) ...[
                            Expanded(
                                child: Text(slot.value,
                                    style: const TextStyle(
                                        fontSize: 19, height: 1.3))),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                              child: Text(
                                  GameCatalog
                                          .equipment[
                                              hero.equippedItems[slot.key]]
                                          ?.item
                                          .name ??
                                      '未装備',
                                  textAlign:
                                      large ? TextAlign.right : TextAlign.left,
                                  style: TextStyle(
                                      fontSize: large ? 20 : 16, height: 1.3))),
                        ]))),
              if (inventory) ...[
                const SizedBox(height: 4),
                _inventoryButton(context, large: large),
              ],
            ]));
  }

  Widget _inventoryButton(BuildContext context, {required bool large}) =>
      LobbyWindow(
          strip: true,
          padding: EdgeInsets.zero,
          child: TextButton(
              onPressed: () => _openInventory(context),
              style: TextButton.styleFrom(
                  foregroundColor: _white,
                  minimumSize: Size(double.infinity, large ? 58 : 50),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.shopping_bag_outlined,
                    color: _gold, size: large ? 24 : 20),
                const SizedBox(width: 10),
                Text('所持アイテム',
                    style: TextStyle(
                        fontFamily: 'SunlitSerif',
                        fontSize: large ? 20 : 16,
                        height: 1.3)),
                const SizedBox(width: 6),
                const Icon(Icons.chevron_right, color: _gold),
              ])));

  @override
  Widget build(BuildContext context) {
    final hero = controller.state!.activeCharacter!;
    return DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: 'SunlitSerif', color: _white),
        child: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/lobby/castle_courtyard.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true),
          Center(
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: LayoutBuilder(builder: (context, bounds) {
                        final large = bounds.maxWidth >= 520;
                        final textScale =
                            MediaQuery.textScalerOf(context).scale(16) / 16;
                        final useTabs =
                            bounds.maxHeight < (large ? 950 : 740) * textScale;
                        final header = LobbyWindow(
                            strip: true,
                            padding: EdgeInsets.symmetric(
                                horizontal: large ? 36 : 24, vertical: 14),
                            child: Row(children: [
                              const Icon(Icons.person, color: _gold, size: 24),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Text('キャラクター',
                                      style: TextStyle(
                                          fontSize: large ? 24 : 18,
                                          height: 1.3,
                                          fontWeight: FontWeight.bold))),
                              IconButton(
                                tooltip: '冒険者証',
                                icon: const Icon(Icons.badge_outlined, color: _gold),
                                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(
                                  builder: (_) => CertificateScreen(controller: controller))),
                              ),
                              if (large)
                                Text('Lv.${hero.level}',
                                    style: const TextStyle(
                                        fontSize: 17, height: 1.3)),
                            ]));
                        Widget portrait() => LayoutBuilder(
                            builder: (context, area) => ClipRect(
                                child: JobPortrait(
                                    typeId: hero.characterType,
                                    appearance: hero.appearance,
                                    lobby: true,
                                    height: area.maxHeight,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.topCenter)));
                        if (useTabs) {
                          return DefaultTabController(
                              length: 2,
                              child: Column(children: [
                                header,
                                const SizedBox(height: 8),
                                if (bounds.maxHeight > 550)
                                  Expanded(flex: 2, child: portrait()),
                                const TabBar(
                                    labelColor: _gold,
                                    unselectedLabelColor: _white,
                                    indicatorColor: _gold,
                                    labelStyle: TextStyle(
                                        fontFamily: 'SunlitSerif',
                                        fontSize: 18),
                                    tabs: [
                                      Tab(text: 'ステータス'),
                                      Tab(text: '装備')
                                    ]),
                                Expanded(
                                    flex: 3,
                                    child: TabBarView(children: [
                                      SingleChildScrollView(
                                          child: _stats(large: false)),
                                      SingleChildScrollView(
                                          child: _equipment(context,
                                              large: false, inventory: false)),
                                    ])),
                                const SizedBox(height: 8),
                                _inventoryButton(context, large: false),
                              ]));
                        }
                        return Column(children: [
                          header,
                          const SizedBox(height: 8),
                          Expanded(child: portrait()),
                          _stats(large: large),
                          const SizedBox(height: 10),
                          _equipment(context, large: large),
                        ]);
                      })))),
        ]));
  }
}

import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../domain/progression_service.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../../certificate/certificate_screen.dart';
import '../../certificate/certificate_catalog.dart';
import '../../../core/widgets/role_logo.dart';
import 'character_art.dart';

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

  void openInventory(BuildContext context) {
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

  void openTitles(BuildContext context) {
    showDialog<void>(
        context: context,
        builder: (dialogContext) => Dialog(
            backgroundColor: const Color(0xff071b30),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            insetPadding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 480,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * .82),
              child: CharacterPanel(
                  asset: 'title_list_panel',
                  padding:
                      const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                  child: AnimatedBuilder(
                      animation: controller,
                      builder: (context, _) {
                        final hero = controller.state!.activeCharacter!;
                        final titles =
                            CertificateCatalog.titles[hero.characterType]!;
                        final selected = CertificateCatalog.displayedTitle(
                            hero.characterType, hero.level, hero.selectedTitle);
                        return DefaultTextStyle(
                            style: const TextStyle(
                                fontFamily: 'SunlitSerif', color: _white),
                            child: Column(children: [
                              Row(children: [
                                const Expanded(
                                    child: Text('称号一覧',
                                        style: TextStyle(fontSize: 22))),
                                IconButton(
                                    tooltip: '閉じる',
                                    onPressed: () =>
                                        Navigator.pop(dialogContext),
                                    icon:
                                        const Icon(Icons.close, color: _gold)),
                              ]),
                              Text(
                                  '${JobPortrait.roleNames[hero.characterType]}  ·  現在 Lv. ${hero.level}',
                                  style: const TextStyle(color: _gold)),
                              const SizedBox(height: 12),
                              Expanded(
                                  child: ListView.builder(
                                      itemCount: titles.length,
                                      itemBuilder: (context, index) {
                                        final unlocked =
                                            hero.level >= index + 1;
                                        final active =
                                            selected == titles[index];
                                        return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: CharacterPanel(
                                                asset: 'equipment_row',
                                                padding: EdgeInsets.zero,
                                                child: ListTile(
                                                  key: ValueKey('title-$index'),
                                                  enabled: unlocked &&
                                                      !controller.busy,
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 20,
                                                          vertical: 4),
                                                  leading: Icon(
                                                      active
                                                          ? Icons
                                                              .check_circle_outline
                                                          : unlocked
                                                              ? Icons
                                                                  .auto_awesome
                                                              : Icons
                                                                  .lock_outline,
                                                      color: unlocked
                                                          ? _gold
                                                          : const Color(
                                                              0xffb4b5bd)),
                                                  title: Text(titles[index],
                                                      style: TextStyle(
                                                          color: unlocked
                                                              ? _white
                                                              : const Color(
                                                                  0xffb4b5bd),
                                                          fontFamily:
                                                              'SunlitSerif',
                                                          fontSize: 15)),
                                                  subtitle: Text(
                                                      'Lv. ${index + 1}で解放${active ? ' · 選択中' : unlocked ? ' · 解放済み' : ' · 未解放'}',
                                                      style: TextStyle(
                                                          fontFamily: 'SunlitSerif',
                                                          color: unlocked
                                                              ? _gold
                                                              : const Color(
                                                                  0xffb4b5bd),
                                                          fontSize: 12)),
                                                  onTap: unlocked &&
                                                          !controller.busy
                                                      ? () async {
                                                          await runAction(
                                                              dialogContext,
                                                              () => controller
                                                                  .selectTitle(
                                                                      titles[
                                                                          index]));
                                                        }
                                                      : null,
                                                )));
                                      })),
                            ]));
                      })),
            )));
  }

  Widget _identity(BuildContext context, {required bool large}) {
    final hero = controller.state!.activeCharacter!;
    final title = CertificateCatalog.displayedTitle(
        hero.characterType, hero.level, hero.selectedTitle);
    return CharacterPanel(
        asset: 'identity_panel',
        padding:
            EdgeInsets.symmetric(horizontal: large ? 32 : 20, vertical: 18),
        child: Row(children: [
          RoleLogo(role: hero.characterType, size: large ? 88 : 60),
          const SizedBox(width: 8),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(hero.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: large ? 30 : 23, height: 1.2)),
                const SizedBox(height: 6),
                Text(title,
                    style: TextStyle(color: _gold, fontSize: large ? 17 : 13)),
                TextButton.icon(
                    key: const ValueKey('change-title'),
                    onPressed: () => openTitles(context),
                    style: TextButton.styleFrom(
                        foregroundColor: _gold,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        minimumSize: const Size(48, 40)),
                    icon: const CharacterIcon('edit_icon', size: 15),
                    label: const Text('称号変更',
                        style: TextStyle(
                            fontFamily: 'SunlitSerif', fontSize: 13))),
              ])),
          const SizedBox(width: 6),
          Column(children: [
            const CharacterIcon('level_icon', size: 23),
            Text('Lv. ${hero.level}',
                style: TextStyle(color: _gold, fontSize: large ? 29 : 22)),
          ]),
        ]));
  }

  Widget _stats({required bool large}) {
    final hero = controller.state!.activeCharacter!;
    final stats = ProgressionService().stats(hero, GameCatalog.equipment);
    final rows = [
      ('stat_hp', 'HP', '${stats.hp}'),
      ('stat_attack', '攻撃力', '${stats.attack}'),
      ('stat_defense', '防御力', '${stats.defense}'),
      ('stat_speed', '素早さ', '${stats.speed}'),
      ('stat_critical', '会心率', '${(stats.criticalRate * 100).round()}%'),
    ];
    Widget stat((String, String, String) row) => CharacterPanel(
        asset: 'equipment_row',
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(children: [
          CharacterIcon(row.$1, size: large ? 22 : 16),
          const SizedBox(width: 6),
          Expanded(
              child: Text(row.$2, style: TextStyle(fontSize: large ? 20 : 13))),
          Text(row.$3, style: TextStyle(fontSize: large ? 20 : 15)),
        ]));
    return CharacterPanel(
        key: const ValueKey('character-stats'),
        asset: 'parchment_panel',
        padding: EdgeInsets.symmetric(
            horizontal: large ? 32 : 20, vertical: large ? 24 : 20),
        child: Column(children: [
          CharacterPanel(
              asset: 'equipment_row',
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(children: [
                Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                    style: TextStyle(fontSize: large ? 16 : 12)),
                const SizedBox(width: 12),
                Expanded(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                            value: (hero.currentExp / hero.requiredExp)
                                .clamp(0.0, 1.0),
                            minHeight: 8,
                            color: const Color(0xff69eeee),
                            backgroundColor: const Color(0xff244965)))),
              ])),
          const SizedBox(height: 6),
          for (var i = 0; i < rows.length; i += 2)
            Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  Expanded(child: stat(rows[i])),
                  const SizedBox(width: 6),
                  Expanded(
                      child: i + 1 < rows.length
                          ? stat(rows[i + 1])
                          : const SizedBox()),
                ])),
        ]));
  }

  Widget _equipment(BuildContext context, {required bool large}) {
    final hero = controller.state!.activeCharacter!;
    return CharacterPanel(
        key: const ValueKey('character-equipment'),
        asset: 'identity_panel',
        padding:
            EdgeInsets.symmetric(horizontal: large ? 28 : 18, vertical: 20),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          CharacterPanel(
              asset: 'header_banner',
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Center(
                  child: Text('装備',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: _gold, fontSize: large ? 26 : 21)))),
          const SizedBox(height: 8),
          for (final slot
              in {'weapon': '武器', 'armor': '防具', 'accessory': 'アクセサリー'}.entries)
            Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: CharacterPanel(
                    asset: 'equipment_row',
                    padding: EdgeInsets.zero,
                    child: TextButton(
                        onPressed: () => openInventory(context),
                        style: TextButton.styleFrom(
                            foregroundColor: _white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12)),
                        child: Row(children: [
                          _itemIcon(slot.key, size: large ? 30 : 24),
                          const SizedBox(width: 10),
                          Expanded(
                              child: Text(slot.value,
                                  style: TextStyle(
                                      fontFamily: 'SunlitSerif',
                                      fontSize: large ? 19 : 14))),
                          Flexible(
                              child: Text(
                                  GameCatalog
                                          .equipment[
                                              hero.equippedItems[slot.key]]
                                          ?.item
                                          .name ??
                                      '未装備',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontFamily: 'SunlitSerif',
                                      fontSize: large ? 17 : 13))),
                          const CharacterIcon('chevron_icon', size: 18),
                        ])))),
          CharacterPanel(
              asset: 'equipment_row',
              padding: EdgeInsets.zero,
              child: TextButton(
                  onPressed: () => openInventory(context),
                  style: TextButton.styleFrom(
                      foregroundColor: _white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12)),
                  child: Row(children: [
                    const CharacterIcon('bag_icon', size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text('所持アイテム',
                            style: TextStyle(
                                fontFamily: 'SunlitSerif',
                                fontSize: large ? 19 : 14))),
                    const CharacterIcon('chevron_icon', size: 18),
                  ]))),
        ]));
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'SunlitSerif', color: _white),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/lobby/castle_courtyard.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true),
        SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: LayoutBuilder(builder: (context, bounds) {
                      final large = bounds.maxWidth >= 520;
                      final hero = controller.state!.activeCharacter!;
                      return SingleChildScrollView(
                          key: const ValueKey('character-scroll'),
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: CharacterPanel(
                                      asset: 'header_banner',
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 17, horizontal: 12),
                                      child: Center(
                                          child: Text('キャラクター',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                  fontSize:
                                                      large ? 28 : 21))))),
                              const SizedBox(width: 6),
                              CharacterPanel(
                                  asset: 'equipment_row',
                                  padding: EdgeInsets.zero,
                                  child: TextButton(
                                      onPressed: () => Navigator.of(context)
                                          .push(MaterialPageRoute<void>(
                                              builder: (_) => CertificateScreen(
                                                  controller: controller))),
                                      style: TextButton.styleFrom(
                                          foregroundColor: _gold,
                                          padding: const EdgeInsets.all(12)),
                                      child: const Column(children: [
                                        CharacterIcon('certificate_icon',
                                            size: 22),
                                        Text('冒険者証を見る',
                                            style: TextStyle(
                                                fontFamily: 'SunlitSerif',
                                                fontSize: 10))
                                      ]))),
                            ]),
                            SizedBox(
                                height: large ? 430 : 280,
                                child: JobPortrait(
                                    typeId: hero.characterType,
                                    appearance: hero.appearance,
                                    lobby: true,
                                    height: large ? 430 : 280,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter)),
                            _identity(context, large: large),
                            const SizedBox(height: 5),
                            _stats(large: large),
                            const SizedBox(height: 7),
                            _equipment(context, large: large),
                          ]));
                    })))),
      ]));
}

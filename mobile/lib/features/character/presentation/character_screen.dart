import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../core/widgets/quest_page_header.dart';
import '../domain/progression_service.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../../certificate/certificate_screen.dart';
import '../../certificate/certificate_catalog.dart';
import 'character_pixel_art.dart';
import 'character_pixel_portrait.dart';

const _gold = Color(0xffffd58b);
const _white = Color(0xfffff8e9);

class CharacterScreen extends StatelessWidget {
  const CharacterScreen({super.key, required this.controller});
  final GameController controller;

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
              child: _ReadablePanel(
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
                              const SizedBox(height: 6),
                              Expanded(
                                  child: ListView.builder(
                                      itemCount: titles.length,
                                      itemBuilder: (context, index) {
                                        final unlockLevel =
                                            CertificateCatalog.unlockLevel(
                                                index);
                                        final unlocked =
                                            hero.level >= unlockLevel;
                                        final active =
                                            selected == titles[index];
                                        return Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 8),
                                            child: CharacterPanel(
                                                asset: 'action_row',
                                                slice: const Rect.fromLTRB(
                                                    16, 9, 384, 31),
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
                                                          fontSize: 16)),
                                                  subtitle: Text(
                                                      'Lv. $unlockLevelで解放${active ? ' · 選択中' : unlocked ? ' · 解放済み' : ' · 未解放'}',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'SunlitSerif',
                                                          color: unlocked
                                                              ? _gold
                                                              : const Color(
                                                                  0xffb4b5bd),
                                                          fontSize: 14)),
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

  Widget _identity(double materialScale) {
    final hero = controller.state!.activeCharacter!;
    final title = CertificateCatalog.displayedTitle(
        hero.characterType, hero.level, hero.selectedTitle);
    return CharacterPanel(
        asset: 'identity_panel',
        slice: const Rect.fromLTRB(28, 16, 372, 54),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(children: [
          CharacterFaceIcon(
              role: hero.characterType,
              appearance: hero.appearance,
              size: 52 * materialScale),
          const SizedBox(width: 10),
          const CharacterIcon('identity_divider', width: 3, height: 50),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(hero.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w600,
                        height: 1.2)),
                const SizedBox(height: 2),
                Text(title,
                    style: const TextStyle(
                        color: _gold, fontSize: 14, height: 1.3)),
              ])),
          const SizedBox(width: 8),
          const CharacterIcon('identity_divider', width: 3, height: 42),
          const SizedBox(width: 10),
          Text('Lv. ${hero.level}',
              style: const TextStyle(
                  color: _gold, fontSize: 22, fontWeight: FontWeight.w600)),
        ]));
  }

  Widget _stats(BuildContext context) {
    final hero = controller.state!.activeCharacter!;
    final stats = ProgressionService().stats(hero, const {});
    final rows = [
      ('stat_hp', 'HP', '${stats.hp}'),
      ('stat_attack', '攻撃力', '${stats.attack}'),
      ('stat_defense', '防御力', '${stats.defense}'),
      ('stat_speed', '素早さ', '${stats.speed}'),
      ('stat_critical', '会心率', '${(stats.criticalRate * 100).round()}%'),
    ];
    Widget stat((String, String, String) row) => CharacterPanel(
        asset: 'stat_row',
        slice: const Rect.fromLTRB(16, 9, 184, 31),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Row(children: [
          CharacterIcon(row.$1, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(row.$2, style: const TextStyle(fontSize: 14))),
          const SizedBox(width: 5),
          const CharacterIcon('value_divider', width: 1, height: 18),
          const SizedBox(width: 8),
          Text(row.$3,
              style: const TextStyle(
                  color: _gold, fontSize: 16, fontWeight: FontWeight.w600)),
        ]));
    return CharacterPanel(
        key: const ValueKey('character-stats'),
        asset: 'stats_parchment',
        slice: const Rect.fromLTRB(24, 24, 376, 156),
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 13),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const CharacterSectionHeading('能力値'),
          const SizedBox(height: 6),
          Row(children: [
            const Text('EXP',
                style: TextStyle(
                    fontSize: 15,
                    color: Color(0xff241b12),
                    fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
                child: Semantics(
                    label: '次のレベルまでの経験値',
                    value: '${hero.currentExp} / ${hero.requiredExp}',
                    child: SizedBox(
                        height: 12 * CharacterMaterialScale.of(context),
                        child: Stack(fit: StackFit.expand, children: [
                          Image.asset('$characterMaterialPath/exp_track.png',
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.none,
                              excludeFromSemantics: true),
                          Padding(
                              padding: const EdgeInsets.all(2),
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                      heightFactor: 1,
                                      widthFactor:
                                          (hero.currentExp / hero.requiredExp)
                                              .clamp(0.0, 1.0),
                                      child: Image.asset(
                                          '$characterMaterialPath/exp_fill.png',
                                          key: const ValueKey(
                                              'character-exp-fill'),
                                          fit: BoxFit.fill,
                                          filterQuality: FilterQuality.none,
                                          excludeFromSemantics: true)))),
                        ])))),
            const SizedBox(width: 10),
            Text('${hero.currentExp} / ${hero.requiredExp}',
                style: const TextStyle(fontSize: 14, color: Color(0xff241b12))),
          ]),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, bounds) {
            final materialScale = CharacterMaterialScale.of(context);
            final single = bounds.maxWidth < 265 * materialScale ||
                MediaQuery.textScalerOf(context).scale(16) > 20 * materialScale;
            final cellWidth =
                single ? bounds.maxWidth : (bounds.maxWidth - 8) / 2;
            return Wrap(spacing: 8, runSpacing: 5, children: [
              for (final row in rows)
                SizedBox(width: cellWidth, child: stat(row)),
            ]);
          }),
          const SizedBox(height: 8),
          _adventurerInfo(context),
        ]));
  }

  Widget _adventurerInfo(BuildContext context) {
    Widget action(String label, String icon, Key key, VoidCallback onPressed) =>
        Semantics(
            button: true,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    key: key,
                    onTap: onPressed,
                    child: CharacterPanel(
                        asset: 'action_row',
                        slice: const Rect.fromLTRB(16, 9, 384, 31),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        child: Row(children: [
                          CharacterIcon(icon, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(label,
                                  style: const TextStyle(fontSize: 14))),
                          const SizedBox(width: 4),
                          const CharacterIcon('chevron_icon', size: 10),
                        ])))));
    return Column(
        key: const ValueKey('adventurer-information'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CharacterSectionHeading('冒険者情報'),
          const SizedBox(height: 6),
          LayoutBuilder(builder: (context, bounds) {
            final titleButton = action('称号変更', 'title_icon',
                    const ValueKey('change-title'), () => openTitles(context)),
                certificateButton = action(
                    '冒険者証を見る',
                    'certificate_icon',
                    const ValueKey('view-certificate'),
                    () => Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) =>
                            CertificateScreen(controller: controller))));
            final factor = CharacterMaterialScale.of(context);
            if (bounds.maxWidth >= 265 * factor &&
                MediaQuery.textScalerOf(context).scale(14) <= 18 * factor) {
              return IntrinsicHeight(
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                    Expanded(child: titleButton),
                    const SizedBox(width: 8),
                    Expanded(child: certificateButton)
                  ]));
            }
            return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleButton,
                  const SizedBox(height: 8),
                  certificateButton
                ]);
          }),
        ]);
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, bounds) {
        // Reference composition is 375px wide; grow spacing and type together.
        final scale = (bounds.maxWidth / 375).clamp(.85, 2.4).toDouble();
        final width =
            (bounds.maxWidth - 16 * scale).clamp(0.0, 862.0).toDouble();
        final hero = controller.state!.activeCharacter!;
        final textScale = MediaQuery.textScalerOf(context).scale(1);
        final stageHeight = (bounds.maxHeight - 344 * scale)
            .clamp(246 * scale, 310 * scale)
            .toDouble();
        return DefaultTextStyle.merge(
            style: const TextStyle(
                fontFamily: 'SunlitSerif',
                color: _white,
                fontSize: 16,
                height: 1.2),
            child: Stack(fit: StackFit.expand, children: [
              Image.asset('$characterMaterialPath/castle_courtyard.png',
                  key: const ValueKey('character-continuous-background'),
                  fit: BoxFit.fill,
                  filterQuality: FilterQuality.none,
                  excludeFromSemantics: true),
              QuestScreenFit(
                  key: const ValueKey('character-scroll'),
                  padding: EdgeInsets.fromLTRB(
                      8 * scale, 6 * scale, 8 * scale, 4 * scale),
                  child: Center(
                      child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.linear(textScale * scale)),
                          child: CharacterMaterialScale(
                              factor: scale,
                              child: SizedBox(
                                width: width,
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      SizedBox(
                                          height: stageHeight,
                                          child: Stack(children: [
                                            Positioned(
                                                top: 0,
                                                left: 0,
                                                right: 0,
                                                child: Center(
                                                    child: SizedBox(
                                                        width: textScale > 1.2
                                                            ? width
                                                            : width * .85,
                                                        child: QuestPageHeader(
                                                            key: const Key(
                                                                'character-page-header'),
                                                            title: 'キャラクター',
                                                            unit: scale,
                                                            textScaler:
                                                                TextScaler.linear(
                                                                    textScale),
                                                            trailing: Icon(
                                                                Icons
                                                                    .people_alt_rounded,
                                                                size:
                                                                    30 * scale,
                                                                color: const Color(
                                                                    0xfff5ce78)))))),
                                            Positioned(
                                                top: 68 * scale,
                                                bottom: 0,
                                                left: 0,
                                                right: 0,
                                                child: CharacterPixelPortrait(
                                                    role: hero.characterType,
                                                    appearance:
                                                        hero.appearance)),
                                          ])),
                                      _identity(scale),
                                      SizedBox(height: 4 * scale),
                                      _stats(context),
                                    ]),
                              ))))),
            ]));
      });
}

class _ReadablePanel extends StatelessWidget {
  const _ReadablePanel({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => CharacterPanel(
      asset: 'identity_panel',
      slice: const Rect.fromLTRB(28, 16, 372, 54),
      padding: const EdgeInsets.all(20),
      child: child);
}

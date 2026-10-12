import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../domain/progression_service.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../../certificate/certificate_screen.dart';
import '../../certificate/certificate_catalog.dart';
import '../../../core/widgets/role_logo.dart';
import 'character_art.dart';

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
                                                      'Lv. $unlockLevelで解放${active ? ' · 選択中' : unlocked ? ' · 解放済み' : ' · 未解放'}',
                                                      style: TextStyle(
                                                          fontFamily:
                                                              'SunlitSerif',
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

  Widget _identity(double width) {
    final hero = controller.state!.activeCharacter!;
    final title = CertificateCatalog.displayedTitle(
        hero.characterType, hero.level, hero.selectedTitle);
    return CharacterPanel(
      asset: 'identity_panel',
      padding: EdgeInsets.symmetric(horizontal: width * .06, vertical: 8),
      child: Row(children: [
        RoleLogo(role: hero.characterType, size: width * .18),
        SizedBox(width: width * .025),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hero.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: width * .066, height: 1.2)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: _gold, fontSize: width * .034)),
        ])),
        CharacterIcon('identity_divider',
            width: width * .020, height: width * .12),
        SizedBox(width: width * .035),
        Column(children: [
          CharacterIcon('level_icon', width: width * .13, height: width * .043),
          Text('Lv. ${hero.level}',
              style: TextStyle(color: _gold, fontSize: width * .058)),
        ]),
      ]),
    );
  }

  Widget _stats(double width) {
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
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(children: [
          CharacterIcon(row.$1, size: width * .037),
          const SizedBox(width: 5),
          Expanded(
              flex: 3,
              child: Text(row.$2, style: TextStyle(fontSize: width * .034))),
          Expanded(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child:
                      Text(row.$3, style: TextStyle(fontSize: width * .033)))),
        ]));
    return Column(key: const ValueKey('character-stats'), children: [
      CharacterPanel(
          asset: 'exp_track',
          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 6),
          child: Row(children: [
            Text('EXP  ${hero.currentExp} / ${hero.requiredExp}',
                style: TextStyle(fontSize: width * .03)),
            const SizedBox(width: 10),
            Expanded(
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                        value: (hero.currentExp / hero.requiredExp)
                            .clamp(0.0, 1.0),
                        minHeight: width * .014,
                        color: const Color(0xff55f4ff),
                        backgroundColor: const Color(0xff183d59)))),
          ])),
      CharacterPanel(
          asset: 'parchment_panel',
          padding: EdgeInsets.fromLTRB(width * .055, 7, width * .055, 11),
          child: Column(children: [
            for (var i = 0; i < rows.length; i += 2)
              Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: stat(rows[i])),
                        SizedBox(width: width * .025),
                        Expanded(
                            child: i + 1 < rows.length
                                ? stat(rows[i + 1])
                                : const SizedBox()),
                      ])),
          ])),
    ]);
  }

  Widget _adventurerInfo(BuildContext context, double width) {
    Widget action(String label, String icon, Key key, VoidCallback onPressed) =>
        CharacterPanel(
            asset: 'action_row',
            padding: EdgeInsets.zero,
            child: TextButton(
                key: key,
                onPressed: onPressed,
                style: TextButton.styleFrom(
                    foregroundColor: _white,
                    minimumSize: const Size(48, 36),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.symmetric(
                        horizontal: width * .035, vertical: 7)),
                child: Row(children: [
                  CharacterIcon(icon, size: width * .046),
                  SizedBox(width: width * .025),
                  Expanded(
                      child: Text(label,
                          style: TextStyle(
                              fontFamily: 'SunlitSerif',
                              fontSize: width * .038))),
                  const CharacterIcon('chevron_icon', size: 19),
                ])));
    return CharacterPanel(
        key: const ValueKey('adventurer-information'),
        asset: 'adventurer_panel',
        padding: EdgeInsets.fromLTRB(width * .10, 7, width * .10, 12),
        child: Column(children: [
          Text('冒険者情報',
              style:
                  TextStyle(color: _gold, fontSize: width * .037, height: 1)),
          const SizedBox(height: 6),
          action('称号変更', 'title_icon', const ValueKey('change-title'),
              () => openTitles(context)),
          const SizedBox(height: 3),
          action(
              '冒険者証を見る',
              'certificate_icon',
              const ValueKey('view-certificate'),
              () => Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => CertificateScreen(controller: controller)))),
        ]));
  }

  @override
  Widget build(BuildContext context) => DefaultTextStyle.merge(
      style: const TextStyle(fontFamily: 'SunlitSerif', color: _white),
      child: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/character_ui_v004/castle_courtyard.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true),
        SafeArea(
            child: Center(
                child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 640),
                    child: LayoutBuilder(builder: (context, bounds) {
                      final width = bounds.maxWidth - 48;
                      final hero = controller.state!.activeCharacter!;
                      final portraitHeight =
                          (bounds.maxHeight - width * 1.03 - 28)
                              .clamp(width * .63, width * 1.04)
                              .toDouble();
                      return SingleChildScrollView(
                          key: const ValueKey('character-scroll'),
                          padding: const EdgeInsets.fromLTRB(24, 6, 24, 18),
                          child: Column(children: [
                            SizedBox(
                                width: width * .72,
                                child: CharacterPanel(
                                    asset: 'header_banner',
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 6, horizontal: 18),
                                    child: Center(
                                        child: Text('キャラクター',
                                            style: TextStyle(
                                                fontSize: width * .047,
                                                letterSpacing: 3))))),
                            SizedBox(
                                height: portraitHeight,
                                child: JobPortrait(
                                    typeId: hero.characterType,
                                    appearance: hero.appearance,
                                    lobby: true,
                                    height: portraitHeight,
                                    fit: BoxFit.contain,
                                    alignment: Alignment.bottomCenter)),
                            _identity(width),
                            const SizedBox(height: 3),
                            _stats(width),
                            const SizedBox(height: 3),
                            _adventurerInfo(context, width),
                          ]));
                    })))),
      ]));
}

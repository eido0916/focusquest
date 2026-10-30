import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/widgets/quest_page_header.dart';
import '../domain/stage_progress.dart';
import '../domain/playable_stage_catalog.dart';
import 'stage_number.dart';

const adventureMapAssets = 'assets/images/adventure_map_v001/';
const adventureMapV3Assets = 'assets/images/adventure_map_v003/';
String adventureMapBackground(int area) => area == 0
    ? '${adventureMapV3Assets}landscape.png'
    : '${adventureMapAssets}map_${(area + 1).toString().padLeft(2, '0')}.png';
const _ivory = Color(0xffffefd0);
const _gold = Color(0xfff5ce78);

TextStyle mapText(double size, {Color color = _ivory}) => TextStyle(
        fontFamily: 'SunlitSerif',
        color: color,
        fontSize: math.max(14, size),
        height: 1.3,
        shadows: const [
          Shadow(color: Color(0xcc00152c), blurRadius: 2, offset: Offset(0, 1))
        ]);

class AdventureMapScene extends StatelessWidget {
  const AdventureMapScene(
      {super.key,
      required this.progress,
      required this.area,
      required this.selected,
      required this.blocked,
      required this.onSelect,
      required this.onChallenge,
      required this.onHistory,
      required this.onNext,
      this.notices = const [],
      this.traveler});
  final StageProgress progress;
  final int area, selected;
  final bool blocked;
  final ValueChanged<int> onSelect;
  final VoidCallback onChallenge, onHistory, onNext;
  final List<Widget> notices;
  final Widget? traveler;

  @override
  Widget build(BuildContext context) {
    final stage = PlayableStageCatalog.stages[selected - 1];
    final replay = progress.cleared.contains(selected);
    final unlocked = progress.canChallenge(selected);
    final nextArea = area + 1;
    final nextUnlocked = nextArea <= progress.currentArea;
    return LayoutBuilder(builder: (context, viewport) {
      final width = viewport.maxWidth;
      final designWidth = math.min(width, 470.0);
      return Stack(fit: StackFit.expand, children: [
        // Fit the scenery to the actual viewport, independently of UI height.
        // Cover preserves the source ratio and fills even short phone screens.
        Positioned.fill(
            child: Image.asset(adventureMapBackground(area),
                key: const Key('adventure-continuous-background'),
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.none,
                excludeFromSemantics: true)),
        QuestScreenFit(
          key: const Key('stage-selection-list'),
          child: Center(
              child: SizedBox(
                  width: width,
                  child: FittedBox(
                    alignment: Alignment.topCenter,
                    fit: BoxFit.fitWidth,
                    child: SizedBox(
                        width: designWidth,
                        child: Stack(children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: Column(children: [
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 44),
                                  child: QuestPageHeader(
                                      key: const Key('adventure-map-header'),
                                      title: '冒険の書',
                                      subtitle: '九つの世界を巡る旅',
                                      titleKey:
                                          const Key('adventure-map-title'),
                                      trailing: IconButton(
                                          key: const Key('adventure-history'),
                                          tooltip: '旅の記録・章を選ぶ',
                                          onPressed: onHistory,
                                          icon: const MapIcon('book',
                                              size: 30)))),
                              const SizedBox(height: 6),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 22),
                                  child: MapPlate(
                                      asset: 'chapter',
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 18, vertical: 10),
                                      child: Row(children: [
                                        SizedBox(
                                            width: 56,
                                            height: 36,
                                            child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(3),
                                                child: Image.asset(
                                                    area == 0
                                                        ? '${adventureMapV3Assets}meadow_thumbnail.png'
                                                        : PlayableStageCatalog
                                                            .backgrounds[area],
                                                    fit: BoxFit.cover,
                                                    filterQuality:
                                                        FilterQuality.none))),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                '第${area + 1}章  ${PlayableStageCatalog.areas[area]}',
                                                style: mapText(17))),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                            width: 116,
                                            child: Column(children: [
                                              Text(
                                                  '${progress.countInArea(area)} / 4 CLEAR',
                                                  style: mapText(12)),
                                              const SizedBox(height: 5),
                                              Container(
                                                  height: 8,
                                                  decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xff001b38),
                                                      border: Border.all(
                                                          color: _gold),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              8)),
                                                  child: Align(
                                                      alignment:
                                                          Alignment.centerLeft,
                                                      child: FractionallySizedBox(
                                                          widthFactor: progress
                                                                  .countInArea(
                                                                      area) /
                                                              4,
                                                          child: Container(
                                                              decoration: const BoxDecoration(
                                                                  color: _gold,
                                                                  borderRadius:
                                                                      BorderRadius.all(
                                                                          Radius.circular(8))))))),
                                            ])),
                                      ]))),
                              if (notices.isNotEmpty)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Column(children: notices)),
                              AspectRatio(
                                  key: const Key('adventure-map-surface'),
                                  aspectRatio: 941 / 730,
                                  child: LayoutBuilder(
                                      builder: (context, bounds) =>
                                          Stack(children: [
                                            for (final local in [3, 4])
                                              if (!progress.canChallenge(
                                                  area * 4 + local))
                                                Positioned.fill(
                                                    child: Image.asset(
                                                        '${adventureMapV3Assets}fog_$local.png',
                                                        fit: BoxFit.fill,
                                                        filterQuality:
                                                            FilterQuality.none,
                                                        excludeFromSemantics:
                                                            true)),
                                            Positioned.fill(
                                                child: Image.asset(
                                                    '${adventureMapV3Assets}route.png',
                                                    fit: BoxFit.fill,
                                                    excludeFromSemantics:
                                                        true)),
                                            for (var i = 0; i < 4; i++)
                                              _positionedNode(
                                                  i,
                                                  bounds.maxWidth,
                                                  bounds.maxHeight),
                                          ]))),
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18),
                                  child: MapPlate(
                                      key: const Key('selected-stage-panel'),
                                      asset: 'details',
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 13),
                                      child: LayoutBuilder(
                                          builder: (context, bounds) {
                                        final largeText =
                                            MediaQuery.textScalerOf(context)
                                                    .scale(1) >
                                                1.3;
                                        final body = Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Text('STAGE $selected',
                                                  style: mapText(23)),
                                              Text(stage.area,
                                                  style: mapText(14)),
                                              const SizedBox(height: 3),
                                              Container(
                                                  height: 1,
                                                  color: _gold.withOpacity(.6)),
                                              const SizedBox(height: 4),
                                              Text(
                                                  unlocked
                                                      ? '推奨 Lv.${stage.recommendedLevel}  ・  3連戦'
                                                      : 'Stage ${selected - 1}をクリアすると解放',
                                                  style: mapText(11)),
                                              const SizedBox(height: 6),
                                              MapAction(
                                                  key: const Key(
                                                      'map-stage-challenge'),
                                                  label: unlocked
                                                      ? (replay
                                                          ? 'もう一度挑戦'
                                                          : '挑戦する')
                                                      : '未解放',
                                                  gold: unlocked,
                                                  onTap: unlocked && !blocked
                                                      ? onChallenge
                                                      : null),
                                            ]);
                                        if (largeText ||
                                            bounds.maxWidth < 300) {
                                          return body;
                                        }
                                        return Row(children: [
                                          Expanded(
                                              flex: 4,
                                              child: AspectRatio(
                                                  key: const Key(
                                                      'selected-stage-thumbnail'),
                                                  aspectRatio: 1.6,
                                                  child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      child: Image.asset(
                                                          area == 0
                                                              ? '${adventureMapV3Assets}meadow_thumbnail.png'
                                                              : PlayableStageCatalog
                                                                      .backgrounds[
                                                                  area],
                                                          fit: BoxFit.cover,
                                                          filterQuality:
                                                              FilterQuality
                                                                  .none)))),
                                          const SizedBox(width: 15),
                                          Expanded(flex: 5, child: body),
                                        ]);
                                      }))),
                              const SizedBox(height: 7),
                              if (nextArea < PlayableStageCatalog.areas.length)
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 18),
                                    child: Semantics(
                                        button: nextUnlocked,
                                        label: nextUnlocked
                                            ? '次の章へ'
                                            : '${PlayableStageCatalog.areas[nextArea]}は未解放',
                                        child: GestureDetector(
                                            key: const Key('next-chapter'),
                                            onTap: nextUnlocked ? onNext : null,
                                            child: MapPlate(
                                                asset: 'teaser',
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: Stack(children: [
                                                  Positioned.fill(
                                                      child: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(4),
                                                          child: Image.asset(
                                                              area == 0
                                                                  ? '${adventureMapV3Assets}ghost_ship.png'
                                                                  : PlayableStageCatalog
                                                                          .backgrounds[
                                                                      nextArea],
                                                              fit: BoxFit.cover,
                                                              filterQuality:
                                                                  FilterQuality
                                                                      .none,
                                                              color: const Color(
                                                                  0xffc1d7f0),
                                                              colorBlendMode:
                                                                  BlendMode
                                                                      .modulate))),
                                                  Positioned.fill(
                                                      child: Container(
                                                          decoration:
                                                              const BoxDecoration(
                                                                  gradient:
                                                                      LinearGradient(
                                                                          colors: [
                                                        Color(0xc0001c3d),
                                                        Color(0x00001c3d)
                                                      ])))),
                                                  Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 23,
                                                          vertical: 5),
                                                      child: Row(children: [
                                                        Expanded(
                                                            child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                              Text(
                                                                  nextUnlocked
                                                                      ? '新たな旅へ'
                                                                      : '次の目的地',
                                                                  style:
                                                                      mapText(
                                                                          11)),
                                                              Text(
                                                                  PlayableStageCatalog
                                                                          .areas[
                                                                      nextArea],
                                                                  style:
                                                                      mapText(
                                                                          22)),
                                                              Text(
                                                                  nextUnlocked
                                                                      ? '次の章へ進む'
                                                                      : '${PlayableStageCatalog.areas[area]}を踏破すると解放',
                                                                  style:
                                                                      mapText(
                                                                          11)),
                                                            ])),
                                                        MapIcon(
                                                            nextUnlocked
                                                                ? 'chevron'
                                                                : 'lock',
                                                            size: 28),
                                                      ])),
                                                ]))))),
                              if (area == 8 && progress.areaComplete(8))
                                Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: MapPlate(
                                        asset: 'chapter',
                                        child: Text('全36ステージ踏破！',
                                            textAlign: TextAlign.center,
                                            style: mapText(20)))),
                              const SizedBox(height: 7),
                              Center(
                                  child: SizedBox(
                                      width: 174,
                                      child: MapAction(
                                          key: const Key('cleared-chapters'),
                                          label: area < progress.currentArea
                                              ? '進行中の章・旅の記録へ'
                                              : 'クリア済みの章へ',
                                          onTap: onHistory))),
                              if (traveler != null)
                                Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: traveler),
                            ]),
                          ),
                        ])),
                  ))),
        )
      ]);
    });
  }

  Widget _positionedNode(int local, double width, double height) {
    // Exactly the same source-space anchors as route.png (941 × 750).
    const centers = [
      Offset(184 / 941, 563 / 750),
      Offset(466 / 941, 480 / 750),
      Offset(767 / 941, 315 / 750),
      Offset(663 / 941, 135 / 750),
    ];
    final number = area * 4 + local + 1;
    final done = progress.cleared.contains(number);
    final unlocked = progress.canChallenge(number);
    final frontier = number == progress.nextStage && !done;
    final size = math.max(44.0, width * .115);
    final graphic = size * 1.12;
    final accessory = size * .46;
    final targetWidth = math.max(70.0, width * .16);
    final center = centers[local];
    final label = done
        ? 'クリア済み'
        : frontier
            ? '挑戦可能'
            : local == 3
                ? 'BOSS'
                : '未解放';
    return Positioned(
        left: center.dx * width - targetWidth / 2,
        top: center.dy * height - graphic / 2 - accessory,
        width: targetWidth,
        child: Semantics(
            button: true,
            label: 'ステージ$number $label',
            selected: selected == number,
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    key: Key('select-stage-$number'),
                    onTap: blocked ? null : () => onSelect(number),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      SizedBox(height: accessory),
                      SizedBox(
                          width: graphic,
                          height: graphic,
                          child: Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                if (frontier)
                                  Positioned.fill(
                                      child: Image.asset(
                                          '${adventureMapV3Assets}frontier_glow.png',
                                          excludeFromSemantics: true)),
                                if (frontier || local == 3)
                                  Positioned(
                                      key: Key('stage-accessory-$number'),
                                      left: frontier && local != 3
                                          ? graphic * .46
                                          : graphic * .2,
                                      top: frontier && local != 3
                                          ? -size * .63
                                          : -size * .43,
                                      width: size * .7,
                                      height: size * (local == 3 ? .5 : .8),
                                      child: MapIcon(
                                          local == 3 ? 'crown' : 'flag',
                                          size: size * .8)),
                                SizedBox(
                                    key: Key('stage-medallion-$number'),
                                    width: size,
                                    height: size,
                                    child: Stack(children: [
                                      Positioned.fill(
                                          child: Image.asset(
                                              local == 3 && !unlocked
                                                  ? '${adventureMapV3Assets}node_boss.png'
                                                  : '$adventureMapAssets${done ? 'node_cleared' : unlocked ? 'node_available' : 'node_locked'}.png',
                                              excludeFromSemantics: true)),
                                      Positioned.fill(
                                          child: StageNumber(
                                              key: Key('stage-number-$number'),
                                              number: number,
                                              locked: !unlocked)),
                                      if (!unlocked)
                                        Positioned(
                                            left: size * .325,
                                            top: size * .10,
                                            child: MapIcon('lock',
                                                size: size * .35)),
                                    ])),
                                if (done)
                                  Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child:
                                          MapIcon('check', size: size * .33)),
                              ])),
                      SizedBox(height: size * .035),
                      MapPlate(
                          key: Key('stage-status-$number'),
                          asset: 'node_label',
                          padding: const EdgeInsets.symmetric(
                              horizontal: 2, vertical: 3),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Flexible(
                                    child: Text(label,
                                        textAlign: TextAlign.center,
                                        style: mapText(
                                            math.max(10, width * .014)))),
                                if (done)
                                  const Padding(
                                      padding: EdgeInsets.only(left: 3),
                                      child: MapIcon('replay', size: 12)),
                              ])),
                    ])))));
  }
}

class MapPlate extends StatelessWidget {
  const MapPlate(
      {super.key,
      this.asset = 'details',
      required this.child,
      this.padding = const EdgeInsets.all(16)});
  final String asset;
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('$adventureMapAssets$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

class MapIcon extends StatelessWidget {
  const MapIcon(this.name, {super.key, this.size = 24});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) => Image.asset(
      '${[
        'compass',
        'flag',
        'crown'
      ].contains(name) ? adventureMapV3Assets : adventureMapAssets}icon_$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true);
}

class MapAction extends StatelessWidget {
  const MapAction(
      {super.key, required this.label, this.gold = false, this.onTap});
  final String label;
  final bool gold;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
          opacity: onTap == null ? .55 : 1,
          child: MapPlate(
              asset: gold ? 'button_gold' : 'button_navy',
              padding: EdgeInsets.zero,
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: onTap,
                      child: Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 15, vertical: gold ? 9 : 6),
                          child: Row(children: [
                            if (!gold) const MapIcon('book', size: 20),
                            Expanded(
                                child: Text(label,
                                    textAlign: TextAlign.center,
                                    style: mapText(gold ? 17 : 13,
                                            color: gold
                                                ? const Color(0xff30200e)
                                                : _gold)
                                        .copyWith(shadows: const []))),
                            MapIcon(gold ? 'chevron_dark' : 'chevron',
                                size: 14),
                          ])))))));
}

import '../../../core/widgets/game_ui.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../../../core/widgets/role_logo.dart';
import '../../../core/widgets/quest_widgets.dart';

const _base = 'assets/images/focus_selection_v001/';
const _gold = Color(0xffe9c589);
const _ink = Color(0xff291b0e);

/// Dedicated illustrated scene. All copy and hit targets are live widgets.
class FocusSelectionScene extends StatelessWidget {
  const FocusSelectionScene({
    super.key,
    required this.typeId,
    required this.appearance,
    required this.minutes,
    required this.stage,
    required this.onMinutes,
    required this.onCustom,
    required this.onParty,
    required this.onStart,
    required this.onNavigate,
    required this.onBack,
    this.taskLabel,
    this.onTask,
    this.areaName,
    this.backgroundPath,
    this.onArea,
    this.partyConnected = false,
    this.message,
    this.characterName = '冒険者',
    this.level = 1,
  });
  final String? taskLabel;
  final VoidCallback? onTask;
  final String typeId, appearance;
  final int minutes, stage;
  final ValueChanged<int> onMinutes;
  final VoidCallback onCustom, onBack;
  final ValueChanged<int> onNavigate;
  final VoidCallback? onParty, onStart;
  final bool partyConnected;
  final String? message, areaName, backgroundPath;
  final VoidCallback? onArea;
  final String characterName;
  final int level;

  static String avatarAsset(String type, String appearance) {
    final role = JobPortrait.roleNames.containsKey(type) ? type : 'warrior';
    final sex = appearance == 'female' ? 'female' : 'male';
    return '${_base}avatars/$sex/$role.png';
  }

  Widget _image(String asset) => asset == 'custom_strip'
      ? const DecoratedBox(
          decoration: BoxDecoration(
              color: Color(0xfffff8e9),
              border:
                  Border.fromBorderSide(BorderSide(color: Color(0xffbfa166))),
              borderRadius: BorderRadius.all(Radius.circular(3))))
      : asset == 'avatar_frame'
          ? Image.asset('${_base}avatar_frame.png',
              fit: BoxFit.fill, excludeFromSemantics: true)
          : GameArtwork(switch (asset) {
              'stage_banner' => 'header_banner',
              'party_panel' || 'avatar_frame' => 'identity_panel',
              'parchment_panel' ||
              'time_button' ||
              'custom_strip' =>
                'parchment_panel',
              _ => 'equipment_row',
            });
  Widget _icon(String icon, double size, {Color? color}) =>
      Image.asset('${_base}icon_$icon.png',
          width: size, height: size, color: color, excludeFromSemantics: true);

  TextStyle _text(double size, {Color color = Colors.white}) => TextStyle(
      fontFamily: 'SunlitSerif',
      height: 1.15,
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      shadows: color == Colors.white
          ? const [
              Shadow(color: Colors.black, offset: Offset(0, 1), blurRadius: 3)
            ]
          : null);

  Widget _tap(
          {required String label,
          required Widget child,
          required VoidCallback? onTap,
          bool selected = false}) =>
      Semantics(
          key: label == '戻る' ? const Key('focus-back') : null,
          button: true,
          label: label,
          selected: selected,
          enabled: onTap != null,
          child: Opacity(
              opacity: onTap == null ? .55 : 1,
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                      onTap: onTap,
                      splashColor: _gold.withOpacity(.18),
                      highlightColor: _gold.withOpacity(.12),
                      child: ExcludeSemantics(child: child)))));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xff092036),
      bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
        if (onTask != null)
          Material(
              color: const Color(0xff092036),
              child: ListTile(
                  key: const ValueKey('focus-task'),
                  leading: const Icon(Icons.assignment_outlined, color: _gold),
                  title: Text(taskLabel ?? 'タスクを入力してAIで成長配分を決める',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.edit, color: _gold),
                  onTap: onTask)),
        QuestNavigation(selected: -1, onSelect: onNavigate),
      ]),
      body: Stack(fit: StackFit.expand, children: [
        Positioned.fill(
            child: Image.asset(
                backgroundPath ??
                    (stage == 1
                        ? gameBackground
                        : 'assets/images/stage_backgrounds/ghost_ship_focus_v002.png'),
                fit: BoxFit.cover,
                excludeFromSemantics: true)),
        SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final portrait =
              MediaQuery.orientationOf(context) == Orientation.portrait;
          final contentUnits = message == null ? 952.0 : 1012.0;
          final width = portrait
              ? math.min(constraints.maxWidth, 1024.0)
              : math.min(
                  constraints.maxWidth,
                  math.min(
                      1024.0, constraints.maxHeight * 1024 / contentUnits));
          final scale = width / 1024;
          final height = portrait
              ? math.max(constraints.maxHeight, width * 1.5)
              : contentUnits * scale;
          final startY = portrait ? height - 212 * scale : 768 * scale;
          final panelY = portrait ? startY - 358 * scale : 410 * scale;
          final partyY = portrait ? panelY - 190 * scale : 220 * scale;
          Widget place(double x, double y, double w, double h, Widget child) =>
              Positioned(
                  left: x * scale,
                  top: y,
                  width: w * scale,
                  height: h * scale,
                  child: child);
          return SingleChildScrollView(
              child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(children: [
                        place(
                            22,
                            18 * scale,
                            90,
                            90,
                            _tap(
                                label: '戻る',
                                onTap: onBack,
                                child: Stack(children: [
                                  Positioned.fill(child: _image('back_button')),
                                  Center(child: _icon('back', 52 * scale))
                                ]))),
                        place(
                            274,
                            16 * scale,
                            420,
                            184,
                            GestureDetector(
                                onTap: onArea,
                                behavior: HitTestBehavior.opaque,
                                child: Stack(children: [
                                  Positioned.fill(
                                      child: _image('stage_banner')),
                                  Center(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                        Text(
                                            onArea == null
                                                ? 'STAGE $stage'
                                                : '集中エリア ▾',
                                            style: _text(24 * scale)),
                                        Text(
                                            areaName ??
                                                (stage == 1 ? '草原' : '幽霊船'),
                                            style: _text(48 * scale)),
                                      ]))
                                ]))),
                        place(
                            28,
                            partyY,
                            968,
                            170,
                            Stack(children: [
                              Positioned.fill(child: _image('party_panel')),
                              Positioned(
                                  left: 48 * scale,
                                  top: 12 * scale,
                                  width: 144 * scale,
                                  height: 144 * scale,
                                  child: Stack(children: [
                                    Positioned.fill(
                                        child: Padding(
                                            padding: EdgeInsets.all(8 * scale),
                                            child: Image.asset(
                                                avatarAsset(typeId, appearance),
                                                filterQuality:
                                                    FilterQuality.none,
                                                fit: BoxFit.contain,
                                                semanticLabel:
                                                    '${JobPortrait.roleNames[typeId]}の顔アバター'))),
                                    Positioned.fill(
                                        child: _image('avatar_frame')),
                                  ])),
                              Positioned(
                                  left: 208 * scale,
                                  top: 12 * scale,
                                  right: 24 * scale,
                                  bottom: 12 * scale,
                                  child: Column(children: [
                                    Row(children: [
                                      RoleLogo(role: typeId, size: 52 * scale),
                                      SizedBox(width: 12 * scale),
                                      Expanded(
                                          child: Text(characterName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: _text(34 * scale,
                                                  color: _ink))),
                                      Text('Lv. $level',
                                          style:
                                              _text(30 * scale, color: _ink)),
                                    ]),
                                    Expanded(
                                        child: _tap(
                                            label: partyConnected
                                                ? 'パーティーを見る'
                                                : 'パーティを組む',
                                            onTap: onParty,
                                            child: Stack(children: [
                                              Positioned.fill(
                                                  child: _image('blue_button')),
                                              Center(
                                                  child: Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                    _icon('party', 44 * scale),
                                                    SizedBox(width: 36 * scale),
                                                    Text(
                                                        partyConnected
                                                            ? 'パーティーを見る'
                                                            : 'パーティを組む',
                                                        style:
                                                            _text(33 * scale)),
                                                    SizedBox(width: 28 * scale),
                                                    _icon('chevron', 40 * scale,
                                                        color: Colors.white),
                                                  ])),
                                            ]))),
                                  ])),
                            ])),
                        place(
                            24,
                            panelY,
                            976,
                            342,
                            Stack(children: [
                              Positioned.fill(child: _image('parchment_panel')),
                              Positioned(
                                  left: 40 * scale,
                                  right: 40 * scale,
                                  top: 26 * scale,
                                  height: 64 * scale,
                                  child: Row(children: [
                                    Expanded(
                                        child: _icon('divider', 130 * scale,
                                            color: const Color(0xffb69662))),
                                    SizedBox(width: 20 * scale),
                                    _icon('hourglass', 54 * scale, color: _ink),
                                    SizedBox(width: 20 * scale),
                                    Text('集中時間を選ぶ',
                                        style: _text(42 * scale, color: _ink)),
                                    SizedBox(width: 20 * scale),
                                    Expanded(
                                        child: _icon('divider', 130 * scale,
                                            color: const Color(0xffb69662))),
                                  ])),
                              Positioned(
                                  left: 44 * scale,
                                  right: 44 * scale,
                                  top: 111 * scale,
                                  height: 114 * scale,
                                  child: Row(children: [
                                    for (final m in [15, 30, 45, 60]) ...[
                                      if (m != 15) SizedBox(width: 12 * scale),
                                      Expanded(
                                          child: _tap(
                                              label: '$m分',
                                              selected: minutes == m,
                                              onTap: () => onMinutes(m),
                                              child: Stack(children: [
                                                Positioned.fill(
                                                    child: _image(minutes == m
                                                        ? 'time_selected'
                                                        : 'time_button')),
                                                Center(
                                                    child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                      _icon('hourglass',
                                                          51 * scale,
                                                          color: minutes == m
                                                              ? const Color(
                                                                  0xffffe1a2)
                                                              : _ink),
                                                      SizedBox(
                                                          width: 13 * scale),
                                                      Text('$m分',
                                                          style: _text(
                                                              30 * scale,
                                                              color: minutes ==
                                                                      m
                                                                  ? Colors.white
                                                                  : _ink)),
                                                    ])),
                                              ]))),
                                    ],
                                  ])),
                              Positioned(
                                  left: 44 * scale,
                                  right: 44 * scale,
                                  top: 244 * scale,
                                  height: 74 * scale,
                                  child: _tap(
                                      label: 'カスタム（1〜180分）',
                                      onTap: onCustom,
                                      selected:
                                          ![15, 30, 45, 60].contains(minutes),
                                      child: Stack(children: [
                                        Positioned.fill(
                                            child: _image('custom_strip')),
                                        Positioned.fill(
                                            child: Padding(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 30 * scale),
                                                child: Row(children: [
                                                  _icon('list', 38 * scale,
                                                      color: _ink),
                                                  SizedBox(width: 24 * scale),
                                                  Expanded(
                                                      child: Text(
                                                          ![
                                                            15,
                                                            30,
                                                            45,
                                                            60
                                                          ].contains(minutes)
                                                              ? 'カスタム · $minutes分'
                                                              : 'カスタム（1〜180分）',
                                                          style: _text(
                                                              28 * scale,
                                                              color: _ink))),
                                                  _icon('chevron', 35 * scale,
                                                      color: _ink),
                                                ]))),
                                      ]))),
                            ])),
                        place(
                            95,
                            startY,
                            814,
                            160,
                            _tap(
                                label: '集中を開始',
                                onTap: onStart,
                                child: Stack(children: [
                                  Positioned.fill(child: _image('blue_button')),
                                  Center(
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                        _icon('compass', 92 * scale),
                                        SizedBox(width: 30 * scale),
                                        Text('集中を開始', style: _text(49 * scale)),
                                        SizedBox(width: 14 * scale),
                                        _icon('chevron', 43 * scale,
                                            color: Colors.white),
                                      ]))
                                ]))),
                        if (message != null)
                          place(
                              48,
                              startY + 160 * scale,
                              928,
                              48,
                              Container(
                                  color: const Color(0xdd0b2237),
                                  alignment: Alignment.center,
                                  child: Text(message!,
                                      style: _text(20 * scale),
                                      textAlign: TextAlign.center))),
                      ]))));
        })),
      ]));
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/playable_stage_battle.dart';
import '../../diagnosis/presentation/job_portrait.dart';

const adventureFramePath = 'assets/images/adventure_ui_v001/';

/// Independent PNG frames; game values and interactions stay live widgets.
class AdventureBattleHud extends StatelessWidget {
  const AdventureBattleHud(
      {super.key,
      required this.battle,
      required this.utilities,
      required this.auto,
      required this.onAuto});
  final PlayableStageBattle battle;
  final Widget utilities;
  final bool auto;
  final VoidCallback onAuto;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth;
        final landscape = w > box.maxHeight;
        final commandSide = landscape ? (w * .115).clamp(80.0, 200.0) : 96.0;
        return Stack(children: [
          if (landscape) ...[
            Positioned(
                left: w * .015,
                top: w * .036,
                width: w * .27,
                height: w * .085,
                child: _status()),
            Positioned(
                left: w * .285,
                top: 2,
                width: w * .43,
                height: w * .073,
                child: _title()),
            Positioned(right: 10, top: 8, child: utilities),
            Positioned(
                right: w * .015,
                top: math.max(60, w * .065),
                width: w * .27,
                height: math.max(52, w * .066),
                child: _phase()),
          ] else ...[
            Positioned(
                left: 10, right: 10, top: 5, height: 56, child: _title()),
            Positioned(right: 8, top: 64, child: utilities),
            Positioned(
                left: 10, right: 10, top: 116, height: 98, child: _status()),
            Positioned(
                left: 10, right: 10, top: 218, height: 64, child: _phase()),
          ],
          Positioned(
              right: 10,
              bottom: landscape ? box.maxHeight * .06 : 14,
              child: Row(
                  key: const Key('stage-floating-controls'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _command(false, commandSide),
                    const SizedBox(width: 6),
                    _command(true, commandSide),
                    const SizedBox(width: 6),
                    SizedBox(
                        width: commandSide * .62,
                        height: commandSide * .62,
                        child: Stack(fit: StackFit.expand, children: [
                          const AdventureFrame('auto_button'),
                          FilledButton(
                              key: const Key('stage-auto'),
                              onPressed: onAuto,
                              style: _buttonStyle(),
                              child: FittedBox(
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                    Icon(
                                        auto ? Icons.pause : Icons.fast_forward,
                                        color: const Color(0xffffecc0),
                                        size: 27),
                                    Text(auto ? 'オート ON' : 'オート',
                                        style: _text(12)),
                                  ]))),
                        ])),
                  ])),
        ]);
      });

  Widget _title() => Stack(fit: StackFit.expand, children: [
        const AdventureFrame('stage_banner'),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 15),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                    'STAGE ${battle.stage.number} - ${battle.stage.area}',
                    style: _text(28)))),
      ]);

  Widget _status() {
    final role = JobPortrait.roleNames.entries
        .firstWhere((entry) => entry.value == battle.character.role,
            orElse: () => const MapEntry('warrior', '剣士'))
        .key;
    return Stack(fit: StackFit.expand, children: [
      const AdventureFrame('status_panel'),
      Padding(
          padding: const EdgeInsets.all(16),
          child: FittedBox(
              child: SizedBox(
                  width: 410,
                  height: 112,
                  child: Row(children: [
                    SizedBox(
                        width: 98,
                        height: 104,
                        child: Stack(fit: StackFit.expand, children: [
                          Padding(
                              padding: const EdgeInsets.all(8),
                              child: ClipRect(
                                  child: JobPortrait(
                                      typeId: role,
                                      appearance: battle.character.female
                                          ? 'female'
                                          : 'male',
                                      lobby: true,
                                      fit: BoxFit.cover,
                                      alignment: Alignment.topCenter))),
                          const AdventureFrame('portrait_frame'),
                        ])),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                          Row(children: [
                            Expanded(
                                child: Text(battle.character.role,
                                    style: _text(25))),
                            Text('Lv. ${battle.character.level}',
                                style: _text(20, gold: true))
                          ]),
                          const Divider(height: 14, color: Color(0xffad8646)),
                          Text('HP  ${battle.hp} / ${battle.character.health}',
                              style: _text(20)),
                          const SizedBox(height: 7),
                          SizedBox(
                              height: 18,
                              child: Stack(fit: StackFit.expand, children: [
                                const AdventureFrame('hp_frame'),
                                Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: LinearProgressIndicator(
                                            value: (battle.hp /
                                                    battle.character.health)
                                                .clamp(0.0, 1.0),
                                            color: const Color(0xff85f42e),
                                            backgroundColor:
                                                const Color(0xff23391e)))),
                              ])),
                        ])),
                  ]))))
    ]);
  }

  Widget _phase() => Stack(fit: StackFit.expand, children: [
        const AdventureFrame('phase_panel'),
        Padding(
            padding: const EdgeInsets.fromLTRB(72, 9, 14, 8),
            child: FittedBox(
                child: SizedBox(
                    width: 330,
                    height: 80,
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            flex: 3,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text('PHASE ${battle.phase + 1} / 3',
                                    style: _text(23)))),
                        const SizedBox(width: 10),
                        Expanded(
                            flex: 2,
                            child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('残り ${battle.remainingEnemies} 体',
                                    style: _text(20))))
                      ]),
                      const SizedBox(height: 12),
                      Row(children: [
                        for (var i = 0; i < 3; i++) ...[
                          Container(
                              width: 17,
                              height: 17,
                              decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: i <= battle.phase
                                      ? const Color(0xff59efff)
                                      : const Color(0xff253546),
                                  border: Border.all(
                                      color: i <= battle.phase
                                          ? Colors.white
                                          : Colors.grey,
                                      width: 2))),
                          if (i < 2)
                            Expanded(
                                child: Container(
                                    height: 3,
                                    color: i < battle.phase
                                        ? const Color(0xff59efff)
                                        : Colors.grey)),
                        ]
                      ]),
                    ])))),
      ]);

  Widget _command(bool skill, double side) {
    final onTap = skill
        ? (battle.canSkill ? battle.skill : null)
        : (battle.canAttack ? battle.attack : null);
    final caption = skill
        ? '命中 ${battle.charge} / 3'
        : '${battle.attackDuration.toStringAsFixed(2)}秒 / 回';
    return SizedBox(
        width: side,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
              height: side,
              child: Stack(fit: StackFit.expand, children: [
                AdventureFrame(skill ? 'skill_button' : 'attack_button'),
                FilledButton(
                    key: Key(skill ? 'stage-skill' : 'stage-attack'),
                    onPressed: onTap,
                    style: _buttonStyle(),
                    child: FittedBox(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      skill
                          ? Icon(Icons.cyclone,
                              size: side * .30, color: const Color(0xff86f5ff))
                          : CustomPaint(
                              size: Size.square(side * .30),
                              painter: const _SwordIcon()),
                      Text(skill ? 'スキル' : '攻撃', style: _text(side * .18)),
                    ]))),
              ])),
          SizedBox(
              height: 28,
              child: Stack(fit: StackFit.expand, children: [
                const AdventureFrame('caption_frame'),
                Center(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 9),
                        child:
                            FittedBox(child: Text(caption, style: _text(12))))),
              ])),
        ]));
  }

  static TextStyle _text(double size, {bool gold = false}) => TextStyle(
          fontFamily: 'SunlitSerif',
          fontSize: size,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: gold ? const Color(0xffffd477) : const Color(0xfffff8e8),
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1))
          ]);
  static ButtonStyle _buttonStyle() => FilledButton.styleFrom(
      padding: const EdgeInsets.all(8),
      shape: const CircleBorder(),
      backgroundColor: Colors.transparent,
      disabledBackgroundColor: const Color(0x44202020),
      foregroundColor: const Color(0xfffff8e8),
      disabledForegroundColor: Colors.white54);
}

class AdventureFrame extends StatelessWidget {
  const AdventureFrame(this.name, {super.key});
  final String name;
  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: Image.asset('$adventureFramePath$name.png',
          fit: BoxFit.fill, excludeFromSemantics: true));
}

class _SwordIcon extends CustomPainter {
  const _SwordIcon();
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xffffefcb);
    final s = size.width;
    final blade = Path()
      ..moveTo(s * .39, s * .54)
      ..lineTo(s * .78, s * .08)
      ..lineTo(s * .94, s * .02)
      ..lineTo(s * .89, s * .22)
      ..lineTo(s * .48, s * .63)
      ..close();
    canvas.drawPath(blade, paint);
    paint
      ..strokeWidth = s * .07
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(s * .29, s * .50), Offset(s * .57, s * .78), paint);
    canvas.drawLine(Offset(s * .40, s * .65), Offset(s * .18, s * .87), paint);
    canvas.drawCircle(Offset(s * .14, s * .90), s * .075, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

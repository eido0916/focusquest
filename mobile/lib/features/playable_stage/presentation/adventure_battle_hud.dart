import '../../../core/widgets/game_ui.dart';
import 'adventure_stage_layout.dart';
import 'package:flutter/material.dart';
import '../domain/playable_stage_battle.dart';

const adventureFramePath = 'assets/images/adventure_ui_v001/';

/// Independent PNG frames; game values and interactions stay live widgets.
class AdventureBattleHud extends StatelessWidget {
  const AdventureBattleHud(
      {super.key, required this.battle, required this.utilities});
  final PlayableStageBattle battle;
  final Widget utilities;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final layout = AdventureStageLayout(box.biggest);
        final commandSide = layout.commandSide;
        return Stack(children: [
          Positioned(
              right: 10, top: layout.landscape ? 8 : 74, child: utilities),
          Positioned(
              left: 14,
              top: 12,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('STAGE ${battle.stage.number} - ${battle.stage.area}',
                        style: _text(14)),
                    const SizedBox(height: 3),
                    Text('PHASE ${battle.phase + 1} / 3', style: _text(14)),
                  ])),
          Positioned(
              right: 10,
              bottom: 14,
              child: Row(
                  key: const Key('stage-floating-controls'),
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _command(false, commandSide),
                    const SizedBox(width: 6),
                    _command(true, commandSide),
                  ])),
        ]);
      });

  Widget _command(bool skill, double side) {
    final onTap = skill
        ? (battle.canSkill ? battle.skill : null)
        : (battle.canAttack ? battle.attack : null);
    return SizedBox(
        width: side,
        height: side,
        child: Stack(fit: StackFit.expand, children: [
          Padding(
              padding: EdgeInsets.all(skill ? 6 : 0),
              child: AdventureFrame(skill ? 'skill_button' : 'attack_button')),
          if (skill)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                    key: const Key('stage-skill-charge'),
                    value: battle.charge / PlayableStageBattle.chargeNeeded,
                    strokeWidth: 3,
                    color: battle.charge >= PlayableStageBattle.chargeNeeded
                        ? const Color(0xffffd477)
                        : const Color(0xff86f5ff),
                    backgroundColor: const Color(0xff233b51),
                    semanticsLabel: 'スキル発動ゲージ',
                    semanticsValue:
                        '${battle.charge} / ${PlayableStageBattle.chargeNeeded}',
                  ),
                ),
              ),
            ),
          FilledButton(
              key: Key(skill ? 'stage-skill' : 'stage-attack'),
              onPressed: onTap,
              style: _buttonStyle(),
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    skill
                        ? Icon(Icons.cyclone,
                            size: side * .30, color: const Color(0xff86f5ff))
                        : CustomPaint(
                            size: Size.square(side * .30),
                            painter: const _SwordIcon()),
                    Text(skill ? 'スキル' : '攻撃',
                        style: _text((side * .20).clamp(12.0, 16.0))),
                  ]))),
        ]));
  }

  static TextStyle _text(double size) => TextStyle(
          fontFamily: 'SunlitSerif',
          fontSize: size,
          height: 1.2,
          fontWeight: FontWeight.bold,
          color: const Color(0xfffff8e8),
          shadows: const [
            Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0, 1))
          ]);
  static ButtonStyle _buttonStyle() => FilledButton.styleFrom(
      padding: const EdgeInsets.all(6),
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
          child: switch (name) {
        'utility_button' => const GameArtwork('equipment_row', minimumScale: 8),
        _ => Image.asset('$adventureFramePath$name.png',
            fit: BoxFit.fill, excludeFromSemantics: true),
      });
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

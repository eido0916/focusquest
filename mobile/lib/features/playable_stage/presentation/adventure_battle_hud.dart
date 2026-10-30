import '../../../core/widgets/game_ui.dart';
import 'adventure_stage_layout.dart';
import 'package:flutter/material.dart';
import '../domain/playable_stage_battle.dart';
import '../../diagnosis/presentation/job_portrait.dart';

const adventureFramePath = 'assets/images/adventure_ui_v001/';

/// Independent PNG frames; game values and interactions stay live widgets.
class AdventureBattleHud extends StatelessWidget {
  const AdventureBattleHud(
      {super.key, required this.battle, required this.utilities});
  final PlayableStageBattle battle;
  final Widget utilities;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (_, box) {
        final w = box.maxWidth;
        final landscape = w > box.maxHeight;
        final layout = AdventureStageLayout(box.biggest);
        final commandSide = layout.commandSide;
        final compact = w < 1000 || box.maxHeight < 500;
        return Stack(children: [
          if (landscape) ...[
            Positioned(
                left: 12,
                top: 48,
                width: w * (compact ? .36 : .27),
                height: compact ? 82 : 124,
                child: _status()),
            Positioned(
                left: w * (compact ? .25 : .30),
                top: 4,
                width: w * (compact ? .47 : .40),
                height: compact ? 52 : 84,
                child: _title()),
            Positioned(right: 10, top: 8, child: utilities),
            Positioned(
                left: compact ? w * .36 + 20 : null,
                right: compact ? null : 12,
                top: compact ? 62 : 100,
                width: w * (compact ? .26 : .27),
                height: 82,
                child: _phase()),
          ] else ...[
            Positioned(
                left: 10, right: 10, top: 5, height: 64, child: _title()),
            Positioned(right: 8, top: 74, child: utilities),
            Positioned(
                left: 10, right: 10, top: 128, height: 104, child: _status()),
            Positioned(
                left: 10, right: 10, top: 238, height: 68, child: _phase()),
          ],
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

  Widget _title() => Stack(fit: StackFit.expand, children: [
        const AdventureFrame('stage_banner'),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
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
    return LayoutBuilder(builder: (context, bounds) {
      final small = bounds.maxHeight < 100;
      final font = small
          ? 14.0
          : bounds.maxWidth > 420
              ? 22.0
              : 18.0;
      return Stack(fit: StackFit.expand, children: [
        const AdventureFrame('status_panel'),
        Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                    width: bounds.maxWidth - 56,
                    child: Row(children: [
                      if (bounds.maxWidth >= 340) ...[
                        SizedBox(
                            width: 64,
                            child: JobPortrait(
                                typeId: role,
                                appearance:
                                    battle.character.female ? 'female' : 'male',
                                lobby: true)),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                            Row(children: [
                              Expanded(
                                  child: Text(battle.character.role,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: _text(font))),
                              const SizedBox(width: 6),
                              Text('Lv. ${battle.character.level}',
                                  style: _text(font, gold: true)),
                            ]),
                            const SizedBox(height: 4),
                            Text(
                                'HP  ${battle.hp} / ${battle.character.health}',
                                style: _text(font)),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                                minHeight: small ? 4 : 8,
                                value: (battle.hp / battle.character.health)
                                    .clamp(0.0, 1.0),
                                color: const Color(0xff85f42e),
                                backgroundColor: const Color(0xff23391e)),
                          ])),
                    ])))),
      ]);
    });
  }

  Widget _phase() => LayoutBuilder(builder: (context, bounds) {
        final font = bounds.maxWidth < 320
            ? 14.0
            : bounds.maxWidth > 420
                ? 22.0
                : 18.0;
        return Stack(fit: StackFit.expand, children: [
          const AdventureFrame('phase_panel'),
          Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 18),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                              child: Text('PHASE ${battle.phase + 1} / 3',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _text(font))),
                          Expanded(
                              child: Text('残り ${battle.remainingEnemies} 体',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  style: _text(font))),
                        ]),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                        minHeight: 4,
                        value: (battle.phase + 1) / 3,
                        color: const Color(0xff59efff),
                        backgroundColor: const Color(0xff253546)),
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
              padding: EdgeInsets.all(skill ? 9 : 0),
              child: AdventureFrame(skill ? 'skill_button' : 'attack_button')),
          if (skill)
            Positioned.fill(
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: CircularProgressIndicator(
                    key: const Key('stage-skill-charge'),
                    value: battle.charge / PlayableStageBattle.chargeNeeded,
                    strokeWidth: 5,
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                skill
                    ? Icon(Icons.cyclone,
                        size: side * .30, color: const Color(0xff86f5ff))
                    : CustomPaint(
                        size: Size.square(side * .30),
                        painter: const _SwordIcon()),
                Text(skill ? 'スキル' : '攻撃', style: _text(side * .18)),
              ]))),
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
          child: switch (name) {
        'stage_banner' ||
        'phase_panel' ||
        'caption_frame' =>
          const GameArtwork('header_banner'),
        'status_panel' => const GameArtwork('identity_panel'),
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

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

/// UI image paths are relative to assets/images/.
class BattleUiAssets {
  static const window = 'character_ui_v002/equipment_row.png';
  static const skillOrb = 'ui/focus_skill_orb.png';
  static const String? levelLogo = null;
}

class FantasyBattleHud {
  FantasyBattleHud({required this.window, required this.orb, this.logo});
  final ui.Image window;
  final ui.Image orb;
  final ui.Image? logo;
  static const gold = Color(0xfff5d68f);
  static const cyan = Color(0xffa9f4ff);
  static const menuRect = Rect.fromLTWH(777, 4, 180, 52);
  static const statusRect = Rect.fromLTWH(4, 68, 952, 105);
  static const bossRect = Rect.fromLTWH(545, 185, 395, 90);
  static String clockText(int seconds) =>
      '${(seconds ~/ 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';

  void frame(Canvas canvas, Rect rect) {
    // Preserve the sculpted endcaps while stretching only the blank interior.
    final scale = rect.height / window.height;
    canvas.save();
    canvas.translate(rect.left, rect.top);
    canvas.scale(scale);
    canvas.drawImageNine(
        window,
        Rect.fromLTRB(window.width * .24, window.height * .36,
            window.width * .76, window.height * .64),
        Rect.fromLTWH(0, 0, rect.width / scale, window.height.toDouble()),
        Paint()..filterQuality = FilterQuality.high);
    canvas.restore();
  }

  void paint(Canvas canvas, BattleStateController state, int level, String job,
      {String? name}) {
    frame(canvas, statusRect);
    frame(canvas, const Rect.fromLTWH(5, 408, 375, 140));
    frame(canvas, const Rect.fromLTWH(595, 408, 360, 140));
    frame(canvas, menuRect);
    text(canvas, state.areaName, const Rect.fromLTWH(76, 100, 232, 38), 26,
        gold);
    for (final x in [323.0, 535.0, 728.0]) {
      canvas.drawLine(
          Offset(x, 91),
          Offset(x, 147),
          Paint()
            ..color = gold.withOpacity(.7)
            ..strokeWidth = .7);
    }
    icon(canvas, Icons.hourglass_bottom_outlined, const Offset(346, 94), 28);
    text(
        canvas, '経過時間', const Rect.fromLTWH(380, 92, 78, 25), 15, Colors.white);
    text(canvas, clockText(state.elapsedSeconds.floor()),
        const Rect.fromLTWH(458, 89, 69, 29), 22, cyan);
    text(canvas, '残り時間', const Rect.fromLTWH(380, 124, 78, 25), 15,
        Colors.white);
    text(canvas, clockText(state.focusRemainingSeconds),
        const Rect.fromLTWH(458, 121, 69, 29), 22, cyan);
    icon(canvas, Icons.sports_martial_arts, const Offset(556, 107), 27);
    text(
        canvas, '討伐数', const Rect.fromLTWH(590, 109, 62, 26), 15, Colors.white);
    text(canvas, '${state.defeatedCount}',
        const Rect.fromLTWH(662, 106, 58, 31), 23, cyan);
    icon(canvas, Icons.auto_awesome, const Offset(749, 107), 27);
    text(
        canvas, 'EXP', const Rect.fromLTWH(784, 109, 43, 26), 17, Colors.white);
    text(canvas, '${state.focusRewardExp} / ${state.focusTotalRewardExp}',
        const Rect.fromLTWH(834, 106, 87, 31), 23, cyan);
    jewel(canvas, const Offset(480, 83), 6);
    jewel(canvas, const Offset(480, 157), 6);

    if (state.isBossBattle) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(bossRect, const Radius.circular(8)),
          Paint()..color = const Color(0xee072641));
      canvas.drawRRect(
          RRect.fromRectAndRadius(bossRect, const Radius.circular(8)),
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
      final left = state.bossRemainingSeconds.ceil();
      text(canvas, 'BOSS · ${state.bossName}',
          const Rect.fromLTWH(575, 200, 330, 28), 22, gold);
      text(
          canvas,
          '撃破まで ${left ~/ 60}:${(left % 60).toString().padLeft(2, '0')}',
          const Rect.fromLTWH(575, 231, 330, 25),
          19,
          cyan);
      canvas.drawRect(
          const Rect.fromLTWH(575, 259, 330, 5), Paint()..color = Colors.black);
      canvas.drawRect(
          Rect.fromLTWH(575, 259, 330 * state.bossRemainingSeconds / 300, 5),
          Paint()..color = const Color(0xffda5a62));
    }

    // The full badge slot remains independent of the window and level text.
    const logoRect = Rect.fromLTWH(42, 426, 80, 92);
    if (logo != null) {
      paintImage(
          canvas: canvas,
          rect: logoRect,
          image: logo!,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high);
    } else {
      final path = Path()
        ..moveTo(82, 429)
        ..lineTo(119, 450)
        ..lineTo(115, 489)
        ..quadraticBezierTo(110, 505, 82, 518)
        ..quadraticBezierTo(54, 505, 49, 489)
        ..lineTo(45, 450)
        ..close();
      canvas.drawPath(path, Paint()..color = const Color(0xff0a345a));
      canvas.drawPath(
          path,
          Paint()
            ..color = gold
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5);
      jewel(canvas, const Offset(82, 473), 19);
    }
    if (name != null) {
      text(canvas, name, const Rect.fromLTWH(137, 442, 201, 32), 25,
          Colors.white);
      text(canvas, 'Lv. $level · $job', const Rect.fromLTWH(137, 477, 201, 26),
          18, gold);
    } else {
      text(canvas, 'Lv. $level', const Rect.fromLTWH(145, 461, 103, 38), 29,
          Colors.white);
      text(
          canvas, job, const Rect.fromLTWH(255, 459, 85, 41), 29, Colors.white);
    }
    rule(canvas, 143, 338, 504);
    paintImage(
        canvas: canvas,
        rect: const Rect.fromLTWH(611, 425, 104, 104),
        image: orb,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high);
    text(canvas, 'スキル 自動発動', const Rect.fromLTWH(724, 445, 200, 27), 21, gold);
    rule(canvas, 726, 920, 476);
    if (state.isSkillPlaying) {
      text(canvas, '${state.skillName} 発動中',
          const Rect.fromLTWH(725, 477, 195, 28), 23, cyan);
    } else {
      final countdown =
          state.secondsUntilSousen.ceil().toString().padLeft(2, '0');
      text(canvas, '${state.skillName}まで',
          const Rect.fromLTWH(725, 479, 98, 25), 17, Colors.white);
      text(canvas, countdown, const Rect.fromLTWH(823, 473, 57, 33), 32, cyan);
      text(
          canvas, '秒', const Rect.fromLTWH(884, 479, 30, 25), 17, Colors.white);
    }
  }

  void text(Canvas canvas, String value, Rect rect, double size, Color color) {
    final p = TextPainter(
        text: TextSpan(
            text: value,
            style: TextStyle(
                fontFamily: 'SunlitSerif',
                fontSize: size,
                color: color,
                fontWeight: FontWeight.w600,
                shadows: [
                  const Shadow(color: Colors.black, blurRadius: 3),
                  if (color == cyan)
                    const Shadow(color: Color(0xff0ab8ff), blurRadius: 7)
                ])),
        maxLines: 1,
        textDirection: TextDirection.ltr)
      ..layout();
    final scale = p.width > rect.width ? rect.width / p.width : 1.0;
    canvas.save();
    canvas.translate(
        rect.left, rect.top + (rect.height - p.height * scale) / 2);
    canvas.scale(scale);
    p.paint(canvas, Offset.zero);
    canvas.restore();
  }

  void icon(Canvas c, IconData icon, Offset point, double size) {
    final p = TextPainter(
        text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
                fontFamily: icon.fontFamily, fontSize: size, color: gold)),
        textDirection: TextDirection.ltr)
      ..layout();
    p.paint(c, point);
  }

  void rule(Canvas c, double left, double right, double y) {
    c.drawLine(
        Offset(left, y),
        Offset(right, y),
        Paint()
          ..color = gold
          ..strokeWidth = .8);
    jewel(c, Offset((left + right) / 2, y), 4);
  }

  void jewel(Canvas c, Offset p, double r) {
    final path = Path()
      ..moveTo(p.dx, p.dy - r)
      ..lineTo(p.dx + r * .55, p.dy)
      ..lineTo(p.dx, p.dy + r)
      ..lineTo(p.dx - r * .55, p.dy)
      ..close();
    c.drawPath(path, Paint()..color = const Color(0xff209fea));
    c.drawPath(
        path,
        Paint()
          ..color = gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
    c.drawLine(
        Offset(p.dx, p.dy - r * .6),
        Offset(p.dx, p.dy + r * .6),
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1);
  }
}

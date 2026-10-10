import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/playable_stage_battle.dart';
import 'playable_stage_assets.dart';
import 'stage_projectile_painter.dart';

class PlayableStagePainter extends CustomPainter {
  PlayableStagePainter(this.battle, this.assets, this.pixelRatio)
      : super(repaint: battle);
  final PlayableStageBattle battle;
  final PlayableStageAssets assets;
  final double pixelRatio;
  final Paint pixelPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  static double baseSpriteSide(Size size, double pixelRatio) {
    final grid = math.max(
        1,
        math
            .min(size.width * pixelRatio / 330,
                size.height * pixelRatio * .72 / (64 * 3))
            .floor());
    return 64 * grid / pixelRatio;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    final height = math.max(size.height,
        size.width / assets.background.width * assets.background.height);
    final ground = battle.stage.groundLine;
    final top = size.height * ground - height * ground;
    final width = height * assets.background.width / assets.background.height;
    final shift = (battle.distance * .35 / 1280 * size.width) % width;
    final left = (size.width - width) / 2 - shift;
    final source = Rect.fromLTWH(0, 0, assets.background.width.toDouble(),
        assets.background.height.toDouble());
    canvas.drawImageRect(assets.background, source,
        Rect.fromLTWH(left, top, width, height), pixelPaint);
    if (left + width < size.width) {
      canvas.drawImageRect(assets.background, source,
          Rect.fromLTWH(left + width, top, width, height), pixelPaint);
    }

    final motion = battle.action == null
        ? battle.mode == StageMode.travel
            ? 'hero_run'
            : 'hero_idle'
        : battle.action == HeroAction.skill
            ? 'hero_skill'
            : 'hero_attack';
    _sprite(
        canvas,
        size,
        motion,
        battle.action == null
            ? battle.mode == StageMode.travel
                ? battle.modeTime
                : battle.clock
            : battle.actionTime *
                assets.motions[motion]!.duration /
                (battle.action == HeroAction.skill
                    ? battle.skillDuration
                    : battle.attackDuration),
        battle.heroX,
        loop: battle.action == null);
    for (final unit in [...battle.enemies]
      ..sort((a, b) => b.homeX.compareTo(a.homeX))) {
      final enemy = unit.definition.id;
      if (!unit.alive && unit.deathTime < unit.defeatDuration) {
        _sprite(canvas, size, '${enemy}_defeat', unit.deathTime, unit.deathX,
            boss: unit.definition.isBoss);
      } else if (unit.alive && battle.mode == StageMode.battle) {
        _sprite(
            canvas,
            size,
            '${enemy}_${unit.attacking ? 'attack' : 'locomotion'}',
            unit.attacking
                ? unit.actionTime
                : battle.modeTime + unit.index * .15,
            unit.x,
            boss: unit.definition.isBoss,
            loop: !unit.attacking);
      } else if (unit.alive &&
          battle.mode == StageMode.travel &&
          battle.modeTime > 1.8) {
        _sprite(canvas, size, '${enemy}_locomotion', battle.modeTime, unit.x,
            loop: true, boss: unit.definition.isBoss);
      }
    }
    final side = baseSpriteSide(size, pixelRatio);
    for (final projectile in battle.projectiles) {
      paintStageProjectile(
          canvas,
          projectile,
          Offset(projectile.x / 1280 * size.width,
              size.height * battle.stage.groundLine - side * projectile.height),
          side / 64,
          pixelRatio);
    }
    for (final damage in battle.damageNumbers) {
      final age = battle.clock - damage.createdAt;
      final text = TextPainter(
          text: TextSpan(
              text: damage.miss
                  ? 'MISS'
                  : '${damage.critical ? 'CRITICAL\n' : ''}${damage.toHero ? '−' : ''}${damage.amount}',
              style: TextStyle(
                  fontFamily: 'SunlitSerif',
                  fontSize: size.width < 500 ? 18 : 25,
                  fontWeight: FontWeight.w900,
                  color: damage.miss
                      ? const Color(0xffd4dce2)
                      : damage.critical
                          ? const Color(0xffffd36a)
                          : damage.toHero
                              ? const Color(0xffffc9b0)
                              : damage.skill
                                  ? const Color(0xffd9ffe2)
                                  : const Color(0xfffff2bf),
                  shadows: const [
                    Shadow(
                        color: Color(0xff173025),
                        blurRadius: 3,
                        offset: Offset(1, 2))
                  ])),
          textDirection: TextDirection.ltr)
        ..layout();
      text.paint(
          canvas,
          Offset(
              damage.x / 1280 * size.width - text.width / 2,
              size.height * battle.stage.groundLine -
                  baseSpriteSide(size, pixelRatio) *
                      (damage.targetIsBoss ? 3 : 1) *
                      .8 -
                  text.height -
                  age * 35));
    }
    canvas.restore();
  }

  void _sprite(Canvas canvas, Size size, String name, double time, double x,
      {bool loop = false, bool boss = false}) {
    final motion = assets.motions[name]!;
    final frame = motion.frame(
        name == 'hero_idle' && motion.metadata['action'] != 'idle' ? 0 : time,
        loop: loop);
    final anchor = motion.metadata['sprite_anchor_px'] as List<dynamic>?;
    final anchorY = anchor == null ? 114.0 : (anchor[1] as num).toDouble();
    // Uniform scale for every action; each original 64px logical pixel gets
    // an integer number of physical pixels, with point sampling and no rotation.
    final side = baseSpriteSide(size, pixelRatio) * (boss ? 3 : 1);
    final ratio = side / 128;
    double snap(double value) => (value * pixelRatio).round() / pixelRatio;
    final left =
        snap(x / 1280 * size.width - side / 2 + frame.offset.dx * ratio);
    final top = snap(size.height * battle.stage.groundLine -
        anchorY * ratio +
        frame.offset.dy * ratio);
    canvas.drawImageRect(frame.image, const Rect.fromLTWH(0, 0, 128, 128),
        Rect.fromLTWH(left, top, side, side), pixelPaint);
  }

  @override
  bool shouldRepaint(PlayableStagePainter oldDelegate) =>
      oldDelegate.assets != assets ||
      oldDelegate.battle != battle ||
      oldDelegate.pixelRatio != pixelRatio;
}

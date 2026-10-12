import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_character.dart';
import 'playable_stage_assets.dart';
import 'stage_projectile_painter.dart';

class PlayableStagePainter extends CustomPainter {
  PlayableStagePainter(this.battle, this.assets, this.pixelRatio,
      {this.bottomInset = 0})
      : super(repaint: battle);
  final PlayableStageBattle battle;
  final PlayableStageAssets assets;
  final double pixelRatio;
  final double bottomInset;

  static Size worldSize(Size size, double bottomInset) =>
      Size(size.width, math.max(1, size.height - bottomInset));

  String get heroMotion => battle.action == null
      ? battle.mode == StageMode.travel
          ? 'hero_run'
          : 'hero_idle'
      : battle.action == HeroAction.skill
          ? 'hero_skill'
          : 'hero_attack';

  double get heroTime => battle.action == null
      ? battle.mode == StageMode.travel
          ? battle.modeTime
          : battle.clock
      : battle.actionTime *
          assets.motions[heroMotion]!.duration /
          (battle.action == HeroAction.skill
              ? battle.skillDuration
              : battle.attackDuration);

  Offset heroHead(Size canvasSize) => _head(
      worldSize(canvasSize, bottomInset), heroMotion, heroTime, battle.heroX,
      loop: battle.action == null);

  Offset enemyHead(Size canvasSize, StageEnemy enemy) => _head(
      worldSize(canvasSize, bottomInset),
      '${enemy.definition.id}_${enemy.attacking ? 'attack' : 'locomotion'}',
      enemy.attacking
          ? enemy.actionTime
          : battle.mode == StageMode.travel
              ? battle.modeTime
              : battle.modeTime + enemy.index * .15,
      enemy.x,
      boss: enemy.definition.isBoss,
      loop: !enemy.attacking);

  Offset _head(Size size, String name, double time, double x,
      {bool loop = false, bool boss = false}) {
    final motion = assets.motions[name]!;
    final frame = motion.frame(
        name == 'hero_idle' && motion.metadata['action'] != 'idle' ? 0 : time,
        loop: loop);
    final anchor = motion.metadata['sprite_anchor_px'] as List<dynamic>?;
    final anchorY = anchor == null ? 114.0 : (anchor[1] as num).toDouble();
    final ratio = baseSpriteSide(size, pixelRatio) * (boss ? 3 : 1) / 128;
    return Offset(
        x / 1280 * size.width + frame.offset.dx * ratio,
        size.height * battle.stage.groundLine +
            (frame.topPixel * 128 / frame.image.height -
                    anchorY +
                    frame.offset.dy) *
                ratio);
  }

  final Paint pixelPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  static double baseSpriteSide(Size size, double pixelRatio) {
    final grid = math.max(
        1,
        math
            .min(size.width * pixelRatio / 300,
                size.height * pixelRatio * .9 / (64 * 3))
            .floor());
    return 64 * grid / pixelRatio;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final canvasSize = size;
    size = worldSize(size, bottomInset);
    canvas.save();
    canvas.clipRect(Offset.zero & canvasSize);
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
    // Extend only the static ground texture underneath the floating controls.
    // Actors keep their original frames and integer pixel scale above them.
    final backgroundBottom = top + height;
    if (backgroundBottom < canvasSize.height) {
      final groundSource = Rect.fromLTWH(0, assets.background.height - 64.0,
          assets.background.width.toDouble(), 64);
      final tileHeight = 64 * height / assets.background.height;
      for (var y = backgroundBottom; y < canvasSize.height; y += tileHeight) {
        canvas.drawImageRect(assets.background, groundSource,
            Rect.fromLTWH(left, y, width, tileHeight), pixelPaint);
        if (left + width < canvasSize.width) {
          canvas.drawImageRect(assets.background, groundSource,
              Rect.fromLTWH(left + width, y, width, tileHeight), pixelPaint);
        }
      }
    }

    // Dim scenery only. Original sprite pixels keep their brightness and color.
    canvas.drawRect(
        Offset.zero & canvasSize, Paint()..color = const Color(0x26000000));

    final motion = heroMotion;
    _sprite(canvas, size, motion, heroTime, battle.heroX,
        loop: battle.action == null);
    if (battle.character.role == 'バーサーカー' &&
        battle.action == HeroAction.skill) {
      final skill = assets.motions['hero_skill']!;
      final tick = (heroTime * 24).floor().clamp(0, skill.timeline.length - 1);
      final key = skill.timeline[tick]['keyframe'] as int;
      if (key >= 3 && key < 8) {
        final offset =
            (assets.floorMetadata['character_floor_centers_from_feet_px']
                as List)[key] as List;
        final side = baseSpriteSide(size, pixelRatio);
        final image = assets
            .effects['floor_${battle.stage.floorMaterial}_${key < 6 ? 0 : 1}']!;
        final center = Offset(
            battle.heroX / 1280 * size.width + (offset[0] as num) * side / 128,
            size.height * battle.stage.groundLine +
                (offset[1] as num) * side / 128);
        canvas.drawImageRect(
            image,
            const Rect.fromLTWH(0, 0, 128, 128),
            Rect.fromLTWH(
                ((center.dx - side / 2) * pixelRatio).round() / pixelRatio,
                ((center.dy - side / 2) * pixelRatio).round() / pixelRatio,
                side,
                side),
            pixelPaint);
      }
    }
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
          pixelRatio,
          image: assets.effects[projectile.kind == ProjectileKind.floor
              ? 'floor_${battle.stage.floorMaterial}_${projectile.resolved && !projectile.missed ? 3 : 2}'
              : projectile.resolved && !projectile.missed
                  ? 'impact'
                  : switch (projectile.kind) {
                      ProjectileKind.holySword => 'holy_sword',
                      ProjectileKind.holyOrb => 'holy_orb',
                      ProjectileKind.darkWave => 'dark_wave',
                      ProjectileKind.lightning ||
                      ProjectileKind.spirits ||
                      ProjectileKind.curse =>
                        'impact',
                      _ => projectile.kind.name,
                    }]);
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
                        color: Colors.black,
                        blurRadius: 4,
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
    // Canvas resolution may vary (128px actors, 384px detailed bosses).
    // Foot anchors/world offsets keep their original 128px coordinate units.
    // Draw the complete original frame with point sampling and no deformation.
    final side = baseSpriteSide(size, pixelRatio) * (boss ? 3 : 1);
    final ratio = side / 128;
    double snap(double value) => (value * pixelRatio).round() / pixelRatio;
    final left =
        snap(x / 1280 * size.width - side / 2 + frame.offset.dx * ratio);
    final top = snap(size.height * battle.stage.groundLine -
        anchorY * ratio +
        frame.offset.dy * ratio);
    canvas.drawImageRect(
        frame.image,
        Rect.fromLTWH(
            0, 0, frame.image.width.toDouble(), frame.image.height.toDouble()),
        Rect.fromLTWH(left, top, side, side),
        pixelPaint);
  }

  @override
  bool shouldRepaint(PlayableStagePainter oldDelegate) =>
      oldDelegate.assets != assets ||
      oldDelegate.battle != battle ||
      oldDelegate.bottomInset != bottomInset ||
      oldDelegate.pixelRatio != pixelRatio;
}

import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../core/assets/asset_catalog.dart';
import 'battle/battle_engine.dart';

/// Placeholder renderer. ActorPose is the replacement boundary for sprites.
class FocusBattleGame extends FlameGame {
  FocusBattleGame(this.engine, this.onFinished,
      {this.heroAssetKey = 'hero.warrior'});
  final String heroAssetKey;
  final Map<String, ui.Image> _art = {};
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    for (final key in [heroAssetKey, 'enemy.slime', 'background.forest']) {
      for (final variant in [
        key,
        ...ActorPose.values.map((pose) => '$key.${pose.name}')
      ]) {
        final path = AssetCatalog.image(variant);
        if (path != null) {
          try {
            _art[variant] = await images.load(path);
          } catch (_) {/* Unavailable assets keep their drawn placeholder. */}
        }
      }
    }
  }

  final BattleEngine engine;
  final VoidCallback onFinished;
  double _time = 0;
  double _impactAge = 1;
  DamageEvent? _hit;
  bool _reported = false;
  @override
  Color backgroundColor() => const Color(0xff142d30);
  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    _impactAge += dt;
    for (final hit in engine.update(dt)) {
      _hit = hit;
      _impactAge = 0;
    }
    if (!_reported &&
        engine.outcome != BattleOutcome.running &&
        _impactAge > 0.6) {
      _reported = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => onFinished());
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {Color color = Colors.white, double fontSize = 14}) {
    final painter = TextPainter(
        text: TextSpan(
            text: text, style: TextStyle(color: color, fontSize: fontSize)),
        textDirection: TextDirection.ltr)
      ..layout(maxWidth: size.x * 0.44);
    painter.paint(canvas, at);
  }

  void _actor(Canvas canvas, Fighter fighter, Offset base, bool player) {
    final hit = _impactAge < 0.3 ? _hit : null;
    final attacks = hit != null && hit.playerAttacks == player;
    final pose = fighter.hp <= 0
        ? ActorPose.death
        : attacks
            ? ActorPose.attack
            : hit != null
                ? ActorPose.damage
                : ActorPose.idle;
    final offset =
        attacks ? sin(_impactAge / 0.3 * pi) * 24 * (player ? 1 : -1) : 0.0;
    final center =
        base + Offset(offset, pose == ActorPose.idle ? sin(_time * 3) * 3 : 0);
    final color = pose == ActorPose.death
        ? Colors.blueGrey
        : pose == ActorPose.damage
            ? Colors.redAccent
            : player
                ? const Color(0xff80e4c1)
                : const Color(0xffb9a2f9);
    final paint = Paint()..color = color;
    final key = player ? heroAssetKey : 'enemy.slime';
    final sprite = _art['$key.${pose.name}'] ?? _art[key];
    if (sprite != null) {
      canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
              0, 0, sprite.width.toDouble(), sprite.height.toDouble()),
          Rect.fromCenter(center: center, width: 72, height: 72),
          Paint());
    } else if (player) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: center,
                  width: 44,
                  height: pose == ActorPose.death ? 16 : 54),
              const Radius.circular(10)),
          paint);
    } else {
      canvas.drawOval(
          Rect.fromCenter(
              center: center,
              width: 60,
              height: pose == ActorPose.death ? 16 : 44),
          paint);
    }
    if (pose != ActorPose.death && sprite == null) {
      canvas.drawCircle(
          center + const Offset(-8, -5), 3, Paint()..color = Colors.black87);
      canvas.drawCircle(
          center + const Offset(8, -5), 3, Paint()..color = Colors.black87);
    }
    final left = Offset(base.dx - 45, base.dy + 50);
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(left.dx, left.dy, 90, 6), const Radius.circular(3)),
        Paint()..color = Colors.white12);
    canvas.drawRect(
        Rect.fromLTWH(left.dx, left.dy, 90 * fighter.hp / fighter.stats.hp, 6),
        Paint()..color = color);
    _text(
        canvas, '${fighter.hp}/${fighter.stats.hp}', left + const Offset(0, 12),
        fontSize: 12);
    if (hit != null && !attacks) {
      _text(canvas, '${hit.critical ? 'CRIT ' : ''}-${hit.damage}',
          center + Offset(-24, -60 - _impactAge * 40),
          color: Colors.amber, fontSize: 22);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final background = _art['background.forest'];
    if (background != null) {
      canvas.drawImageRect(
          background,
          Rect.fromLTWH(
              0, 0, background.width.toDouble(), background.height.toDouble()),
          Rect.fromLTWH(0, 0, size.x, size.y),
          Paint());
    }
    canvas.drawRect(Rect.fromLTWH(0, size.y * 0.66, size.x, size.y * 0.34),
        Paint()..color = const Color(0xff1c3833));
    _text(canvas, engine.player.name, const Offset(16, 16));
    _text(canvas, engine.enemy.name, Offset(size.x * 0.55, 16));
    _actor(canvas, engine.player, Offset(size.x * 0.25, size.y * 0.5), true);
    _actor(canvas, engine.enemy, Offset(size.x * 0.75, size.y * 0.5), false);
    if (engine.outcome != BattleOutcome.running) {
      _text(
          canvas,
          engine.outcome == BattleOutcome.victory ? 'VICTORY' : 'TRY AGAIN',
          Offset(size.x * 0.32, size.y - 36),
          color: Colors.amber,
          fontSize: 20);
    }
  }
}

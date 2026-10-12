import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../domain/playable_character.dart';
import '../domain/playable_stage_battle.dart';

// Fixed pixel drawings. Only their world position changes during flight;
// original character PNGs are neither altered nor interpolated.
const _patterns = {
  ProjectileKind.arrow: [
    'ww...................',
    '.ww..............w...',
    '..bbbbbbbbbbbbbbbbwww',
    '.ww..............w...',
    'ww...................'
  ],
  ProjectileKind.bullet: ['..yyyyy..', 'yyyyyyyyw', '..ooooo..'],
  ProjectileKind.fire: [
    '...rr....',
    '.rorrr...',
    'rryoorr..',
    'royyyorr.',
    'roywwyorr',
    'royyyorr.',
    'rryoorr..',
    '.rorrr...',
    '...rr....'
  ],
  ProjectileKind.ice: [
    '....c....',
    '...cwc...',
    '..cwwwc..',
    '.cwwwwwc.',
    'cwwwbwwwc',
    '.cwwwwwc.',
    '..cwwwc..',
    '...cwc...',
    '....c....'
  ],
  ProjectileKind.shuriken: [
    '....g....',
    '....gw...',
    '..g.gw...',
    '.wggggg..',
    'ggggbgggg',
    '..gggggw.',
    '...wg.g..',
    '...wg....',
    '....g....'
  ],
};
const _impact = [
  '....y....',
  '.y..y..y.',
  '..y.y.y..',
  '...www...',
  'yywwwwwyy',
  '...www...',
  '..y.y.y..',
  '.y..y..y.',
  '....y....'
];
const _palette = {
  'w': Color(0xfffff5dc),
  'b': Color(0xff674d39),
  'y': Color(0xffffdc58),
  'o': Color(0xffff9238),
  'r': Color(0xffef453b),
  'c': Color(0xff61def4),
  'g': Color(0xffb6c9da),
};

void paintStageProjectile(Canvas canvas, StageProjectile projectile, Offset tip,
    double dot, double pixelRatio,
    {ui.Image? image}) {
  if (image != null) {
    final side = 64 *
        dot *
        (projectile.skill && projectile.kind == ProjectileKind.ice ? 2 : 1);
    canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Rect.fromLTWH(
            ((tip.dx - side / 2) * pixelRatio).round() / pixelRatio,
            ((tip.dy - side / 2) * pixelRatio).round() / pixelRatio,
            side,
            side),
        Paint()
          ..filterQuality = FilterQuality.none
          ..isAntiAlias = false);
    return;
  }
  final pattern = projectile.resolved && !projectile.missed
      ? _impact
      : _patterns[projectile.kind]!;
  if (projectile.skill && projectile.kind == ProjectileKind.ice) dot *= 2;
  final left =
      ((tip.dx - pattern.first.length * dot) * pixelRatio).round() / pixelRatio;
  final top =
      ((tip.dy - pattern.length * dot / 2) * pixelRatio).round() / pixelRatio;
  final paint = Paint()..isAntiAlias = false;
  for (var y = 0; y < pattern.length; y++) {
    for (var x = 0; x < pattern[y].length; x++) {
      final color = _palette[pattern[y][x]];
      if (color == null) continue;
      canvas.drawRect(Rect.fromLTWH(left + x * dot, top + y * dot, dot, dot),
          paint..color = color);
    }
  }
}

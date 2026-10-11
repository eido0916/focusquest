import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class BackgroundComponent extends Component {
  BackgroundComponent(this.state, {required this.image, this.scrollSpeed = 108})
      : super(priority: -100);
  final BattleStateController state;
  final ui.Image image;

  /// Pixels per second in the game's 960 x 540 logical viewport.
  /// Visual only: this never changes enemies, attack timing or EXP.
  final double scrollSpeed;

  static const viewportWidth = 960.0;
  static const viewportHeight = 540.0;
  final _imagePaint = Paint()..filterQuality = FilterQuality.medium;

  @override
  void render(Canvas canvas) {
    final tileWidth = image.width * viewportHeight / image.height;
    // Derive position from the focus clock, not render frame counts. Keeps the
    // animation smooth at any frame rate and freezes at the session's end.
    final distance =
        (state.backgroundTravelSeconds * scrollSpeed) % (tileWidth * 2);
    final firstTile = (distance / tileWidth).floor();
    var left = -(distance % tileWidth);
    var tile = firstTile;
    final source =
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.save();
    canvas.clipRect(const Rect.fromLTWH(0, 0, viewportWidth, viewportHeight));
    while (left < viewportWidth) {
      canvas.save();
      // Alternate original/mirrored scenery so neighbouring tiles share the
      // exact same edge pixels, even if the illustration is not seamless.
      // Only scenery is mirrored; the hero always keeps facing right.
      canvas.translate(tile.isOdd ? left + tileWidth : left, 0);
      if (tile.isOdd) canvas.scale(-1, 1);
      canvas.drawImageRect(image, source,
          Rect.fromLTWH(0, 0, tileWidth + .5, viewportHeight), _imagePaint);
      canvas.restore();
      left += tileWidth;
      tile++;
    }
    canvas.restore();
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 960, 540),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x12000000), Color(0x00000000), Color(0x40031425)],
        ).createShader(const Rect.fromLTWH(0, 0, 960, 540)),
    );
  }
}

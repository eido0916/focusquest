import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';
import '../../features/focus/domain/focus_adventure.dart';

class BackgroundComponent extends Component {
  BackgroundComponent(this.state,
      {required this.image, this.scrollSpeed = 108, this.ghostShip})
      : super(priority: -100);
  final BattleStateController state;
  final ui.Image image;
  final ui.Image? ghostShip;

  /// Pixels per second in the game's 960 x 540 logical viewport.
  /// Visual only: this never changes enemies, attack timing or EXP.
  final double scrollSpeed;

  static const viewportWidth = 960.0;
  static const viewportHeight = 540.0;
  static const asset = 'ui/forest_meadow_pixel_v001.png';
  static final _imagePaint = Paint()
    ..filterQuality = FilterQuality.none
    ..isAntiAlias = false;

  @override
  void render(Canvas canvas) {
    paintScenery(
        canvas,
        ghostShip != null && FocusAdventure.chapter(state.adventureSeconds) == 2
            ? ghostShip!
            : image,
        travelSeconds: state.backgroundTravelSeconds,
        scrollSpeed: state.isBossBattle ? 0 : scrollSpeed);
  }

  /// Shared by solo and party focus battles. Preserve the artwork's aspect
  /// ratio and point sampling; move only in complete source-pixel steps.
  static void paintScenery(Canvas canvas, ui.Image image,
      {double travelSeconds = 0, double scrollSpeed = 108}) {
    final pixelScale = viewportHeight / image.height;
    final tileWidth = image.width * viewportHeight / image.height;
    // Derive position from the focus clock, not render frame counts. Keeps the
    // animation smooth at any frame rate and freezes at the session's end.
    final distance = (travelSeconds * scrollSpeed / pixelScale).floor() *
        pixelScale %
        (tileWidth * 2);
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
          Rect.fromLTWH(0, 0, tileWidth, viewportHeight), _imagePaint);
      canvas.restore();
      left += tileWidth;
      tile++;
    }
    canvas.restore();
  }
}

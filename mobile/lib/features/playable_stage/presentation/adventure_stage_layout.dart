import 'dart:math' as math;
import 'package:flutter/widgets.dart';

/// One ground baseline for every terrain, with controls below the actors.
class AdventureStageLayout {
  AdventureStageLayout(this.size);
  final Size size;
  bool get landscape => size.width > size.height;
  double get commandSide => math.min((size.width * .115).clamp(88.0, 176.0),
      math.max(72.0, (size.width - 32) / 2.70));
  double get controlHeight => commandSide;
  double get groundY => size.height - controlHeight - 26;
  // A tall viewport may need a world slightly taller than the canvas; the
  // painter crops it while keeping the scenery's ratio and ground baseline.
  double bottomInset(double sourceGroundLine) =>
      size.height - groundY / sourceGroundLine;
  double get messageTop =>
      landscape ? (size.width < 1000 || size.height < 500 ? 150 : 190) : 308;
}

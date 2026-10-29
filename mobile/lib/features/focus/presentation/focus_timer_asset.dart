import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Samples the artwork's content rectangle; generated source PNGs are intact.
class FocusTimerAsset extends StatelessWidget {
  const FocusTimerAsset(this.name, {super.key, this.fit = BoxFit.fill});
  final String name;
  final BoxFit fit;
  static const _content = <String, List<double>>{
    // canvas width/height, alpha content left/top/right/bottom
    'chapter_crest': [1254, 1254, 85, 70, 1169, 1169],
    'crossed_swords': [1254, 1254, 66, 82, 1188, 1178],
    'gauge_fill': [2172, 724, 83, 296, 2089, 426],
    'gauge_frame': [1774, 887, 9, 379, 1766, 511],
    'gold_divider': [1373, 1145, 28, 546, 1345, 601],
    'name_banner': [1774, 887, 117, 311, 1759, 565],
    'panel_frame': [1447, 1087, 15, 22, 1432, 1066],
    'timer_circle': [1254, 1254, 10, 84, 1245, 1185],
  };

  @override
  Widget build(BuildContext context) {
    final asset = 'assets/images/focus_timer_v001/$name.png';
    final bounds = _content[name];
    if (bounds == null) {
      return Image.asset(asset, fit: fit, excludeFromSemantics: true);
    }
    return ClipRect(child: LayoutBuilder(builder: (context, constraints) {
      final contentWidth = bounds[4] - bounds[2];
      final contentHeight = bounds[5] - bounds[3];
      var sx = constraints.maxWidth / contentWidth;
      var sy = constraints.maxHeight / contentHeight;
      if (fit == BoxFit.contain) {
        sx = sy = math.min(sx, sy);
      } else if (fit == BoxFit.cover) {
        sx = sy = math.max(sx, sy);
      }
      return Stack(children: [
        Positioned(
          left: (constraints.maxWidth - contentWidth * sx) / 2 - bounds[2] * sx,
          top:
              (constraints.maxHeight - contentHeight * sy) / 2 - bounds[3] * sy,
          width: bounds[0] * sx,
          height: bounds[1] * sy,
          child:
              Image.asset(asset, fit: BoxFit.fill, excludeFromSemantics: true),
        )
      ]);
    }));
  }
}

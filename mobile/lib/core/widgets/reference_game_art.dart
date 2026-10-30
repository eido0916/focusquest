import 'dart:math' as math;
import 'package:flutter/material.dart';

const referenceArtPath = 'assets/images/home_focus_ui_v002';
const referenceGold = Color(0xffffdc94);
const referenceWhite = Color(0xfffffbef);
TextStyle referenceText(double size,
        {Color color = referenceWhite, FontWeight weight = FontWeight.w600}) =>
    TextStyle(
        fontFamily: 'SunlitSerif',
        fontSize: math.max(14, size),
        height: 1.35,
        fontWeight: weight,
        color: color);

class ReferenceBackdrop extends StatelessWidget {
  const ReferenceBackdrop({super.key, required this.name, required this.child});
  final String name;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset('$referenceArtPath/$name.png',
            fit: BoxFit.cover,
            filterQuality: FilterQuality.none,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true),
        child,
        const Positioned.fill(
            child: IgnorePointer(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        border: Border.fromBorderSide(BorderSide(
                            color: Color(0xffd3ad62), width: 1.5))))))
      ]);
}

/// Frame PNGs contain decoration only. Values and labels are live widgets.
class ReferenceFrame extends StatelessWidget {
  const ReferenceFrame(
      {super.key,
      required this.child,
      this.asset = 'status_frame',
      this.padding = const EdgeInsets.all(16)});
  final String asset;
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) {
    // Match the fixed edges of the nine-slice artwork. Content determines the
    // panel height, so wrapping text grows the frame instead of covering it.
    final requested = padding.resolve(Directionality.of(context));
    final verticalInset = asset == 'timer_frame' ? 32.0 : 18.0;
    final contentPadding = EdgeInsets.fromLTRB(
        math.max(28, requested.left),
        math.max(verticalInset, requested.top),
        math.max(28, requested.right),
        math.max(verticalInset, requested.bottom));
    final size = switch (asset) {
      'timer_frame' => const Size(1200, 900),
      'record_frame' => const Size(600, 240),
      _ => const Size(1200, 240)
    };
    return Stack(children: [
      Positioned.fill(
          child: Image.asset('$referenceArtPath/$asset.png',
              fit: BoxFit.fill,
              scale: 3,
              centerSlice: Rect.fromLTRB(
                  28,
                  asset == 'timer_frame' ? 32 : 18,
                  (size.width - 84) / 3,
                  (size.height - (asset == 'timer_frame' ? 96 : 54)) / 3),
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true)),
      if (asset != 'record_frame' && asset != 'adventure_frame') ...[
        Positioned(
            left: 0,
            right: 0,
            top: -1,
            height: 12,
            child: Center(
                child: Image.asset('$referenceArtPath/ornament_top.png',
                    width: 28,
                    height: 12,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true))),
        Positioned(
            left: 0,
            right: 0,
            bottom: -1,
            height: 12,
            child: Center(
                child: Image.asset('$referenceArtPath/ornament_bottom.png',
                    width: 28,
                    height: 12,
                    fit: BoxFit.fill,
                    excludeFromSemantics: true))),
      ],
      Padding(padding: contentPadding, child: child)
    ]);
  }
}

class ReferenceIcon extends StatelessWidget {
  const ReferenceIcon(this.name, {super.key, this.size = 28, this.color});
  final String name;
  final double size;
  final Color? color;
  @override
  Widget build(BuildContext context) =>
      Image.asset('$referenceArtPath/icon_$name.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          color: color,
          excludeFromSemantics: true);
}

class ReferenceAction extends StatelessWidget {
  const ReferenceAction(
      {super.key,
      required this.label,
      required this.onTap,
      this.icon,
      this.light = false,
      this.compact = false,
      this.chevron = true});
  final String label;
  final String? icon;
  final VoidCallback? onTap;
  final bool light, compact, chevron;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
          opacity: onTap == null ? .5 : 1,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  child: ReferenceFrame(
                      asset: light
                          ? 'adventure_frame'
                          : compact
                              ? 'utility_frame'
                              : 'action_frame',
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 14 : 18,
                          vertical: compact ? 12 : 14),
                      child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: compact ? 28 : 36),
                          child: Row(children: [
                            if (icon != null) ...[
                              ReferenceIcon(icon!,
                                  size: compact ? 22 : 36,
                                  color:
                                      light ? const Color(0xff9f7935) : null),
                              SizedBox(width: compact ? 8 : 12)
                            ],
                            Expanded(
                                child: Text(label,
                                    textAlign: TextAlign.center,
                                    style: referenceText(compact ? 16 : 22,
                                        color: light
                                            ? const Color(0xff082044)
                                            : compact
                                                ? referenceGold
                                                : referenceWhite))),
                            if (chevron) ...[
                              const SizedBox(width: 6),
                              const ReferenceIcon('chevron', size: 14)
                            ],
                          ])))))));
}

class ReferenceGauge extends StatelessWidget {
  const ReferenceGauge(
      {super.key,
      required this.value,
      this.height = 12,
      this.fillKey,
      this.semanticLabel = '経験値'});
  final double value, height;
  final Key? fillKey;
  final String semanticLabel;
  @override
  Widget build(BuildContext context) => Semantics(
      label: semanticLabel,
      value: '${(value.clamp(0, 1) * 100).round()}%',
      child: SizedBox(
          height: height,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset('$referenceArtPath/gauge_track.png',
                fit: BoxFit.fill,
                centerSlice: const Rect.fromLTRB(9, 4, 291, 16),
                scale: 2,
                excludeFromSemantics: true),
            Padding(
                padding: const EdgeInsets.all(2),
                child: Align(
                    alignment: Alignment.centerLeft,
                    child: FractionallySizedBox(
                        widthFactor: value.clamp(0.0, 1.0),
                        heightFactor: 1,
                        child: SizedBox.expand(
                            key: fillKey,
                            child: ClipRRect(
                                borderRadius: BorderRadius.circular(height),
                                child: Image.asset(
                                    '$referenceArtPath/gauge_fill.png',
                                    fit: BoxFit.fill,
                                    excludeFromSemantics: true))))))
          ])));
}

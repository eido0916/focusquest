import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'package:flutter/material.dart';

const sanctuaryAssets = 'assets/images/diagnosis/sanctuary_v001';
const sanctuaryInk = Color(0xff07194b);
const sanctuaryGold = Color(0xffd3ae65);

// Keep the artwork and controls in proportion on larger portrait screens.
double sanctuaryScale(BuildContext context) =>
    ((MediaQuery.sizeOf(context).width.clamp(0, 900) - 44) / 476)
        .clamp(1.0, 1.65)
        .toDouble();

class _SanctuaryTextScaler extends TextScaler {
  const _SanctuaryTextScaler(this.base, this.factor);
  final TextScaler base;
  final double factor;
  @override
  double scale(double fontSize) => base.scale(fontSize) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
}

/// Text and controls remain native widgets; each illustration is a separate PNG.
class SanctuaryFrame extends StatelessWidget {
  const SanctuaryFrame(
      {super.key,
      required this.child,
      this.blue = false,
      this.asset,
      this.padding = const EdgeInsets.all(24)});
  final Widget child;
  final bool blue;
  final String? asset;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset(
                '$sanctuaryAssets/${asset ?? (blue ? 'sapphire-panel' : 'parchment-panel')}.png',
                fit: BoxFit.fill,
                excludeFromSemantics: true)),
        Padding(padding: padding * sanctuaryScale(context), child: child),
      ]);
}

class SanctuaryShell extends StatelessWidget {
  const SanctuaryShell(
      {super.key, required this.children, required this.scroll});
  final List<Widget> children;
  final ScrollController scroll;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'SunlitSerif',
                bodyColor: sanctuaryInk,
                displayColor: sanctuaryInk)),
        child: Scaffold(
          backgroundColor: const Color(0xff1e416f),
          body: Stack(children: [
            Positioned.fill(
                child: Image.asset('$sanctuaryAssets/sanctuary.png',
                    fit: BoxFit.cover, excludeFromSemantics: true)),
            const Positioned.fill(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: RadialGradient(
                            center: Alignment(0, .15),
                            radius: .9,
                            colors: [Color(0xb3102b62), Color(0x00102b62)],
                            stops: [.35, 1])))),
            SafeArea(
                child: Center(
                    child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                      textScaler: _SanctuaryTextScaler(
                          MediaQuery.textScalerOf(context),
                          sanctuaryScale(context))),
                  child: QuestScreenFit(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children))),
            ))),
          ]),
        ),
      );
}

class SanctuaryHeader extends StatelessWidget {
  const SanctuaryHeader({super.key});
  @override
  Widget build(BuildContext context) => LayoutBuilder(
      builder: (context, size) => Column(children: [
            Image.asset('$sanctuaryAssets/crystal.png',
                height: size.maxWidth * .42,
                width: size.maxWidth * .62,
                fit: BoxFit.contain,
                excludeFromSemantics: true),
            SizedBox(
                width: size.maxWidth * .88,
                child: const SanctuaryFrame(
                    asset: 'title-plaque',
                    padding: EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Center(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('冒険のはじまり',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'SunlitSerif',
                                    fontSize: 23,
                                    color: Colors.white,
                                    letterSpacing: 2)))))),
            const SizedBox(height: 12),
          ]));
}

class SanctuaryCommand extends StatelessWidget {
  const SanctuaryCommand(
      {super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onPressed != null,
      child: Opacity(
          opacity: onPressed == null ? .62 : 1,
          child: SanctuaryFrame(
            asset: 'confirm-button',
            padding: EdgeInsets.zero,
            child: TextButton(
                style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 18),
                    minimumSize:
                        Size(double.infinity, 64 * sanctuaryScale(context))),
                onPressed: onPressed,
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Image.asset('$sanctuaryAssets/compass.png',
                      width: 28 * sanctuaryScale(context),
                      height: 28 * sanctuaryScale(context),
                      excludeFromSemantics: true),
                  const SizedBox(width: 12),
                  Flexible(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontFamily: 'SunlitSerif',
                              fontSize: 21,
                              letterSpacing: 1))),
                  const SizedBox(width: 10),
                  const Text('〉',
                      style: TextStyle(fontSize: 26, color: Colors.white)),
                ])),
          )));
}

class SanctuaryChoice extends StatelessWidget {
  const SanctuaryChoice(
      {super.key,
      required this.label,
      required this.selected,
      required this.onTap,
      this.letter,
      this.purple = false,
      this.compact = false});
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final String? letter;
  final bool purple;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: selected,
      child: SanctuaryFrame(
          blue: selected,
          padding: EdgeInsets.zero,
          child: TextButton(
              style: TextButton.styleFrom(
                  foregroundColor: selected ? Colors.white : sanctuaryInk,
                  padding: EdgeInsets.symmetric(
                          horizontal: compact ? 12 : 16, vertical: 13) *
                      sanctuaryScale(context),
                  minimumSize: Size(double.infinity,
                      (compact ? 66 : 80) * sanctuaryScale(context))),
              onPressed: onTap,
              child: Row(children: [
                SizedBox(
                    width: 48 * sanctuaryScale(context),
                    height: (compact ? 48 : 58) * sanctuaryScale(context),
                    child: Stack(alignment: Alignment.center, children: [
                      Image.asset(
                          '$sanctuaryAssets/orb-${purple ? 'purple' : 'blue'}.png',
                          excludeFromSemantics: true),
                      if (letter != null)
                        Text(letter!,
                            style: const TextStyle(
                                fontFamily: 'SunlitSerif',
                                fontSize: 30,
                                color: Colors.white)),
                    ])),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontFamily: 'SunlitSerif',
                            fontSize: compact ? 27 : 17,
                            height: 1.6,
                            fontWeight: FontWeight.w600))),
              ]))));
}

class SanctuaryProgress extends StatelessWidget {
  const SanctuaryProgress(
      {super.key, required this.index, required this.count});
  final int index;
  final int count;
  @override
  Widget build(BuildContext context) => Semantics(
      label: '全$count問中、第${index + 1}問',
      child: Column(children: [
        Row(children: [
          Image.asset('$sanctuaryAssets/compass.png',
              width: 26, height: 26, excludeFromSemantics: true),
          Expanded(
              child: SizedBox(
                  height: 28,
                  child: CustomPaint(painter: _ProgressPainter(index, count)))),
          Image.asset('$sanctuaryAssets/compass.png',
              width: 26, height: 26, excludeFromSemantics: true),
        ]),
        Text('${index + 1} / $count',
            style: const TextStyle(
                color: Colors.white, fontSize: 16, fontFamily: 'SunlitSerif')),
      ]));
}

class _ProgressPainter extends CustomPainter {
  const _ProgressPainter(this.index, this.count);
  final int index, count;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawLine(
        Offset(0, size.height / 2),
        Offset(size.width, size.height / 2),
        Paint()
          ..color = sanctuaryGold
          ..strokeWidth = 1);
    for (var i = 0; i < count; i++) {
      final x = size.width * (i + .5) / count;
      final y = size.height / 2;
      final r = i == index ? 9.0 : 4.0;
      final star = Path()
        ..moveTo(x, y - r)
        ..lineTo(x + 1.5, y - 1.5)
        ..lineTo(x + r, y)
        ..lineTo(x + 1.5, y + 1.5)
        ..lineTo(x, y + r)
        ..lineTo(x - 1.5, y + 1.5)
        ..lineTo(x - r, y)
        ..lineTo(x - 1.5, y - 1.5)
        ..close();
      if (i == index) {
        canvas.drawCircle(
            Offset(x, y),
            5,
            Paint()
              ..color = const Color(0xffa3d6ff)
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5));
      }
      canvas.drawPath(
          star,
          Paint()
            ..color = i == index
                ? Colors.white
                : i < index
                    ? sanctuaryGold
                    : const Color(0xff9aadc1));
    }
  }

  @override
  bool shouldRepaint(covariant _ProgressPainter old) =>
      old.index != index || old.count != count;
}

class SanctuaryBadge extends StatelessWidget {
  const SanctuaryBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => CustomPaint(
      painter: const _BadgePainter(),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 8),
          child: Text(label,
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SunlitSerif',
                  fontSize: 19))));
}

class _BadgePainter extends CustomPainter {
  const _BadgePainter();
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..lineTo(size.width, size.height / 2)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(0, size.height / 2)
      ..close();
    canvas.drawPath(path, Paint()..color = const Color(0xff102c60));
    canvas.drawPath(
        path,
        Paint()
          ..color = sanctuaryGold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);
    canvas.save();
    canvas.translate(size.width * .06, size.height * .06);
    canvas.scale(.88);
    canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xfff4e4b4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .7);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BadgePainter oldDelegate) => false;
}

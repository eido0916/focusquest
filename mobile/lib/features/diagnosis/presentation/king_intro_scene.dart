import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'king_intro_ornaments.dart';

/// Independently painted still layers; no character interpolation.
class KingIntroScene extends StatefulWidget {
  const KingIntroScene({super.key, required this.onTouchStone});
  final VoidCallback onTouchStone;
  static const dialogue =
      '新たな冒険者よ。\nこの石に触れ、そなたの真の力を知るがよい。\nそして、自らの力とともに冒険へ旅立つのだ。';
  static const assetRoot = 'assets/images/diagnosis/king_intro_v002';
  @override
  State<KingIntroScene> createState() => _KingIntroSceneState();
}

class _KingIntroSceneState extends State<KingIntroScene> {
  Timer? _typing;
  int _visible = 0;
  bool _departing = false;
  bool get _finished => _visible == KingIntroScene.dialogue.length;
  @override
  void initState() {
    super.initState();
    _typing = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted) return;
      setState(() => _visible++);
      if (_finished) timer.cancel();
    });
  }

  void _reveal() {
    _typing?.cancel();
    setState(() => _visible = KingIntroScene.dialogue.length);
  }

  Future<void> _touchStone() async {
    if (_departing) return;
    if (!_finished) _reveal();
    setState(() => _departing = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) widget.onTouchStone();
  }

  @override
  void dispose() {
    _typing?.cancel();
    super.dispose();
  }

  Widget _art() => LayoutBuilder(builder: (context, c) {
        final w = math.max(c.maxWidth, c.maxHeight * 941 / 1672);
        final h = w * 1672 / 941;
        final x = (c.maxWidth - w) / 2, y = (c.maxHeight - h) / 2;
        Widget layer(String name,
                {double left = 0, double top = 0, double scale = 1}) =>
            Positioned(
                left: x + w * left,
                top: y + h * top,
                width: w * scale,
                height: h * scale,
                child: IgnorePointer(
                    child: Image.asset('${KingIntroScene.assetRoot}/$name.png',
                        fit: BoxFit.fill, excludeFromSemantics: true)));
        return ClipRect(
            child: Stack(children: [
          layer('cathedral'),
          layer('old_king', left: -.015, top: .013, scale: 1.03),
          // Fixed registration compensates for each asset's transparent margins.
          layer('magic_crystal', left: .225, top: .235, scale: .55),
          layer('touch_hand', left: .035, top: .10),
          Positioned(
              left: x + w * .35,
              top: y + h * .36,
              width: w * .34,
              height: h * .24,
              child: Semantics(
                  label: '魔法石に触れて性格診断をはじめる',
                  button: true,
                  child: Tooltip(
                      message: '魔法石に触れる',
                      child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              key: const Key('magic-stone'),
                              onTap: _departing ? null : _touchStone,
                              customBorder: const CircleBorder(),
                              splashColor: const Color(0x447ddfff),
                              child: const SizedBox.expand()))))),
        ]));
      });

  Widget _title(double width) => IgnorePointer(
      child: SizedBox(
          width: width * .46,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('冒険のはじまり',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'SunlitSerif',
                    color: const Color(0xfff7f0ff),
                    fontSize: (width * .035).clamp(15.0, 28.0),
                    letterSpacing: 4,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6)
                    ])),
            const SizedBox(height: 5),
            const SizedBox(
                height: 14,
                width: double.infinity,
                child: CustomPaint(painter: KingTitleRulePainter())),
          ])));

  Widget _dialogue(double width, bool reducedMotion) {
    String wrapDialogue(String text) => width < 300
        ? text
            .replaceFirst('この石に触れ、', 'この石に触れ、\n')
            .replaceFirst('そして、自らの力とともに', 'そして、自らの力とともに\n')
        : text;
    final style = TextStyle(
        fontFamily: 'SunlitSerif',
        color: const Color(0xfff6f3f7),
        fontSize: (width * .0335).clamp(width < 300 ? 12.0 : 13.0, 23.0),
        height: 1.75,
        letterSpacing: .4);
    return Semantics(
        label: '老王。${KingIntroScene.dialogue}',
        onTap: _reveal,
        child: GestureDetector(
            key: const Key('king-dialogue'),
            onTap: _departing ? null : _reveal,
            child: CustomPaint(
                painter: const KingDialogueFramePainter(),
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(19, 14, 19, 14),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(children: [
                            Text('— ',
                                style: style.copyWith(color: kingIntroGold)),
                            Text('老王',
                                style: style.copyWith(
                                    color: kingIntroGold,
                                    fontSize: style.fontSize! + 1,
                                    letterSpacing: 2)),
                          ]),
                          const SizedBox(height: 5),
                          ExcludeSemantics(
                              child: Stack(children: [
                            Opacity(
                                opacity: 0,
                                child: Text(
                                    wrapDialogue(KingIntroScene.dialogue),
                                    style: style)),
                            Text(
                                wrapDialogue(reducedMotion
                                    ? KingIntroScene.dialogue
                                    : KingIntroScene.dialogue
                                        .substring(0, _visible)),
                                style: style),
                          ])),
                          Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                  key: const Key('king-continue'),
                                  onPressed: _departing ? null : _touchStone,
                                  tooltip: '魔法石に触れる',
                                  visualDensity: VisualDensity.compact,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(
                                      minWidth: 44, minHeight: 32),
                                  icon: const SizedBox(
                                      width: 19,
                                      height: 19,
                                      child: CustomPaint(
                                          painter: KingContinuePainter())))),
                        ])))));
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    return Scaffold(
        backgroundColor: const Color(0xff100e20),
        body: LayoutBuilder(builder: (context, c) {
          final wide = c.maxWidth > c.maxHeight;
          final artWidth = wide ? c.maxWidth * .48 : c.maxWidth;
          final panelWidth =
              wide ? c.maxWidth * .46 : math.min(c.maxWidth * .895, 720.0);
          return Stack(children: [
            Positioned(
                left: 0, top: 0, bottom: 0, width: artWidth, child: _art()),
            Positioned(
                top: MediaQuery.paddingOf(context).top + c.maxHeight * .033,
                left: 0,
                width: artWidth,
                child: Center(child: _title(artWidth))),
            if (wide)
              Positioned(
                  left: c.maxWidth * .51,
                  right: c.maxWidth * .03,
                  top: 12,
                  bottom: 12,
                  child: Center(
                      child: SingleChildScrollView(
                          child: _dialogue(panelWidth, reducedMotion))))
            else
              Positioned(
                  left: (c.maxWidth - panelWidth) / 2,
                  width: panelWidth,
                  bottom: math.max(MediaQuery.paddingOf(context).bottom + 14,
                      c.maxHeight * (c.maxHeight < 650 ? .025 : .10)),
                  child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: c.maxHeight * .43),
                      child: SingleChildScrollView(
                          child: _dialogue(panelWidth, reducedMotion)))),
            IgnorePointer(
                child: AnimatedOpacity(
                    opacity: _departing ? 1 : 0,
                    duration: Duration(milliseconds: reducedMotion ? 0 : 650),
                    child: const ColoredBox(
                        color: Colors.white, child: SizedBox.expand()))),
          ]);
        }));
  }
}

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

/// The first encounter, before any diagnosis answers or progress are saved.
class KingIntroScene extends StatefulWidget {
  const KingIntroScene({super.key, required this.onTouchStone});

  final VoidCallback onTouchStone;
  static const dialogue =
      '新たな冒険者よ。\nこの石に触れ、そなたの真の力を知るがよい。\nそして、自らの力とともに冒険へ旅立つのだ。';

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

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;
    final dialogueStyle = TextStyle(
      color: Colors.white,
      fontSize: MediaQuery.sizeOf(context).width < 360 ? 16 : 18,
      height: 1.8,
      letterSpacing: 1,
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        Column(children: [
          Expanded(
            child: LayoutBuilder(builder: (context, constraints) {
              // Match the gemstone's position in the centered, cover-fit art.
              final scale = math.max(
                  constraints.maxWidth / 1672, constraints.maxHeight / 941);
              final gemY = constraints.maxHeight / 2 + (540 - 941 / 2) * scale;
              final targetSize = math.min(170.0,
                  math.min(constraints.maxWidth, constraints.maxHeight) * .42);
              return Stack(fit: StackFit.expand, children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
                  duration: const Duration(milliseconds: 1100),
                  builder: (context, value, child) =>
                      Opacity(opacity: value, child: child),
                  child: Image.asset(
                    'assets/images/diagnosis/old-king-magic-stone.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    excludeFromSemantics: true,
                  ),
                ),
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Colors.transparent,
                          Color(0xdd000000)
                        ],
                        stops: [0, .6, 1],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.paddingOf(context).top + 20,
                  left: 0,
                  right: 0,
                  child: const Text('冒険のはじまり',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          letterSpacing: 5,
                          shadows: [Shadow(blurRadius: 8)])),
                ),
                Positioned(
                  left: (constraints.maxWidth - targetSize) / 2,
                  top: (gemY - targetSize / 2)
                      .clamp(0.0, constraints.maxHeight - targetSize),
                  width: targetSize,
                  height: targetSize,
                  child: Semantics(
                    label: '魔法石に触れて性格診断をはじめる',
                    button: true,
                    child: Tooltip(
                      message: '魔法石に触れる',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: const Key('magic-stone'),
                          customBorder: const CircleBorder(),
                          splashColor: const Color(0x667ddfff),
                          onTap: _departing ? null : _touchStone,
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
              ]);
            }),
          ),
          SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Stack(clipBehavior: Clip.none, children: [
                      Semantics(
                        label: '老王。${KingIntroScene.dialogue}',
                        onTap: _reveal,
                        child: GestureDetector(
                          key: const Key('king-dialogue'),
                          onTap: _departing ? null : _reveal,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(18, 24, 18, 18),
                            decoration: BoxDecoration(
                              color: const Color(0xff08090e),
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: const [
                                BoxShadow(
                                    color: Color(0x553e305e), blurRadius: 18)
                              ],
                            ),
                            child: ExcludeSemantics(
                              child: Stack(children: [
                                // Reserve full text height during the reveal.
                                Opacity(
                                    opacity: 0,
                                    child: Text(KingIntroScene.dialogue,
                                        style: dialogueStyle)),
                                Text(
                                    reducedMotion
                                        ? KingIntroScene.dialogue
                                        : KingIntroScene.dialogue
                                            .substring(0, _visible),
                                    style: dialogueStyle),
                              ]),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: -12,
                        left: 18,
                        child: Container(
                          color: const Color(0xff08090e),
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: const Text('老王',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 3)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _departing ? null : _touchStone,
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xffd6c8ff),
                          minimumSize: const Size(220, 48)),
                      child: Text(_departing ? '石が光を放っている…' : '✧  魔法石に触れる',
                          style:
                              const TextStyle(fontSize: 16, letterSpacing: 2)),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ]),
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _departing ? 1 : 0,
            duration: Duration(milliseconds: reducedMotion ? 0 : 650),
            child:
                const ColoredBox(color: Colors.white, child: SizedBox.expand()),
          ),
        ),
      ]),
    );
  }
}

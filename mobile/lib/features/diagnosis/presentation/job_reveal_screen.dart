import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../domain/diagnosis_service.dart';
import 'job_portrait.dart';
import 'king_intro_ornaments.dart';

const jobRevealAssets = 'assets/images/diagnosis/job_reveal_v001';
const _ink = Color(0xff081c49);
const _gold = Color(0xff956022);

/// Separate illustrated materials with supplied portraits and live text.
class JobRevealScreen extends StatelessWidget {
  const JobRevealScreen(
      {super.key,
      required this.result,
      required this.name,
      required this.appearance,
      required this.scroll,
      required this.onBegin,
      required this.onReview,
      this.busy = false,
      this.error,
      this.code});
  final PersonalityType result;
  final String name, appearance;
  final ScrollController scroll;
  final VoidCallback onBegin, onReview;
  final bool busy;
  final String? error, code;

  @override
  Widget build(BuildContext context) => Theme(
        data: Theme.of(context).copyWith(
            textTheme: Theme.of(context).textTheme.apply(
                fontFamily: 'SunlitSerif',
                bodyColor: _ink,
                displayColor: _ink)),
        child: Scaffold(
            backgroundColor: const Color(0xff142a49),
            body: Stack(children: [
              Positioned.fill(
                  child: Image.asset('$jobRevealAssets/background.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      excludeFromSemantics: true)),
              SafeArea(child: LayoutBuilder(builder: (context, constraints) {
                final w = math.min(constraints.maxWidth, 720.0);
                final scale = (w / 390).clamp(.82, 1.6).toDouble();
                return Center(
                    child: SizedBox(
                        width: w,
                        child: QuestScreenFit(
                            padding: EdgeInsets.fromLTRB(
                                34 * scale, 57 * scale, 34 * scale, 20 * scale),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('冒険のはじまり',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 17 * scale,
                                          color: Colors.white,
                                          letterSpacing: 4,
                                          shadows: const [
                                            Shadow(
                                                blurRadius: 5,
                                                color: Color(0xff001333))
                                          ])),
                                  SizedBox(height: 3 * scale),
                                  SizedBox(
                                      height: 10 * scale,
                                      child: const CustomPaint(
                                          painter: KingTitleRulePainter())),
                                  SizedBox(height: 17 * scale),
                                  Stack(clipBehavior: Clip.none, children: [
                                    _Panel('dialogue',
                                        padding: EdgeInsets.fromLTRB(21 * scale,
                                            18 * scale, 18 * scale, 17 * scale),
                                        child: Text('「その魂が示す道は、ここにある。」',
                                            style: TextStyle(
                                                fontSize: 14 * scale,
                                                height: 1.65,
                                                fontWeight: FontWeight.w600))),
                                    Positioned(
                                        top: -12 * scale,
                                        left: 13 * scale,
                                        child: SizedBox(
                                            width: 86 * scale,
                                            child: _Panel('plaque',
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 3 * scale,
                                                    horizontal: 12 * scale),
                                                child: Text('魔法石',
                                                    textAlign: TextAlign.center,
                                                    style: TextStyle(
                                                        fontSize: 13 * scale,
                                                        color:
                                                            Colors.white))))),
                                  ]),
                                  SizedBox(height: 13 * scale),
                                  _Panel('card',
                                      padding: EdgeInsets.fromLTRB(22 * scale,
                                          28 * scale, 22 * scale, 32 * scale),
                                      child: Column(children: [
                                        _OrnamentLabel(name, size: 15 * scale),
                                        SizedBox(height: 3 * scale),
                                        JobPortrait(
                                            typeId: result.typeId,
                                            appearance: appearance,
                                            lobby: true,
                                            height: 211 * scale),
                                        _OrnamentLabel(result.job,
                                            singleLine: true,
                                            size: (result.job.length > 6
                                                    ? 23
                                                    : 32) *
                                                scale,
                                            color: const Color(0xff001a61)),
                                        if (code != null)
                                          Padding(
                                              padding: EdgeInsets.only(
                                                  top: 2 * scale),
                                              child: Text(code!,
                                                  key: const Key(
                                                      'diagnosis-code'),
                                                  style: TextStyle(
                                                      fontSize: 13 * scale,
                                                      letterSpacing: 4,
                                                      color: _gold))),
                                        SizedBox(height: 5 * scale),
                                        Text(result.name,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 15 * scale,
                                                color: const Color(0xff713a09),
                                                fontWeight: FontWeight.w700,
                                                height: 1.6)),
                                        SizedBox(height: 6 * scale),
                                        Text(result.description,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                                fontSize: 12.5 * scale,
                                                height: 1.65,
                                                fontWeight: FontWeight.w600)),
                                        SizedBox(height: 10 * scale),
                                        _Panel('traits',
                                            padding: EdgeInsets.symmetric(
                                                vertical: 8 * scale,
                                                horizontal: 10 * scale),
                                            child: Text(
                                                result.traits.join('   ◆   '),
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                    fontSize: 11.5 * scale,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                      ])),
                                  SizedBox(height: 8 * scale),
                                  Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 15 * scale),
                                      child: _Panel('guide',
                                          padding: EdgeInsets.symmetric(
                                              horizontal: 16 * scale,
                                              vertical: 12 * scale),
                                          child: Row(children: [
                                            Image.asset(
                                                '$jobRevealAssets/book.png',
                                                width: 29 * scale,
                                                height: 29 * scale,
                                                excludeFromSemantics: true),
                                            SizedBox(width: 12 * scale),
                                            Expanded(
                                                child: Text(
                                                    '集中する時間が、あなたの冒険になる。\nホームで時間を選ぶと、冒険が始まります。',
                                                    style: TextStyle(
                                                        fontSize: 10.5 * scale,
                                                        height: 1.7,
                                                        color: Colors.white))),
                                          ]))),
                                  SizedBox(height: 9 * scale),
                                  if (error != null)
                                    Padding(
                                        padding: EdgeInsets.all(8 * scale),
                                        child: Text(error!,
                                            style: const TextStyle(
                                                color: Colors.white),
                                            textAlign: TextAlign.center)),
                                  Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 13 * scale),
                                      child: _Panel('button',
                                          padding: EdgeInsets.zero,
                                          child: TextButton(
                                              key: const Key('begin-adventure'),
                                              onPressed: busy ? null : onBegin,
                                              style: TextButton.styleFrom(
                                                  foregroundColor: Colors.white,
                                                  disabledForegroundColor:
                                                      Colors.white70,
                                                  padding: EdgeInsets.symmetric(
                                                      horizontal: 34 * scale,
                                                      vertical: 13 * scale),
                                                  minimumSize: Size(
                                                      double.infinity,
                                                      51 * scale)),
                                              child: Text(
                                                  busy ? '冒険の記録を保存中…' : '冒険に進む',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                      fontFamily: 'SunlitSerif',
                                                      fontSize: 21 * scale,
                                                      height: 1.4))))),
                                  SizedBox(height: 4 * scale),
                                  Center(
                                      child: Column(children: [
                                    TextButton(
                                        onPressed: busy ? null : onReview,
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            minimumSize: const Size(150, 44)),
                                        child: Text('答えを見直す',
                                            style: TextStyle(
                                                fontFamily: 'SunlitSerif',
                                                fontSize: 13 * scale,
                                                letterSpacing: 1))),
                                    SizedBox(
                                        width: 90 * scale,
                                        height: 5 * scale,
                                        child: const CustomPaint(
                                            painter: KingTitleRulePainter())),
                                  ])),
                                ]))));
              })),
            ])),
      );
}

class _Panel extends StatelessWidget {
  const _Panel(this.asset, {required this.child, required this.padding});
  final String asset;
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('$jobRevealAssets/$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

class _OrnamentLabel extends StatelessWidget {
  const _OrnamentLabel(this.text,
      {required this.size, this.color = _ink, this.singleLine = false});
  final String text;
  final double size;
  final Color color;
  final bool singleLine;
  @override
  Widget build(BuildContext context) {
    final label = Text(text,
        textAlign: TextAlign.center,
        maxLines: singleLine ? 1 : null,
        softWrap: !singleLine,
        style: TextStyle(
            fontSize: size, color: color, fontWeight: FontWeight.w600));
    return Row(children: [
      const Expanded(
          child: SizedBox(
              height: 8, child: CustomPaint(painter: KingTitleRulePainter()))),
      Expanded(
          flex: 5,
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: singleLine
                  ? FittedBox(fit: BoxFit.scaleDown, child: label)
                  : label)),
      const Expanded(
          child: SizedBox(
              height: 8, child: CustomPaint(painter: KingTitleRulePainter()))),
    ]);
  }
}

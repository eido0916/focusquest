import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'focus_timer_asset.dart';

const _gold = Color(0xffffdf91);

/// Illustrated assets stay separate from live session values and controls.
class FocusTimerScene extends StatelessWidget {
  const FocusTimerScene({
    super.key,
    required this.characterName,
    required this.characterType,
    required this.level,
    required this.chapter,
    required this.seconds,
    required this.progress,
    required this.onBattle,
    required this.onCancel,
    required this.onSound,
    required this.onBack,
    this.onParty,
    this.partySize = 0,
    this.message,
    this.error,
    this.onRetry,
  });
  final String characterName, characterType;
  final int level, chapter, seconds, partySize;
  final double progress;
  final VoidCallback? onBattle, onCancel, onParty, onRetry;
  final VoidCallback onSound, onBack;
  final String? message, error;

  Widget _asset(String name, {BoxFit fit = BoxFit.fill}) =>
      FocusTimerAsset(name, fit: fit);

  TextStyle _text(double size, {Color color = Colors.white}) => TextStyle(
      fontFamily: 'SunlitSerif',
      fontSize: size,
      fontWeight: FontWeight.w700,
      height: 1.3,
      color: color,
      shadows: const [Shadow(color: Color(0xff001429), blurRadius: 5)]);

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xff05203b),
        body: Stack(children: [
          Positioned.fill(child: _asset('background', fit: BoxFit.cover)),
          SafeArea(child: LayoutBuilder(builder: (context, constraints) {
            final width = math.min(constraints.maxWidth, 620.0);
            final scale = width / 992;
            final height = math.max(constraints.maxHeight, width * 1.6);
            final panelTop = height * .205;
            final panelHeight = 710 * scale;
            Widget place(
                    double x, double y, double w, double h, Widget child) =>
                Positioned(
                    left: x * scale,
                    top: y,
                    width: w * scale,
                    height: h * scale,
                    child: child);
            return SingleChildScrollView(
                child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(children: [
                    place(
                        24,
                        panelTop,
                        944,
                        710,
                        Stack(children: [
                          Positioned.fill(
                              child: Padding(
                                  padding: EdgeInsets.all(12 * scale),
                                  child: ColoredBox(
                                      color: const Color(0xff001731)
                                          .withOpacity(.84)))),
                          Positioned.fill(child: _asset('panel_frame')),
                          Positioned(
                              left: 38 * scale,
                              right: 38 * scale,
                              top: 36 * scale,
                              child: Row(children: [
                                SizedBox(
                                    width: 52 * scale,
                                    height: 56 * scale,
                                    child: _asset('chapter_crest',
                                        fit: BoxFit.contain)),
                                SizedBox(width: 22 * scale),
                                Flexible(
                                    child: Text('第$chapter章 · 集中クエスト進行中',
                                        style: _text(24 * scale))),
                              ])),
                          Positioned(
                              left: 58 * scale,
                              right: 58 * scale,
                              top: 91 * scale,
                              height: 14 * scale,
                              child: _asset('gold_divider')),
                          Positioned(
                              left: 130 * scale,
                              right: 130 * scale,
                              top: 152 * scale,
                              height: 78 * scale,
                              child: TextButton(
                                  onPressed: onBattle,
                                  style: TextButton.styleFrom(
                                      foregroundColor: _gold,
                                      padding: EdgeInsets.zero,
                                      disabledForegroundColor:
                                          _gold.withOpacity(.5)),
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                            width: 52 * scale,
                                            height: 52 * scale,
                                            child: _asset('crossed_swords',
                                                fit: BoxFit.contain)),
                                        SizedBox(width: 18 * scale),
                                        Flexible(
                                            child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text('戦いの様子を見る',
                                                    style: _text(34 * scale,
                                                        color: _gold)))),
                                      ]))),
                          Positioned(
                              left: 228 * scale,
                              top: 220 * scale,
                              width: 488 * scale,
                              height: 340 * scale,
                              child:
                                  _asset('timer_circle', fit: BoxFit.contain)),
                          Positioned(
                              left: 110 * scale,
                              right: 110 * scale,
                              top: 306 * scale,
                              height: 150 * scale,
                              child: Semantics(
                                  label: '残り時間',
                                  liveRegion: false,
                                  child: Center(
                                      child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                              '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                              style: _text(122 * scale,
                                                      color: const Color(
                                                          0xffedfcff))
                                                  .copyWith(shadows: const [
                                                Shadow(
                                                    color: Color(0xff00aaff),
                                                    blurRadius: 18),
                                                Shadow(
                                                    color: Color(0xff007fff),
                                                    blurRadius: 7)
                                              ])))))),
                          Positioned(
                              left: 48 * scale,
                              right: 48 * scale,
                              top: 486 * scale,
                              height: 78 * scale,
                              child: _ProgressGauge(value: progress)),
                          Positioned(
                              left: 68 * scale,
                              right: 68 * scale,
                              top: 590 * scale,
                              child: Text(
                                  partySize > 0
                                      ? '$partySize人で集中中'
                                      : '自分の時間に、集中しましょう。',
                                  textAlign: TextAlign.center,
                                  style: _text(22 * scale,
                                      color: const Color(0xffe3eaf2)))),
                        ])),
                    Positioned(
                        left: 24 * scale,
                        right: 24 * scale,
                        top: panelTop + panelHeight + 22 * scale,
                        child: Column(children: [
                          if (message != null || error != null)
                            Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    color: const Color(0xee001731),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Text(error ?? message!,
                                    textAlign: TextAlign.center,
                                    style:
                                        const TextStyle(color: Colors.white))),
                          if (error != null)
                            TextButton(
                                onPressed: onRetry,
                                child: const Text('結果の保存を再試行',
                                    style: TextStyle(color: _gold))),
                          Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 6,
                              children: [
                                TextButton.icon(
                                    onPressed: onSound,
                                    icon: const Icon(Icons.volume_up, size: 18),
                                    label: const Text('サウンド設定')),
                                if (onParty != null)
                                  TextButton.icon(
                                      onPressed: onParty,
                                      icon: const Icon(Icons.groups_rounded,
                                          size: 18),
                                      label: const Text('パーティーを見る')),
                                TextButton(
                                    onPressed: onCancel,
                                    child: const Text('集中を中断')),
                              ]
                                  .map((child) => Container(
                                      decoration: BoxDecoration(
                                          color: const Color(0xd9001731),
                                          borderRadius:
                                              BorderRadius.circular(8)),
                                      child: Theme(
                                          data: Theme.of(context).copyWith(
                                              textButtonTheme: TextButtonThemeData(
                                                  style: TextButton.styleFrom(
                                                      textStyle: const TextStyle(
                                                          fontFamily:
                                                              'SunlitSerif'),
                                                      foregroundColor:
                                                          const Color(
                                                              0xffffdfb0)))),
                                          child: child)))
                                  .toList()),
                        ])),
                    Positioned(
                        left: 6,
                        top: 0,
                        child: IconButton(
                            tooltip: '戻る',
                            onPressed: onBack,
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_back))),
                  ])),
            ));
          })),
        ]),
      );
}

class _ProgressGauge extends StatelessWidget {
  const _ProgressGauge({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Semantics(
        label: '集中の進捗',
        value: '${(value.clamp(0, 1) * 100).round()}%',
        child: Stack(children: [
          const Positioned.fill(child: FocusTimerAsset('gauge_frame')),
          Positioned.fill(
              child: FractionallySizedBox(
                  widthFactor: .92,
                  heightFactor: .55,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                              widthFactor: value.clamp(0, 1),
                              heightFactor: 1,
                              child: const FocusTimerAsset('gauge_fill')))))),
        ]),
      );
}

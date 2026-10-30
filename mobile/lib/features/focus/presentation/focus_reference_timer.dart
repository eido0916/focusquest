import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../core/widgets/reference_game_art.dart';
import '../../../core/widgets/quest_display.dart';

class FocusTimerScene extends StatelessWidget {
  const FocusTimerScene(
      {super.key,
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
      this.durationSeconds = 1800,
      this.onParty,
      this.partySize = 0,
      this.message,
      this.error,
      this.onRetry});
  final String characterName, characterType;
  final int level, chapter, seconds, durationSeconds, partySize;
  final double progress;
  final VoidCallback? onBattle, onCancel, onParty, onRetry;
  final VoidCallback onSound, onBack;
  final String? message, error;
  static String clock(int value) {
    final safe = math.max(0, value);
    return '${(safe ~/ 60).toString().padLeft(2, '0')}:${(safe % 60).toString().padLeft(2, '0')}';
  }

  Widget _timer(double width) {
    final elapsed = (durationSeconds - seconds).clamp(0, durationSeconds);
    return ReferenceFrame(
        key: const Key('focus-time-panel'),
        asset: 'timer_frame',
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text('残り時間',
              textAlign: TextAlign.center,
              style: referenceText(18, color: referenceGold)),
          const SizedBox(height: 6),
          Center(
              child: SizedBox(
                  width: 150,
                  height: 8,
                  child: Image.asset('$referenceArtPath/divider.png',
                      fit: BoxFit.fill, excludeFromSemantics: true))),
          SizedBox(
              height: (width * .43).clamp(130.0, 220.0),
              child: Stack(fit: StackFit.expand, children: [
                Center(
                    child: Opacity(
                        opacity: .52,
                        child: Image.asset(
                            '$referenceArtPath/timer_compass.png',
                            fit: BoxFit.contain,
                            excludeFromSemantics: true))),
                Semantics(
                    label: '残り時間',
                    value: clock(seconds),
                    child: Center(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                                '${math.max(0, seconds) ~/ 60}:${(math.max(0, seconds) % 60).toString().padLeft(2, '0')}',
                                key: const Key('focus-remaining-time'),
                                textScaler: TextScaler.noScaling,
                                style: referenceText(
                                        (width * .26).clamp(56.0, 120.0),
                                        color: const Color(0xffe7fbff),
                                        weight: FontWeight.w500)
                                    .copyWith(
                                        height: 1.15,
                                        fontFeatures: const [
                                      ui.FontFeature.tabularFigures()
                                    ],
                                        shadows: const [
                                      Shadow(
                                          color: Color(0xff168fff),
                                          blurRadius: 12),
                                      Shadow(
                                          color: Color(0xff54dfff),
                                          blurRadius: 3)
                                    ]))))),
              ])),
          const SizedBox(height: 8),
          ReferenceGauge(
              value: progress,
              height: 18,
              fillKey: const Key('focus-progress-fill'),
              semanticLabel: '集中の進捗'),
          const SizedBox(height: 8),
          Text('経過 ${clock(elapsed)} / ${clock(durationSeconds)}',
              textAlign: TextAlign.center, style: referenceText(13)),
          const SizedBox(height: 12),
          SizedBox(
              height: 7,
              child: Image.asset('$referenceArtPath/divider.png',
                  fit: BoxFit.fill, excludeFromSemantics: true)),
          ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Center(
                      child: Text(
                          partySize > 0 ? '$partySize人で集中中' : '自分の時間に、集中しましょう。',
                          textAlign: TextAlign.center,
                          style: referenceText(16))))),
        ]));
  }

  @override
  Widget build(BuildContext context) => QuestOrientationScope(
      orientation: Orientation.portrait,
      child: Scaffold(
          backgroundColor: const Color(0xff05203b),
          body: ReferenceBackdrop(
              name: 'timer_background',
              child: SafeArea(child: LayoutBuilder(builder: (context, box) {
                final width = math.min(box.maxWidth, 620.0);
                final gap =
                    (box.maxHeight - 558 - math.max(0, width - 390) * .43)
                        .clamp(0.0, 400.0);
                return QuestScreenFit(
                    key: const Key('focus-timer-scroll'),
                    child: Center(
                        child: SizedBox(
                            width: width,
                            child: Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 12, 12, 16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      ReferenceFrame(
                                          asset: 'chapter_frame',
                                          padding: const EdgeInsets.fromLTRB(
                                              15, 12, 10, 12),
                                          child: Row(children: [
                                            const ReferenceIcon('compass',
                                                size: 32),
                                            const SizedBox(width: 10),
                                            Expanded(
                                                child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                  Text('第$chapter章 · 集中クエスト進行中',
                                                      style: referenceText(14)),
                                                  Text(
                                                      '${durationSeconds ~/ 60}分の集中',
                                                      style: referenceText(12)),
                                                ])),
                                            IconButton(
                                                tooltip: '戻る',
                                                onPressed: onBack,
                                                icon: const ReferenceIcon(
                                                    'back',
                                                    size: 20),
                                                padding: EdgeInsets.zero,
                                                constraints:
                                                    const BoxConstraints(
                                                        minWidth: 40,
                                                        minHeight: 44))
                                          ])),
                                      SizedBox(height: gap),
                                      _timer(width - 24),
                                      const SizedBox(height: 10),
                                      ReferenceAction(
                                          key: const Key('focus-watch-battle'),
                                          label: '戦いの様子を見る',
                                          icon: 'swords',
                                          onTap: onBattle),
                                      const SizedBox(height: 8),
                                      if (message != null || error != null) ...[
                                        ReferenceFrame(
                                            child: Text(error ?? message!,
                                                style: referenceText(14),
                                                textAlign: TextAlign.center)),
                                        const SizedBox(height: 8),
                                      ],
                                      if (error != null) ...[
                                        ReferenceAction(
                                            label: '結果の保存を再試行',
                                            onTap: onRetry,
                                            compact: true),
                                        const SizedBox(height: 8)
                                      ],
                                      LayoutBuilder(
                                          builder: (context, available) {
                                        final sound = ReferenceAction(
                                            key: const Key('focus-sound'),
                                            label: 'サウンド設定',
                                            icon: 'sound',
                                            onTap: onSound,
                                            compact: true,
                                            chevron: false);
                                        final cancel = ReferenceAction(
                                            key: const Key('focus-cancel'),
                                            label: '集中を中断',
                                            icon: 'pause',
                                            onTap: onCancel,
                                            compact: true,
                                            chevron: false);
                                        if (available.maxWidth < 320 ||
                                            MediaQuery.textScalerOf(context)
                                                    .scale(1) >
                                                1.25) {
                                          return Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                sound,
                                                const SizedBox(height: 8),
                                                cancel
                                              ]);
                                        }
                                        return IntrinsicHeight(
                                            child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.stretch,
                                                children: [
                                              Expanded(child: sound),
                                              const SizedBox(width: 8),
                                              Expanded(child: cancel)
                                            ]));
                                      }),
                                      if (onParty != null) ...[
                                        const SizedBox(height: 8),
                                        ReferenceAction(
                                            label: 'パーティーを見る',
                                            icon: 'party',
                                            onTap: onParty,
                                            compact: true,
                                            chevron: false)
                                      ],
                                    ])))));
              })))));
}

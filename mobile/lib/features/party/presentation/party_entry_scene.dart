import 'package:focusquest/core/widgets/quest_screen_fit.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

const _base = 'assets/images/party_entry_v002/';
const _white = Color(0xfffffcf5);

/// Separate original artwork keeps every label selectable by the UI and every
/// action accessible. The source reference's duration panel belongs in the lobby.
class PartyEntryScene extends StatelessWidget {
  const PartyEntryScene({
    super.key,
    required this.onBack,
    required this.onCreate,
    required this.onJoin,
    this.connecting = false,
    this.error,
    this.reconnecting = false,
  });
  final VoidCallback onBack;
  final VoidCallback? onCreate, onJoin;
  final bool connecting, reconnecting;
  final String? error;

  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset('${_base}background.png',
            fit: BoxFit.cover,
            alignment: Alignment.bottomCenter,
            filterQuality: FilterQuality.none,
            excludeFromSemantics: true),
        SafeArea(child: LayoutBuilder(builder: (context, constraints) {
          final width = math.min(constraints.maxWidth, 620.0);
          final unit = width / 941;
          final textScale = MediaQuery.textScalerOf(context).scale(1);
          final grow = math.max(1.0, textScale);
          final headerHeight = math.max(48.0, 104 * unit);
          final actionHeight = math.max(64.0, 145 * unit) * grow;
          return QuestScreenFit(
              key: const Key('party-lobby-list'),
              child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                          width: width,
                          child: Column(children: [
                            SizedBox(height: 14 * unit),
                            Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 14 * unit),
                                child: Row(children: [
                                  Semantics(
                                      button: true,
                                      label: '戻る',
                                      child: SizedBox(
                                          width: headerHeight,
                                          height: headerHeight,
                                          child: _ArtPanel(
                                              asset: 'back',
                                              child: IconButton(
                                                  tooltip: '戻る',
                                                  onPressed: onBack,
                                                  icon: Image.asset(
                                                      '${_base}icon-back.png',
                                                      width: headerHeight * .68,
                                                      excludeFromSemantics:
                                                          true))))),
                                  SizedBox(width: 7 * unit),
                                  Expanded(
                                      child: SizedBox(
                                          height: headerHeight,
                                          child: _ArtPanel(
                                              asset: 'title',
                                              child: Center(
                                                  child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 14),
                                                      child: Text('パーティーを組む',
                                                          textAlign:
                                                              TextAlign.center,
                                                          style: _style(math.max(
                                                              17,
                                                              36 * unit)))))))),
                                ])),
                            SizedBox(
                                height: math.max(
                                    36.0,
                                    constraints.maxHeight * .168 -
                                        headerHeight -
                                        14 * unit)),
                            Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: width * .08),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      _EntryAction(
                                          key: const Key('party-create'),
                                          label: 'パーティーを作成',
                                          icon: 'icon-create',
                                          height: actionHeight,
                                          unit: unit,
                                          onTap: onCreate),
                                      SizedBox(height: 28 * unit),
                                      _EntryAction(
                                          key: const Key('party-join'),
                                          label: 'コードで参加',
                                          icon: 'icon-join',
                                          height: actionHeight,
                                          unit: unit,
                                          onTap: onJoin),
                                      SizedBox(height: 25 * unit),
                                      _ArtPanel(
                                          asset: 'information',
                                          child: Padding(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal:
                                                      math.max(23, 65 * unit),
                                                  vertical:
                                                      math.max(12, 35 * unit)),
                                              child: Text(
                                                  '最大4人で、同じ時間に集中。\nコードを共有して仲間を招待しましょう。',
                                                  style: _style(math.max(
                                                          13, 31 * unit))
                                                      .copyWith(
                                                          height: 1.55)))),
                                      if (reconnecting) ...[
                                        const SizedBox(height: 12),
                                        const _Message(
                                            '切断したパーティーのコードを入力すると復帰できます。'),
                                      ],
                                      if (connecting) ...[
                                        const SizedBox(height: 16),
                                        const LinearProgressIndicator(
                                            color: Color(0xffffce60)),
                                        const _Message('仲間の待つ場所へ接続しています…'),
                                      ],
                                      if (error != null) ...[
                                        const SizedBox(height: 12),
                                        _Message(error!,
                                            key: const Key('party-error')),
                                      ],
                                    ])),
                            const SizedBox(height: 24),
                          ])))));
        })),
      ]);
}

TextStyle _style(double size) => TextStyle(
        fontFamily: 'SunlitSerif',
        color: _white,
        fontSize: size,
        fontWeight: FontWeight.w500,
        shadows: const [
          Shadow(color: Color(0x99001430), offset: Offset(0, 1), blurRadius: 2)
        ]);

class _ArtPanel extends StatelessWidget {
  const _ArtPanel({required this.asset, required this.child});
  final String asset;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('$_base$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        child,
      ]);
}

class _EntryAction extends StatelessWidget {
  const _EntryAction(
      {super.key,
      required this.label,
      required this.icon,
      required this.height,
      required this.unit,
      this.onTap});
  final String label, icon;
  final double height, unit;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
          opacity: onTap == null ? .6 : 1,
          child: SizedBox(
              height: height,
              child: _ArtPanel(
                  asset: 'action',
                  child: SizedBox.expand(
                      child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 52 * unit),
                                  child: Row(children: [
                                    Image.asset('${_base}compass.png',
                                        width: 70 * unit,
                                        excludeFromSemantics: true),
                                    SizedBox(width: 24 * unit),
                                    Image.asset('$_base$icon.png',
                                        width: 48 * unit,
                                        excludeFromSemantics: true),
                                    SizedBox(width: 28 * unit),
                                    Image.asset('${_base}separator.png',
                                        width: 3 * unit,
                                        height: 56 * unit,
                                        excludeFromSemantics: true),
                                    SizedBox(width: 27 * unit),
                                    Expanded(
                                        child: Text(label,
                                            textAlign: TextAlign.center,
                                            style: _style(
                                                math.max(17, 40 * unit)))),
                                    SizedBox(width: 18 * unit),
                                    Image.asset('${_base}icon-chevron.png',
                                        width: 33 * unit,
                                        excludeFromSemantics: true),
                                  ])))))))));
}

class _Message extends StatelessWidget {
  const _Message(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => _ArtPanel(
      asset: 'information',
      child: Padding(
          padding: const EdgeInsets.all(18),
          child: Text(message, style: _style(14))));
}

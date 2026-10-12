import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'sunlit_widgets.dart';
import 'game_ui.dart';

/// A game window, with a restrained double border and an inset caption.
class QuestCard extends StatelessWidget {
  const QuestCard(
      {super.key, required this.child, this.parchment = false, this.caption});
  final Widget child;
  final bool parchment;
  final String? caption;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GamePanel(
          asset: parchment ? 'parchment_panel' : 'identity_panel',
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (caption != null) ...[
                  Text(caption!,
                      style: TextStyle(
                          color: parchment ? gamePaperInk : gameGold,
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                ],
                child,
              ])));
}

class QuestBackdrop extends StatelessWidget {
  const QuestBackdrop({super.key, required this.child, this.dim = .08});
  final Widget child;
  final double dim;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(gameBackground,
            fit: BoxFit.cover, alignment: Alignment.topCenter),
        ColoredBox(color: Colors.black.withOpacity(dim)),
        const DecoratedBox(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
              Color(0x05061627),
              Color(0x10061627),
              Color(0xda061627)
            ]))),
        child,
      ]);
}

class QuestScenery extends StatelessWidget {
  const QuestScenery({super.key, this.height = 200, this.child});
  final double height;
  final Widget? child;
  @override
  Widget build(BuildContext context) => SizedBox(
      height: height,
      child: QuestBackdrop(child: child ?? const SizedBox.shrink()));
}

/// Leaves an open view of the world between the HUD and the command windows.
/// Short screens and enlarged text can scroll without clipping controls.
class QuestStage extends StatelessWidget {
  const QuestStage(
      {super.key, required this.hud, required this.commands, this.figure});
  final Widget hud;
  final Widget commands;
  final Widget? figure;
  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final scale = MediaQuery.textScalerOf(context).scale(1);
        final height = math.max(
            constraints.maxHeight, 580.0 + math.max(0, scale - 1) * 280);
        return SingleChildScrollView(
            child: SizedBox(
                height: height,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          hud,
                          Expanded(
                              child: Center(
                                  child: figure ?? const SizedBox.shrink())),
                          commands,
                        ]))));
      });
}

class QuestCommand extends StatelessWidget {
  const QuestCommand({super.key, required this.label, this.onTap, this.detail});
  final String label;
  final String? detail;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
          onTap: onTap,
          child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Row(children: [
                Text('▸',
                    style: TextStyle(
                        fontSize: 20,
                        color: onTap == null ? Colors.white24 : AppTheme.gold)),
                const SizedBox(width: 12),
                Expanded(
                    child: Text(label,
                        style: TextStyle(
                            fontSize: 16,
                            color: onTap == null
                                ? Colors.white38
                                : const Color(0xfff5f0df)))),
                if (detail != null)
                  Text(detail!,
                      style:
                          const TextStyle(fontSize: 12, color: AppTheme.gold)),
              ]))));
}

class QuestNavigation extends StatelessWidget {
  const QuestNavigation(
      {super.key, required this.selected, required this.onSelect});
  final int selected;
  final ValueChanged<int> onSelect;
  @override
  Widget build(BuildContext context) {
    const labels = ['ホーム', 'キャラクター', '冒険', '設定'];
    const icons = [
      Icons.home_rounded,
      Icons.people_alt_rounded,
      Icons.map_outlined,
      Icons.settings_rounded
    ];
    return Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff0a2034), Color(0xff04131f)]),
            border: Border(top: BorderSide(color: sunlitGold, width: 1))),
        child: SafeArea(
            top: false,
            child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
                child: Row(
                    children: List.generate(labels.length, (i) {
                  final active = selected == i;
                  final content = SizedBox(
                      height: 88,
                      width: double.infinity,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12, horizontal: 12),
                          child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icons[i],
                                    size: 27,
                                    color: active
                                        ? const Color(0xffffe8b0)
                                        : sunlitGold,
                                    shadows: active
                                        ? const [
                                            Shadow(
                                                color: Color(0xffffd584),
                                                blurRadius: 14)
                                          ]
                                        : null),
                                const SizedBox(height: 4),
                                FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(labels[i],
                                        maxLines: 1,
                                        style: TextStyle(
                                            fontFamily: 'SunlitSerif',
                                            fontSize: 12,
                                            fontWeight: active
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: active
                                                ? const Color(0xffffe8b0)
                                                : sunlitGold))),
                              ])));
                  return Expanded(
                      child: Semantics(
                          selected: active,
                          button: true,
                          child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                  onTap: () => onSelect(i),
                                  child: active
                                      ? GamePanel(
                                          asset: 'equipment_row',
                                          protectContent: false,
                                          padding: EdgeInsets.zero,
                                          child: content)
                                      : Container(
                                          decoration: BoxDecoration(
                                              border: i > 0
                                                  ? const Border(
                                                      left: BorderSide(
                                                          color: Color(
                                                              0x335f6e77)))
                                                  : null),
                                          child: content)))));
                })))));
  }
}

class HeroArtwork extends StatelessWidget {
  const HeroArtwork(
      {super.key, this.height = 360, this.alignment = Alignment.bottomCenter});
  final double height;
  final Alignment alignment;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/ui/hero_swordsman.png',
          height: height,
          fit: BoxFit.contain,
          alignment: alignment,
          filterQuality: FilterQuality.high);
}

class QuestActionButton extends StatelessWidget {
  const QuestActionButton(
      {super.key,
      required this.label,
      required this.icon,
      this.onTap,
      this.compact = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      enabled: onTap != null,
      child: Opacity(
          opacity: onTap == null ? .48 : 1,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  child: GamePanel(
                      asset: 'equipment_row',
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      child: ConstrainedBox(
                          constraints:
                              BoxConstraints(minHeight: compact ? 40 : 56),
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon,
                                    color: gameGold, size: compact ? 26 : 32),
                                const SizedBox(width: 12),
                                Flexible(
                                    child: Text(label,
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontFamily: 'SunlitSerif',
                                            fontSize: compact ? 18 : 23,
                                            fontWeight: FontWeight.bold,
                                            color: gameWhite))),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_right_rounded,
                                    color: gameGold),
                              ])))))));
}

Future<void> runAction(
    BuildContext context, Future<void> Function() action) async {
  try {
    await action();
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(error is StateError || error is ArgumentError
              ? error.toString().replaceFirst(RegExp(r'^[^:]+: '), '')
              : '保存または接続に失敗しました。もう一度お試しください。')));
    }
  }
}

class HeroBadge extends StatelessWidget {
  const HeroBadge(
      {super.key,
      required this.name,
      this.large = false,
      this.assetKey = 'hero.warrior'});
  final String name;
  final bool large;
  final String assetKey;
  @override
  Widget build(BuildContext context) =>
      Column(mainAxisSize: MainAxisSize.min, children: [
        AdventurerFigure(type: assetKey, size: large ? 120 : 56),
        const SizedBox(height: 6),
        Text(name, style: Theme.of(context).textTheme.titleMedium),
      ]);
}

/// Original small game figure; no franchise artwork is bundled.
class AdventurerFigure extends StatelessWidget {
  const AdventurerFigure(
      {super.key, this.type = 'hero.warrior', this.size = 160});
  final String type;
  final double size;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: SizedBox(
          width: size * .75,
          height: size,
          child: CustomPaint(painter: _AdventurerPainter(type))));
}

class _AdventurerPainter extends CustomPainter {
  const _AdventurerPainter(this.type);
  final String type;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 128);
    final paint = Paint();
    void rect(double x, double y, double w, double h, Color color) =>
        canvas.drawRect(Rect.fromLTWH(x, y, w, h), paint..color = color);
    final cloak = type.contains('mage')
        ? const Color(0xff73599c)
        : type.contains('ranger')
            ? const Color(0xff477d55)
            : const Color(0xff386c94);
    canvas.drawOval(
        const Rect.fromLTWH(13, 112, 73, 12), paint..color = Colors.black45);
    canvas.drawPath(
        Path()
          ..moveTo(29, 43)
          ..lineTo(66, 43)
          ..lineTo(81, 103)
          ..lineTo(18, 105)
          ..close(),
        paint..color = const Color(0xff1c2834));
    canvas.drawPath(
        Path()
          ..moveTo(33, 44)
          ..lineTo(65, 44)
          ..lineTo(75, 99)
          ..lineTo(22, 99)
          ..close(),
        paint..color = cloak);
    rect(34, 90, 12, 24, const Color(0xff443429));
    rect(53, 90, 12, 24, const Color(0xff443429));
    rect(29, 109, 18, 9, const Color(0xff282826));
    rect(51, 109, 19, 9, const Color(0xff282826));
    rect(31, 45, 38, 42, const Color(0xff9aa8a4));
    rect(36, 49, 27, 31, const Color(0xffd1d5c3));
    rect(31, 79, 38, 7, const Color(0xff68513a));
    rect(46, 79, 9, 7, AppTheme.gold);
    rect(32, 20, 33, 28, const Color(0xffdbb285));
    rect(28, 15, 40, 14, const Color(0xff463423));
    rect(29, 25, 9, 15, const Color(0xff463423));
    rect(57, 24, 10, 11, const Color(0xff463423));
    rect(42, 34, 4, 4, const Color(0xff282826));
    rect(56, 34, 4, 4, const Color(0xff282826));
    rect(32, 22, 32, 4, AppTheme.gold);
    rect(22, 53, 10, 31, const Color(0xff82948f));
    rect(68, 53, 9, 31, const Color(0xff82948f));
    rect(78, 35, 4, 49, const Color(0xffdfe4d5));
    rect(72, 80, 17, 4, AppTheme.gold);
    rect(78, 84, 4, 14, const Color(0xff68442e));
    canvas.drawPath(
        Path()
          ..moveTo(14, 64)
          ..lineTo(35, 59)
          ..lineTo(38, 86)
          ..lineTo(25, 98)
          ..lineTo(13, 86)
          ..close(),
        paint..color = AppTheme.gold);
    canvas.drawPath(
        Path()
          ..moveTo(18, 67)
          ..lineTo(31, 64)
          ..lineTo(33, 84)
          ..lineTo(25, 92)
          ..lineTo(18, 84)
          ..close(),
        paint..color = cloak);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_AdventurerPainter oldDelegate) =>
      oldDelegate.type != type;
}

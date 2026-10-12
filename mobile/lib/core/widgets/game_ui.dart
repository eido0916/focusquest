import 'package:flutter/material.dart';
import 'dart:math' as math;

const gameGold = Color(0xffffd58b);
const gameWhite = Color(0xfffff8e9);
const gameInk = Color(0xff071b30);
const gamePaperInk = Color(0xff352819);
const gameUiAssets = 'assets/images/character_ui_v002/';
const gameBackground = 'assets/images/lobby/castle_courtyard.png';

class GameArtwork extends StatelessWidget {
  const GameArtwork(this.asset, {super.key});
  final String asset;
  @override
  Widget build(BuildContext context) {
    final height = switch (asset) {
      'identity_panel' => 350.0,
      'equipment_row' => 228.0,
      'header_banner' => 261.0,
      'parchment_panel' => 382.0,
      _ => 350.0,
    };
    final topBorder = asset == 'equipment_row'
        ? 56.0
        : asset == 'header_banner'
            ? 72.0
            : 80.0;
    final bottomBorder = asset == 'equipment_row'
        ? 64.0
        : asset == 'header_banner'
            ? 72.0
            : 112.0;
    return LayoutBuilder(builder: (context, bounds) {
      final scale = math.max(
          4.0,
          math.max(
              bounds.maxWidth.isFinite
                  ? 250 / math.max(1, bounds.maxWidth)
                  : 4.0,
              bounds.maxHeight.isFinite
                  ? (topBorder + bottomBorder + 16) /
                      math.max(1, bounds.maxHeight)
                  : 4.0));
      return Image.asset('$gameUiAssets$asset.png',
          scale: scale,
          centerSlice: Rect.fromLTRB(112 / scale, topBorder / scale,
              1168 / scale, (height - bottomBorder) / scale),
          fit: BoxFit.fill,
          excludeFromSemantics: true);
    });
  }
}

/// Shared artwork from the character screen. Gameplay sprites are separate.
class GamePanel extends StatelessWidget {
  const GamePanel(
      {super.key,
      required this.child,
      this.asset = 'identity_panel',
      this.padding = const EdgeInsets.all(20),
      this.protectContent = true});
  final Widget child;
  final String asset;
  final EdgeInsetsGeometry padding;
  final bool protectContent;
  @override
  Widget build(BuildContext context) {
    final requested = padding.resolve(Directionality.of(context));
    final safe = asset == 'equipment_row'
        ? const EdgeInsets.fromLTRB(28, 16, 28, 20)
        : const EdgeInsets.fromLTRB(32, 28, 32, 40);
    final inset = protectContent
        ? EdgeInsets.fromLTRB(
            math.max(requested.left, safe.left),
            math.max(requested.top, safe.top),
            math.max(requested.right, safe.right),
            math.max(requested.bottom, safe.bottom))
        : requested;
    return Stack(alignment: Alignment.center, children: [
      Positioned.fill(child: GameArtwork(asset)),
      Padding(padding: inset, child: child),
    ]);
  }
}

class GameBackdrop extends StatelessWidget {
  const GameBackdrop({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(fit: StackFit.expand, children: [
        Image.asset(gameBackground,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            excludeFromSemantics: true),
        child,
      ]);
}

class GameAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GameAppBar(
      {super.key,
      this.title,
      this.actions,
      this.backgroundColor,
      this.foregroundColor,
      this.elevation,
      this.automaticallyImplyLeading = true});
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor, foregroundColor;
  final double? elevation;
  final bool automaticallyImplyLeading;
  @override
  Size get preferredSize => const Size.fromHeight(76);
  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(
            child: IgnorePointer(child: GameArtwork('header_banner'))),
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: AppBar(
                toolbarHeight: 76,
                title: title,
                actions: actions,
                automaticallyImplyLeading: automaticallyImplyLeading,
                backgroundColor: Colors.transparent,
                foregroundColor: gameWhite,
                elevation: 0,
                surfaceTintColor: Colors.transparent))
      ]);
}

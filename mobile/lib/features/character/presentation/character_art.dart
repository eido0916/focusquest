import 'package:flutter/material.dart';

const characterGold = Color(0xffffd58b);
const characterWhite = Color(0xfffff8e9);

class CharacterIcon extends StatelessWidget {
  const CharacterIcon(this.name, {super.key, this.size = 24});
  final String name;
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/character_ui_v002/$name.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          excludeFromSemantics: true);
}

/// Separate image materials with live text, stats and accessible controls.
class CharacterPanel extends StatelessWidget {
  const CharacterPanel(
      {super.key,
      required this.asset,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final String asset;
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('assets/images/character_ui_v002/$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

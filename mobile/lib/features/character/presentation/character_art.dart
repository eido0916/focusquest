import 'package:flutter/material.dart';

const characterGold = Color(0xffffd58b);
const characterWhite = Color(0xfffff8e9);
const characterMaterialPath = 'assets/images/character_ui_v006';

class CharacterMaterialScale extends InheritedWidget {
  const CharacterMaterialScale(
      {super.key, required this.factor, required super.child});
  final double factor;
  static double of(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<CharacterMaterialScale>()
          ?.factor ??
      1;
  @override
  bool updateShouldNotify(CharacterMaterialScale oldWidget) =>
      factor != oldWidget.factor;
}

class CharacterIcon extends StatelessWidget {
  const CharacterIcon(this.name,
      {super.key, this.size = 24, this.width, this.height});
  final String name;
  final double size;
  final double? width;
  final double? height;
  @override
  Widget build(BuildContext context) =>
      Image.asset('$characterMaterialPath/$name.png',
          width: (width ?? size) * CharacterMaterialScale.of(context),
          height: (height ?? size) * CharacterMaterialScale.of(context),
          fit: BoxFit.contain,
          excludeFromSemantics: true);
}

/// Texture and edge pieces stay separate from dynamic text and hit targets.
class CharacterPanel extends StatelessWidget {
  const CharacterPanel(
      {super.key,
      required this.asset,
      required this.child,
      this.padding = const EdgeInsets.all(20),
      this.slice});
  final String asset;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Rect? slice;
  @override
  Widget build(BuildContext context) {
    final factor = CharacterMaterialScale.of(context);
    final scaledSlice = slice == null
        ? null
        : Rect.fromLTRB(slice!.left * factor, slice!.top * factor,
            slice!.right * factor, slice!.bottom * factor);
    return Stack(children: [
      Positioned.fill(
          child: Image.asset('$characterMaterialPath/$asset.png',
              fit: BoxFit.fill,
              centerSlice: scaledSlice,
              scale: slice == null ? 1 : 3 / factor,
              filterQuality: FilterQuality.high,
              excludeFromSemantics: true)),
      Padding(padding: padding * factor, child: child),
    ]);
  }
}

class CharacterSectionHeading extends StatelessWidget {
  const CharacterSectionHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: CharacterIcon('section_rule', height: 12)),
        const SizedBox(width: 12),
        Expanded(
            flex: 2,
            child: Center(
                child: Text(title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 20,
                        color: Color(0xff241b12),
                        fontWeight: FontWeight.w600,
                        height: 1.25)))),
        const SizedBox(width: 12),
        const Expanded(
            child: RotatedBox(
                quarterTurns: 2,
                child: CharacterIcon('section_rule', height: 12))),
      ]);
}

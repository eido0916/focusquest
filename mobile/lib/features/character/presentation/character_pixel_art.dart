import 'package:flutter/material.dart';
import 'character_art.dart' show CharacterMaterialScale;
export 'character_art.dart' show CharacterMaterialScale;

const characterMaterialPath = 'assets/images/character_ui_v008';
const characterGold = Color(0xffffd58b);

/// Independent PNG assets with fixed corner ornaments and live content.
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
    final Size native = switch (asset) {
      'header_banner' => const Size(240, 44),
      'stats_parchment' => const Size(400, 286),
      'stat_row' => const Size(200, 42),
      'action_row' => const Size(200, 46),
      _ => const Size(400, 82),
    };
    return Stack(children: [
      Positioned.fill(child: LayoutBuilder(builder: (context, box) {
        final width = box.maxWidth / factor;
        final height = box.maxHeight / factor;
        return OverflowBox(
            alignment: Alignment.topLeft,
            minWidth: width,
            maxWidth: width,
            minHeight: height,
            maxHeight: height,
            child: Transform.scale(
                scale: factor,
                alignment: Alignment.topLeft,
                child: Image.asset('$characterMaterialPath/$asset.png',
                    width: width,
                    height: height,
                    fit: BoxFit.fill,
                    centerSlice: Rect.fromLTRB(
                        19, 12, native.width - 19, native.height - 12),
                    filterQuality: FilterQuality.none,
                    excludeFromSemantics: true)));
      })),
      Padding(padding: padding * factor, child: child),
    ]);
  }
}

class CharacterIcon extends StatelessWidget {
  const CharacterIcon(this.name,
      {super.key, this.size = 24, this.width, this.height});
  final String name;
  final double size;
  final double? width, height;
  @override
  Widget build(BuildContext context) =>
      Image.asset('$characterMaterialPath/$name.png',
          width: (width ?? size) * CharacterMaterialScale.of(context),
          height: (height ?? size) * CharacterMaterialScale.of(context),
          fit: name == 'section_rule' ? BoxFit.fill : BoxFit.contain,
          filterQuality: FilterQuality.none,
          excludeFromSemantics: true);
}

class CharacterSectionHeading extends StatelessWidget {
  const CharacterSectionHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Row(children: [
        const Expanded(child: CharacterIcon('section_rule', height: 10)),
        const SizedBox(width: 8),
        Text(title,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: title == '能力値' ? 20 : 17,
                color: const Color(0xff241b12),
                fontWeight: FontWeight.w600,
                height: 1.2)),
        const SizedBox(width: 8),
        const Expanded(
            child: RotatedBox(
                quarterTurns: 2,
                child: CharacterIcon('section_rule', height: 10))),
      ]);
}

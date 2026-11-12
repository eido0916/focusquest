import 'package:flutter/material.dart';
import '../../diagnosis/presentation/job_portrait.dart';

/// Detailed static menu originals, independent of battle animation.
class CharacterPixelPortrait extends StatelessWidget {
  const CharacterPixelPortrait(
      {super.key, required this.role, required this.appearance});
  final String role, appearance;

  static String assetFor(String role, String appearance) {
    final type = JobPortrait.roleNames.containsKey(role) ? role : 'warrior';
    final sex = appearance == 'female' ? 'female' : 'male';
    return 'assets/images/character_ui_v008/standing/$sex/$type.png';
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final side =
            box.maxWidth < box.maxHeight ? box.maxWidth : box.maxHeight;
        return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
                width: side,
                height: side,
                child: Image.asset(assetFor(role, appearance),
                    filterQuality: FilterQuality.none,
                    isAntiAlias: false,
                    fit: BoxFit.fill,
                    semanticLabel:
                        '${appearance == 'female' ? '女性' : '男性'}の${JobPortrait.roleNames[role] ?? '剣士'}のドット絵の立ち姿')));
      });
}

class CharacterFaceIcon extends StatelessWidget {
  const CharacterFaceIcon(
      {super.key,
      required this.role,
      required this.appearance,
      this.size = 56});
  final String role, appearance;
  final double size;
  @override
  Widget build(BuildContext context) {
    final type = JobPortrait.roleNames.containsKey(role) ? role : 'warrior';
    final sex = appearance == 'female' ? 'female' : 'male';
    return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
            color: const Color(0xff061d3e),
            border: Border.all(color: const Color(0xffffd58b), width: 2)),
        child: Image.asset(
            'assets/images/focus_selection_v001/avatars/$sex/$type.png',
            filterQuality: FilterQuality.none,
            isAntiAlias: false,
            semanticLabel: '${JobPortrait.roleNames[type]}の顔アイコン'));
  }
}

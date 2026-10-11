import 'package:flutter/material.dart';

/// Shared supplied artwork for diagnosis, home, and character screens.
class JobPortrait extends StatelessWidget {
  const JobPortrait({
    super.key,
    required this.typeId,
    this.appearance = 'male',
    this.height = 240,
    this.lobby = false,
    this.fit = BoxFit.contain,
    this.alignment,
  });

  final String typeId;
  final String appearance;
  final double height;
  final bool lobby;
  final BoxFit fit;
  final Alignment? alignment;

  static const roleNames = {
    'warrior': '剣士',
    'boxer': '拳闘士',
    'samurai': '侍',
    'guardian': '重騎士',
    'ninja': '忍者',
    'assassin': 'アサシン',
    'ranger': '弓使い',
    'gunner': 'ガンナー',
    'mage': '魔法使い',
    'spellblade': '魔剣士',
    'onmyoji': '陰陽師',
    'reaper': '鎌使い',
    'angel': '天使',
    'devil': '悪魔',
    'dragon_knight': 'ドラゴンナイト',
    'berserker': 'バーサーカー',
  };

  @override
  Widget build(BuildContext context) {
    final role = roleNames.containsKey(typeId) ? typeId : 'warrior';
    final variant = appearance == 'female' ? 'female' : 'male';
    return SizedBox(
      height: height,
      width: lobby ? double.infinity : null,
      child: Image.asset(
        lobby
            ? 'assets/images/lobby/portraits/${variant == 'female' ? 'female/' : ''}$role.png'
            : 'assets/images/portraits/$variant/$role.webp',
        fit: fit,
        alignment:
            alignment ?? (lobby ? Alignment.center : Alignment.bottomCenter),
        semanticLabel:
            '${variant == 'female' ? '女' : '男'}の${roleNames[role]}の立ち絵',
      ),
    );
  }
}

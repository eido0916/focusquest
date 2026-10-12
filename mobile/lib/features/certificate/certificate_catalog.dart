import 'package:flutter/material.dart';

class CertificateCatalog {
  static const titles = <String, List<String>>{
    'warrior': ['駆け出し剣士', '見習い剣士', '一人前の剣士', '歴戦の剣士', '剣の達人', '剣豪', '剣王', '剣聖'],
    'boxer': [
      '駆け出し拳闘士',
      '見習い拳闘士',
      '一人前の拳闘士',
      '熟練の拳士',
      '拳の達人',
      '拳豪',
      '拳聖',
      '武神'
    ],
    'samurai': ['若侍', '一人前の侍', '熟練の侍', '歴戦の剣客', '居合の達人', '剣豪', '剣鬼', '天下無双'],
    'guardian': [
      '見習い重騎士',
      '駆け出し守護者',
      '王国の重騎士',
      '歴戦の重騎士',
      '鉄壁の騎士',
      '城塞の守護者',
      '不落の守護者',
      '守護神'
    ],
    'ninja': ['忍び見習い', '下忍', '中忍', '上忍', '影の達人', '影忍', '影頭', '忍神'],
    'assassin': [
      '見習い暗殺者',
      '駆け出し暗殺者',
      '隠密の刃',
      '熟練の暗殺者',
      '影刃',
      '闇の処刑人',
      '漆黒の死神',
      '暗殺王'
    ],
    'ranger': [
      '駆け出し弓使い',
      '見習い射手',
      '一人前の射手',
      '熟練の射手',
      '弓の名手',
      '必中の狩人',
      '神弓の射手',
      '弓神'
    ],
    'gunner': [
      '新米ガンナー',
      '見習い銃士',
      '一人前の銃士',
      '熟練の銃士',
      '早撃ちの名手',
      '百発百中の銃士',
      '伝説の銃士',
      '銃神'
    ],
    'mage': [
      '見習い魔法使い',
      '初級魔法使い',
      '魔術師',
      '熟練の魔術師',
      '魔導士',
      '高位魔導士',
      '魔導の賢者',
      '大魔導士'
    ],
    'spellblade': [
      '駆け出し魔剣士',
      '見習い魔剣士',
      '一人前の魔剣士',
      '闇刃の使い手',
      '魔刃の達人',
      '深淵の魔剣士',
      '魔剣王',
      '魔王騎士'
    ],
    'onmyoji': [
      '見習い陰陽師',
      '駆け出し陰陽師',
      '式神使い',
      '陰陽の術士',
      '熟練の陰陽師',
      '陰陽の達人',
      '大陰陽師',
      '天命の陰陽師'
    ],
    'reaper': [
      '見習い鎌使い',
      '駆け出し鎌使い',
      '鎌の使い手',
      '魂狩り',
      '死霊の狩人',
      '黄昏の死神',
      '冥府の死神',
      '冥王'
    ],
    'angel': ['下級天使', '若き天使', '守護天使', '祝福の天使', '聖光の使徒', '上級天使', '大天使', '熾天使'],
    'devil': ['見習い悪魔', '下級悪魔', '闇の使い手', '中級悪魔', '上級悪魔', '魔将', '魔王', '魔神'],
    'dragon_knight': [
      '見習い竜騎士',
      '駆け出し竜騎士',
      '一人前の竜騎士',
      '竜槍の使い手',
      '竜騎兵長',
      '竜騎将',
      '竜騎王',
      '竜神騎士'
    ],
    'berserker': [
      '駆け出し狂戦士',
      '荒くれ戦士',
      '猛き狂戦士',
      '血染めの戦士',
      '戦鬼',
      '紅蓮の狂戦士',
      '破壊王',
      '破壊神'
    ],
  };

  static String title(String role, int level) {
    final list = titles[role];
    if (list == null) throw ArgumentError.value(role, 'role');
    return list[level.clamp(1, 8) - 1];
  }

  static Color accent(String role) => switch (role) {
        'boxer' || 'berserker' || 'devil' => const Color(0xff712e28),
        'assassin' || 'reaper' => const Color(0xff493045),
        'ranger' => const Color(0xff36523c),
        'mage' || 'spellblade' || 'onmyoji' => const Color(0xff4d416b),
        'angel' || 'guardian' => const Color(0xff655333),
        _ => const Color(0xff253e5b),
      };

  static String portrait(String role, String gender) => role == 'gunner' &&
          gender == 'female'
      ? 'assets/images/lobby/portraits/female/gunner_dark_brown_transparent_v002.png'
      : 'assets/images/lobby/portraits/${gender == 'female' ? 'female/' : ''}$role.png';
  static String template(String role, String gender) => role == 'gunner' &&
          gender == 'female'
      ? 'assets/images/certificates_landscape_v002/gunner_female_dark_brown_v003.png'
      : 'assets/images/certificates_landscape_v002/${role}_$gender.png';
}

import '../../../core/config/game_balance.dart';
import 'stats.dart';

class Character {
  Character(
      {required this.id,
      required this.name,
      required this.characterType,
      required this.baseStats,
      this.appearance = 'male',
      this.level = 1,
      this.currentExp = 0,
      this.rarity = 'N',
      Map<String, String> equippedItems = const {}})
      : equippedItems = Map.unmodifiable(equippedItems);
  final String id;
  final String name;
  final String characterType;
  final String appearance;
  final String rarity;
  final int level;
  final int currentExp;
  final Stats baseStats;
  final Map<String, String> equippedItems;
  int get requiredExp => GameBalance.requiredExp(level);
  Character copyWith(
          {int? level, int? currentExp, Map<String, String>? equippedItems}) =>
      Character(
          id: id,
          name: name,
          characterType: characterType,
          appearance: appearance,
          baseStats: baseStats,
          rarity: rarity,
          level: level ?? this.level,
          currentExp: currentExp ?? this.currentExp,
          equippedItems: equippedItems ?? this.equippedItems);
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterType': characterType,
        'appearance': appearance,
        'rarity': rarity,
        'level': level,
        'currentExp': currentExp,
        'baseStats': baseStats.toJson(),
        'equippedItems': equippedItems
      };
  factory Character.fromJson(Map<String, dynamic> json) => Character(
      id: json['id'] as String,
      name: json['name'] as String,
      characterType: json['characterType'] as String,
      appearance: json['appearance'] as String? ?? 'male',
      baseStats:
          Stats.fromJson(Map<String, dynamic>.from(json['baseStats'] as Map)),
      rarity: json['rarity'] as String,
      level: json['level'] as int,
      currentExp: json['currentExp'] as int,
      equippedItems: Map<String, String>.from(json['equippedItems'] as Map));
}

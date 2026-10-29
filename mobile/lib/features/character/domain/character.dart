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
      this.selectedTitle,
      this.rarity = 'N',
      Map<String, int> trainingPoints = const {},
      Set<String> unlockedJobs = const {},
      Map<String, String> equippedItems = const {}})
      : trainingPoints = Map.unmodifiable(trainingPoints),
        unlockedJobs = Set.unmodifiable(unlockedJobs),
        equippedItems = Map.unmodifiable(equippedItems);
  final Map<String, int> trainingPoints;
  final Set<String> unlockedJobs;
  final String id;
  final String name;
  final String characterType;
  final String appearance;
  final String rarity;
  final int level;
  final int currentExp;

  /// Null follows the highest unlocked title; explicit choices persist.
  final String? selectedTitle;
  final Stats baseStats;
  final Map<String, String> equippedItems;
  int get requiredExp => GameBalance.requiredExp(level);
  Character copyWith(
          {String? name,
          Map<String, int>? trainingPoints,
          int? level,
          int? currentExp,
          String? selectedTitle,
          Map<String, String>? equippedItems}) =>
      Character(
          id: id,
          name: name ?? this.name,
          trainingPoints: trainingPoints ?? this.trainingPoints,
          unlockedJobs: unlockedJobs,
          characterType: characterType,
          appearance: appearance,
          baseStats: baseStats,
          rarity: rarity,
          level: level ?? this.level,
          currentExp: currentExp ?? this.currentExp,
          selectedTitle: selectedTitle ?? this.selectedTitle,
          equippedItems: equippedItems ?? this.equippedItems);
  Map<String, dynamic> toJson() => {
        'trainingPoints': trainingPoints,
        'unlockedJobs': unlockedJobs.toList(),
        'id': id,
        'name': name,
        'characterType': characterType,
        'appearance': appearance,
        'rarity': rarity,
        'level': level,
        'currentExp': currentExp,
        'selectedTitle': selectedTitle,
        'baseStats': baseStats.toJson(),
        'equippedItems': equippedItems
      };
  factory Character.fromJson(Map<String, dynamic> json) => Character(
      trainingPoints:
          Map<String, int>.from(json['trainingPoints'] as Map? ?? {}),
      unlockedJobs: Set<String>.from(json['unlockedJobs'] as List? ?? []),
      id: json['id'] as String,
      name: json['name'] as String,
      characterType: json['characterType'] as String,
      appearance: json['appearance'] as String? ?? 'male',
      baseStats:
          Stats.fromJson(Map<String, dynamic>.from(json['baseStats'] as Map)),
      rarity: json['rarity'] as String,
      level: json['level'] as int,
      currentExp: json['currentExp'] as int,
      selectedTitle: json['selectedTitle'] as String?,
      equippedItems: Map<String, String>.from(json['equippedItems'] as Map));
}

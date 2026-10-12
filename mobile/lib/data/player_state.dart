import '../features/character/domain/character.dart';
import '../features/focus/domain/focus_session.dart';

class PlayerState {
  PlayerState(
      {required this.uid,
      this.onboardingComplete = false,
      this.coins = 0,
      this.activeCharacterId,
      this.monitoring = false,
      this.targetPackages = const [],
      this.firstPlayedAt,
      this.adventurerNumber,
      this.totalDefeats = 0,
      this.focusAdventureSeconds = 0,
      Set<int> clearedPlayableStages = const {},
      Set<String> encounteredEnemyIds = const {},
      Map<String, Character> characters = const {},
      Map<String, int> inventory = const {},
      Map<String, FocusSession> sessions = const {},
      Set<String> appliedOperations = const {}})
      : characters = Map.unmodifiable(characters),
        clearedPlayableStages = Set.unmodifiable(clearedPlayableStages),
        encounteredEnemyIds = Set.unmodifiable(encounteredEnemyIds),
        inventory = Map.unmodifiable(inventory),
        sessions = Map.unmodifiable(sessions),
        appliedOperations = Set.unmodifiable(appliedOperations);
  final String uid;
  final DateTime? firstPlayedAt;
  final String? adventurerNumber;
  final int totalDefeats;
  final int focusAdventureSeconds;
  final bool onboardingComplete;
  final int coins;
  final String? activeCharacterId;
  final bool monitoring;
  final List<String> targetPackages;
  final Map<String, Character> characters;
  final Map<String, int> inventory;
  final Map<String, FocusSession> sessions;
  final Set<String> appliedOperations;
  final Set<int> clearedPlayableStages;
  final Set<String> encounteredEnemyIds;
  Character? get activeCharacter => characters[activeCharacterId];

  PlayerState copyWith(
          {bool? onboardingComplete,
          DateTime? firstPlayedAt,
          String? adventurerNumber,
          int? totalDefeats,
          int? focusAdventureSeconds,
          int? coins,
          String? activeCharacterId,
          bool? monitoring,
          List<String>? targetPackages,
          Map<String, Character>? characters,
          Map<String, int>? inventory,
          Map<String, FocusSession>? sessions,
          Set<int>? clearedPlayableStages,
          Set<String>? encounteredEnemyIds,
          Set<String>? appliedOperations}) =>
      PlayerState(
          uid: uid,
          firstPlayedAt: firstPlayedAt ?? this.firstPlayedAt,
          adventurerNumber: adventurerNumber ?? this.adventurerNumber,
          totalDefeats: totalDefeats ?? this.totalDefeats,
          focusAdventureSeconds:
              focusAdventureSeconds ?? this.focusAdventureSeconds,
          onboardingComplete: onboardingComplete ?? this.onboardingComplete,
          coins: coins ?? this.coins,
          activeCharacterId: activeCharacterId ?? this.activeCharacterId,
          monitoring: monitoring ?? this.monitoring,
          targetPackages: targetPackages ?? this.targetPackages,
          characters: characters ?? this.characters,
          inventory: inventory ?? this.inventory,
          sessions: sessions ?? this.sessions,
          clearedPlayableStages:
              clearedPlayableStages ?? this.clearedPlayableStages,
          encounteredEnemyIds: encounteredEnemyIds ?? this.encounteredEnemyIds,
          appliedOperations: appliedOperations ?? this.appliedOperations);

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'firstPlayedAt': firstPlayedAt?.toUtc().toIso8601String(),
        'adventurerNumber': adventurerNumber,
        'totalDefeats': totalDefeats,
        'focusAdventureSeconds': focusAdventureSeconds,
        'uid': uid,
        'onboardingComplete': onboardingComplete,
        'coins': coins,
        'activeCharacterId': activeCharacterId,
        'monitoring': monitoring,
        'targetPackages': targetPackages,
        'clearedPlayableStages': clearedPlayableStages.toList(),
        'encounteredEnemyIds': encounteredEnemyIds.toList(),
        'characters':
            characters.map((key, value) => MapEntry(key, value.toJson())),
        'inventory': inventory,
        'sessions': sessions.map((key, value) => MapEntry(key, value.toJson())),
        'appliedOperations': appliedOperations.toList()
      };

  factory PlayerState.fromJson(Map<String, dynamic> json) {
    if (json['schemaVersion'] != 1) throw const FormatException('未対応の保存データです。');
    return PlayerState(
        uid: json['uid'] as String,
        firstPlayedAt: json['firstPlayedAt'] == null
            ? null
            : DateTime.parse(json['firstPlayedAt'] as String),
        adventurerNumber: json['adventurerNumber'] as String?,
        totalDefeats: json['totalDefeats'] as int? ?? 0,
        focusAdventureSeconds: json['focusAdventureSeconds'] as int? ?? 0,
        onboardingComplete: json['onboardingComplete'] as bool,
        coins: json['coins'] as int,
        activeCharacterId: json['activeCharacterId'] as String?,
        monitoring: json['monitoring'] as bool? ?? false,
        clearedPlayableStages:
            Set<int>.from(json['clearedPlayableStages'] as List? ?? []),
        encounteredEnemyIds:
            Set<String>.from(json['encounteredEnemyIds'] as List? ?? []),
        targetPackages:
            List<String>.from(json['targetPackages'] as List? ?? []),
        characters: (json['characters'] as Map).map((key, value) => MapEntry(
            key as String,
            Character.fromJson(Map<String, dynamic>.from(value as Map)))),
        inventory: Map<String, int>.from(json['inventory'] as Map),
        sessions: (json['sessions'] as Map).map((key, value) => MapEntry(
            key as String,
            FocusSession.fromJson(Map<String, dynamic>.from(value as Map)))),
        appliedOperations: Set<String>.from(json['appliedOperations'] as List));
  }
}

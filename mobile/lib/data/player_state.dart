import '../features/character/domain/character.dart';
import '../features/focus/domain/focus_session.dart';
import '../features/adventure/domain/adventure.dart';

class PlayerState {
  PlayerState(
      {required this.uid,
      this.onboardingComplete = false,
      this.coins = 0,
      this.activeCharacterId,
      this.monitoring = false,
      this.targetPackages = const [],
      Set<String> clearedStages = const {},
      Set<int> clearedPlayableStages = const {},
      this.adventureRun,
      this.lastAdventure,
      Map<String, Character> characters = const {},
      Map<String, int> inventory = const {},
      Map<String, FocusSession> sessions = const {},
      Set<String> appliedOperations = const {}})
      : characters = Map.unmodifiable(characters),
        clearedStages = Set.unmodifiable(clearedStages),
        clearedPlayableStages = Set.unmodifiable(clearedPlayableStages),
        inventory = Map.unmodifiable(inventory),
        sessions = Map.unmodifiable(sessions),
        appliedOperations = Set.unmodifiable(appliedOperations);
  final String uid;
  final bool onboardingComplete;
  final int coins;
  final String? activeCharacterId;
  final bool monitoring;
  final List<String> targetPackages;
  final Map<String, Character> characters;
  final Map<String, int> inventory;
  final Map<String, FocusSession> sessions;
  final Set<String> appliedOperations;
  final Set<String> clearedStages;
  final Set<int> clearedPlayableStages;
  final AdventureRun? adventureRun;
  final AdventureRecord? lastAdventure;
  Character? get activeCharacter => characters[activeCharacterId];

  PlayerState copyWith(
          {bool? onboardingComplete,
          int? coins,
          String? activeCharacterId,
          bool? monitoring,
          List<String>? targetPackages,
          Map<String, Character>? characters,
          Map<String, int>? inventory,
          Map<String, FocusSession>? sessions,
          Set<String>? clearedStages,
          Set<int>? clearedPlayableStages,
          AdventureRun? adventureRun,
          bool clearAdventureRun = false,
          AdventureRecord? lastAdventure,
          Set<String>? appliedOperations}) =>
      PlayerState(
          uid: uid,
          onboardingComplete: onboardingComplete ?? this.onboardingComplete,
          coins: coins ?? this.coins,
          activeCharacterId: activeCharacterId ?? this.activeCharacterId,
          monitoring: monitoring ?? this.monitoring,
          targetPackages: targetPackages ?? this.targetPackages,
          characters: characters ?? this.characters,
          inventory: inventory ?? this.inventory,
          sessions: sessions ?? this.sessions,
          clearedStages: clearedStages ?? this.clearedStages,
          clearedPlayableStages:
              clearedPlayableStages ?? this.clearedPlayableStages,
          adventureRun:
              clearAdventureRun ? null : adventureRun ?? this.adventureRun,
          lastAdventure: lastAdventure ?? this.lastAdventure,
          appliedOperations: appliedOperations ?? this.appliedOperations);

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'uid': uid,
        'onboardingComplete': onboardingComplete,
        'coins': coins,
        'activeCharacterId': activeCharacterId,
        'monitoring': monitoring,
        'targetPackages': targetPackages,
        'clearedStages': clearedStages.toList(),
        'clearedPlayableStages': clearedPlayableStages.toList(),
        'adventureRun': adventureRun?.toJson(),
        'lastAdventure': lastAdventure?.toJson(),
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
        onboardingComplete: json['onboardingComplete'] as bool,
        coins: json['coins'] as int,
        activeCharacterId: json['activeCharacterId'] as String?,
        monitoring: json['monitoring'] as bool? ?? false,
        clearedStages: Set<String>.from(json['clearedStages'] as List? ?? []),
        clearedPlayableStages:
            Set<int>.from(json['clearedPlayableStages'] as List? ?? []),
        adventureRun: json['adventureRun'] == null
            ? null
            : AdventureRun.fromJson(
                Map<String, dynamic>.from(json['adventureRun'] as Map)),
        lastAdventure: json['lastAdventure'] == null
            ? null
            : AdventureRecord.fromJson(
                Map<String, dynamic>.from(json['lastAdventure'] as Map)),
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

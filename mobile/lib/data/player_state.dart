import '../features/character/domain/character.dart';
import '../features/focus/domain/focus_session.dart';

class PlayerState {
  PlayerState(
      {required this.uid,
      this.onboardingComplete = false,
      this.coins = 0,
      this.adventureProgress = 0,
      this.stage = 1,
      this.activeCharacterId,
      this.pendingBattle,
      this.monitoring = false,
      this.targetPackages = const [],
      this.gachaHistory = const [],
      this.battleHistory = const [],
      Map<String, Character> characters = const {},
      Map<String, int> inventory = const {},
      Map<String, FocusSession> sessions = const {},
      Set<String> appliedOperations = const {}})
      : characters = Map.unmodifiable(characters),
        inventory = Map.unmodifiable(inventory),
        sessions = Map.unmodifiable(sessions),
        appliedOperations = Set.unmodifiable(appliedOperations);
  final String uid;
  final bool onboardingComplete;
  final int coins;
  final int adventureProgress;
  final int stage;
  final String? activeCharacterId;
  final Map<String, dynamic>? pendingBattle;
  final bool monitoring;
  final List<String> targetPackages;
  final List<Map<String, dynamic>> gachaHistory;
  final List<Map<String, dynamic>> battleHistory;
  final Map<String, Character> characters;
  final Map<String, int> inventory;
  final Map<String, FocusSession> sessions;
  final Set<String> appliedOperations;
  Character? get activeCharacter => characters[activeCharacterId];

  PlayerState copyWith(
          {bool? onboardingComplete,
          int? coins,
          int? adventureProgress,
          int? stage,
          String? activeCharacterId,
          Map<String, dynamic>? pendingBattle,
          bool clearBattle = false,
          bool? monitoring,
          List<String>? targetPackages,
          List<Map<String, dynamic>>? gachaHistory,
          List<Map<String, dynamic>>? battleHistory,
          Map<String, Character>? characters,
          Map<String, int>? inventory,
          Map<String, FocusSession>? sessions,
          Set<String>? appliedOperations}) =>
      PlayerState(
          uid: uid,
          onboardingComplete: onboardingComplete ?? this.onboardingComplete,
          coins: coins ?? this.coins,
          adventureProgress: adventureProgress ?? this.adventureProgress,
          stage: stage ?? this.stage,
          activeCharacterId: activeCharacterId ?? this.activeCharacterId,
          pendingBattle:
              clearBattle ? null : pendingBattle ?? this.pendingBattle,
          monitoring: monitoring ?? this.monitoring,
          targetPackages: targetPackages ?? this.targetPackages,
          gachaHistory: gachaHistory ?? this.gachaHistory,
          battleHistory: battleHistory ?? this.battleHistory,
          characters: characters ?? this.characters,
          inventory: inventory ?? this.inventory,
          sessions: sessions ?? this.sessions,
          appliedOperations: appliedOperations ?? this.appliedOperations);

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'uid': uid,
        'onboardingComplete': onboardingComplete,
        'coins': coins,
        'adventureProgress': adventureProgress,
        'stage': stage,
        'activeCharacterId': activeCharacterId,
        'pendingBattle': pendingBattle,
        'monitoring': monitoring,
        'targetPackages': targetPackages,
        'gachaHistory': gachaHistory,
        'battleHistory': battleHistory,
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
        adventureProgress: json['adventureProgress'] as int,
        stage: json['stage'] as int,
        activeCharacterId: json['activeCharacterId'] as String?,
        pendingBattle: json['pendingBattle'] == null
            ? null
            : Map<String, dynamic>.from(json['pendingBattle'] as Map),
        monitoring: json['monitoring'] as bool? ?? false,
        targetPackages:
            List<String>.from(json['targetPackages'] as List? ?? []),
        gachaHistory: (json['gachaHistory'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        battleHistory: (json['battleHistory'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
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

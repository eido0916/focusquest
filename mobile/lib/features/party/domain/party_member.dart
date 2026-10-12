class PartyMember {
  const PartyMember(
      {required this.id,
      required this.name,
      required this.characterType,
      required this.appearance,
      required this.level,
      this.unlockedAreas = const [],
      this.ready = false,
      this.status = 'waiting'});
  final String id, name, characterType, appearance, status;
  final int level;
  final bool ready;
  final List<int> unlockedAreas;
  factory PartyMember.fromJson(Map<String, dynamic> json) => PartyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      characterType: json['characterType'] as String,
      appearance: json['appearance'] as String,
      level: json['level'] as int,
      unlockedAreas: List<int>.from(json['unlockedAreas'] as List? ?? []),
      ready: json['ready'] == true,
      status: json['status'] as String? ?? 'waiting');
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterType': characterType,
        'appearance': appearance,
        'level': level,
        'unlockedAreas': unlockedAreas,
        'ready': ready,
        'status': status
      };
}

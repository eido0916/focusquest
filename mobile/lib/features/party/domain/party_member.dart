class PartyMember {
  const PartyMember(
      {required this.id,
      required this.name,
      required this.characterType,
      required this.appearance,
      required this.level,
      this.ready = false,
      this.status = 'waiting'});
  final String id, name, characterType, appearance, status;
  final int level;
  final bool ready;
  factory PartyMember.fromJson(Map<String, dynamic> json) => PartyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      characterType: json['characterType'] as String,
      appearance: json['appearance'] as String,
      level: json['level'] as int,
      ready: json['ready'] == true,
      status: json['status'] as String? ?? 'waiting');
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'characterType': characterType,
        'appearance': appearance,
        'level': level,
        'ready': ready,
        'status': status
      };
}

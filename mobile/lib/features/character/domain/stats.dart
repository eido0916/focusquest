class Stats {
  const Stats(
      {this.hp = 100,
      this.attack = 15,
      this.defense = 5,
      this.speed = 10,
      this.criticalRate = 0.05});
  final int hp;
  final int attack;
  final int defense;
  final int speed;
  final double criticalRate;
  Stats add(Stats bonus) => Stats(
      hp: hp + bonus.hp,
      attack: attack + bonus.attack,
      defense: defense + bonus.defense,
      speed: speed + bonus.speed,
      criticalRate: (criticalRate + bonus.criticalRate).clamp(0.0, 1.0));
  Map<String, dynamic> toJson() => {
        'hp': hp,
        'attack': attack,
        'defense': defense,
        'speed': speed,
        'criticalRate': criticalRate
      };
  factory Stats.fromJson(Map<String, dynamic> json) => Stats(
      hp: json['hp'] as int,
      attack: json['attack'] as int,
      defense: json['defense'] as int,
      speed: json['speed'] as int,
      criticalRate: (json['criticalRate'] as num).toDouble());
}

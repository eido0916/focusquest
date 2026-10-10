enum ProjectileKind { arrow, bullet, fire, ice, shuriken }

class PlayableCharacter {
  const PlayableCharacter(this.id, this.role, this.female, this.health,
      this.power, this.speed, this.attackEvent, this.skillEvent, this.skillName,
      {this.ranged = false});
  final String id, role, attackEvent, skillEvent, skillName;
  final bool female, ranged;
  final int health, power, speed;
  String get name => '$role · ${female ? '女性' : '男性'}';
  double get attackSeconds => 100 / speed;
  double get skillSeconds => attackSeconds * 1.75;
  int get skillPower => power * 4;
  ProjectileKind? projectileFor(bool skill) => switch (role) {
        '弓使い' => ProjectileKind.arrow,
        'ガンナー' => ProjectileKind.bullet,
        '魔法使い' => skill ? ProjectileKind.ice : ProjectileKind.fire,
        '忍者' => skill ? null : ProjectileKind.shuriken,
        _ => null,
      };
}

class PlayableCharacters {
  static final all = List<PlayableCharacter>.unmodifiable([
    for (final female in [false, true]) ...[
      PlayableCharacter(
          'character_01${female ? '_female' : ''}',
          '剣士',
          female,
          160,
          28,
          100,
          female ? 'attack_active' : 'slash_active',
          female ? 'skill_release' : 'wave_release',
          '蓄力斬撃'),
      PlayableCharacter('character_02${female ? '_female' : ''}', '拳闘士', female,
          180, 24, 130, female ? 'punch_hit' : 'jab', 'kick_hit', '旋風蹴り'),
      PlayableCharacter(
          'character_03${female ? '_female' : ''}',
          '侍',
          female,
          150,
          38,
          85,
          female ? 'attack_active' : 'draw_cut_hit',
          female ? 'flurry_hit' : 'slash_1',
          '連続居合'),
      PlayableCharacter(
          'character_04${female ? '_female' : ''}',
          '重騎士',
          female,
          250,
          46,
          60,
          female ? 'attack_active' : 'downward_hit',
          female ? 'skill_release' : 'sweep_hit',
          '蓄力薙ぎ払い'),
      PlayableCharacter(
          'character_05${female ? '_female' : ''}',
          '忍者',
          female,
          120,
          20,
          170,
          female ? 'attack_active' : 'projectile_release',
          'dagger_hit',
          '瞬身突き',
          ranged: true),
      PlayableCharacter(
          'character_06${female ? '_female' : ''}',
          'アサシン',
          female,
          130,
          26,
          145,
          female ? 'attack_active' : 'thrust_active',
          female ? 'skill_release' : 'critical_impact',
          '蓄力クリティカル'),
      PlayableCharacter('character_07${female ? '_female' : ''}', '弓使い', female,
          140, 25, 125, 'arrow_release', 'arrow_release', '三連射',
          ranged: true),
      PlayableCharacter('character_08${female ? '_female' : ''}', '魔法使い',
          female, 110, 44, 80, 'fire_release', 'ice_release', '大氷結',
          ranged: true),
      PlayableCharacter('character_09${female ? '_female' : ''}', 'ガンナー',
          female, 135, 23, 150, 'bullet_release', 'bullet_release', '早撃ち',
          ranged: true),
      PlayableCharacter('character_10${female ? '_female' : ''}', '魔剣士', female,
          170, 36, 95, 'sword_hit', 'lightning_strike', '雷剣・落雷'),
    ]
  ]);
  static PlayableCharacter get defaultCharacter => all.first;
}

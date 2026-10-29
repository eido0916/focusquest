enum ProjectileKind {
  arrow,
  bullet,
  fire,
  ice,
  shuriken,
  wave,
  talisman,
  sickle,
  holyOrb,
  holySword,
  darkWave,
  lightning,
  spirits,
  curse,
  floor
}

class PlayableCharacter {
  const PlayableCharacter(this.id, this.role, this.female, this.health,
      this.power, this.speed, this.attackEvent, this.skillEvent, this.skillName,
      {this.ranged = false,
      this.effectType,
      this.level = 1,
      this.defense = 0,
      this.criticalRate = .2,
      this.attackTimeScale = 100});
  final String id, role, attackEvent, skillEvent, skillName;
  final bool female, ranged;
  final String? effectType;
  final int health, power, speed;
  final int level;
  final int defense;
  final double criticalRate;
  // FQ uses the character screen's speed units; standalone demos use 100-based units.
  final double attackTimeScale;
  String get name => '$role · ${female ? '女性' : '男性'}';
  double get attackSeconds => attackTimeScale / speed;
  double get skillSeconds => attackSeconds * 1.75;
  int get skillPower => power * 4;
  ProjectileKind? projectileFor(bool skill) => switch (role) {
        '弓使い' => ProjectileKind.arrow,
        'ガンナー' => ProjectileKind.bullet,
        '魔法使い' => skill ? ProjectileKind.ice : ProjectileKind.fire,
        '忍者' => skill ? null : ProjectileKind.shuriken,
        '剣士' => skill ? ProjectileKind.wave : null,
        '魔剣士' => skill ? ProjectileKind.lightning : null,
        '陰陽師' => skill ? ProjectileKind.spirits : ProjectileKind.talisman,
        '鎌使い' => skill ? ProjectileKind.sickle : null,
        '天使' => skill ? ProjectileKind.holySword : ProjectileKind.holyOrb,
        '悪魔' => skill ? ProjectileKind.curse : ProjectileKind.darkWave,
        'バーサーカー' => skill ? ProjectileKind.floor : null,
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
      PlayableCharacter('character_11${female ? '_female' : ''}', '陰陽師', female,
          130, 32, 90, 'holy_talisman_release', 'shikigami_attack', '五行封陣',
          ranged: true),
      PlayableCharacter('character_12${female ? '_female' : ''}', '鎌使い', female,
          155, 34, 105, 'scythe_hit', 'chain_scythe_throw', '冥月刈り'),
      PlayableCharacter('character_13${female ? '_female' : ''}', '天使', female,
          145, 30, 100, 'holy_orb_release', 'holy_swords_release', '聖光の翼',
          ranged: true),
      PlayableCharacter('character_14${female ? '_female' : ''}', '悪魔', female,
          145, 35, 100, 'dark_wave_release', 'curse_apply', '獄炎の波',
          ranged: true),
      PlayableCharacter('character_15${female ? '_female' : ''}', 'ドラゴンナイト',
          female, 210, 38, 100, 'spear_hit', 'dragon_flurry_hit', '竜炎突撃'),
      PlayableCharacter('character_16${female ? '_female' : ''}', 'バーサーカー',
          female, 230, 42, 90, 'punch_hit', 'floor_release', '狂戦裂破'),
    ]
  ]);
  static PlayableCharacter get defaultCharacter => all.first;
}

import '../features/character/domain/item.dart';
import '../features/character/domain/stats.dart';
import '../features/diagnosis/domain/diagnosis_service.dart';
import '../features/gacha/domain/gacha_service.dart';

class GameCatalog {
  static const questions = [
    DiagnosisQuestion('challenge', '新しいことにはすぐ挑戦したくなる', 0),
    DiagnosisQuestion('plan', '行動する前にじっくり計画を立てる', 0, reversed: true),
    DiagnosisQuestion('company', '誰かと協力すると力を発揮できる', 1),
    DiagnosisQuestion('alone', '一人で考える時間を大切にしている', 1, reversed: true),
  ];
  static const types = {
    0: PersonalityType(
        typeId: 'mage',
        name: '静かな探究者',
        description: '考える力で道を切りひらくタイプ。',
        job: '魔法使い',
        stats: Stats(hp: 85, attack: 22, defense: 4),
        assetKey: 'hero.mage',
        traits: ['探究心']),
    1: PersonalityType(
        typeId: 'ranger',
        name: '自由な冒険家',
        description: '好奇心を羅針盤に、一歩を踏み出すタイプ。',
        job: 'レンジャー',
        stats: Stats(hp: 90, attack: 17, speed: 15, criticalRate: 0.1),
        assetKey: 'hero.ranger',
        traits: ['好奇心']),
    2: PersonalityType(
        typeId: 'guardian',
        name: '頼れる守り手',
        description: '仲間を支えながら着実に進むタイプ。',
        job: '守護者',
        stats: Stats(hp: 130, attack: 12, defense: 10),
        assetKey: 'hero.guardian',
        traits: ['忍耐']),
    3: PersonalityType(
        typeId: 'warrior',
        name: '勇敢な先導者',
        description: '周りを勇気づけ、新しい道に挑むタイプ。',
        job: '戦士',
        stats: Stats(hp: 110, attack: 19, defense: 6),
        assetKey: 'hero.warrior',
        traits: ['勇気']),
  };
  static const equipment = {
    'wooden_sword': Equipment(
        item: Item(
            id: 'wooden_sword',
            name: '木の剣',
            rarity: 'N',
            assetKey: 'item.wooden_sword'),
        slot: EquipmentSlot.weapon,
        bonus: Stats(hp: 0, attack: 3, defense: 0, speed: 0, criticalRate: 0)),
    'cloth_armor': Equipment(
        item: Item(
            id: 'cloth_armor',
            name: '旅人の服',
            rarity: 'R',
            assetKey: 'item.cloth_armor'),
        slot: EquipmentSlot.armor,
        bonus: Stats(hp: 15, attack: 0, defense: 3, speed: 0, criticalRate: 0)),
    'silver_ring': Equipment(
        item: Item(
            id: 'silver_ring',
            name: '銀の指輪',
            rarity: 'SR',
            assetKey: 'item.silver_ring'),
        slot: EquipmentSlot.accessory,
        bonus:
            Stats(hp: 10, attack: 2, defense: 2, speed: 2, criticalRate: 0.05)),
  };
  static const gachaPool = [
    GachaPrize('wooden_sword', '木の剣', 'N', GachaPrizeKind.equipment),
    GachaPrize('cloth_armor', '旅人の服', 'R', GachaPrizeKind.equipment),
    GachaPrize('ranger', 'レンジャー', 'R', GachaPrizeKind.character),
    GachaPrize('silver_ring', '銀の指輪', 'SR', GachaPrizeKind.equipment),
    GachaPrize('mage', '星読みの魔法使い', 'SSR', GachaPrizeKind.character),
  ];
}

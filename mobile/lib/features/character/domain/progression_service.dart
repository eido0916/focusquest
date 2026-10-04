import 'character.dart';
import 'item.dart';
import 'stats.dart';

class ProgressionService {
  Character addExp(Character character, int amount) {
    if (amount < 0) throw ArgumentError.value(amount, 'amount');
    var next = character.copyWith(currentExp: character.currentExp + amount);
    while (next.currentExp >= next.requiredExp) {
      next = next.copyWith(
          currentExp: next.currentExp - next.requiredExp,
          level: next.level + 1);
    }
    return next;
  }

  Stats stats(Character character, Map<String, Equipment> catalog) {
    final growth = character.level - 1;
    var result = character.baseStats.add(Stats(
        hp: growth * 12,
        attack: growth * 3,
        defense: growth * 2,
        speed: growth,
        criticalRate: 0));
    for (final entry in character.equippedItems.entries) {
      final equipment = catalog[entry.value];
      if (equipment != null && equipment.slot.name == entry.key) {
        result = result.add(equipment.bonus);
      }
    }
    return result;
  }

  Character equip(
      Character character, Equipment equipment, Map<String, int> inventory) {
    if ((inventory[equipment.item.id] ?? 0) < 1) {
      throw StateError('所持していない装備です。');
    }
    return character.copyWith(equippedItems: {
      ...character.equippedItems,
      equipment.slot.name: equipment.item.id
    });
  }
}

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

  // Keep the legacy catalog argument for callers and old saves. Equipment no
  // longer affects either displayed stats or combat stats.
  Stats stats(Character character, Map<String, Equipment> catalog) {
    final growth = character.level - 1;
    return character.baseStats.add(Stats(
        hp: growth * 12,
        attack: growth * 3,
        defense: growth * 2,
        speed: growth,
        criticalRate: 0));
  }

  Character equip(
      Character character, Equipment equipment, Map<String, int> inventory) {
    throw StateError('装備機能は廃止されました。');
  }
}

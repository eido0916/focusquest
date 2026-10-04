import 'stats.dart';

enum EquipmentSlot { weapon, armor, accessory }

class Item {
  const Item(
      {required this.id,
      required this.name,
      required this.rarity,
      required this.assetKey});
  final String id;
  final String name;
  final String rarity;
  final String assetKey;
}

class Equipment {
  const Equipment(
      {required this.item, required this.slot, required this.bonus});
  final Item item;
  final EquipmentSlot slot;
  final Stats bonus;
}

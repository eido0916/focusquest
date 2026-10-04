import 'dart:math';
import '../../../core/config/game_balance.dart';

enum GachaPrizeKind { character, equipment }

class GachaPrize {
  const GachaPrize(this.id, this.name, this.rarity, this.kind);
  final String id;
  final String name;
  final String rarity;
  final GachaPrizeKind kind;
}

class GachaResult {
  const GachaResult(this.cost, this.prizes);
  final int cost;
  final List<GachaPrize> prizes;
}

class GachaService {
  GachaService(
      {required this.random,
      required this.pool,
      this.weights = GameBalance.rarityWeights}) {
    if (weights.isEmpty || weights.values.any((w) => w <= 0)) {
      throw ArgumentError('排出率は正の整数です。');
    }
    for (final rarity in weights.keys) {
      if (!pool.any((p) => p.rarity == rarity)) {
        throw ArgumentError('$rarity の排出対象がありません。');
      }
    }
  }
  final Random random;
  final List<GachaPrize> pool;
  final Map<String, int> weights;
  GachaResult draw({required int count, required int balance}) {
    if (count != 1 && count != 10) throw ArgumentError('1回または10回を選択してください。');
    final cost = count * GameBalance.summonCost;
    if (balance < cost) throw StateError('ポイントが足りません。集中して集めましょう。');
    final total = weights.values.reduce((a, b) => a + b);
    final prizes = <GachaPrize>[];
    for (var i = 0; i < count; i++) {
      var ticket = random.nextInt(total);
      for (final entry in weights.entries) {
        if (ticket < entry.value) {
          final choices = pool.where((p) => p.rarity == entry.key).toList();
          prizes.add(choices[random.nextInt(choices.length)]);
          break;
        }
        ticket -= entry.value;
      }
    }
    return GachaResult(cost, List.unmodifiable(prizes));
  }
}

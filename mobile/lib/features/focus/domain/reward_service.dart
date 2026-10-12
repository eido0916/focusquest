import 'dart:math';
import '../../../core/config/game_balance.dart';
import 'focus_session.dart';

class Reward {
  const Reward(
      {this.exp = 0,
      this.coins = 0,
      this.defeatedEnemies = 0,
      this.items = const []});
  final int exp;
  final int coins;
  final int defeatedEnemies;
  final List<String> items;
}

class RewardService {
  RewardService(this.random);
  final Random random;
  Reward focus(FocusSession session) {
    if (session.status != FocusStatus.succeeded) return const Reward();
    final minutes = session.durationMinutes;
    return Reward(exp: minutes * GameBalance.expPerMinute);
  }

  Reward battle(int defeated) {
    if (defeated < 0) throw ArgumentError.value(defeated);
    return Reward(
        exp: defeated * 20, coins: defeated * 10, defeatedEnemies: defeated);
  }
}

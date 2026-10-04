import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/assets/asset_catalog.dart';
import 'package:focusquest/core/config/game_balance.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/domain/progression_service.dart';
import 'package:focusquest/features/character/domain/stats.dart';
import 'package:focusquest/features/diagnosis/domain/diagnosis_service.dart';
import 'package:focusquest/features/focus/domain/focus_service.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/domain/reward_service.dart';
import 'package:focusquest/features/focus/domain/streak_service.dart';
import 'package:focusquest/features/gacha/domain/gacha_service.dart';
import 'package:focusquest/game/battle/battle_engine.dart';

class FixedRandom implements Random {
  FixedRandom(this.ticket, [this.fraction = 0.5]);
  final int ticket;
  final double fraction;
  @override
  bool nextBool() => false;
  @override
  double nextDouble() => fraction;
  @override
  int nextInt(int max) => ticket % max;
}

void main() {
  final hero = Character(
      id: 'hero',
      name: '勇者',
      characterType: 'warrior',
      baseStats: const Stats());
  final start = DateTime(2026, 10, 1, 9);
  final focus = FocusService();
  group('EXP / equipment', () {
    test('EXP boundaries and multiple levels retain remainder', () {
      final service = ProgressionService();
      expect(service.addExp(hero, 99).level, 1);
      expect(service.addExp(hero, 100).currentExp, 0);
      final grown = service.addExp(hero, 300);
      expect(grown.level, 3);
      expect(grown.currentExp, 50);
      expect(grown.requiredExp, 200);
      expect(GameBalance.requiredExp(4), greaterThan(grown.requiredExp));
      expect(() => service.addExp(hero, -1), throwsArgumentError);
    });
    test('owned equipment applies once and survives serialization', () {
      final service = ProgressionService();
      final sword = GameCatalog.equipment['wooden_sword']!;
      expect(() => service.equip(hero, sword, {}), throwsStateError);
      final equipped = service.equip(hero, sword, {'wooden_sword': 1});
      final restored = Character.fromJson(equipped.toJson());
      expect(service.stats(restored, GameCatalog.equipment).attack, 18);
      expect(
          service
              .stats(service.equip(restored, sword, {'wooden_sword': 1}),
                  GameCatalog.equipment)
              .attack,
          18);
      expect(hero.equippedItems, isEmpty);
    });
  });
  group('Focus', () {
    test('timer ends at exact deadline, including background gap', () {
      final session = focus.start(id: 's', now: start, minutes: 30);
      expect(focus.evaluate(session, start.add(const Duration(minutes: 29))),
          FocusStatus.active);
      expect(focus.evaluate(session, session.endsAt), FocusStatus.succeeded);
      expect(focus.evaluate(session, start.add(const Duration(hours: 2))),
          FocusStatus.succeeded);
      expect(session.remaining(start.add(const Duration(hours: 2))),
          Duration.zero);
      expect(
          focus.evaluate(session, start.subtract(const Duration(seconds: 1))),
          FocusStatus.failed);
    });
    test('cancelled sessions never become successful', () {
      final session = focus
          .start(id: 's', now: start, minutes: 30)
          .finish(FocusStatus.cancelled);
      expect(focus.evaluate(session, session.endsAt), FocusStatus.cancelled);
      expect(RewardService(Random(1)).focus(session).exp, 0);
    });
    test('monitored focus needs evidence and fails for target use', () {
      final session = focus.start(
          id: 's',
          now: start,
          minutes: 30,
          monitored: true,
          targetPackages: ['example.app']);
      expect(focus.evaluate(session, session.endsAt), FocusStatus.failed);
      expect(
          focus.evaluate(session, session.endsAt,
              usageEvidenceAvailable: true, targetUsed: true),
          FocusStatus.failed);
      expect(
          focus.evaluate(session, session.endsAt, usageEvidenceAvailable: true),
          FocusStatus.succeeded);
      expect(FocusSession.fromJson(session.toJson()).verification,
          FocusVerification.usageStats);
    });
    test('duration and target validation', () {
      for (final minutes in [0, -1, 181]) {
        expect(() => focus.start(id: 's', now: start, minutes: minutes),
            throwsArgumentError);
      }
      expect(
          () => focus.start(id: 's', now: start, minutes: 30, monitored: true),
          throwsArgumentError);
    });
    test('30 minutes awards 300 EXP, 100 coins and 30 progress', () {
      final session = focus
          .start(id: 's', now: start, minutes: 30)
          .finish(FocusStatus.succeeded);
      final reward = RewardService(FixedRandom(0, 0)).focus(session);
      expect(
          [reward.exp, reward.coins, reward.adventureProgress], [300, 100, 30]);
      expect(reward.items, ['wooden_sword']);
    });
  });
  group('Streaks', () {
    FocusSession session(String id, int month, int day,
            {FocusStatus status = FocusStatus.succeeded}) =>
        FocusSession(
            id: id,
            startedAt: DateTime(2026, month, day, 9),
            durationMinutes: 30,
            status: status);
    test('calendar month boundary, duplicate ids, repeated same day', () {
      final sessions = [
        session('a', 9, 30),
        session('b', 10, 1),
        session('b', 10, 1),
        session('c', 10, 1)
      ];
      final summary =
          StreakService().summarize(sessions, DateTime(2026, 10, 1, 12));
      expect(summary.streak, 2);
      expect(summary.longestStreak, 2);
      expect(summary.todayMinutes, 60);
      expect(summary.totalMinutes, 90);
    });
    test('yesterday carries streak; missed day breaks it; failures ignored',
        () {
      final sessions = [
        session('a', 9, 30),
        session('b', 10, 1),
        session('c', 10, 2, status: FocusStatus.failed)
      ];
      expect(
          StreakService().summarize(sessions, DateTime(2026, 10, 2)).streak, 2);
      final summary =
          StreakService().summarize(sessions, DateTime(2026, 10, 3));
      expect(summary.streak, 0);
      expect(summary.longestStreak, 2);
    });
  });
  group('Gacha', () {
    test('all cumulative probability boundaries', () {
      for (final entry in {
        0: 'N',
        59: 'N',
        60: 'R',
        89: 'R',
        90: 'SR',
        97: 'SR',
        98: 'SSR',
        99: 'SSR'
      }.entries) {
        final result = GachaService(
                random: FixedRandom(entry.key), pool: GameCatalog.gachaPool)
            .draw(count: 1, balance: 100);
        expect(result.prizes.single.rarity, entry.value);
      }
    });
    test('10 draws charge 1000; rejects insufficient funds and invalid count',
        () {
      final service =
          GachaService(random: Random(42), pool: GameCatalog.gachaPool);
      final result = service.draw(count: 10, balance: 1000);
      expect(result.prizes.length, 10);
      expect(result.cost, 1000);
      expect(() => service.draw(count: 10, balance: 999), throwsStateError);
      expect(() => service.draw(count: 2, balance: 1000), throwsArgumentError);
      expect(
          () => GachaService(random: Random(), pool: []), throwsArgumentError);
    });
  });
  group('Battle', () {
    test('minimum damage and critical defense arithmetic', () {
      expect(
          BattleEngine.damage(
              const Stats(attack: 5), const Stats(defense: 100)),
          1);
      expect(
          BattleEngine.damage(const Stats(attack: 20), const Stats(defense: 5),
              critical: true),
          25);
    });
    test('victory stops attacks and dead enemy cannot retaliate', () {
      final engine = BattleEngine(
          player: Fighter('hero', const Stats(attack: 100, speed: 12)),
          enemy: Fighter('slime', const Stats(hp: 10, speed: 12)),
          random: FixedRandom(0));
      for (var i = 0; i < 4; i++) {
        engine.update(0.25);
      }
      expect(engine.outcome, BattleOutcome.victory);
      expect(engine.enemy.pose, ActorPose.death);
      expect(engine.player.hp, 100);
      expect(engine.update(1), isEmpty);
    });
    test('faster enemy can defeat hero; no negative HP', () {
      final engine = BattleEngine(
          player: Fighter('hero', const Stats(hp: 1, speed: 1)),
          enemy: Fighter('slime', const Stats(attack: 100, speed: 48)),
          random: FixedRandom(0));
      engine.update(0.25);
      expect(engine.outcome, BattleOutcome.defeat);
      expect(engine.player.hp, 0);
    });
  });
  group('Diagnosis', () {
    const diagnosis = DiagnosisService(
        questions: GameCatalog.questions, types: GameCatalog.types);
    test('answers yield four configured types and reverse scoring', () {
      for (var mask = 0; mask < 4; mask++) {
        final answers = {
          'challenge': (mask & 1) != 0 ? 5 : 1,
          'plan': 3,
          'company': (mask & 2) != 0 ? 5 : 1,
          'alone': 3
        };
        expect(diagnosis.evaluate(answers).typeId,
            GameCatalog.types[mask]!.typeId);
      }
      expect(
          diagnosis.evaluate(
              {'challenge': 3, 'plan': 1, 'company': 3, 'alone': 1}).typeId,
          'warrior');
      expect(() => diagnosis.evaluate({}), throwsArgumentError);
    });
  });
}

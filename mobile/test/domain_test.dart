import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
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
    test('30 minutes awards only 300 EXP', () {
      final session = focus
          .start(id: 's', now: start, minutes: 30)
          .finish(FocusStatus.succeeded);
      final reward = RewardService(FixedRandom(0, 0)).focus(session);
      expect([reward.exp, reward.coins], [300, 0]);
      expect(reward.items, isEmpty);
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
  group('Diagnosis', () {
    const diagnosis = DiagnosisService(
        questions: GameCatalog.questions, types: GameCatalog.types);
    test('all 1024 answer patterns resolve to all 16 jobs', () {
      final seen = <String>{};
      for (var pattern = 0; pattern < 1024; pattern++) {
        final answers = {
          for (var i = 0; i < 10; i++)
            'q${i + 1}': pattern & (1 << i) == 0 ? 1 : 2
        };
        seen.add(diagnosis.evaluate(answers).typeId);
      }
      expect(seen, GameCatalog.types.values.map((t) => t.typeId).toSet());
      expect(seen.length, 16);
      expect(
          diagnosis
              .evaluate({for (final q in GameCatalog.questions) q.id: 1}).job,
          '剣士');
      expect(
          diagnosis
              .evaluate({for (final q in GameCatalog.questions) q.id: 2}).job,
          '魔法使い');
      expect(() => diagnosis.evaluate({}), throwsArgumentError);
      expect(
          () => diagnosis
              .evaluate({for (final q in GameCatalog.questions) q.id: 3}),
          throwsArgumentError);
    });
    test('Q9 and Q10 break conflicting pairs', () {
      final answers = {for (final q in GameCatalog.questions) q.id: 1};
      answers['q9'] = 2;
      answers['q10'] = 2;
      expect(diagnosis.evaluate(answers).job, 'ドラゴンナイト');
    });
  });
}

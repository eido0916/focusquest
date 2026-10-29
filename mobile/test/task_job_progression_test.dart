import 'package:focusquest/features/focus/data/task_ai_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/focus/domain/focus_task.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/domain/focus_ledger.dart';
import 'package:focusquest/features/focus/domain/reward_service.dart';
import 'package:focusquest/features/focus/presentation/focus_task_dialog.dart';
import 'package:focusquest/features/character/domain/job_progression.dart';
import 'package:focusquest/features/character/presentation/job_change_page.dart';
import 'support/memory_repository.dart';

void main() {
  late MemoryRepository repo;
  late GameController controller;
  var now = DateTime(2026, 10, 24, 10);
  setUp(() async {
    repo = MemoryRepository();
    now = DateTime(2026, 10, 24, 10);
    controller = GameController(repo, clock: () => now);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!,
        name: 'テスト', appearance: 'female');
  });
  tearDown(() => controller.dispose());
  FocusTask study() =>
      FocusTask(title: '英語の勉強', allocation: {'knowledge': 7, 'creativity': 3});

  test('successful task survives restart and rewards exactly once', () async {
    await controller.startFocus(60, task: study());
    final active = controller.activeFocus!;
    expect(active.task!.title, '英語の勉強');
    repo.state = PlayerState.fromJson(repo.state.toJson());
    await controller.load();
    now = now.add(const Duration(minutes: 60));
    await controller.finishFocus();
    final hero = controller.state!.activeCharacter!;
    expect(hero.trainingPoints, {'knowledge': 420, 'creativity': 180});
    expect(JobProgression.canChange(hero, 'mage'), isTrue);
    final retried = FocusLedger().settle(controller.state!, active.id,
        FocusStatus.succeeded, const Reward(exp: 999, coins: 0, items: []));
    expect(retried.toJson(), controller.state!.toJson());
    await controller.changeJob('mage');
    expect(controller.state!.activeCharacter!.appearance, 'female');
    expect(controller.state!.activeCharacter!.level, hero.level);
    expect(controller.state!.activeCharacter!.currentExp, hero.currentExp);
    expect(controller.state!.activeCharacter!.baseStats.toJson(),
        GameCatalog.types[0]!.stats.toJson());
    expect(
        controller.state!.activeCharacter!.trainingPoints, hero.trainingPoints);
    repo.state = PlayerState.fromJson(repo.state.toJson());
    await controller.load();
    await controller.changeJob('warrior');
    expect(controller.state!.activeCharacter!.characterType, 'warrior');
    await controller.changeJob('mage');
    expect(controller.state!.activeCharacter!.characterType, 'mage');
  });

  test('cancel and failure never grant points', () async {
    for (final status in [FocusStatus.cancelled, FocusStatus.failed]) {
      final session = FocusSession(
          id: status.name, startedAt: now, durationMinutes: 60, task: study());
      final begun = FocusLedger().begin(controller.state!, session);
      final settled = FocusLedger().settle(begun, session.id, status,
          const Reward(exp: 600, coins: 0, items: []));
      expect(settled.activeCharacter!.trainingPoints, isEmpty);
    }
  });

  test('requirements are inclusive and require every field', () {
    final hero = controller.state!.activeCharacter!;
    expect(
        JobProgression.canChange(
            hero.copyWith(
                trainingPoints: {'knowledge': 300, 'creativity': 149}),
            'mage'),
        isFalse);
    expect(
        JobProgression.canChange(
            hero.copyWith(
                trainingPoints: {'knowledge': 300, 'creativity': 150}),
            'mage'),
        isTrue);
    expect(JobProgression.requirements.keys.toSet(),
        GameCatalog.types.values.map((e) => e.typeId).toSet());
  });

  test('old saves load and task validation rejects invalid input', () {
    final old = controller.state!.toJson();
    for (final hero in (old['characters'] as Map).values) {
      (hero as Map).remove('trainingPoints');
      hero.remove('unlockedJobs');
    }
    expect(PlayerState.fromJson(old).activeCharacter!.trainingPoints, isEmpty);
    expect(() => FocusTask(title: ' ', allocation: {'knowledge': 10}),
        throwsArgumentError);
    expect(() => FocusTask(title: 'a', allocation: {'unknown': 10}),
        throwsArgumentError);
    expect(() => FocusTask(title: 'a', allocation: {'knowledge': 9}),
        throwsArgumentError);
  });

  test(
      'job changes reject locked jobs, active focus, adventure and failed saves',
      () async {
    await expectLater(controller.changeJob('mage'), throwsStateError);
    await repo.transact(
        GameController.uid,
        (s) => s.copyWith(characters: {
              ...s.characters,
              s.activeCharacterId!: s.activeCharacter!.copyWith(
                  trainingPoints: {'knowledge': 300, 'creativity': 150})
            }));
    await controller.load();
    await controller.startFocus(1, task: study());
    await expectLater(controller.changeJob('mage'), throwsStateError);
    await controller.finishFocus(cancel: true);
    await controller.beginPlayableAdventure();
    await expectLater(controller.changeJob('mage'), throwsStateError);
    controller.endPlayableAdventure();
    repo.fail = true;
    await expectLater(controller.changeJob('mage'), throwsStateError);
    expect(controller.state!.activeCharacter!.characterType, 'warrior');
  });

  testWidgets('task editor validates and previews points on small screen',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    FocusTask? result;
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                body: TextButton(
                    onPressed: () async {
                      result = await chooseFocusTask(context,
                          minutes: 30, ai: _TestAi());
                    },
                    child: const Text('設定'))))));
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AIで配分を決める'));
    await tester.pumpAndSettle();
    expect(find.text('タスク名は1〜80文字で入力してください。'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '読書');
    await tester.pump();
    await tester.tap(find.text('AIで配分を決める'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.add), findsNothing);
    expect(find.text('AIの判定理由：読書で知識を増やし、継続して読む習慣を育てます。'), findsOneWidget);
    await tester.tap(find.text('このタスクに設定'));
    await tester.pumpAndSettle();
    expect(result!.title, '読書');
    expect(result!.gains(30), {'knowledge': 150, 'discipline': 150});
    expect(tester.takeException(), isNull);
  });

  testWidgets('job page displays growth and locked jobs without overflow',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester
        .pumpWidget(MaterialApp(home: JobChangePage(controller: controller)));
    await tester.pumpAndSettle();
    expect(find.text('知識  0pt'), findsOneWidget);
    expect(find.text('条件未達成'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}

class _TestAi extends TaskAiService {
  @override
  Future<FocusTask> assess(String input) async {
    if (input.trim().isEmpty) {
      throw const TaskAiException('タスク名は1〜80文字で入力してください。');
    }
    return FocusTask(
        title: input,
        allocation: {'knowledge': 5, 'discipline': 5},
        allocationSource: 'openai',
        rubricVersion: 1,
        model: 'test-model',
        reason: '読書で知識を増やし、継続して読む習慣を育てます。');
  }
}

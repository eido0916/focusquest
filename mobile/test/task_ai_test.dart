import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/focus/data/task_ai_service.dart';
import 'package:focusquest/features/focus/domain/focus_task.dart';
import 'package:focusquest/features/focus/presentation/focus_task_dialog.dart';

Map<String, int> allocation() => {
      'knowledge': 6,
      'creativity': 0,
      'discipline': 2,
      'vitality': 0,
      'insight': 2,
      'empathy': 0
    };
void main() {
  testWidgets(
      'editing task invalidates AI result; retries preserve entered text',
      (tester) async {
    final ai = _ControlledAi();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => chooseFocusTask(context, ai: ai),
                child: const Text('開く')))));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '英語の読書');
    await tester.tap(find.text('AIで配分を決める'));
    await tester.pumpAndSettle();
    expect(find.text('接続エラー'), findsOneWidget);
    expect(find.text('このタスクに設定'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '英語の読書');
    ai.fail = false;
    await tester.tap(find.text('AI判定を再試行'));
    await tester.pumpAndSettle();
    expect(find.text('このタスクに設定'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '筋トレ');
    await tester.pumpAndSettle();
    expect(find.text('このタスクに設定'), findsNothing);
    expect(find.text('AIで配分を決める'), findsOneWidget);
    expect(ai.calls, 2);
  });

  testWidgets('late AI response after closing dialog is harmless',
      (tester) async {
    final ai = _PendingAi();
    await tester.pumpWidget(MaterialApp(
        home: Builder(
            builder: (context) => TextButton(
                onPressed: () => chooseFocusTask(context, ai: ai),
                child: const Text('開く')))));
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '読書');
    await tester.tap(find.text('AIで配分を決める'));
    await tester.pump();
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    ai.pending.complete(FocusTask(
        title: '読書',
        allocation: allocation(),
        allocationSource: 'openai',
        reason: '読書の判定',
        model: 'test',
        rubricVersion: 1));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}

class _ControlledAi extends TaskAiService {
  bool fail = true;
  int calls = 0;
  @override
  Future<FocusTask> assess(String title) async {
    calls++;
    if (fail) throw const TaskAiException('接続エラー');
    return FocusTask(
        title: title,
        allocation: allocation(),
        allocationSource: 'openai',
        reason: '読書の判定',
        model: 'test',
        rubricVersion: 1);
  }
}

class _PendingAi extends TaskAiService {
  final pending = Completer<FocusTask>();
  @override
  Future<FocusTask> assess(String title) => pending.future;
}

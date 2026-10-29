import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'support/memory_repository.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/auth/domain/auth_repository.dart';
import 'package:focusquest/features/auth/presentation/auth_screen.dart';
import 'package:focusquest/features/diagnosis/presentation/diagnosis_screen.dart';
import 'package:focusquest/features/diagnosis/presentation/sanctuary_widgets.dart';

class TestAuth implements AuthRepository {
  int requests = 0;
  bool fail = false;
  @override
  Stream<AuthUser?> get authStateChanges => const Stream.empty();
  @override
  Future<void> signIn(String email, String password) async {
    requests++;
    if (fail) throw StateError('offline');
  }

  @override
  Future<void> register(String email, String password) =>
      signIn(email, password);
  @override
  Future<void> sendPasswordReset(String email) async {}
  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('local first launch opens onboarding without Firebase or login',
      (tester) async {
    final controller = GameController(MemoryRepository());
    await controller.load();
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    expect(find.text('老王'), findsOneWidget);
    expect(find.byKey(const Key('magic-stone')), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
  testWidgets('login validates fields, handles errors and allows retry',
      (tester) async {
    final auth = TestAuth()..fail = true;
    await tester.pumpWidget(
        MaterialApp(theme: AppTheme.dark, home: AuthScreen(repository: auth)));
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pump();
    expect(auth.requests, 0);
    await tester.enterText(
        find.byType(TextFormField).at(0), 'player@example.com');
    await tester.enterText(find.byType(TextFormField).at(1), 'test-password');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();
    expect(auth.requests, 1);
    expect(find.text('接続状況と入力内容を確認し、もう一度お試しください。'), findsOneWidget);
    auth.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();
    expect(auth.requests, 2);
  });
  testWidgets('identity, ten questions, review, result and save retry',
      (tester) async {
    String? savedName;
    String? savedAppearance;
    String? savedType;
    var fail = true;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: DiagnosisScreen(onComplete: (type, name, appearance) async {
          if (fail) throw StateError('disk full');
          savedType = type.typeId;
          savedName = name;
          savedAppearance = appearance;
        })));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pumpAndSettle();
    final start = find.text('石の問いに答える');
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    expect(find.text('名前を入力してください。'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('adventurer-name')), '  アオイ  ');
    await tester.ensureVisible(find.byKey(const Key('appearance-female')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('appearance-female')));
    await tester.ensureVisible(start);
    await tester.pumpAndSettle();
    await tester.tap(start);
    await tester.pumpAndSettle();
    for (var i = 1; i <= 10; i++) {
      final next = find.text(i < 10 ? 'この答えで進む' : '診断結果を見る');
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      expect(
          tester
              .widget<TextButton>(
                  find.ancestor(of: next, matching: find.byType(TextButton)))
              .onPressed,
          isNull);
      final option = find.byKey(Key('q$i-1'));
      await tester.ensureVisible(option);
      await tester.pumpAndSettle();
      await tester.tap(option);
      await tester.pump();
      await tester.ensureVisible(next);
      await tester.pumpAndSettle();
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(savedType, isNull);
    expect(find.text('剣士'), findsOneWidget);
    expect(find.text('迷う前に、一歩踏み出す'), findsOneWidget);
    await tester.ensureVisible(find.text('答えを見直す'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('答えを見直す'));
    await tester.pumpAndSettle();
    expect(
        tester.widget<SanctuaryChoice>(find.byKey(const Key('q10-1'))).selected,
        isTrue);
    final result = find.text('診断結果を見る');
    await tester.ensureVisible(result);
    await tester.pumpAndSettle();
    await tester.tap(result);
    await tester.pumpAndSettle();
    final begin = find.text('▶  冒険に進む');
    await tester.ensureVisible(begin);
    await tester.pumpAndSettle();
    await tester.tap(begin);
    await tester.pumpAndSettle();
    expect(find.text('冒険の記録を保存できませんでした。もう一度お試しください。'), findsOneWidget);
    expect(savedType, isNull);
    fail = false;
    await tester.ensureVisible(begin);
    await tester.pumpAndSettle();
    await tester.tap(begin);
    await tester.pumpAndSettle();
    expect(savedType, 'warrior');
    expect(savedName, 'アオイ');
    expect(savedAppearance, 'female');
    expect(tester.takeException(), isNull);
  });
}

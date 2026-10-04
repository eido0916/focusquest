import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'support/memory_repository.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/auth/domain/auth_repository.dart';
import 'package:focusquest/features/auth/presentation/auth_screen.dart';
import 'package:focusquest/features/diagnosis/presentation/diagnosis_screen.dart';

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
    expect(find.text('集中を、あなたの力に。'), findsOneWidget);
    expect(tester.takeException(), isNull);
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
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();
    expect(auth.requests, 1);
    expect(find.text('接続状況と入力内容を確認し、もう一度お試しください。'), findsOneWidget);
    auth.fail = false;
    await tester.tap(find.widgetWithText(FilledButton, 'ログイン'));
    await tester.pumpAndSettle();
    expect(auth.requests, 2);
  });
  testWidgets(
      'diagnosis requires all answers and finishes tutorial before saving',
      (tester) async {
    String? savedType;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: DiagnosisScreen(onComplete: (type) async {
          savedType = type.typeId;
        })));
    await tester.tap(find.text('性格診断をはじめる'));
    await tester.pumpAndSettle();
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('どちらでもない'));
      await tester.pump();
      final next = find.text(i == 3 ? '診断結果を見る' : '次へ');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pumpAndSettle();
    }
    expect(savedType, isNull);
    expect(find.text('静かな探究者'), findsOneWidget);
    await tester.tap(find.text('この仲間と進む'));
    await tester.pumpAndSettle();
    expect(savedType, isNull);
    await tester.tap(find.text('冒険をはじめる'));
    await tester.pumpAndSettle();
    expect(savedType, 'mage');
  });
}

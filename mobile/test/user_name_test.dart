import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/local_player_repository.dart';
import 'package:focusquest/features/settings/settings_screen.dart';
import 'support/memory_repository.dart';

void main() {
  test('rename persists across restart and preserves progress', () async {
    final directory = await Directory.systemTemp.createTemp('focusquest-name-');
    addTearDown(() => directory.delete(recursive: true));
    final controller = GameController(LocalPlayerRepository(directory));
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!, name: 'アオイ');
    await controller.recordPlayableClear(1);
    await controller.repository.transact(
        GameController.uid,
        (s) => s.copyWith(characters: {
              ...s.characters,
              s.activeCharacterId!: s.activeCharacter!.copyWith(
                  level: 7, currentExp: 12, selectedTitle: 'test-title'),
            }));
    await controller.load();
    final before = controller.state!.toJson();
    await controller.changeUserName('  ヒカリ  ');
    final restarted = GameController(LocalPlayerRepository(directory));
    addTearDown(restarted.dispose);
    await restarted.load();
    final after = restarted.state!.toJson();
    final characters = before['characters'] as Map;
    (characters[controller.state!.activeCharacterId] as Map)['name'] = 'ヒカリ';
    expect(after, before);
    for (final invalid in ['   ', List.filled(17, 'あ').join()]) {
      await expectLater(
          controller.changeUserName(invalid), throwsArgumentError);
    }
    expect(controller.state!.activeCharacter!.name, 'ヒカリ');
    await controller.changeUserName(List.filled(16, '👩‍🚀').join());
    expect(controller.state!.activeCharacter!.name.characters.length, 16);
  });

  testWidgets('settings rename validates, cancels, and retries failed saves',
      (tester) async {
    final repository = MemoryRepository();
    final controller = GameController(repository);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!, name: 'アオイ');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: AnimatedBuilder(
                animation: controller,
                builder: (_, __) => SettingsScreen(controller: controller)))));
    await tester.pumpAndSettle();
    final edit = find.byKey(const Key('change-user-name'));
    await tester.ensureVisible(edit);
    await tester.tap(edit);
    await tester.pumpAndSettle();
    final input = find.byKey(const Key('user-name-input'));
    final save = find.byKey(const Key('save-user-name'));
    expect(tester.widget<TextFormField>(input).controller!.text, 'アオイ');
    await tester.enterText(input, '   ');
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('ユーザー名を入力してください。'), findsOneWidget);
    await tester.enterText(input, 'キャンセル後');
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(controller.state!.activeCharacter!.name, 'アオイ');
    await tester.tap(edit);
    await tester.pumpAndSettle();
    await tester.enterText(input, '  ヒカリ  ');
    repository.fail = true;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.text('変更を保存できませんでした。もう一度お試しください。'), findsOneWidget);
    expect(controller.state!.activeCharacter!.name, 'アオイ');
    expect(tester.widget<TextFormField>(input).controller!.text, '  ヒカリ  ');
    repository.fail = false;
    await tester.tap(save);
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.text('ヒカリ'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/app.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/data/local_player_repository.dart';
import 'package:focusquest/features/settings/developer_character_screen.dart';
import 'support/memory_repository.dart';

void main() {
  test('role and gender persist while progress is retained', () async {
    final directory = await Directory.systemTemp.createTemp('fq-role-');
    addTearDown(() => directory.delete(recursive: true));
    var now = DateTime(2026, 10, 10);
    final controller = GameController(MemoryRepository(), clock: () => now);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!, name: 'アオイ');
    await controller.startFocus(30);
    now = now.add(const Duration(minutes: 30));
    await controller.finishFocus();
    final before = controller.state!;
    for (final type in GameCatalog.types.values) {
      for (final appearance in ['male', 'female']) {
        await controller.setCharacterForDevelopment(type.typeId, appearance);
        final changed = controller.state!.activeCharacter!;
        expect(changed.characterType, type.typeId);
        expect(changed.appearance, appearance);
        expect(changed.baseStats.toJson(), type.stats.toJson());
        expect(changed.name, before.activeCharacter!.name);
        expect(changed.level, before.activeCharacter!.level);
        expect(changed.currentExp, before.activeCharacter!.currentExp);
        expect(changed.equippedItems, before.activeCharacter!.equippedItems);
        expect(controller.state!.toJson()['sessions'],
            before.toJson()['sessions']);
      }
    }
    final diskRepository = LocalPlayerRepository(directory);
    await diskRepository.transact(GameController.uid, (_) => controller.state!);
    final restored = GameController(diskRepository);
    addTearDown(restored.dispose);
    await restored.load();
    expect(restored.state!.toJson(), controller.state!.toJson());
    await restored.setCharacterForDevelopment('ranger', 'female');
    expect(
        (await diskRepository.load(GameController.uid))
            .activeCharacter!
            .characterType,
        'ranger');
  });

  test('invalid values, ongoing sessions and save failure preserve character',
      () async {
    final repository = MemoryRepository();
    final controller = GameController(repository);
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    final hero = controller.state!.activeCharacter!.toJson();
    await expectLater(controller.setCharacterForDevelopment('unknown', 'male'),
        throwsArgumentError);
    await expectLater(controller.setCharacterForDevelopment('mage', 'unknown'),
        throwsArgumentError);
    repository.fail = true;
    await expectLater(controller.setCharacterForDevelopment('mage', 'female'),
        throwsStateError);
    expect(controller.state!.activeCharacter!.toJson(), hero);
    repository.fail = false;
    await controller.startFocus(30);
    await expectLater(controller.setCharacterForDevelopment('mage', 'female'),
        throwsStateError);
    await controller.finishFocus(cancel: true);
    await controller.beginPlayableAdventure();
    await expectLater(controller.setCharacterForDevelopment('mage', 'female'),
        throwsStateError);
    expect(controller.state!.activeCharacter!.toJson(), hero);
  });

  testWidgets('settings opens picker, previews choice and applies changes',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[0]!);
    await tester.pumpWidget(FocusQuestApp(controller: controller));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
        of: find.byType(QuestNavigation), matching: find.text('設定')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('職業・性別を選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('職業・性別を選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('developer-job')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('拳闘士').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('developer-gender')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('女').last);
    await tester.pumpAndSettle();
    expect(controller.state!.activeCharacter!.characterType, 'mage');
    await tester.ensureVisible(find.text('変更を適用'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('変更を適用'));
    await tester.pumpAndSettle();
    expect(find.byType(DeveloperCharacterScreen), findsNothing);
    expect(controller.state!.activeCharacter!.characterType, 'boxer');
    expect(controller.state!.activeCharacter!.appearance, 'female');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

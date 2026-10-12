import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/core/widgets/role_logo.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/presentation/character_screen.dart';
import 'package:focusquest/features/certificate/certificate_catalog.dart';
import 'package:focusquest/features/certificate/certificate_data.dart';
import 'support/memory_repository.dart';

void main() {
  test('all jobs expose eight unlocks and reject locked titles', () async {
    for (final role in CertificateCatalog.titles.keys) {
      final repo = MemoryRepository();
      final controller = GameController(repo);
      await controller.load();
      await controller.onboard(
          GameCatalog.types.values.firstWhere((t) => t.typeId == role));
      final titles = CertificateCatalog.titles[role]!;
      expect(titles.length, 8);
      await expectLater(controller.selectTitle(titles[1]), throwsStateError);
      expect(controller.state!.activeCharacter!.selectedTitle, isNull);
      final hero = controller.state!.activeCharacter!;
      repo.state =
          repo.state.copyWith(characters: {hero.id: hero.copyWith(level: 9)});
      await controller.load();
      await expectLater(controller.selectTitle(titles[1]), throwsStateError);
      repo.state =
          repo.state.copyWith(characters: {hero.id: hero.copyWith(level: 10)});
      await controller.load();
      await controller.selectTitle(titles[1]);
      await controller.load();
      final restored =
          Character.fromJson(controller.state!.activeCharacter!.toJson());
      expect(restored.selectedTitle, titles[1]);
      expect(restored.copyWith(level: 20).selectedTitle, titles[1]);
      expect(
          CertificateData.fromState(controller.state!, DateTime(2026, 10, 12))
              .title,
          titles[1]);
      expect(CertificateCatalog.displayedTitle(role, 1, titles[1]), titles[0]);
      controller.dispose();
    }
  });

  testWidgets('title dialog shows unlock levels and saves selection',
      (tester) async {
    final repo = MemoryRepository();
    final controller = GameController(repo);
    await controller.load();
    await controller.onboard(
        GameCatalog.types.values.firstWhere((t) => t.typeId == 'warrior'),
        name: 'たろう');
    final hero = controller.state!.activeCharacter!;
    repo.state =
        repo.state.copyWith(characters: {hero.id: hero.copyWith(level: 20)});
    await controller.load();
    await tester.pumpWidget(MaterialApp(
        home: AnimatedBuilder(
            animation: controller,
            builder: (context, _) =>
                Scaffold(body: CharacterScreen(controller: controller)))));
    await tester.pumpAndSettle();
    expect(tester.widget<RoleLogo>(find.byType(RoleLogo)).role, 'warrior');
    await tester.ensureVisible(find.byKey(const ValueKey('change-title')));
    await tester.tap(find.byKey(const ValueKey('change-title')));
    await tester.pumpAndSettle();
    expect(find.text('称号一覧'), findsOneWidget);
    expect(find.text('Lv. 10で解放 · 解放済み'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('title-1')));
    await tester.pumpAndSettle();
    expect(controller.state!.activeCharacter!.selectedTitle, '見習い剣士');
    final locked = find.byKey(const ValueKey('title-7'));
    await tester.scrollUntilVisible(locked, 140,
        scrollable: find.descendant(
            of: find.byType(Dialog), matching: find.byType(Scrollable)));
    expect(find.text('Lv. 70で解放 · 未解放'), findsOneWidget);
    expect(tester.widget<ListTile>(locked).onTap, isNull);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
}

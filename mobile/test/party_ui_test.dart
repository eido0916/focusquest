import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/presentation/focus_screen.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:focusquest/features/party/presentation/party_battle_page.dart';
import 'package:focusquest/features/party/presentation/party_page.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    final font = await rootBundle.load('assets/fonts/NotoSerifJP.ttf');
    await (FontLoader('SunlitSerif')..addFont(Future.value(font))).load();
  });
  testWidgets('focus screen opens code party lobby on narrow phone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final controller = GameController(MemoryRepository());
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!);
    await tester
        .pumpWidget(MaterialApp(home: FocusScreen(controller: controller)));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('パーティを組む'));
    await tester.tap(find.text('パーティを組む'));
    await tester.pumpAndSettle();
    expect(find.byType(PartyPage), findsOneWidget);
    expect(find.text('パーティーコード'), findsOneWidget);
    expect(find.text('コードで参加'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });
  for (final count in [2, 4]) {
    testWidgets('$count originals on the left and $count enemy lanes',
        (tester) async {
      tester.view.physicalSize = const Size(960, 540);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      rootBundle.clear();
      Flame.images.clearCache();
      final now = DateTime(2026, 10, 11);
      final members = [
        const PartyMember(
            id: '1',
            name: '剣士',
            characterType: 'warrior',
            appearance: 'male',
            level: 12),
        const PartyMember(
            id: '2',
            name: '弓使い',
            characterType: 'ranger',
            appearance: 'female',
            level: 9),
        const PartyMember(
            id: '3',
            name: '拳闘士',
            characterType: 'boxer',
            appearance: 'male',
            level: 7),
        const PartyMember(
            id: '4',
            name: '魔法使い',
            characterType: 'mage',
            appearance: 'female',
            level: 10),
      ].take(count).toList();
      final boundary = GlobalKey();
      final game = PartyBattleGame(
          session: FocusSession(
              id: 'party',
              startedAt: now,
              durationMinutes: 30,
              partyMembers: members),
          clock: () => now.add(const Duration(milliseconds: 2600)),
          onFinished: () {});
      await tester.pumpWidget(MaterialApp(
          home: RepaintBoundary(key: boundary, child: GameWidget(game: game))));
      var loaded = false;
      game.loaded.then((_) => loaded = true);
      for (var i = 0; i < 2400 && !loaded; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(loaded, isTrue);
      expect(game.loadError, isNull);
      expect(game.session.partyMembers, hasLength(count));
      await tester.pump();
      if (const bool.fromEnvironment('CAPTURE_PARTY')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../output/party/party-$count.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(tester.takeException(), isNull);
      game.pauseEngine();
      await tester.pumpWidget(const SizedBox());
    });
  }
}

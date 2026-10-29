import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:focusquest/features/party/presentation/party_battle_page.dart';
import 'support/memory_repository.dart';

void main() {
  setUpAll(() async {
    for (final entry in {
      'SunlitSerif': 'assets/fonts/NotoSerifJP.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  for (final size in [
    const Size(960, 540),
    const Size(844, 390),
    const Size(390, 844)
  ]) {
    testWidgets('party controls remain usable on $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      rootBundle.clear();
      Flame.images.clearCache();
      final controller = GameController(MemoryRepository());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        controller.dispose();
      });
      await controller.load();
      await controller.setSoundSettings(bgm: false, se: false);
      final now = DateTime(2026, 10, 12);
      final boundary = GlobalKey();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(MaterialApp(
          navigatorKey: navigator, home: const Scaffold(body: Text('タイマー画面'))));
      navigator.currentState!.push(MaterialPageRoute<void>(
          builder: (_) => RepaintBoundary(
              key: boundary,
              child: PartyBattlePage(
                controller: controller,
                session: FocusSession(
                    id: 'party-ui',
                    startedAt: now,
                    durationMinutes: 30,
                    adventureStartSeconds: 1800,
                    partyMembers: const [
                      PartyMember(
                          id: '1',
                          name: 'まさし',
                          characterType: 'warrior',
                          appearance: 'male',
                          level: 3),
                      PartyMember(
                          id: '2',
                          name: 'きんたま',
                          characterType: 'ninja',
                          appearance: 'male',
                          level: 5),
                      PartyMember(
                          id: '3',
                          name: 'ルーナ',
                          characterType: 'mage',
                          appearance: 'female',
                          level: 4),
                      PartyMember(
                          id: '4',
                          name: 'ガルド',
                          characterType: 'ranger',
                          appearance: 'male',
                          level: 4),
                    ]),
                clock: () => now.add(const Duration(milliseconds: 2600)),
              ))));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final game = tester
          .widget<GameWidget>(
              find.byWidgetPredicate((widget) => widget is GameWidget))
          .game as PartyBattleGame;
      var loaded = false;
      game.loaded.then((_) => loaded = true);
      for (var i = 0; i < 2400 && !loaded; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)));
        await tester.pump();
      }
      expect(loaded, isTrue);
      expect(game.loadError, isNull);
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byTooltip('サウンド設定'), findsOneWidget);
      expect(find.text('タイマーに戻る'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('サウンド設定'));
      await tester.pump();
      expect(find.byType(AlertDialog), findsOneWidget);
      navigator.currentState!.pop();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(AlertDialog), findsNothing);
      if (size == const Size(960, 540) &&
          const bool.fromEnvironment('CAPTURE_PARTY')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../output/party/party-complete-page.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.tap(find.text('タイマーに戻る'));
      expect(navigator.currentState!.canPop(), isFalse);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(PartyBattlePage), findsNothing);
      expect(find.text('タイマー画面'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      game.images.clearCache();
    });
  }
}

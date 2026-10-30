import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/presentation/battle_replay_page.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';

void main() {
  setUp(() {
    rootBundle.clear();
    Flame.images.clearCache();
  });
  setUpAll(() async {
    for (final entry in {
      'SunlitSerif': 'assets/fonts/NotoSerifJP.ttf',
      'Ahem': 'assets/fonts/NotoSerifJP.ttf',
      'Roboto': 'assets/fonts/NotoSerifJP.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      final bytes = await rootBundle.load(entry.value);
      await (FontLoader(entry.key)..addFont(Future.value(bytes))).load();
    }
  });
  for (final size in [const Size(960, 540), const Size(390, 844)]) {
    testWidgets('battle returns once at the focus deadline in $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var now = DateTime(2026, 10, 4);
      final session =
          FocusSession(id: 'test', startedAt: now, durationMinutes: 1);
      BattleResultData? result;
      final boundary = GlobalKey();
      await tester.pumpWidget(RepaintBoundary(
          key: boundary,
          child: MaterialApp(
              debugShowCheckedModeBanner: false,
              home: Builder(
                  builder: (context) => Scaffold(
                      body: TextButton(
                          onPressed: () async {
                            result = await Navigator.of(context)
                                .push<BattleResultData>(MaterialPageRoute(
                                    builder: (_) => BattleReplayPage(
                                        heroLevel: 12,
                                        session: session,
                                        clock: () => now)));
                          },
                          child: const Text('start')))))));
      await tester.tap(find.text('start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final widget = tester
          .widget<GameWidget>(find.byWidgetPredicate((w) => w is GameWidget));
      final game = widget.game as FocusQuestBattleGame;
      expect(game.heroAvatarAsset,
          'focus_selection_v001/avatars/male/warrior.png');
      expect(game.heroName, '冒険者');
      var loaded = false;
      var heroReady = false;
      game.loaded.then((_) => loaded = true);
      for (var i = 0; i < 400 && !loaded; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        game.update(0);
        await tester.pump();
      }
      expect(loaded, isTrue);
      game.heroLoaded!.then((_) => heroReady = true);
      for (var i = 0; i < 1200 && !heroReady; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 25)));
        game.update(0);
        await tester.pump();
      }
      expect(heroReady, isTrue);
      expect(game.heroLevel, 12);
      expect(game.hud, isNotNull);
      now = now.add(const Duration(seconds: 4));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 25));
      }
      if (const bool.fromEnvironment('CAPTURE_FOCUS')) {
        await tester.runAsync(() async {
          final render = boundary.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File('../output/focus/${size.width.toInt()}-battle.png');
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pump();
      now = now.add(const Duration(seconds: 61));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('start'), findsOneWidget);
      expect(result!.elapsedTime, const Duration(minutes: 1));
      expect(result!.defeatedCount, greaterThan(0));
      expect(tester.takeException(), isNull);
    });
  }
}

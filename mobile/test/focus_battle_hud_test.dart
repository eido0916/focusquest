import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/config/game_balance.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/domain/reward_service.dart';
import 'package:focusquest/features/focus/presentation/battle_replay_page.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/fantasy_battle_hud.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';

class RecordedHud extends FantasyBattleHud {
  RecordedHud(ui.Image image) : super(window: image, orb: image);
  final labels = <String, Color>{};
  @override
  void text(Canvas canvas, String value, Rect rect, double size, Color color) {
    labels[value] = color;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    for (final entry in {
      'SunlitSerif': 'assets/fonts/NotoSerifJP.ttf',
      'Roboto': 'assets/fonts/NotoSerifJP.ttf',
      'Ahem': 'assets/fonts/NotoSerifJP.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf'
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value)))
          .load();
    }
  });
  test('displayed EXP changes on defeats and equals successful rewards', () {
    final now = DateTime(2026, 10, 12);
    for (final minutes in [5, 15, 30, 180]) {
      final session = FocusSession(
          id: '$minutes', startedAt: now, durationMinutes: minutes);
      final state = BattleStateController(durationSeconds: minutes * 60.0);
      state.advanceTo(1);
      expect(state.focusRewardExp, 0);
      state.advanceTo(minutes * 60.0);
      expect(
          state.focusRewardExp,
          RewardService(Random(1))
              .focus(session.finish(FocusStatus.succeeded),
                  defeatedEnemies: state.defeatedCount,
                  defeatedBosses: state.bossDefeatedCount)
              .exp);
      expect(state.focusRemainingSeconds, 0);
      expect(state.focusRewardExp,
          state.defeatedCount * GameBalance.focusEnemyExp);
      expect(
          RewardService(Random(1))
              .focus(session.finish(FocusStatus.cancelled),
                  defeatedEnemies: state.defeatedCount, defeatedBosses: 0)
              .exp,
          0);
    }
    expect(GameBalance.focusExpForDefeats(0, 0), 0);
    expect(GameBalance.focusExpForDefeats(3, 1), 102);
    expect(() => GameBalance.focusExpForDefeats(0, 1), throwsArgumentError);
  });
  test(
      'HUD has remaining time, a white EXP label, and independent menu/status/boss frames',
      () async {
    final recorder = ui.PictureRecorder();
    Canvas(recorder);
    final image = await recorder.endRecording().toImage(1, 1);
    final hud = RecordedHud(image);
    final state = BattleStateController(durationSeconds: 300)
      ..elapsedSeconds = 13
      ..gainedExp = 999;
    hud.paint(Canvas(ui.PictureRecorder()), state, 7, '陰陽師');
    expect(hud.labels['残り時間'], Colors.white);
    expect(hud.labels['04:47'], FantasyBattleHud.cyan);
    expect(hud.labels['00:13'], FantasyBattleHud.cyan);
    expect(hud.labels['EXP'], Colors.white);
    expect(hud.labels, contains('+999'));
    expect(FantasyBattleHud.menuRect.bottom + 8,
        lessThanOrEqualTo(FantasyBattleHud.statusRect.top));
    expect(
        FantasyBattleHud.statusRect.overlaps(FantasyBattleHud.bossRect), false);
    image.dispose();
  });
  testWidgets(
      'real focus screen fits the header and menu in a landscape viewport',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final now = DateTime(2026, 10, 12);
    final boundary = GlobalKey();
    await tester.pumpWidget(RepaintBoundary(
        key: boundary,
        child: MaterialApp(
            theme: AppTheme.dark,
            debugShowCheckedModeBanner: false,
            home: BattleReplayPage(
                session:
                    FocusSession(id: 'hud', startedAt: now, durationMinutes: 5),
                clock: () => now.add(const Duration(seconds: 13)),
                characterType: 'onmyoji',
                heroLevel: 7))));
    await tester.pump();
    final game = tester
        .widget<GameWidget>(
            find.byWidgetPredicate((widget) => widget is GameWidget))
        .game as FocusQuestBattleGame;
    var loaded = false;
    game.loaded.then((_) => loaded = true);
    for (var i = 0; i < 500 && (!loaded || game.hud == null); i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      await tester.pump();
    }
    expect(loaded, true);
    var heroLoaded = false;
    game.heroLoaded!.then((_) => heroLoaded = true);
    for (var i = 0; i < 500 && !heroLoaded; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 20)));
      game.update(0);
      await tester.pump();
    }
    expect(heroLoaded, true);
    for (var i = 0; i < 20; i++) {
      game.update(0);
      await tester.pump();
    }
    expect(game.state.focusRewardExp,
        game.state.defeatedCount * GameBalance.focusEnemyExp);
    expect(game.state.focusRewardExp, greaterThan(0));
    final menu = tester.getRect(find.byKey(const Key('focus-battle-menu')));
    expect(menu.bottom, lessThan(FantasyBattleHud.statusRect.top * 1280 / 960));
    if (const bool.fromEnvironment('CAPTURE_FOCUS_HUD')) {
      await tester.runAsync(() async {
        final render = boundary.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/focus-hud-review/landscape.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

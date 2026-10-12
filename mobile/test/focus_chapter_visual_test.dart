import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/focus_quest_battle_game.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';

void main() {
  testWidgets('chapter scenery and timed bosses render from original frames',
      (tester) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in {
      'SunlitSerif': 'assets/fonts/NotoSerifJP.ttf',
      'Ahem': 'assets/fonts/NotoSerifJP.ttf',
      'Roboto': 'assets/fonts/NotoSerifJP.ttf',
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
    }.entries) {
      await (FontLoader(entry.key)..addFont(rootBundle.load(entry.value))).load();
    }
    const magePreview = bool.fromEnvironment('EFFECT_PREVIEW_MAGE');
    final role = magePreview ? 'mage' : 'warrior';
    final appearance = magePreview ? 'female' : 'male';
    var now = magePreview ? 20.15 : 1500.0;
    var finished = false;
    final state = BattleStateController(
        durationSeconds: 3600,
        adventureStartSeconds: 0,
        config: PixelBattleAssets.runnerConfig(role, appearance));
    final game = FocusQuestBattleGame(
        state: state, characterType: role, appearance: appearance, elapsed: () => now, onFinished: (_) => finished = true);
    final key = GlobalKey();
    await tester.pumpWidget(MaterialApp(
        home: RepaintBoundary(key: key, child: GameWidget(game: game))));
    var loaded = false;
    var heroReady = false;
    game.loaded.then((_) => loaded = true);
    for (var i = 0; i < 600 && !loaded; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      game.update(0);
      await tester.pump();
    }
    expect(loaded, isTrue);
    game.heroLoaded!.then((_) => heroReady = true);
    for (var i = 0; i < 600 && !heroReady; i++) {
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)));
      game.update(0);
      await tester.pump();
    }
    expect(heroReady, isTrue);
    for (final entry in {
      if (magePreview) 'mage-charge': 20.15,
      if (magePreview) 'mage-ice': 21.15,
      'grassland-boss': 1501.0,
      'ghost-ship': 1802.0,
      'ghost-ship-boss': 3301.0
    }.entries) {
      now = entry.value;
      state.advanceTo(now);
      game.update(0);
      game.update(0);
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      expect(state.areaName, contains(entry.value < 1800 ? '草原' : '幽霊船'));
      if (entry.key.endsWith('boss')) expect(state.isBossBattle, isTrue);
      await tester.runAsync(() async {
        final image = await (key.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('../output/focus-chapters/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    now = 3600;
    state.advanceTo(now);
    game.update(0);
    expect(finished, isFalse);
    game.update(.6);
    game.update(.6);
    expect(finished, isFalse);
    game.update(.2);
    expect(finished, isTrue);
    game.pauseEngine();
    await tester.pumpWidget(const SizedBox());
  });
}

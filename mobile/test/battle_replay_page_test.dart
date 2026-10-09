import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/focus/presentation/battle_replay_page.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';

void main() {
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
      await tester.pumpWidget(MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                  body: TextButton(
                      onPressed: () async {
                        result = await Navigator.of(context)
                            .push<BattleResultData>(MaterialPageRoute(
                                builder: (_) => BattleReplayPage(
                                    session: session, clock: () => now)));
                      },
                      child: const Text('start'))))));
      await tester.tap(find.text('start'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final widget = tester
          .widget<GameWidget>(find.byWidgetPredicate((w) => w is GameWidget));
      await tester.runAsync(() => (widget.game as FlameGame).loaded);
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

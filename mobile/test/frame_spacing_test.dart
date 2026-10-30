import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/core/widgets/game_ui.dart';
import 'package:focusquest/core/widgets/quest_widgets.dart';

void main() {
  for (final width in [320.0, 643.0, 1920.0]) {
    testWidgets('selected navigation stays centered at width $width',
        (tester) async {
      tester.view.physicalSize = Size(width, 360);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
              appBar: const GameAppBar(
                  title: Text('冒険者証'),
                  actions: [TextButton(onPressed: null, child: Text('PNG保存'))]),
              bottomNavigationBar:
                  QuestNavigation(selected: 0, onSelect: (_) {}))));
      await tester.pump();
      final active = find.byKey(const ValueKey('navigation-0'));
      final frame = tester.getRect(active);
      for (final item in [find.byIcon(Icons.home_rounded), find.text('ホーム')]) {
        final rect = tester.getRect(item);
        expect(rect.center.dx, closeTo(frame.center.dx, .1));
        expect(rect.top, greaterThan(frame.top + 10));
        expect(rect.bottom, lessThan(frame.bottom - 10));
      }
      final action = tester.getRect(find.text('PNG保存'));
      expect(action.right, lessThan(width - 28));
      expect(tester.takeException(), isNull);
    });
  }
}

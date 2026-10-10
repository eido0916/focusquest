import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/theme/app_theme.dart';
import 'package:focusquest/features/diagnosis/presentation/king_intro_scene.dart';

void main() {
  testWidgets('dialogue reveals on tap and stone starts only once',
      (tester) async {
    var starts = 0;
    await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: KingIntroScene(onTouchStone: () => starts++)));
    await tester.pump(const Duration(milliseconds: 100));
    expect(starts, 0);
    await tester.tap(find.byKey(const Key('king-dialogue')));
    await tester.pump();
    expect(find.text(KingIntroScene.dialogue), findsNWidgets(2));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('magic-stone')));
    expect(starts, 0);
    await tester.pump(const Duration(milliseconds: 750));
    expect(starts, 1);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  for (final size in [
    const Size(390, 844),
    const Size(320, 568),
    const Size(844, 390)
  ]) {
    testWidgets('scene fits ${size.width} x ${size.height}', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(
          theme: AppTheme.dark, home: KingIntroScene(onTouchStone: () {})));
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
      expect(find.text('✧  魔法石に触れる'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('leaving during light transition cancels diagnosis launch',
      (tester) async {
    var starts = 0;
    await tester.pumpWidget(
        MaterialApp(home: KingIntroScene(onTouchStone: () => starts++)));
    await tester.tap(find.byKey(const Key('magic-stone')));
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
    expect(starts, 0);
    expect(tester.takeException(), isNull);
  });
}

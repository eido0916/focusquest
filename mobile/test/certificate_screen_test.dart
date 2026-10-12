import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/certificate/certificate_screen.dart';
import 'support/memory_repository.dart';

void main() {
  testWidgets('small phone shows real player card and enables PNG export',
      (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final cardImage = find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is MemoryImage);
    final controller =
        GameController(MemoryRepository(), clock: () => DateTime(2026, 10, 11));
    addTearDown(controller.dispose);
    await controller.load();
    await controller.onboard(GameCatalog.types[15]!,
        name: 'アオイ', appearance: 'female');
    await tester.runAsync(() async {
      await tester.pumpWidget(
          MaterialApp(home: CertificateScreen(controller: controller)));
      for (var i = 0; i < 100 && cardImage.evaluate().isEmpty; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await tester.pump();
      }
    });
    await tester.pump();
    expect(cardImage, findsOneWidget);
    final image = tester.widget<Image>(cardImage);
    expect(image.semanticLabel, 'アオイの冒険者証');
    final codec = await tester.runAsync(
        () => ui.instantiateImageCodec((image.image as MemoryImage).bytes));
    final frame = await tester.runAsync(() => codec!.getNextFrame());
    expect(frame!.image.width, 2304);
    expect(frame.image.height, 1536);
    frame.image.dispose();
    codec!.dispose();
    final save = tester.widget<TextButton>(find
        .ancestor(
            of: find.text('PNG保存'),
            matching: find.byWidgetPredicate((widget) => widget is TextButton))
        .first);
    expect(save.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    expect(cardImage, findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}

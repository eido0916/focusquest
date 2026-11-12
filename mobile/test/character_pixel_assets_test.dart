import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'package:focusquest/features/character/presentation/character_pixel_portrait.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 32 detailed menu originals preserve transparent margins', () async {
    final paths = <String>{};
    for (final sex in ['male', 'female']) {
      for (final role in JobPortrait.roleNames.keys) {
        final asset = CharacterPixelPortrait.assetFor(role, sex);
        expect(paths.add(asset), isTrue,
            reason: '$sex $role must have its own original');
        final bytes = await rootBundle.load(asset);
        final codec =
            await ui.instantiateImageCodec(bytes.buffer.asUint8List());
        final image = (await codec.getNextFrame()).image;
        expect(image.width, 512);
        expect(image.height, 512);
        final rgba =
            (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        var visible = 0;
        final colors = <int>{};
        for (var y = 0; y < 512; y++) {
          for (var x = 0; x < 512; x++) {
            final offset = (y * 512 + x) * 4;
            final alpha = rgba[offset + 3];
            if (alpha > 0) {
              visible++;
              colors.add((rgba[offset] << 16) |
                  (rgba[offset + 1] << 8) |
                  rgba[offset + 2]);
            }
            if (x < 16 || x >= 496 || y < 16 || y >= 496) {
              expect(alpha, 0, reason: '$sex $role: clipped silhouette');
            }
          }
        }
        expect(visible, greaterThan(10000));
        expect(colors.length, greaterThan(100),
            reason: 'Preserve the detailed original palette');
        image.dispose();
        codec.dispose();
      }
    }
    expect(paths.length, 32);
  });

  for (final dpr in [1.0, 1.5, 2.0, 3.0]) {
    testWidgets('detailed standing art fits the stage at DPR $dpr',
        (tester) async {
      tester.view.devicePixelRatio = dpr;
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MaterialApp(
          home: Center(
              child: SizedBox(
                  width: 217,
                  height: 199,
                  child: CharacterPixelPortrait(
                      role: 'warrior', appearance: 'female')))));
      final finder = find.descendant(
          of: find.byType(CharacterPixelPortrait),
          matching: find.byType(Image));
      final physicalSide = tester.getSize(finder).width * dpr;
      expect(physicalSide, lessThanOrEqualTo(199 * dpr));
      expect(physicalSide, greaterThan(190 * dpr));
      expect(tester.widget<Image>(finder).filterQuality, FilterQuality.none);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}

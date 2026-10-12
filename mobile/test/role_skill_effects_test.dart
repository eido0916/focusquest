import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/game/runner/role_skill_effects.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('all 16 diagnosis roles have unique effects and named skills', () async {
    final manifest = jsonDecode(await rootBundle
        .loadString('${RoleSkillEffects.base}manifest.json')) as Map;
    expect(manifest.keys.toSet(),
        GameCatalog.types.values.map((t) => t.typeId).toSet());
    expect(manifest.values.map((v) => v['kind']).toSet().length, 16);
    for (final type in GameCatalog.types.values) {
      expect(
          manifest[type.typeId]['skill'], RoleSkillEffects.names[type.typeId]);
      for (final sex in ['male', 'female']) {
        expect(PixelBattleAssets.runnerConfig(type.typeId, sex).pixelSkillName,
            RoleSkillEffects.names[type.typeId]);
      }
    }
  });

  test('source clock snaps at 24fps and dispatches each ranged release', () {
    expect(RoleSkillEffects.frameIndex(-1, 1.5, [.5]), 11);
    expect(RoleSkillEffects.frameIndex(1.5, 1.5, [.5]), 11);
    expect(RoleSkillEffects.frameIndex(0, 1.5, [.5]), 0);
    expect(RoleSkillEffects.frameIndex(.49, 1.5, [.5]), 2);
    expect(RoleSkillEffects.frameIndex(.5, 1.5, [.5]), 3);
    for (final pair in [
      [7, 3],
      [10, 5],
      [13, 7]
    ]) {
      expect(
          RoleSkillEffects.frameIndex(
              pair[0] / 24, 20 / 24, [7 / 24, 10 / 24, 13 / 24]),
          pair[1]);
    }
    for (var tick = 0; tick < 36; tick++) {
      expect(RoleSkillEffects.frameIndex((tick + .01) / 24, 1.5, [.5]),
          RoleSkillEffects.frameIndex((tick + .99) / 24, 1.5, [.5]));
    }
  });

  test('all 32 gender timelines match the frame selection used by the game',
      () async {
    final bindings = jsonDecode(await rootBundle
        .loadString('${RoleSkillEffects.base}bindings.json')) as Map;
    expect(bindings.length, 32);
    for (final entry in bindings.entries) {
      final data = entry.value as Map;
      final key = entry.key as String;
      final female = key.endsWith('_female');
      final type = key.substring(0, key.length - (female ? 7 : 5));
      final character =
          PixelBattleAssets.characterFor(type, female ? 'female' : 'male');
      expect(data['source_motion'], character.id);
      expect(data['source_event'], character.skillEvent);
      final duration = (data['duration_seconds'] as num).toDouble();
      final releases = (data['release_ticks'] as List)
          .map((t) => (t as num).toDouble() / 24)
          .toList();
      for (final row in data['timeline'] as List) {
        expect(
            RoleSkillEffects.frameIndex(
                (row['tick'] + .01) / 24, duration, releases),
            row['keyframe'],
            reason: '${entry.key} tick ${row['tick']}');
      }
    }
  });

  for (final type in RoleSkillEffects.names.keys) {
    test('$type draws one focal effect without repeats, clears at end',
        () async {
      final effects = await RoleSkillEffects.load(type, (path) async {
        final bytes = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
        final image = (await codec.getNextFrame()).image;
        codec.dispose();
        return image;
      });
      try {
        expect(effects.frames.length, 12);
        expect(effects.metadata['interpolation'], 'none');
        expect(effects.metadata['composition'], 'single');
        Future<ui.Image> render(double age) async {
          final recorder = ui.PictureRecorder();
          effects.paint(ui.Canvas(recorder),
              origin: const ui.Offset(30, 285),
              viewport: const ui.Rect.fromLTWH(0, 0, 700, 320),
              age: age,
              duration: 1.5,
              releases: [.5]);
          final picture = recorder.endRecording();
          final result = await picture.toImage(750, 320);
          picture.dispose();
          return result;
        }

        final active = await render(.65);
        final rgba =
            (await active.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        var attackPixels = 0, beforeHero = 0, beyondViewport = 0;
        for (var y = 0; y < 320; y++) {
          for (var x = 0; x < 750; x++) {
            final alpha = rgba[(y * 750 + x) * 4 + 3];
            if (x < 30) beforeHero += alpha;
            if (x >= 30 && x < 480) attackPixels += alpha;
            if (x >= 700) beyondViewport += alpha;
          }
        }
        expect(beforeHero, 0);
        expect(beyondViewport, 0);
        expect(attackPixels, greaterThan(0));
        active.dispose();
        final wideRecorder = ui.PictureRecorder();
        effects.paint(ui.Canvas(wideRecorder),
            origin: const ui.Offset(30, 180),
            viewport: const ui.Rect.fromLTWH(0, 0, 1800, 200),
            age: .65,
            duration: 1.5,
            releases: [.5],
            logicalPixel: 1);
        final widePicture = wideRecorder.endRecording();
        final wide = await widePicture.toImage(1800, 200);
        final wideBytes =
            (await wide.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        var wideRight = 0;
        for (var y = 0; y < 200; y++) {
          for (var x = 254; x < 1800; x++) {
            wideRight += wideBytes[(y * 1800 + x) * 4 + 3];
          }
        }
        expect(wideRight, 0,
            reason: 'The original must never tile across a wide viewport');
        wide.dispose();
        widePicture.dispose();
        final end = await render(1.5);
        final bytes =
            (await end.toByteData(format: ui.ImageByteFormat.rawRgba))!
                .buffer
                .asUint8List();
        expect(bytes.every((v) => v == 0), true);
        end.dispose();
      } finally {
        for (final image in effects.frames) {
          image.dispose();
        }
      }
    });
  }
}

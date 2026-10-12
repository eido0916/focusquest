import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/certificate/certificate_catalog.dart';
import 'package:focusquest/features/certificate/certificate_data.dart';
import 'package:focusquest/features/certificate/certificate_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render all 32 original-art certificates at production resolution',
      () async {
    final font = FontLoader('SunlitSerif')
      ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf'));
    await font.load();
    final export = Platform.environment['FQ_CERTIFICATE_EXPORT'];
    final contacts = <String, List<ui.Image>>{'male': [], 'female': []};
    for (final role in CertificateCatalog.titles.keys) {
      for (final gender in ['male', 'female']) {
        final bytes = await CertificateRenderer.buildTemplate(role, gender);
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        expect(frame.image.width, 1536);
        expect(frame.image.height, 2304);
        frame.image.dispose();
        codec.dispose();
        if (export != null) {
          final target = File('assets/images/certificates/${role}_$gender.png');
          await target.writeAsBytes(bytes, flush: true);
          final template = File('$export/templates/${role}_$gender.png');
          await template.parent.create(recursive: true);
          await template.writeAsBytes(bytes);
          final preview = await CertificateRenderer.render(
              CertificateData(
                  role: role,
                  gender: gender,
                  name: '見本',
                  level: 8,
                  focusMinutes: 7600,
                  defeats: 1284,
                  days: 18,
                  stages: 8,
                  number: 'AG-0000001',
                  issuedAt: DateTime(2026, 10, 11)),
              templateBytes: bytes);
          final sample = File('$export/previews/${role}_$gender.png');
          await sample.parent.create(recursive: true);
          await sample.writeAsBytes(preview);
          final previewCodec = await ui.instantiateImageCodec(preview,
              targetWidth: 256, targetHeight: 384);
          contacts[gender]!.add((await previewCodec.getNextFrame()).image);
          previewCodec.dispose();
        }
      }
    }
    if (export != null) {
      for (final gender in contacts.keys) {
        for (var sheet = 0; sheet < 2; sheet++) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          for (var i = 0; i < 8; i++) {
            canvas.drawImage(contacts[gender]![sheet * 8 + i],
                ui.Offset((i % 4) * 256, (i ~/ 4) * 384), ui.Paint());
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(1024, 768);
          final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
          await File('$export/$gender-review-${sheet + 1}.png')
              .writeAsBytes(png.buffer.asUint8List());
          image.dispose();
          picture.dispose();
        }
        for (final image in contacts[gender]!) {
          image.dispose();
        }
      }
    }
  }, timeout: const Timeout(Duration(minutes: 8)));
}

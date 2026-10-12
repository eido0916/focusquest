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
        expect(frame.image.width, 2304);
        expect(frame.image.height, 1536);
        frame.image.dispose();
        codec.dispose();
        if (export != null) {
          final target = File(
              'assets/images/certificates_landscape_v002/${role}_$gender.png');
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
              targetWidth: 384, targetHeight: 256);
          contacts[gender]!.add((await previewCodec.getNextFrame()).image);
          previewCodec.dispose();
        }
      }
    }
    if (export != null) {
      final materials = await CertificateRenderer.materials();
      for (final entry in materials.entries) {
        final file = File('$export/materials/${entry.key}.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final mage = await File(
              'assets/images/certificates_landscape_v002/mage_female.png')
          .readAsBytes();
      final current = await CertificateRenderer.render(
          const CertificateData(
              role: 'mage',
              gender: 'female',
              name: 'たろう',
              level: 3,
              focusMinutes: 30,
              defeats: 1284,
              days: 1,
              stages: 1,
              number: 'AG-0421890',
              issuedAt: null),
          templateBytes: mage);
      await File('$export/current-screen-example.png').writeAsBytes(current);
      for (final gender in contacts.keys) {
        for (var sheet = 0; sheet < 2; sheet++) {
          final recorder = ui.PictureRecorder();
          final canvas = ui.Canvas(recorder);
          for (var i = 0; i < 8; i++) {
            canvas.drawImage(contacts[gender]![sheet * 8 + i],
                ui.Offset((i % 4) * 384, (i ~/ 4) * 256), ui.Paint());
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(1536, 512);
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

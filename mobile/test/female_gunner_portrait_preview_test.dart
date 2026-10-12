import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/certificate/certificate_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('female gunner portrait has a transparent background and renders',
      () async {
    final data = await rootBundle.load(
        'assets/images/lobby/portraits/female/gunner_dark_brown_transparent_v002.png');
    final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    final image = (await codec.getNextFrame()).image;
    final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();
    expect(rgba[3], 0);
    expect(rgba[((image.width - 1) * 4) + 3], 0);
    expect(rgba[((200 * image.width + 500) * 4) + 3], greaterThan(250));
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xffe7ebf0), ui.BlendMode.src);
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    final picture = recorder.endRecording();
    final preview = await picture.toImage(image.width, image.height);
    final out = Directory('../output/female-gunner');
    await out.create(recursive: true);
    await File('${out.path}/transparent-preview.png').writeAsBytes(
        (await preview.toByteData(format: ui.ImageByteFormat.png))!
            .buffer
            .asUint8List());
    image.dispose();
    codec.dispose();
    picture.dispose();
    preview.dispose();
    await (FontLoader('SunlitSerif')
          ..addFont(rootBundle.load('assets/fonts/NotoSerifJP.ttf')))
        .load();
    final certificate =
        await CertificateRenderer.buildTemplate('gunner', 'female');
    await File('${out.path}/certificate-preview.png').writeAsBytes(certificate);
  });
}

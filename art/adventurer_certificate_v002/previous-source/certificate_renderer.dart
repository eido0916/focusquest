import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../diagnosis/presentation/job_portrait.dart';
import 'certificate_catalog.dart';
import 'certificate_data.dart';

/// Original artwork is cropped and drawn directly; no generative face edits.
class CertificateRenderer {
  static const width = 1536, height = 2304;
  static const ink = Color(0xff342616);
  static Future<ui.Image> _load(String path) async {
    final bytes = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  static void _text(Canvas c, String text, Rect box, double size,
      {Color color = ink,
      bool bold = false,
      TextAlign align = TextAlign.left}) {
    var font = size;
    late TextPainter p;
    do {
      p = TextPainter(
          text: TextSpan(
              text: text,
              style: TextStyle(
                  fontFamily: 'SunlitSerif',
                  fontSize: font,
                  color: color,
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  height: 1.15)),
          textDirection: TextDirection.ltr,
          textAlign: align,
          maxLines: 1);
      p.layout();
      if (p.width <= box.width && p.height <= box.height || font <= 8) break;
      p.dispose();
      font -= 1;
    } while (true);
    c.save();
    c.clipRect(box);
    final x = align == TextAlign.center
        ? box.left + (box.width - p.width) / 2
        : box.left;
    p.paint(c, Offset(x, box.top + (box.height - p.height) / 2));
    c.restore();
    p.dispose();
  }

  static Future<Uint8List> _png(ui.PictureRecorder recorder) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    try {
      return (await image.toByteData(format: ui.ImageByteFormat.png))!
          .buffer
          .asUint8List();
    } finally {
      image.dispose();
      picture.dispose();
    }
  }

  static Future<Uint8List> buildTemplate(String role, String gender) async {
    final bg =
        await _load('assets/images/certificates/parchment-background.png');
    final hero = await _load(CertificateCatalog.portrait(role, gender));
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)..scale(1.5);
    c.drawImageRect(
        bg,
        Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
        const Rect.fromLTWH(0, 0, 1024, 1536),
        Paint());
    // A calm paper panel above the landscape protects the heading's contrast.
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(294, 106, 580, 107), const Radius.circular(8)),
        Paint()..color = const Color(0xf4f4e4bb));
    _text(c, '冒険者証', const Rect.fromLTWH(312, 112, 545, 94), 69,
        bold: true, align: TextAlign.center);
    const destination = Rect.fromLTWH(68, 347, 373, 449);
    // Centered upper-body crop, preserving the source face, hair and costume.
    final sourceHeight = hero.height * .57;
    final sourceWidth = sourceHeight * destination.width / destination.height;
    final source = Rect.fromLTWH(
        (hero.width - sourceWidth) / 2, 0, sourceWidth, sourceHeight);
    c.save();
    c.clipRect(destination);
    c.drawRect(destination, Paint()..color = const Color(0xffd9c496));
    c.drawImageRect(
        hero, source, destination, Paint()..filterQuality = FilterQuality.high);
    c.restore();
    c.drawRRect(
        RRect.fromRectAndRadius(
            const Rect.fromLTWH(546, 539, 366, 68), const Radius.circular(5)),
        Paint()..color = CertificateCatalog.accent(role));
    _text(c, '名前', const Rect.fromLTWH(512, 359, 428, 40), 25);
    _text(c, '称号', const Rect.fromLTWH(562, 534, 332, 25), 17,
        color: const Color(0xffffebbb));
    _text(c, '役職名', const Rect.fromLTWH(512, 663, 428, 38), 25);
    _text(c, JobPortrait.roleNames[role]!,
        const Rect.fromLTWH(512, 706, 422, 70), 43,
        bold: true);
    const labels = ['Lv.', '総集中時間', '累計討伐数', '冒険日数', '最深到達'];
    const boxes = [
      Rect.fromLTWH(104, 886, 376, 35),
      Rect.fromLTWH(548, 886, 389, 35),
      Rect.fromLTWH(104, 1032, 376, 35),
      Rect.fromLTWH(548, 1032, 389, 35),
      Rect.fromLTWH(104, 1161, 376, 35)
    ];
    for (var i = 0; i < labels.length; i++) {
      _text(c, labels[i], boxes[i], 26);
    }
    _text(c, 'ギルドマスター', const Rect.fromLTWH(548, 1161, 389, 35), 24);
    _text(c, 'Eishin', const Rect.fromLTWH(548, 1200, 350, 53), 37);
    _text(c, '冒険者番号', const Rect.fromLTWH(87, 1320, 192, 24), 20,
        align: TextAlign.center);
    _text(c, '発行ギルド', const Rect.fromLTWH(468, 1311, 342, 32), 19);
    _text(c, '王都フォカス冒険者ギルド', const Rect.fromLTWH(468, 1349, 342, 38), 25,
        bold: true);
    _text(c, '発行日', const Rect.fromLTWH(468, 1395, 342, 28), 18);
    hero.dispose();
    bg.dispose();
    return _png(recorder);
  }

  static Future<Uint8List> render(CertificateData data,
      {Uint8List? templateBytes}) async {
    final ui.Image base;
    if (templateBytes == null) {
      base = await _load(CertificateCatalog.template(data.role, data.gender));
    } else {
      final codec = await ui.instantiateImageCodec(templateBytes);
      base = (await codec.getNextFrame()).image;
      codec.dispose();
    }
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)..scale(1.5);
    c.drawImageRect(
        base,
        Rect.fromLTWH(0, 0, base.width.toDouble(), base.height.toDouble()),
        const Rect.fromLTWH(0, 0, 1024, 1536),
        Paint());
    _text(c, data.name, const Rect.fromLTWH(512, 411, 422, 72), 45, bold: true);
    _text(c, data.title, const Rect.fromLTWH(562, 562, 330, 42), 32,
        color: const Color(0xffffebbb), bold: true, align: TextAlign.center);
    _text(c, '${data.level}', const Rect.fromLTWH(104, 931, 376, 60), 46,
        bold: true);
    _text(c, '${data.focusMinutes ~/ 60}時間 ${data.focusMinutes % 60}分',
        const Rect.fromLTWH(548, 931, 389, 60), 37,
        bold: true);
    _text(c, '${data.defeats}体', const Rect.fromLTWH(104, 1070, 376, 58), 42,
        bold: true);
    _text(c, '${data.days}日', const Rect.fromLTWH(548, 1070, 389, 58), 42,
        bold: true);
    _text(c, '${data.stages}ステージ', const Rect.fromLTWH(104, 1200, 376, 53), 38,
        bold: true);
    _text(c, data.number, const Rect.fromLTWH(87, 1374, 192, 51), 23,
        bold: true, align: TextAlign.center);
    final date = data.issuedAt;
    _text(c, date == null ? '未記録' : '${date.year}年${date.month}月${date.day}日',
        const Rect.fromLTWH(468, 1425, 330, 28), 21);
    base.dispose();
    return _png(recorder);
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../diagnosis/presentation/job_portrait.dart';
import 'certificate_catalog.dart';
import 'certificate_data.dart';

/// One continuous engraved parchment surface. Text never sits on UI panels.
class CertificateRenderer {
  static const width = 2304, height = 1536;
  static const ink = Color(0xff241708);
  static const master =
      'assets/images/certificates_landscape_v002/master-landscape.png';

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
      {Color color = ink, bool bold = true, TextAlign align = TextAlign.left}) {
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
                  height: 1.08)),
          textDirection: TextDirection.ltr,
          maxLines: 1);
      p.layout();
      if (p.width <= box.width && p.height <= box.height || font <= 8) break;
      p.dispose();
      font -= 1;
    } while (true);
    c.save();
    c.clipRect(box);
    p.paint(
        c,
        Offset(
            align == TextAlign.center
                ? box.left + (box.width - p.width) / 2
                : box.left,
            box.top + (box.height - p.height) / 2));
    c.restore();
    p.dispose();
  }

  static Future<Uint8List> _png(ui.PictureRecorder recorder,
      {int pixelsWide = width, int pixelsHigh = height}) async {
    final picture = recorder.endRecording();
    final image = await picture.toImage(pixelsWide, pixelsHigh);
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
    final bg = await _load(master);
    final hero = await _load(CertificateCatalog.portrait(role, gender));
    final recorder = ui.PictureRecorder();
    final c = Canvas(recorder)..scale(1.5);
    c.drawImageRect(
        bg,
        Rect.fromLTWH(0, 0, bg.width.toDouble(), bg.height.toDouble()),
        const Rect.fromLTWH(0, 0, 1536, 1024),
        Paint());
    const portrait = Rect.fromLTWH(86, 247, 458, 540);
    final sourceHeight = hero.height * .46;
    final sourceWidth = sourceHeight * portrait.width / portrait.height;
    c.save();
    c.clipRect(portrait);
    c.drawImageRect(
        hero,
        Rect.fromLTWH(
            (hero.width - sourceWidth) / 2, 0, sourceWidth, sourceHeight),
        portrait,
        Paint()..filterQuality = FilterQuality.high);
    c.restore();
    // Every ornament, title band, icon, seal and signature is already integrated
    // in the master. Only typography is printed here; no opaque rectangles.
    _text(c, '名前', const Rect.fromLTWH(659, 281, 108, 59), 30);
    _text(c, '称号', const Rect.fromLTWH(659, 386, 108, 60), 30);
    _text(c, '役職名', const Rect.fromLTWH(659, 477, 113, 68), 28);
    _text(c, JobPortrait.roleNames[role]!,
        const Rect.fromLTWH(803, 480, 632, 69), 47);
    _text(c, 'Lv.', const Rect.fromLTWH(658, 582, 110, 60), 29);
    _text(c, '総集中時間', const Rect.fromLTWH(655, 655, 121, 60), 22);
    _text(c, '累計討伐数', const Rect.fromLTWH(655, 729, 121, 60), 22);
    _text(c, '冒険日数', const Rect.fromLTWH(1152, 583, 119, 64), 25);
    _text(c, '最深到達', const Rect.fromLTWH(1152, 695, 119, 65), 25);
    _text(c, '冒険者番号', const Rect.fromLTWH(146, 849, 215, 32), 24,
        align: TextAlign.center);
    _text(c, '発行ギルド', const Rect.fromLTWH(544, 846, 310, 43), 24);
    _text(c, '王都フォカス冒険者ギルド', const Rect.fromLTWH(544, 889, 305, 57), 27);
    _text(c, '発行日', const Rect.fromLTWH(884, 857, 161, 44), 21,
        align: TextAlign.center);
    _text(c, 'ギルドマスター', const Rect.fromLTWH(1115, 844, 207, 45), 23,
        align: TextAlign.center);
    hero.dispose();
    bg.dispose();
    return _png(recorder);
  }

  static String _number(int number) => '$number'
      .replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]},');

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
        const Rect.fromLTWH(0, 0, 1536, 1024),
        Paint());
    _text(c, data.name, const Rect.fromLTWH(803, 274, 631, 75), 51);
    _text(c, data.title, const Rect.fromLTWH(900, 386, 442, 58), 43,
        color: const Color(0xffffefc9), align: TextAlign.center);
    _text(c, '${data.level}', const Rect.fromLTWH(803, 579, 223, 64), 52);
    _text(c, '${data.focusMinutes ~/ 60}時間${data.focusMinutes % 60}分',
        const Rect.fromLTWH(803, 655, 223, 63), 40);
    _text(c, _number(data.defeats), const Rect.fromLTWH(803, 729, 223, 63), 49);
    _text(c, '${data.days}日', const Rect.fromLTWH(1300, 582, 141, 67), 47);
    _text(c, '${data.stages}ステージ', const Rect.fromLTWH(1300, 695, 141, 68), 35);
    _text(c, data.number, const Rect.fromLTWH(142, 892, 236, 49), 30,
        align: TextAlign.center);
    final date = data.issuedAt;
    _text(c, date == null ? '未記録' : '${date.year}年${date.month}月${date.day}日',
        const Rect.fromLTWH(879, 899, 174, 48), 23,
        align: TextAlign.center);
    base.dispose();
    return _png(recorder);
  }

  /// Separately inspectable source components retain their surrounding paper
  /// grain. The final document uses the continuous master, not pasted tiles.
  static Future<Map<String, Uint8List>> materials() async {
    final bg = await _load(master);
    const crops = <String, Rect>{
      'portrait-frame-and-paper': Rect.fromLTWH(72, 226, 492, 581),
      'title-cartouche': Rect.fromLTWH(782, 369, 666, 88),
      'dragon-wax-seal': Rect.fromLTWH(1314, 783, 184, 199),
      'eishin-signature': Rect.fromLTWH(1102, 883, 217, 74),
      'guild-crest': Rect.fromLTWH(430, 837, 105, 121),
      'name-icon': Rect.fromLTWH(587, 275, 63, 69),
      'title-icon': Rect.fromLTWH(588, 375, 64, 77),
      'role-icon': Rect.fromLTWH(583, 476, 70, 70),
      'level-icon': Rect.fromLTWH(585, 573, 62, 71),
      'focus-icon': Rect.fromLTWH(585, 660, 60, 50),
      'defeats-icon': Rect.fromLTWH(582, 727, 64, 67),
      'days-icon': Rect.fromLTWH(1081, 583, 60, 58),
      'stages-icon': Rect.fromLTWH(1077, 693, 69, 64),
    };
    final result = <String, Uint8List>{};
    for (final entry in crops.entries) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder)..scale(1.5);
      final crop = entry.value;
      final source = Rect.fromLTWH(
          crop.left * bg.width / 1536,
          crop.top * bg.height / 1024,
          crop.width * bg.width / 1536,
          crop.height * bg.height / 1024);
      canvas.drawImageRect(
          bg, source, Rect.fromLTWH(0, 0, crop.width, crop.height), Paint());
      result[entry.key] = await _png(recorder,
          pixelsWide: (crop.width * 1.5).round(),
          pixelsHigh: (crop.height * 1.5).round());
    }
    bg.dispose();
    return result;
  }
}

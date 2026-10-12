import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/services.dart';

/// Complete transparent originals. The renderer selects a PNG and crops only
/// at the viewport edge; it never stretches an effect to fit the screen.
class RoleSkillEffects {
  RoleSkillEffects(this.type, this.metadata, this.frames);
  final String type;
  final Map<String, dynamic> metadata;
  final List<ui.Image> frames;
  static const base = 'assets/images/role_skill_effects/';
  static const names = {
    'warrior': '蓄力斬撃',
    'boxer': '旋風蹴り',
    'samurai': '連続居合',
    'guardian': '蓄力薙ぎ払い',
    'ninja': '瞬身突き',
    'assassin': '蓄力クリティカル',
    'ranger': '三連射',
    'mage': '大氷結',
    'gunner': '早撃ち',
    'spellblade': '雷剣・落雷',
    'onmyoji': '五行封陣',
    'reaper': '冥月刈り',
    'angel': '聖光の翼',
    'devil': '獄炎の波',
    'dragon_knight': '竜炎突撃',
    'berserker': '狂戦裂破',
  };
  static const roleTypes = {
    '剣士': 'warrior',
    '拳闘士': 'boxer',
    '侍': 'samurai',
    '重騎士': 'guardian',
    '忍者': 'ninja',
    'アサシン': 'assassin',
    '弓使い': 'ranger',
    '魔法使い': 'mage',
    'ガンナー': 'gunner',
    '魔剣士': 'spellblade',
    '陰陽師': 'onmyoji',
    '鎌使い': 'reaper',
    '天使': 'angel',
    '悪魔': 'devil',
    'ドラゴンナイト': 'dragon_knight',
    'バーサーカー': 'berserker',
  };

  static Future<RoleSkillEffects> load(
      String type, Future<ui.Image> Function(String path) decode) async {
    final selected = names.containsKey(type) ? type : 'warrior';
    final manifest =
        jsonDecode(await rootBundle.loadString('${base}manifest.json'))
            as Map<String, dynamic>;
    final frames = <ui.Image>[];
    for (var i = 0; i < 12; i++) {
      frames.add(
          await decode('$base${selected}_${i.toString().padLeft(3, '0')}.png'));
    }
    return RoleSkillEffects(
        selected, Map<String, dynamic>.from(manifest[selected] as Map), frames);
  }

  /// Quantize the source action clock to 24fps. Release events select authored
  /// impact frames exactly, including the three distinct ranged releases.
  static int frameIndex(double age, double duration, List<double> releases) {
    if (age < 0 || age >= duration || duration <= 0) return 11;
    final total = math.max(1, (duration * 24).round());
    final tick = (age * 24 + 1e-7).floor();
    final events = releases
        .where((t) => t >= 0 && t < duration)
        .map((t) => (t * 24).round())
        .toSet()
        .toList()
      ..sort();
    if (events.isEmpty) events.add((total * .55).floor());
    final first = events.first;
    if (tick < first) return math.min(2, tick * 3 ~/ math.max(1, first));
    if (events.length >= 3) {
      for (var i = 0; i < 2; i++) {
        if (tick < events[i + 1]) {
          return 3 +
              i * 2 +
              math.min(
                  1,
                  (tick - events[i]) *
                      2 ~/
                      math.max(1, events[i + 1] - events[i]));
        }
      }
      return math.min(
          11, 7 + (tick - events[2]) * 5 ~/ math.max(1, total - events[2]));
    }
    return math.min(11, 3 + (tick - first) * 9 ~/ math.max(1, total - first));
  }

  /// Source pixels measured from the top, relative to the hero's feet.
  /// Charge art is centered at 166px; the hero's hands are 32 source pixels
  /// above its ground anchor. Ground attacks use the authored 248px baseline.
  double anchorY(int index, {double chargeHeight = 32}) {
    if (index < 3) return 166 + chargeHeight;
    switch (metadata['kind']) {
      case 'earth':
      case 'ice':
      case 'lightning':
      case 'talismans':
      case 'hellfire':
      case 'dragon':
      case 'rage':
        return 248;
      case 'holy':
        return 196;
      case 'reap':
        return 182;
      case 'arrows':
      case 'bullets':
        return 186;
      default:
        return 188;
    }
  }

  void paint(
    ui.Canvas canvas, {
    required ui.Offset origin,
    required ui.Rect viewport,
    required double age,
    required double duration,
    required List<double> releases,
    double logicalPixel = 2,
    double devicePixelRatio = 1,
    double chargeHeight = 32,
  }) {
    final index = frameIndex(age, duration, releases);
    final frame = frames[index];
    // Each 2px source block is one logical pixel. Keep an integer number of
    // physical pixels per logical pixel, equally in X and Y.
    final grid = math.max(1, (logicalPixel * devicePixelRatio).round());
    final scale = grid / devicePixelRatio / 2;
    double snap(double value) =>
        (value * devicePixelRatio).round() / devicePixelRatio;
    final x = snap(origin.dx),
        y = snap(
            origin.dy - anchorY(index, chargeHeight: chargeHeight) * scale);
    canvas.save();
    canvas.clipRect(ui.Rect.fromLTRB(math.max(viewport.left, x), viewport.top,
        viewport.right, viewport.bottom));
    final width = frame.width * scale;
    // Unusually wide stage viewports reuse complete originals at subsequent
    // world positions. Charging remains only at the character's position.
    final copies = index >= 3 && index < 11
        ? math.max(1, ((viewport.right - x) / width).ceil())
        : 1;
    for (var copy = 0; copy < copies; copy++) {
      canvas.drawImageRect(
          frame,
          ui.Rect.fromLTWH(
              0, 0, frame.width.toDouble(), frame.height.toDouble()),
          ui.Rect.fromLTWH(x + copy * width, y, width, frame.height * scale),
          ui.Paint()
            ..filterQuality = ui.FilterQuality.none
            ..isAntiAlias = false);
    }
    canvas.restore();
  }
}

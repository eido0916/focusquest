import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'swordsman_sousen_timing.dart';

/// Flame-ready data for the non-looping 35-frame initial skill, 蒼閃.
class SwordsmanSousenAssets {
  SwordsmanSousenAssets._({
    required this.animation,
    required this.frameSize,
    required this.anchor,
    required this.duration,
    required this.damageTime,
  });

  static const _assetDirectory =
      'assets/images/characters/swordsman/skills/sousen';

  final SpriteAnimation animation;
  final Vector2 frameSize;
  final Anchor anchor;
  final Duration duration;
  final Duration damageTime;

  static Future<SwordsmanSousenAssets> load(FlameGame game) async {
    final raw = await rootBundle.loadString(
      '$_assetDirectory/swordsman_sousen_spritesheet.json',
    );
    final metadata = jsonDecode(raw) as Map<String, dynamic>;
    final frameSizeJson = metadata['frameSize'] as Map<String, dynamic>;
    final sheetJson = metadata['sheet'] as Map<String, dynamic>;
    final anchorJson = metadata['anchor'] as Map<String, dynamic>;
    final frameCount = metadata['frameCount'] as int;
    final columns = sheetJson['columns'] as int;
    final frameSize = Vector2(
      (frameSizeJson['width'] as num).toDouble(),
      (frameSizeJson['height'] as num).toDouble(),
    );
    final image = await game.images.load(
      'characters/swordsman/skills/sousen/'
      '${metadata['image'] as String}',
    );
    final sheet = SpriteSheet(image: image, srcSize: frameSize);
    final sprites = List<Sprite>.generate(
      frameCount,
      (index) => sheet.getSprite(index ~/ columns, index % columns),
    );
    // Runtime timing is shared with combat, rather than the original export's
    // delays. All 35 poses and the existing atlas stay in their original order.
    final stepTimes = SwordsmanSousenTiming.stepTimes;

    return SwordsmanSousenAssets._(
      animation: SpriteAnimation.variableSpriteList(
        sprites,
        stepTimes: stepTimes,
        loop: false,
      ),
      frameSize: frameSize,
      anchor: Anchor(
        (anchorJson['x'] as num).toDouble(),
        (anchorJson['y'] as num).toDouble(),
      ),
      duration: Duration(
          milliseconds: (SwordsmanSousenTiming.durationSeconds * 1000).round()),
      damageTime: Duration(
          milliseconds:
              (SwordsmanSousenTiming.damageTimeSeconds * 1000).round()),
    );
  }
}

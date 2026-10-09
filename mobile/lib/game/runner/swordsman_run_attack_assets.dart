import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

/// Flame-ready animations built from the 50 aligned swordsman frames.
class SwordsmanRunAttackAssets {
  SwordsmanRunAttackAssets._({
    required this.swordsmanRunAttack,
    required this.swordsmanRun,
    required this.frameSize,
    required this.anchor,
    required this.duration,
  });

  static const _assetDirectory = 'assets/images/characters/swordsman/attack';

  final SpriteAnimation swordsmanRunAttack;
  final SpriteAnimation swordsmanRun;
  final Vector2 frameSize;
  final Anchor anchor;
  final Duration duration;

  static Future<SwordsmanRunAttackAssets> load(FlameGame game) async {
    final raw = await rootBundle.loadString(
      '$_assetDirectory/swordsman_attack_spritesheet.json',
    );
    final metadata = jsonDecode(raw) as Map<String, dynamic>;
    final frameSizeJson = metadata['frameSize'] as Map<String, dynamic>;
    final sheetJson = metadata['sheet'] as Map<String, dynamic>;
    final animationJson = metadata['animation'] as Map<String, dynamic>;
    final anchorJson = metadata['anchor'] as Map<String, dynamic>;
    final frameCount = metadata['frameCount'] as int;
    final columns = sheetJson['columns'] as int;
    final frameSize = Vector2(
      (frameSizeJson['width'] as num).toDouble(),
      (frameSizeJson['height'] as num).toDouble(),
    );
    final image = await game.images.load(
      'characters/swordsman/attack/'
      '${metadata['image'] as String}',
    );
    final sheet = SpriteSheet(image: image, srcSize: frameSize);
    final sprites = List<Sprite>.generate(
      frameCount,
      (index) => sheet.getSprite(index ~/ columns, index % columns),
    );
    final stepTimes = (animationJson['stepTimesMs'] as List<dynamic>)
        .map((value) => (value as num).toDouble() / 1000)
        .toList(growable: false);

    final swordsmanRunAttack = SpriteAnimation.variableSpriteList(
      sprites,
      stepTimes: stepTimes,
      loop: false,
    );

    // The final source montage is a clean five-pose run cycle. Reusing it
    // keeps the non-loop attack's final pose and the normal run aligned.
    final runFrameIndexes = List<int>.generate(
      5,
      (index) => frameCount - 5 + index,
    );
    final swordsmanRun = SpriteAnimation.spriteList(
      [for (final index in runFrameIndexes) sprites[index]],
      stepTime: .095,
      loop: true,
    );

    return SwordsmanRunAttackAssets._(
      swordsmanRunAttack: swordsmanRunAttack,
      swordsmanRun: swordsmanRun,
      frameSize: frameSize,
      anchor: Anchor(
        (anchorJson['x'] as num).toDouble(),
        (anchorJson['y'] as num).toDouble(),
      ),
      duration: Duration(milliseconds: animationJson['durationMs'] as int),
    );
  }
}

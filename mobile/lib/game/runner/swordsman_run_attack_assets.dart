import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'swordsman_normal_attack_sequence.dart';

/// Normal running two-slash attack, using only the reviewed candidate subset.
class SwordsmanRunAttackAssets {
  SwordsmanRunAttackAssets._({
    required this.swordsmanRunAttack,
    required this.swordsmanRun,
    required this.frameSize,
    required this.anchor,
    required this.duration,
  });

  static const _assetDirectory =
      'assets/images/characters/swordsman/normal_attack';

  final SpriteAnimation swordsmanRunAttack;
  final SpriteAnimation swordsmanRun;
  final Vector2 frameSize;
  final Anchor anchor;
  final Duration duration;

  static Future<SwordsmanRunAttackAssets> load(FlameGame game) async {
    final raw = await rootBundle.loadString(
      '$_assetDirectory/normal_attack.json',
    );
    final metadata = jsonDecode(raw) as Map<String, dynamic>;
    final frameSizeJson = metadata['frameSize'] as Map<String, dynamic>;
    final anchorJson = metadata['anchor'] as Map<String, dynamic>;
    final frameIds = (metadata['frameIds'] as List<dynamic>).cast<String>();
    final columns = metadata['columns'] as int;
    final frameSize = Vector2(
      (frameSizeJson['width'] as num).toDouble(),
      (frameSizeJson['height'] as num).toDouble(),
    );
    final image = await game.images.load(
      'characters/swordsman/normal_attack/normal_attack.png',
    );
    final sheet = SpriteSheet(image: image, srcSize: frameSize);
    final individualFrames = <String, Sprite>{
      for (var index = 0; index < frameIds.length; index++)
        frameIds[index]: sheet.getSprite(index ~/ columns, index % columns),
    };
    final attackFrames = [
      for (final id in SwordsmanNormalAttackSequence.frameIds)
        individualFrames[id] ??
            (throw StateError('Missing reviewed normal attack frame: $id')),
    ];

    final swordsmanRunAttack = SpriteAnimation.variableSpriteList(
      attackFrames,
      stepTimes: SwordsmanNormalAttackSequence.stepTimes,
      loop: false,
    );

    // Same normalized canvas and body/ground anchor as the attack's last poses.
    final swordsmanRun = SpriteAnimation.spriteList(
      [
        for (final id in SwordsmanNormalAttackSequence.runFrameIds)
          individualFrames[id]!
      ],
      stepTime: .07,
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
      duration: Duration(
        microseconds:
            (SwordsmanNormalAttackSequence.duration * 1000000).round(),
      ),
    );
  }

  /// Raw 50 candidates for tooling/alternative players. Exact width / 5 and
  /// full source height; never sort filenames. Some raw slots clip swords or
  /// include a neighbour, so production uses the alpha-isolated atlas above.
  static Future<Map<String, Sprite>> loadSourceCandidates(
      FlameGame game) async {
    final raw =
        await rootBundle.loadString('$_assetDirectory/normal_attack.json');
    final metadata = jsonDecode(raw) as Map<String, dynamic>;
    final sources = (metadata['sources'] as List<dynamic>).cast<String>();
    final frames = <String, Sprite>{};
    for (var sheetIndex = 0; sheetIndex < sources.length; sheetIndex++) {
      final image = await game.images.load(
        'characters/swordsman/normal_attack/${sources[sheetIndex]}',
      );
      final width = image.width / 5;
      for (var frame = 0; frame < 5; frame++) {
        final id =
            'file_${(sheetIndex + 1).toString().padLeft(2, '0')}_f${frame + 1}';
        frames[id] = Sprite(
          image,
          srcPosition: Vector2(frame * width, 0),
          srcSize: Vector2(width, image.height.toDouble()),
        );
      }
    }
    return frames;
  }
}

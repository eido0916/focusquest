import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

/// One non-looping skill. Timing/selection live in skill.json, not the PNG.
class FemaleSkillAssets {
  FemaleSkillAssets._(this.frames, this.stepTimes, this.sourceFrames,
      this.activeIndexes, this.recoveryIndex, this.frameSize, this.anchor);

  static const directory = 'characters/female_swordsman/skill';
  final List<Sprite> frames;
  final List<double> stepTimes;
  final List<int> sourceFrames;
  final List<int> activeIndexes;
  final int recoveryIndex;
  final Vector2 frameSize;
  final Anchor anchor;
  double timeAt(int index) => stepTimes.take(index).fold(0.0, (a, b) => a + b);
  double get duration => timeAt(stepTimes.length);
  double get activeStart => timeAt(activeIndexes.first);
  double get activeEnd => timeAt(activeIndexes.last + 1);
  double get recoveryStart => timeAt(recoveryIndex);
  int sourceFrameAt(double age) {
    for (var index = 0; index < stepTimes.length; index++) {
      if (age < timeAt(index + 1)) return sourceFrames[index];
    }
    return sourceFrames.last;
  }

  SpriteAnimation animation() => SpriteAnimation.variableSpriteList(frames,
      stepTimes: stepTimes, loop: false);

  static Future<FemaleSkillAssets> load(FlameGame game,
      {double timeScale = 1}) async {
    if (!timeScale.isFinite || timeScale <= 0) {
      throw ArgumentError.value(timeScale, 'timeScale');
    }
    final data = jsonDecode(
            await rootBundle.loadString('assets/images/$directory/skill.json'))
        as Map<String, dynamic>;
    final size = Vector2(
        (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
    final sheet = SpriteSheet(
        image: await game.images.load('$directory/skill.png'), srcSize: size);
    final columns = data['columns'] as int;
    final atlasIds = (data['atlasFrames'] as List).cast<int>();
    final sprites = <int, Sprite>{
      for (var i = 0; i < atlasIds.length; i++)
        atlasIds[i]: sheet.getSprite(i ~/ columns, i % columns)
    };
    final ids = (data['attackFrames'] as List).cast<int>();
    return FemaleSkillAssets._(
      [for (final id in ids) sprites[id]!],
      [
        for (final time in data['stepTimes'] as List)
          (time as num).toDouble() * timeScale
      ],
      ids,
      (data['activeHitIndexes'] as List).cast<int>(),
      data['recoveryIndex'] as int,
      size,
      Anchor((data['anchorX'] as num).toDouble(),
          (data['anchorY'] as num).toDouble()),
    );
  }

  /// All 35 exact five-way source slots for tools, not production playback.
  static Future<Map<String, Sprite>> loadSourceCandidates(
      FlameGame game) async {
    final data = jsonDecode(
            await rootBundle.loadString('assets/images/$directory/skill.json'))
        as Map<String, dynamic>;
    final sources = (data['sources'] as List).cast<String>();
    final result = <String, Sprite>{};
    for (var index = 0; index < sources.length; index++) {
      final image = await game.images.load('$directory/${sources[index]}');
      for (var slot = 0; slot < 5; slot++) {
        final id = 'sheet${(index + 1).toString().padLeft(2, '0')}'
            '_frame${(slot + 1).toString().padLeft(2, '0')}';
        result[id] = Sprite(image,
            srcPosition: Vector2(slot * image.width / 5, 0),
            srcSize: Vector2(image.width / 5, image.height.toDouble()));
      }
    }
    return result;
  }
}

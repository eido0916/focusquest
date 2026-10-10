import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

/// Reviewed female normal attack only; not a skill or a two-hit combo.
class FemaleRunAttackAssets {
  FemaleRunAttackAssets._(
      this.frames,
      this.attackIds,
      this.runIds,
      this.stepTimes,
      this.hitIndexes,
      this.recoveryIndex,
      this.frameSize,
      this.anchor);

  static const directory = 'characters/female_swordsman/normal_attack';
  final Map<int, Sprite> frames;
  final List<int> attackIds;
  final List<int> runIds;
  final List<double> stepTimes;
  final List<int> hitIndexes;
  final int recoveryIndex;
  final Vector2 frameSize;
  final Anchor anchor;

  double get duration => stepTimes.fold(0, (a, b) => a + b);
  double timeAt(int index) => stepTimes.take(index).fold(0, (a, b) => a + b);
  double get hitStart => timeAt(hitIndexes.first);
  double get hitEnd => timeAt(hitIndexes.last + 1);
  double get recoveryStart => timeAt(recoveryIndex);

  SpriteAnimation attackAnimation() => SpriteAnimation.variableSpriteList(
        [for (final id in attackIds) frames[id]!],
        stepTimes: stepTimes,
        loop: false,
      );
  SpriteAnimation runAnimation() =>
      SpriteAnimation.spriteList([for (final id in runIds) frames[id]!],
          stepTime: .07, loop: true);

  /// Increase timeScale to slow the motion; atlas regeneration is unnecessary.
  static Future<FemaleRunAttackAssets> load(FlameGame game,
      {double timeScale = 1}) async {
    if (!timeScale.isFinite || timeScale <= 0) {
      throw ArgumentError.value(timeScale, 'timeScale', 'Must be positive');
    }
    final data = jsonDecode(await rootBundle.loadString(
        'assets/images/$directory/normal_attack.json')) as Map<String, dynamic>;
    List<int> ints(String key) => (data[key] as List).cast<int>();
    final size = Vector2(
        (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
    final sheet = SpriteSheet(
        image: await game.images.load('$directory/normal_attack.png'),
        srcSize: size);
    final ids = ints('atlasFrames');
    final columns = data['columns'] as int;
    return FemaleRunAttackAssets._(
      {
        for (var i = 0; i < ids.length; i++)
          ids[i]: sheet.getSprite(i ~/ columns, i % columns)
      },
      ints('attackFrames'),
      ints('runFrames'),
      [
        for (final t in data['stepTimes'] as List)
          (t as num).toDouble() * timeScale
      ],
      ints('activeHitIndexes'),
      data['recoveryIndex'] as int,
      size,
      Anchor((data['anchorX'] as num).toDouble(),
          (data['anchorY'] as num).toDouble()),
    );
  }

  /// Tooling access to all 30 original slots: explicit source order, width / 5.
  /// Raw slots contain overlaps. Use the reviewed atlas for gameplay.
  static Future<Map<int, Sprite>> loadSourceCandidates(FlameGame game) async {
    final data = jsonDecode(await rootBundle.loadString(
        'assets/images/$directory/normal_attack.json')) as Map<String, dynamic>;
    final result = <int, Sprite>{};
    final sources = (data['sources'] as List).cast<String>();
    for (var sheet = 0; sheet < sources.length; sheet++) {
      final image = await game.images.load('$directory/${sources[sheet]}');
      final width = image.width / 5;
      for (var slot = 0; slot < 5; slot++) {
        result[sheet * 5 + slot + 1] = Sprite(image,
            srcPosition: Vector2(slot * width, 0),
            srcSize: Vector2(width, image.height.toDouble()));
      }
    }
    return result;
  }
}

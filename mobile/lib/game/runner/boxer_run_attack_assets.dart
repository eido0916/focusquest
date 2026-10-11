import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'boxer_normal_attack_sequence.dart';
import 'boxer_run_assets.dart';

class BoxerRunAttackAssets {
  BoxerRunAttackAssets(
      this.attack, this.run, this.frameSize, this.anchor, this.runAssets);
  final SpriteAnimation attack;
  final SpriteAnimation run;
  final Vector2 frameSize;
  final Anchor anchor;
  final BoxerRunAssets runAssets;

  static Future<BoxerRunAttackAssets> load(FlameGame game) async {
    const directory = 'characters/boxer/normal_attack';
    final data = jsonDecode(await rootBundle.loadString(
      'assets/images/$directory/normal_attack.json',
    )) as Map<String, dynamic>;
    final size = Vector2(
        (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
    final sheet = SpriteSheet(
        image: await game.images.load('$directory/normal_attack.png'),
        srcSize: size);
    final ids = (data['atlasFrames'] as List).cast<int>();
    final columns = data['columns'] as int;
    final sprites = <int, Sprite>{
      for (var i = 0; i < ids.length; i++)
        ids[i]: sheet.getSprite(i ~/ columns, i % columns),
    };
    final running = await BoxerRunAssets.load(game);
    return BoxerRunAttackAssets(
      SpriteAnimation.variableSpriteList(
        [for (final id in BoxerNormalAttackSequence.frameIds) sprites[id]!],
        stepTimes: BoxerNormalAttackSequence.stepTimes,
        loop: false,
      ),
      running.animation,
      size,
      Anchor((data['anchorX'] as num).toDouble(),
          (data['anchorY'] as num).toDouble()),
      running,
    );
  }
}

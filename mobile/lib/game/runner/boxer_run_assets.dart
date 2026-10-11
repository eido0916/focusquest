import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';

/// Exact pre-skill running poses, using the skill's canvas and anchor.
class BoxerRunAssets {
  BoxerRunAssets(this.animation, this.frameSize, this.anchor,
      this.displayHeight, this.frameIds);
  final SpriteAnimation animation;
  final Vector2 frameSize;
  final Anchor anchor;
  final double displayHeight;
  final List<int> frameIds;
  double get duration =>
      animation.frames.fold(0, (sum, frame) => sum + frame.stepTime);

  static Future<BoxerRunAssets> load(FlameGame game) async {
    const directory = 'characters/boxer/run_from_skill';
    final data = jsonDecode(
            await rootBundle.loadString('assets/images/$directory/run.json'))
        as Map<String, dynamic>;
    final size = Vector2(
        (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
    final sheet = SpriteSheet(
        image: await game.images.load('$directory/run.png'), srcSize: size);
    final ids = (data['frameIds'] as List).cast<int>();
    return BoxerRunAssets(
      SpriteAnimation.variableSpriteList(
        [for (var i = 0; i < ids.length; i++) sheet.getSprite(0, i)],
        stepTimes: (data['stepTimes'] as List)
            .map((value) => (value as num).toDouble())
            .toList(),
        loop: true,
      ),
      size,
      Anchor((data['anchorX'] as num).toDouble(),
          (data['anchorY'] as num).toDouble()),
      (data['displayHeight'] as num).toDouble(),
      ids,
    );
  }
}

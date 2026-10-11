import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'boxer_front_kick_sequence.dart';
import 'boxer_wind_effect_component.dart';

class BoxerFrontKickAssets {
  BoxerFrontKickAssets(this.animation, this.frameSize, this.anchor,
      {this.windFrames = const []});
  final SpriteAnimation animation;
  final Vector2 frameSize;
  final Anchor anchor;
  final List<Sprite> windFrames;
  static Future<BoxerFrontKickAssets> load(FlameGame game) async {
    const directory = 'characters/boxer/skills/front_kick';
    final data = jsonDecode(await rootBundle.loadString(
        'assets/images/$directory/front_kick.json')) as Map<String, dynamic>;
    final ids = (data['frames'] as List).cast<int>();
    final ticks = (data['holdTicks'] as List).cast<int>();
    if (ids.join(',') != BoxerFrontKickSequence.frameIds.join(',') ||
        ticks.join(',') != BoxerFrontKickSequence.holdTicks.join(',') ||
        data['events']['impactIndex'] != BoxerFrontKickSequence.impactIndex) {
      throw StateError('Front kick atlas and combat timeline disagree');
    }
    final size = Vector2(
        (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
    final sheet = SpriteSheet(
        image: await game.images.load('$directory/front_kick.png'),
        srcSize: size);
    final columns = data['columns'] as int;
    final wind = await game.images.load('$directory/wind_spear.png');
    return BoxerFrontKickAssets(
        SpriteAnimation.variableSpriteList([
          for (var i = 0; i < ids.length; i++)
            sheet.getSprite(i ~/ columns, i % columns)
        ], stepTimes: BoxerFrontKickSequence.stepTimes, loop: false),
        size * BoxerFrontKickSequence.sourcePixelDisplayScale,
        Anchor((data['anchorX'] as num).toDouble(),
            (data['anchorY'] as num).toDouble()),
        windFrames: [
          for (final rect in BoxerWindEffectComponent.sourceRects)
            Sprite(wind,
                srcPosition: Vector2(rect.left, rect.top),
                srcSize: Vector2(rect.width, rect.height))
        ]);
  }
}

import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'archer_attack_animation_controller.dart';

class FemaleArcherSkillAssets {
  FemaleArcherSkillAssets._(
      this.frames, this.windFrames, this.data, this.timeScale);
  static const directory = 'characters/female_archer/skill';
  final Map<int, Sprite> frames;
  final List<Sprite> windFrames;
  final Map<String, dynamic> data;
  final double timeScale;
  List<int> get skillIds => (data['skillFrames'] as List).cast<int>();
  List<int> get runIds => (data['runFrames'] as List).cast<int>();
  Vector2 get frameSize => Vector2(
      (data['width'] as num).toDouble(), (data['height'] as num).toDouble());
  Anchor get anchor => Anchor(
      (data['anchorX'] as num).toDouble(), (data['anchorY'] as num).toDouble());
  Vector2 get muzzleOffset => Vector2(
      (data['muzzleX'] as num).toDouble() - anchor.x * frameSize.x,
      (data['muzzleY'] as num).toDouble() - anchor.y * frameSize.y);
  List<double> get stepTimes => [
        for (final ticks in data['holdTicks'] as List)
          (ticks as num) / 24 * timeScale
      ];
  ArcherAttackAnimationController createController() =>
      ArcherAttackAnimationController(
          frameIds: skillIds,
          stepTimes: stepTimes,
          phases: (data['phases'] as List).cast<String>(),
          releaseFrame: data['releaseFrame'] as int);
  SpriteAnimation skillAnimation() => SpriteAnimation.variableSpriteList(
      [for (final id in skillIds) frames[id]!],
      stepTimes: stepTimes, loop: false);
  SpriteAnimation runAnimation() => SpriteAnimation.variableSpriteList([
        for (final id in runIds) frames[id]!
      ], stepTimes: [
        for (final ticks in data['runHoldTicks'] as List)
          (ticks as num) / 24 * timeScale
      ], loop: true);

  static Future<FemaleArcherSkillAssets> load(FlameGame game,
      {double timeScale = 1}) async {
    if (!timeScale.isFinite || timeScale <= 0) {
      throw ArgumentError.value(timeScale, 'timeScale');
    }
    final data = jsonDecode(
            await rootBundle.loadString('assets/images/$directory/skill.json'))
        as Map<String, dynamic>;
    final sheets = <SpriteSheet>[];
    for (final name in data['atlasPages'] as List) {
      sheets.add(SpriteSheet(
          image: await game.images.load('$directory/$name'),
          srcSize: Vector2((data['width'] as num).toDouble(),
              (data['height'] as num).toDouble())));
    }
    final ids = (data['atlasFrames'] as List).cast<int>();
    final columns = data['columns'] as int;
    final capacity = data['pageCapacity'] as int;
    final windSheet = SpriteSheet(
      image: await game.images.load('$directory/wind_arrow.png'),
      srcSize: Vector2(318, 245),
    );
    return FemaleArcherSkillAssets._({
      for (var i = 0; i < ids.length; i++)
        ids[i]: sheets[i ~/ capacity]
            .getSprite((i % capacity) ~/ columns, i % columns)
    }, [
      for (var i = 0; i < 8; i++) windSheet.getSprite(0, i)
    ], data, timeScale);
  }
}

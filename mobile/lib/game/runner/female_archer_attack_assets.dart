import 'dart:convert';
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/services.dart';
import 'archer_attack_animation_controller.dart';

class FemaleArcherAttackAssets {
  FemaleArcherAttackAssets._(
      this.frames, this.arrow, this.data, this.timeScale);
  static const directory = 'characters/female_archer/normal_attack';
  final Map<int, Sprite> frames;
  final Sprite arrow;
  final Map<String, dynamic> data;
  final double timeScale;
  List<int> get attackIds => (data['attackFrames'] as List).cast<int>();
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
  // Keep the shot sharp; give the post-shot legs two ticks per original.
  List<double> get reviewedStepTimes => [
        for (var i = 0; i < attackIds.length; i++)
          stepTimes[i] * (attackIds[i] <= 5 || attackIds[i] >= 24 ? 2 : 1)
      ];
  double get releaseTime => reviewedStepTimes
      .take(attackIds.indexOf(data['releaseFrame'] as int))
      .fold(0, (a, b) => a + b);
  double get duration => reviewedStepTimes.fold(0, (a, b) => a + b);
  ArcherAttackAnimationController createController() =>
      ArcherAttackAnimationController(
          frameIds: attackIds,
          stepTimes: reviewedStepTimes,
          phases: (data['phases'] as List).cast<String>(),
          releaseFrame: data['releaseFrame'] as int);
  SpriteAnimation attackAnimation() => SpriteAnimation.variableSpriteList(
      [for (final id in attackIds) frames[id]!],
      stepTimes: reviewedStepTimes, loop: false);
  SpriteAnimation runAnimation() => SpriteAnimation.variableSpriteList([
        for (final id in runIds) frames[id]!
      ], stepTimes: [
        for (final ticks in data['runHoldTicks'] as List)
          (ticks as num) / 24 * timeScale * 1.5
      ], loop: true);

  static Future<FemaleArcherAttackAssets> load(FlameGame game,
      {double timeScale = 1}) async {
    if (!timeScale.isFinite || timeScale <= 0) {
      throw ArgumentError.value(timeScale, 'timeScale');
    }
    final data = jsonDecode(await rootBundle.loadString(
        'assets/images/$directory/normal_attack.json')) as Map<String, dynamic>;
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
    return FemaleArcherAttackAssets._({
      for (var i = 0; i < ids.length; i++)
        ids[i]: sheets[i ~/ capacity]
            .getSprite((i % capacity) ~/ columns, i % columns)
    }, Sprite(await game.images.load('$directory/arrow.png')), data, timeScale);
  }

  /// Raw five-slot source slicing for review. Fractional width is avoided by
  /// using the same rounded integer edges as the Python extractor. Some bows
  /// cross slot boundaries; use the reviewed atlas above in the actual game.
  static Future<List<Sprite>> loadSourceCandidates(FlameGame game) async {
    final result = <Sprite>[];
    for (var sheet = 1; sheet <= 9; sheet++) {
      final image = await game.images
          .load('$directory/source_${sheet.toString().padLeft(2, '0')}.png');
      for (var slot = 0; slot < 5; slot++) {
        final left = (slot * image.width / 5).round();
        final right = ((slot + 1) * image.width / 5).round();
        result.add(Sprite(image,
            srcPosition: Vector2(left.toDouble(), 0),
            srcSize:
                Vector2((right - left).toDouble(), image.height.toDouble())));
      }
    }
    return result;
  }
}

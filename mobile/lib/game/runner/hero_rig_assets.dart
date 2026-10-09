import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/services.dart';

class HeroPartAsset {
  const HeroPartAsset({
    required this.sprite,
    required this.pivot,
    required this.aspectRatio,
  });

  final Sprite sprite;
  final Vector2 pivot;
  final double aspectRatio;
}

class HeroRigAssets {
  HeroRigAssets._(this.parts);

  static const _assetDirectory = 'assets/images/battle/hero_rig';

  final Map<String, HeroPartAsset> parts;

  HeroPartAsset operator [](String name) => parts[name]!;

  static Future<HeroRigAssets> load(FlameGame game) async {
    final raw = await rootBundle.loadString('$_assetDirectory/rig.json');
    final metadata = jsonDecode(raw) as Map<String, dynamic>;
    final definitions = metadata['parts'] as Map<String, dynamic>;
    final parts = <String, HeroPartAsset>{};

    for (final entry in definitions.entries) {
      final definition = entry.value as Map<String, dynamic>;
      final pivot = definition['pivot'] as Map<String, dynamic>;
      final image = await game.images.load(
        'battle/hero_rig/${definition['file'] as String}',
      );
      parts[entry.key] = HeroPartAsset(
        sprite: Sprite(image),
        pivot: Vector2(
          (pivot['x'] as num).toDouble(),
          (pivot['y'] as num).toDouble(),
        ),
        aspectRatio:
            (definition['width'] as num) / (definition['height'] as num),
      );
    }
    return HeroRigAssets._(parts);
  }
}

import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import '../domain/playable_stage_catalog.dart';
import '../domain/playable_character.dart';
import '../../../game/runner/role_skill_effects.dart';

class StageFrame {
  const StageFrame(this.image, this.offset, [this.topPixel = 0]);
  final ui.Image image;
  final ui.Offset offset;
  final double topPixel;
}

class StageMotion {
  StageMotion(this.metadata, this.images, {this.topPixels = const []});
  final Map<String, dynamic> metadata;
  final List<ui.Image> images;
  final List<double> topPixels;
  List<dynamic> get timeline => metadata['timeline'] as List<dynamic>;
  double get duration => (metadata['duration_seconds'] as num).toDouble();
  int eventTick(String event, int fallback) {
    for (final row in metadata['events'] as List<dynamic>) {
      if (row['event'] == event) return row['tick'] as int;
    }
    return fallback;
  }

  List<int> eventTicks(String event) => [
        for (final row in metadata['events'] as List<dynamic>)
          if (row['event'] == event) row['tick'] as int,
      ];

  StageFrame frame(double elapsed, {bool loop = false}) {
    var tick = (elapsed * 24).floor();
    tick = loop ? tick % timeline.length : tick.clamp(0, timeline.length - 1);
    final row = timeline[tick] as Map<String, dynamic>;
    final offset = row['root_offset_px'] as List<dynamic>;
    return StageFrame(
        images[row['keyframe'] as int],
        ui.Offset((offset[0] as num).toDouble(), (offset[1] as num).toDouble()),
        topPixels.isEmpty ? 0 : topPixels[row['keyframe'] as int]);
  }
}

class PlayableStageAssets {
  PlayableStageAssets._(this.background, this.motions, this.effects,
      this.floorMetadata, this.effect);
  static const base = 'assets/images/playable_stage/';
  final ui.Image background;
  final Map<String, StageMotion> motions;
  final Map<String, ui.Image> effects;
  final Map<String, dynamic> floorMetadata;
  final RoleSkillEffects effect;

  static Future<PlayableStageAssets> load(
      {PlayableStageDefinition? stage, PlayableCharacter? character}) async {
    final hero = character ?? PlayableCharacters.defaultCharacter;
    final enemyIds = stage == null
        ? null
        : {
            for (var i = 0; i < stage.opponents.length; i++)
              for (final enemy in stage.wave(i)) enemy.id
          };
    final allocated = <ui.Image>[];
    Future<ui.Image> decode(String path) async {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
      try {
        final image = (await codec.getNextFrame()).image;
        allocated.add(image);
        return image;
      } finally {
        codec.dispose();
      }
    }

    try {
      final manifest =
          jsonDecode(await rootBundle.loadString('${base}manifest.json'))
              as Map<String, dynamic>;
      final background =
          await decode(stage?.backgroundPath ?? '${base}grassland.png');
      final motions = <String, StageMotion>{};
      // Decode sequentially so error/disposal cannot race unfinished allocations.
      for (final name
          in (manifest['motions'] as List<dynamic>).cast<String>()) {
        if (name.startsWith('hero_')) continue;
        final heroMotion = ['run', 'attack', 'skill', 'idle']
            .any((action) => name == '${hero.id}_$action');
        if (name.startsWith('character_') && !heroMotion) {
          continue;
        }
        if (enemyIds != null &&
            !heroMotion &&
            !enemyIds.any((id) => name.startsWith('${id}_'))) {
          continue;
        }
        final meta = jsonDecode(await rootBundle.loadString('$base$name.json'))
            as Map<String, dynamic>;
        final frames = <ui.Image>[];
        final topPixels = <double>[];
        for (final key in meta['keyframes'] as List<dynamic>) {
          frames.add(await decode(
              '$base${name}_${(key['index'] as int).toString().padLeft(3, '0')}.png'));
          final rgba =
              await frames.last.toByteData(format: ui.ImageByteFormat.rawRgba);
          var top = frames.last.height.toDouble();
          if (rgba != null) {
            for (var i = 3; i < rgba.lengthInBytes; i += 4) {
              if (rgba.getUint8(i) != 0) {
                top = ((i ~/ 4) ~/ frames.last.width).toDouble();
                break;
              }
            }
          }
          topPixels.add(top);
        }
        motions[heroMotion ? name.replaceFirst('${hero.id}_', 'hero_') : name] =
            StageMotion(meta, frames, topPixels: topPixels);
      }
      // Characters without an idle keep their original attack stance on screen.
      motions['hero_idle'] ??= motions['hero_attack']!;
      final effects = <String, ui.Image>{};
      for (final name in [
        'arrow',
        'bullet',
        'fire',
        'ice',
        'shuriken',
        'holy_sword',
        'talisman',
        'holy_orb',
        'dark_wave',
        'wave',
        'sickle',
        'impact'
      ]) {
        effects[name] = await decode('${base}effect_$name.png');
      }
      final floorMeta =
          jsonDecode(await rootBundle.loadString('${base}floor_materials.json'))
              as Map<String, dynamic>;
      if (hero.role == 'バーサーカー') {
        final material = stage?.floorMaterial ?? 'grass';
        for (var pose = 0; pose < 4; pose++) {
          effects['floor_${material}_$pose'] = await decode(
              '${base}floor_${material}_${pose.toString().padLeft(3, '0')}.png');
        }
      }
      final effect = await RoleSkillEffects.load(
          hero.effectType ?? RoleSkillEffects.roleTypes[hero.role] ?? 'warrior',
          decode);
      return PlayableStageAssets._(
          background, motions, effects, floorMeta, effect);
    } catch (_) {
      for (final image in allocated) {
        image.dispose();
      }
      rethrow;
    }
  }

  void dispose() {
    background.dispose();
    for (final image in effect.frames) {
      image.dispose();
    }
    for (final image in effects.values) {
      image.dispose();
    }
    for (final motion in motions.values.toSet()) {
      for (final image in motion.images) {
        image.dispose();
      }
    }
  }
}

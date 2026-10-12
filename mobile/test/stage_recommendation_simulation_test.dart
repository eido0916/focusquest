import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';

final _motions = <String, Map<String, dynamic>>{};
Map<String, dynamic> motion(String name) => _motions.putIfAbsent(
    name,
    () => jsonDecode(
            File('assets/images/playable_stage/$name.json').readAsStringSync())
        as Map<String, dynamic>);
int simulations = 0;
bool simulate(PlayableStageDefinition stage, PlayableCharacter base, int level,
    int seed) {
  simulations++;
  final growth = level - 1;
  final hero = PlayableCharacter(
      base.id,
      base.role,
      base.female,
      base.health + growth * 12,
      base.power + growth * 3,
      base.speed + growth * 5,
      base.attackEvent,
      base.skillEvent,
      base.skillName,
      ranged: base.ranged);
  final battle = PlayableStageBattle(
      stage: stage, character: hero, roll: Random(seed).nextDouble)
    ..configureHeroTiming(
        motion('${base.id}_attack'), motion('${base.id}_skill'))
    ..start();
  final configured = <StageEnemy>{};
  for (var tick = 0; tick < 60 * 300 && battle.active; tick++) {
    for (final enemy in battle.enemies) {
      if (!configured.add(enemy)) continue;
      final attack = motion('${enemy.definition.id}_attack');
      enemy.attackDuration = (attack['duration_seconds'] as num).toDouble();
      int event(String name, int fallback) {
        for (final row in attack['events'] as List) {
          if (row['event'] == name) return row['tick'] as int;
        }
        return fallback;
      }

      enemy.hitTick = event(
          'attack_active_or_release',
          event('enemy_attack_hit',
              event('boss_attack_hit', event('fire_breath_start', 11))));
      enemy.defeatDuration =
          (motion('${enemy.definition.id}_defeat')['duration_seconds'] as num)
              .toDouble();
    }
    battle.update(1 / 60);
    if (battle.canSkill) {
      battle.skill();
    } else if (battle.canAttack) {
      battle.attack();
    }
  }
  final won = battle.mode == StageMode.won;
  battle.dispose();
  return won;
}

void main() {
  test(
      'calibrate all 36 stages using original timing, 32 actors and seeded battles',
      () {
    final report = <Map<String, dynamic>>[];
    for (final stage in PlayableStageCatalog.stages) {
      final levels = <String, int>{};
      for (final hero in PlayableCharacters.all) {
        bool ready(int level) =>
            List.generate(12, (seed) => simulate(stage, hero, level, seed))
                .where((win) => win)
                .length >=
            10;
        var high = 8;
        while (!ready(high) && high < 512) {
          high *= 2;
        }
        expect(ready(high), isTrue, reason: '${stage.number}/${hero.id}');
        var low = 1;
        while (low < high) {
          final mid = (low + high) ~/ 2;
          if (ready(mid)) {
            high = mid;
          } else {
            low = mid + 1;
          }
        }
        levels[hero.id] = low;
        print('Stage ${stage.number} ${hero.id}: Lv.$low');
      }
      // Validate each actor on separate seeds; increase if the search sample was optimistic.
      for (final hero in PlayableCharacters.all) {
        var level = levels[hero.id]!;
        while (List.generate(
                    40, (seed) => simulate(stage, hero, level, seed + 1000))
                .where((win) => win)
                .length <
            32) {
          level++;
          expect(level, lessThan(512));
        }
        levels[hero.id] = level;
      }
      final recommended = levels.values.reduce(max);
      report.add({
        'stage': stage.number,
        'difficultyLevel': stage.difficultyLevel,
        'recommendedLevel': recommended,
        'actors': levels
      });
      // Progress is useful while running this explicit, relatively long audit.
      print(
          'Stage ${stage.number}: Lv.$recommended; actor range ${levels.values.reduce(min)}–$recommended; $simulations battles');
    }
    Directory('build').createSync(recursive: true);
    File('build/stage-recommendations.json')
        .writeAsStringSync(const JsonEncoder.withIndent('  ').convert({
      'simulations': simulations,
      'seedSearch': '0–11',
      'seedValidation': '1000–1039',
      'targetWinRate': .8,
      'framesPerSecond': 60,
      'strategy': 'attack whenever ready, skill whenever ready',
      'stages': report
    }));
  },
      timeout: const Timeout(Duration(minutes: 25)),
      skip: !const bool.fromEnvironment('CALIBRATE_STAGES'));
}

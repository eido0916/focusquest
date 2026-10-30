import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/config/game_balance.dart';
import 'package:focusquest/features/character/domain/character.dart';
import 'package:focusquest/features/character/domain/stats.dart';
import 'package:focusquest/features/character/domain/progression_service.dart';
import 'package:focusquest/features/diagnosis/presentation/job_portrait.dart';
import 'package:focusquest/features/focus/domain/focus_adventure.dart';
import 'package:focusquest/game/runner/battle_state_controller.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';

void main() {
  final hero = Character(
      id: 'balance',
      name: '勇者',
      characterType: 'warrior',
      baseStats: const Stats());
  final growth = ProgressionService();
  final report = <Map<String, Object>>[];

  test('30-minute growth remains modest for every original role and sex', () {
    for (final role in JobPortrait.roleNames.keys) {
      for (final sex in ['male', 'female']) {
        final battle = BattleStateController(
            durationSeconds: 1800,
            adventureStartSeconds: 0,
            config: PixelBattleAssets.runnerConfig(role, sex))
          ..advanceTo(1800);
        final result = growth.addExp(hero, battle.gainedExp);
        expect(battle.bossDefeatedCount, 1);
        expect(result.level, inInclusiveRange(3, 4), reason: '$role/$sex');
        expect(battle.gainedExp, battle.defeatedCount - 1 + 100);
        report.add({
          'role': role,
          'sex': sex,
          'minutes': 30,
          'normalDefeats': battle.defeatedCount - 1,
          'bosses': 1,
          'exp': battle.gainedExp,
          'level': result.level,
          'remainingExp': result.currentExp
        });
      }
    }
  });

  test('long sessions and party kills keep the same conservative curve', () {
    for (final minutes in [15, 60, 180]) {
      final battle = BattleStateController(
          durationSeconds: minutes * 60.0,
          adventureStartSeconds: 0,
          config: PixelBattleAssets.runnerConfig('warrior', 'male'))
        ..advanceTo(minutes * 60.0);
      final result = growth.addExp(hero, battle.gainedExp);
      expect(
          result.level,
          lessThanOrEqualTo(minutes == 15
              ? 3
              : minutes == 60
                  ? 6
                  : 12));
      report.add({
        'role': 'warrior',
        'sex': 'male',
        'minutes': minutes,
        'normalDefeats': battle.defeatedCount - battle.bossDefeatedCount,
        'bosses': battle.bossDefeatedCount,
        'exp': battle.gainedExp,
        'level': result.level
      });
    }
    for (var members = 1; members <= 4; members++) {
      final defeats = FocusAdventure.partyDefeats(
          1800, 1800, List.generate(members, (_) => [1.0, 1.0]));
      final exp = GameBalance.focusExpForDefeats(defeats, 1);
      final result = growth.addExp(hero, exp);
      expect(result.level, lessThanOrEqualTo(3));
      report.add({
        'partyMembers': members,
        'minutes': 30,
        'normalDefeats': defeats - 1,
        'bosses': 1,
        'exp': exp,
        'level': result.level
      });
    }
  });

  test('existing levels and EXP survive loading under the new curve', () {
    final saved = hero.copyWith(level: 25, currentExp: 600);
    final restored = Character.fromJson(saved.toJson());
    expect(growth.addExp(restored, 0).toJson(), saved.toJson());
    expect(growth.addExp(restored, 1).level, 25);
    expect(restored.requiredExp, 3900);
  });

  tearDownAll(() {
    if (const bool.fromEnvironment('CAPTURE_BALANCE')) {
      final file = File('build/focus-growth-balance.json');
      file.parent.createSync(recursive: true);
      file.writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(report));
    }
  });
}

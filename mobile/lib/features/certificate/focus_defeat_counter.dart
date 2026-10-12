import 'dart:convert';
import 'package:flutter/services.dart';
import '../../game/runner/battle_state_controller.dart';
import '../../game/runner/pixel_battle_assets.dart';
import '../character/domain/character.dart';
import '../focus/domain/focus_session.dart';
import '../focus/domain/focus_adventure.dart';

/// Recreates the same deterministic battle, including when its view was closed.
class FocusDefeatCounter {
  static Future<int> count(
      FocusSession session, Character hero, DateTime now) async {
    final elapsed =
        session.focusNow(now).difference(session.startedAt).inMilliseconds /
            1000;
    final duration = session.durationMinutes * 60.0;
    final time = elapsed.clamp(0.0, duration);
    if (session.partyMembers.isNotEmpty) {
      var defeats = 0;
      final durations = <String, List<double>>{};
      for (final member in session.partyMembers) {
        final character = PixelBattleAssets.characterFor(
            member.characterType, member.appearance);
        if (!durations.containsKey(character.id)) {
          final lengths = <double>[];
          for (final action in ['attack', 'skill']) {
            final json = jsonDecode(await rootBundle.loadString(
                    'assets/images/playable_stage/${character.id}_$action.json'))
                as Map<String, dynamic>;
            lengths
                .add((json['timeline'] as List).length / (json['fps'] as num));
          }
          durations[character.id] = lengths;
        }
      }
      for (var wave = 0; wave * 6 < time; wave++) {
        for (final member in session.partyMembers) {
          final character = PixelBattleAssets.characterFor(
              member.characterType, member.appearance);
          final hitAt = 2 + durations[character.id]![wave % 4 == 3 ? 1 : 0];
          if (time >= wave * 6 + hitAt &&
              !FocusAdventure.fightingBoss(
                  session.adventureStartSeconds + wave * 6 + hitAt)) defeats++;
        }
      }
      return defeats +
          FocusAdventure.cycle(session.adventureStartSeconds + time) -
          FocusAdventure.cycle(session.adventureStartSeconds.toDouble());
    }
    final battle = BattleStateController(
        adventureStartSeconds: session.adventureStartSeconds,
        focusAreaIndex: session.focusAreaIndex,
        config:
            PixelBattleAssets.runnerConfig(hero.characterType, hero.appearance),
        durationSeconds: duration);
    battle.advanceTo(time.toDouble());
    return battle.defeatedCount;
  }
}

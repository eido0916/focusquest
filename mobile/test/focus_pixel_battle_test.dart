import 'package:flame/game.dart';
import 'package:flame/cache.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/data/game_catalog.dart';
import 'package:focusquest/features/focus/domain/focus_session.dart';
import 'package:focusquest/features/party/domain/party_member.dart';
import 'package:focusquest/features/party/presentation/party_battle_page.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all sixteen roles select distinct originals in solo and party battles',
      () {
    expect(PixelBattleAssets.roles.keys.toSet(),
        GameCatalog.types.values.map((t) => t.typeId).toSet());
    final ids = <String>{};
    final now = DateTime(2026, 10, 12);
    final party = PartyBattleGame(
        session:
            FocusSession(id: 'identity', startedAt: now, durationMinutes: 30),
        clock: () => now,
        onFinished: () {});
    for (final type in GameCatalog.types.values.map((t) => t.typeId)) {
      for (final appearance in ['male', 'female']) {
        final hero = PixelBattleAssets.characterFor(type, appearance);
        expect(hero.role, PixelBattleAssets.roles[type]);
        expect(hero.female, appearance == 'female');
        ids.add(hero.id);
        expect(
            party.actorKey(PartyMember(
                id: type,
                name: type,
                characterType: type,
                appearance: appearance,
                level: 1)),
            '${appearance == 'female' ? 'players_female' : 'players'}/${hero.id}');
      }
    }
    expect(ids, PlayableCharacters.all.map((c) => c.id).toSet());
    for (final type in ['unknown']) {
      for (final appearance in ['male', 'female']) {
        expect(PixelBattleAssets.characterFor(type, appearance),
            same(PlayableCharacters.defaultCharacter));
        final config = PixelBattleAssets.runnerConfig(type, appearance);
        final fallback = PixelBattleAssets.runnerConfig('warrior', 'male');
        expect(config.sousenDurationSeconds, fallback.sousenDurationSeconds);
        expect(
            config.sousenDamageTimeSeconds, fallback.sousenDamageTimeSeconds);
        expect(config.normalHitTimes, fallback.normalHitTimes);
      }
    }
  });

  for (final type in PixelBattleAssets.roles.keys) {
    for (final appearance in ['male', 'female']) {
      test('$type $appearance loads complete originals and keeps event timing',
          () async {
        final game = FlameGame()..images = Images();
        addTearDown(game.images.clearCache);
        final assets = await PixelBattleAssets.load(game, type, appearance);
        final config = PixelBattleAssets.runnerConfig(type, appearance);
        final attack = assets.motions['attack']!;
        final skill = assets.motions['skill']!;
        expect(
            config.normalAttackDuration, closeTo(attack.duration * .8, 1e-7));
        expect(config.sousenDurationSeconds, closeTo(skill.duration, 1e-7));
        expect(config.normalHitTimes,
            attack.eventTicks(assets.character.attackEvent).map((t) => t / 30));
        expect(config.sousenDamageTimeSeconds,
            skill.eventTick(assets.character.skillEvent, -1) / 24);
        for (final motion in assets.motions.values) {
          expect(motion.metadata['interpolation'], 'none');
          expect(motion.metadata['direction'], 'right');
          for (var tick = 0; tick < motion.timeline.length; tick++) {
            final frame = motion.frame((tick + .01) / 24);
            expect(frame.image,
                same(motion.images[motion.timeline[tick]['keyframe'] as int]));
            expect(frame.image.width, 128);
            expect(frame.image.height, 128);
          }
          expect(motion.frame(motion.duration, loop: true).image,
              same(motion.frame(0).image));
        }
      });
    }
  }
}

import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all ten roles select the supplied male and female originals', () {
    for (final type in PixelBattleAssets.roles.keys) {
      for (final appearance in ['male', 'female']) {
        final hero = PixelBattleAssets.characterFor(type, appearance);
        expect(hero.role, PixelBattleAssets.roles[type]);
        expect(hero.female, appearance == 'female');
      }
    }
    for (final type in [
      'onmyoji',
      'reaper',
      'angel',
      'devil',
      'dragon_knight',
      'berserker',
      'unknown'
    ]) {
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
        final assets =
            await PixelBattleAssets.load(FlameGame(), type, appearance);
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

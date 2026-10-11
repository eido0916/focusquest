import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_character.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_assets.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'melee heroes approach while ranged attacks hold position, including original teleport offsets',
      () async {
    const stage = PlayableStageDefinition(
        1,
        '草原',
        'assets/images/playable_stage/grassland.png',
        .885,
        [StageOpponent('slime', 'スライム', 1000, 8, 100, '間合い検証')]);
    for (final hero in PlayableCharacters.all) {
      final assets =
          await PlayableStageAssets.load(stage: stage, character: hero);
      final battle =
          PlayableStageBattle(stage: stage, character: hero, roll: () => .5)
            ..start();
      final attack = assets.motions['hero_attack']!,
          skill = assets.motions['hero_skill']!;
      battle.attackHitFraction =
          attack.eventTick(hero.attackEvent, -1) / (24 * attack.duration);
      battle.skillHitFraction =
          skill.eventTick(hero.skillEvent, -1) / (24 * skill.duration);
      battle.actionOffsetPx = (isSkill, progress) {
        final motion = isSkill ? skill : attack;
        return motion.frame(progress * motion.duration).offset.dx;
      };
      advance(battle, 3);
      battle.target.wait = 100;
      var impacts = 0;
      var isSkill = false;
      final victim = battle.target;
      final subscription = battle.soundEvents.listen((sound) {
        if (sound != BattleSound.hit) return;
        impacts++;
        if (hero.projectileFor(isSkill) != null) {
          expect(battle.heroX, PlayableStageBattle.heroHomeX);
          return;
        }
        final enemy = victim;
        expect(enemy.x - battle.heroX - battle.heroPoseOffset,
            closeTo(battle.contactGap(enemy), 1),
            reason: hero.name);
        expect(battle.heroX + battle.heroPoseOffset,
            greaterThan(PlayableStageBattle.heroHomeX),
            reason: hero.name);
      });
      battle.attack();
      advance(battle, battle.attackDuration + .05);
      expect(battle.heroX, PlayableStageBattle.heroHomeX);
      battle.charge = 3;
      isSkill = true;
      battle.skill();
      advance(battle, battle.skillDuration + .05);
      expect(battle.heroX, PlayableStageBattle.heroHomeX);
      expect(impacts, 2, reason: hero.name);
      await subscription.cancel();
      battle.dispose();
      assets.dispose();
    }
  });
  test(
      'normal monsters and large bosses approach before damage and return home',
      () async {
    for (final boss in [false, true]) {
      final battle = PlayableStageBattle(
          stage: PlayableStageCatalog.stages[boss ? 3 : 0], roll: () => .5);
      if (boss) battle.phase = 2;
      battle.start();
      advance(battle, 3);
      final attacker = boss ? battle.enemies.last : battle.enemies.first;
      for (final enemy in battle.enemies) {
        enemy.wait = 100;
      }
      attacker.wait = 0;
      var impacts = 0;
      final subscription = battle.soundEvents.listen((sound) {
        if (sound != BattleSound.hurt) return;
        impacts++;
        expect(
            attacker.x - battle.heroX, closeTo(battle.contactGap(attacker), 1));
        expect(attacker.x, lessThan(attacker.homeX));
      });
      advance(battle, .3);
      battle.pause();
      final x = attacker.x;
      advance(battle, 10);
      expect(attacker.x, x);
      battle.resume();
      advance(battle, 1);
      expect(impacts, 1);
      expect(attacker.x, attacker.homeX);
      await subscription.cancel();
      battle.dispose();
    }
  });
  test(
      'simultaneous actions keep monsters on the right; a kill does not retarget motion',
      () async {
    final battle = PlayableStageBattle(roll: () => .5)..start();
    advance(battle, 3);
    final first = battle.target;
    first.hp = 1;
    first.wait = 0;
    battle.enemies[1].wait = 100;
    battle.attack();
    while (first.alive) {
      battle.update(1 / 120);
      expect(first.x, greaterThan(battle.heroX));
    }
    final impactX = battle.heroX;
    expect(battle.target, isNot(same(first)));
    expect(battle.actionTarget, same(first));
    advance(battle, .1);
    expect(battle.heroX, closeTo(impactX, 1));
    expect(battle.actionTarget, same(first));
    advance(battle, 1);
    expect(battle.heroX, PlayableStageBattle.heroHomeX);
    expect(battle.actionTarget, isNull);
    battle.dispose();
  });
}

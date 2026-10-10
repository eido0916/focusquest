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
  test('each wave has multiple enemies and bosses retain two escorts', () {
    for (final stage in PlayableStageCatalog.stages) {
      expect(stage.wave(0).length, 2);
      expect(stage.wave(1).length, 3);
      expect(stage.wave(2).length, 3);
      expect(stage.wave(2).where((unit) => unit.isBoss).length,
          stage.hasBoss ? 1 : 0);
    }
  });
  test('a defeated target plays once while other enemies keep fighting',
      () async {
    final battle = PlayableStageBattle(roll: () => .5)..start();
    final sounds = <BattleSound>[];
    final subscription = battle.soundEvents.listen(sounds.add);
    advance(battle, 3);
    final first = battle.target, second = battle.enemies[1];
    battle.attack();
    advance(battle, 1.1);
    battle.attack();
    advance(battle, 1.1);
    expect(first.hp, 0);
    expect(first.deathX, greaterThan(0));
    expect(second.hp, second.definition.hp);
    expect(battle.target, same(second));
    expect(battle.mode, StageMode.battle);
    expect(battle.cleared, 1);
    expect(sounds.where((sound) => sound == BattleSound.enemyDefeat).length, 1);
    final hp = battle.hp;
    advance(battle, 2);
    expect(battle.hp, lessThan(hp));
    expect(first.deathTime, greaterThan(first.defeatDuration));
    await subscription.cancel();
    battle.dispose();
  });
  test('speed changes action lock; power and health apply to combat and reset',
      () {
    final fast = PlayableStageBattle(
        character: PlayableCharacters.all[4], roll: () => .5)
      ..start();
    final slow = PlayableStageBattle(
        character: PlayableCharacters.all[3], roll: () => .5)
      ..start();
    advance(fast, 3);
    advance(slow, 3);
    expect(fast.hp, 120);
    expect(slow.hp, 250);
    fast.attack();
    slow.attack();
    advance(fast, .7);
    advance(slow, .7);
    expect(fast.canAttack, true);
    expect(slow.canAttack, false);
    expect(fast.enemies.first.hp, 56 - 20);
    advance(slow, 1.1);
    expect(slow.enemies.first.hp, 56 - 46);
    expect(slow.canAttack, true);
    slow.hp = 1;
    slow.restart();
    expect(slow.hp, 250);
    fast.dispose();
    slow.dispose();
  });
  test('all twenty heroes can clear stage 16 with attack and skill', () async {
    for (final hero in PlayableCharacters.all) {
      final battle = PlayableStageBattle(
          stage: PlayableStageCatalog.stages.last,
          character: hero,
          roll: () => .5)
        ..start();
      final assets = await PlayableStageAssets.load(
          stage: PlayableStageCatalog.stages.last, character: hero);
      final attack = assets.motions['hero_attack']!;
      final skill = assets.motions['hero_skill']!;
      battle.attackReleaseFractions = attack
          .eventTicks(hero.attackEvent)
          .map((tick) => tick / (24 * attack.duration))
          .toList();
      battle.skillReleaseFractions = skill
          .eventTicks(hero.skillEvent)
          .map((tick) => tick / (24 * skill.duration))
          .toList();
      for (var tick = 0; tick < 120 * 150 && battle.active; tick++) {
        if (battle.canSkill) {
          battle.skill();
        } else if (battle.canAttack) {
          battle.attack();
        }
        battle.update(1 / 120);
      }
      expect(battle.mode, StageMode.won, reason: hero.name);
      expect(battle.cleared, 8, reason: hero.name);
      battle.dispose();
      assets.dispose();
    }
  });
  test('every hero loads their own original animations and combat events',
      () async {
    for (final hero in PlayableCharacters.all) {
      final assets = await PlayableStageAssets.load(
          stage: PlayableStageCatalog.stages.first, character: hero);
      try {
        expect(assets.motions['hero_attack']!.metadata['asset'], hero.id);
        expect(assets.motions['hero_attack']!.eventTick(hero.attackEvent, -1),
            greaterThanOrEqualTo(0));
        expect(assets.motions['hero_skill']!.eventTick(hero.skillEvent, -1),
            greaterThanOrEqualTo(0));
        expect(assets.motions.containsKey('hero_run'), true);
        expect(assets.motions.containsKey('hero_idle'), true);
      } finally {
        assets.dispose();
      }
    }
  });
}

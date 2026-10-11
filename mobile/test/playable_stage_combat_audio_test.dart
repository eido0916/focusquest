import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_battle.dart';
import 'package:focusquest/features/playable_stage/domain/playable_stage_catalog.dart';
import 'package:focusquest/features/playable_stage/presentation/playable_stage_audio.dart';

void advance(PlayableStageBattle battle, double seconds) {
  for (var i = 0; i < (seconds * 120).ceil(); i++) {
    battle.update(1 / 120);
  }
}

class RecordingAudio implements StageAudioOutput {
  final musicCalls = <String>[];
  final sounds = <BattleSound>[];
  bool disposed = false;
  @override
  Future<void> music(String? track, {required bool paused}) async {
    musicCalls.add('$track:$paused');
  }

  @override
  Future<void> effect(BattleSound sound) async {
    sounds.add(sound);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  const singleStage = PlayableStageDefinition(
      1,
      '草原',
      'assets/images/playable_stage/grassland.png',
      .885,
      [StageOpponent('slime', 'スライム', 112, 8, 4.8, '判定テスト')]);
  test('a miss resolves once without damage or skill charge', () async {
    var rolls = 0;
    final battle = PlayableStageBattle(
        stage: singleStage,
        roll: () {
          rolls++;
          return .9;
        });
    final sounds = <BattleSound>[];
    final subscription = battle.soundEvents.listen(sounds.add);
    battle.start();
    advance(battle, 3);
    battle.attack();
    advance(battle, 1.1);
    expect(battle.enemyHp, 112);
    expect(battle.hits, 0);
    expect(battle.charge, 0);
    expect(battle.attempts, 1);
    expect(battle.misses, 1);
    expect(rolls, 1);
    expect(battle.damageNumbers.single.miss, true);
    expect(sounds, [BattleSound.swing, BattleSound.miss]);
    await subscription.cancel();
    battle.dispose();
  });
  test('critical normal attack doubles damage and adds one charge', () {
    final values = [.899, .199].iterator;
    final battle = PlayableStageBattle(
        stage: singleStage,
        roll: () {
          values.moveNext();
          return values.current;
        });
    battle.start();
    advance(battle, 3);
    battle.attack();
    advance(battle, 1.1);
    expect(battle.enemyHp, 56);
    expect(battle.charge, 1);
    expect(battle.criticals, 1);
    expect(battle.damageNumbers.single.critical, true);
    battle.dispose();
  });
  test('critical boundary is non-critical; skill ignores hit chance', () {
    final normal = PlayableStageBattle(stage: singleStage, roll: () => .2)
      ..start();
    advance(normal, 3);
    normal.attack();
    advance(normal, 1.1);
    expect(normal.enemyHp, 84);
    expect(normal.criticals, 0);
    normal.dispose();
    final skill = PlayableStageBattle(stage: singleStage, roll: () => .99)
      ..start();
    advance(skill, 3);
    skill.charge = 3;
    skill.skill();
    advance(skill, 1.4);
    expect(skill.enemyHp, 0);
    expect(skill.misses, 0);
    expect(skill.charge, 0);
    expect(skill.skills, 1);
    skill.reset();
    expect(skill.criticals, 0);
    expect(skill.attempts, 0);
    expect(skill.misses, 0);
    skill.dispose();
  });
  test('enemy miss and critical use separate probabilities', () {
    final miss = PlayableStageBattle(roll: () => .85)..start();
    advance(miss, 5.2);
    expect(miss.hp, 160);
    expect(miss.damageNumbers.single.miss, true);
    expect(miss.damageNumbers.single.toHero, true);
    miss.dispose();
    final values = [.849, .099].iterator;
    final critical = PlayableStageBattle(roll: () {
      values.moveNext();
      return values.current;
    })
      ..start();
    advance(critical, 5.2);
    expect(critical.hp, 148);
    expect(critical.damageNumbers.single.critical, true);
    critical.dispose();
  });
  test('music changes for bosses; pause, mute, exit and disposal stop playback',
      () async {
    final output = RecordingAudio();
    final battle = PlayableStageBattle(
        stage: PlayableStageCatalog.stages[3], roll: () => .5);
    final audio = PlayableStageAudio(battle, output: output);
    Future<void> flush() => Future<void>.delayed(Duration.zero);
    await flush();
    expect(output.musicCalls.last, 'null:false');
    battle.start();
    await flush();
    expect(output.musicCalls.last, 'battle:false');
    advance(battle, 3);
    battle.attack();
    await flush();
    expect(output.sounds.last, BattleSound.swing);
    advance(battle, 1.1);
    await flush();
    expect(output.sounds.last, BattleSound.hit);
    battle.pause();
    await flush();
    expect(output.musicCalls.last, 'battle:true');
    battle.resume();
    await flush();
    expect(output.musicCalls.last, 'battle:false');
    audio.toggle();
    await flush();
    expect(output.musicCalls.last, 'battle:true');
    final count = output.sounds.length;
    battle.attack();
    advance(battle, 1.1);
    await flush();
    expect(output.sounds.length, count);
    audio.toggle();
    await flush();
    while (battle.active) {
      if (battle.canSkill) {
        battle.skill();
      } else if (battle.canAttack) {
        battle.attack();
      }
      battle.update(1 / 120);
      await flush();
    }
    expect(output.musicCalls, contains('boss:false'));
    expect(output.musicCalls.last, 'null:false');
    expect(
        output.sounds.where((sound) => sound == BattleSound.victory).length, 1);
    await audio.close();
    expect(output.disposed, true);
    battle.dispose();
  });
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:focusquest/core/game_controller.dart';
import 'support/memory_repository.dart';
import 'package:focusquest/data/player_state.dart';
import 'package:focusquest/features/focus/presentation/focus_audio.dart';
import 'package:focusquest/game/runner/pixel_battle_assets.dart';

class RecordingFocusAudio implements FocusAudioOutput {
  final tracks = <String?>[];
  final effects = <String>[];
  int stops = 0;
  bool disposed = false;
  @override
  Future<void> music(String? track) async => tracks.add(track);
  @override
  Future<void> effect(String name) async => effects.add(name);
  @override
  Future<void> silenceEffects() async {
    stops++;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
      'all male and female attack releases have timings and bundled PCM sounds',
      () async {
    for (final role in PixelBattleAssets.roles.keys) {
      for (final appearance in ['male', 'female']) {
        final character = PixelBattleAssets.characterFor(role, appearance);
        for (final skill in [false, true]) {
          final action = skill ? 'skill' : 'attack';
          final metadata = jsonDecode(await rootBundle.loadString(
                  'assets/images/playable_stage/${character.id}_$action.json'))
              as Map<String, dynamic>;
          final times = focusSoundTimes(
              metadata, skill ? character.skillEvent : character.attackEvent);
          expect(times, isNotEmpty, reason: '${character.id}/$action');
          expect(
              times.every(
                  (t) => t >= 0 && t < (metadata['duration_seconds'] as num)),
              isTrue);
          final bytes = await rootBundle.load(
              'assets/audio/focus_adventure/${focusEffect(role, skill)}.wav');
          expect(ascii.decode(bytes.buffer.asUint8List(0, 4)), 'RIFF');
          expect(bytes.getUint16(22, Endian.little), 1);
          expect(bytes.getUint32(24, Endian.little), 44100);
        }
      }
    }
    final punches = focusSoundTimes({
      'duration_seconds': 1.25,
      'events': [
        {'event': 'jab', 'tick': 6},
        {'event': 'cross', 'tick': 11},
        {'event': 'hook', 'tick': 16},
      ]
    }, 'jab', playbackDuration: 1);
    expect(punches, hasLength(3));
    for (var i = 0; i < 3; i++) {
      expect(punches[i], closeTo([6 / 30, 11 / 30, 16 / 30][i], 1e-9));
    }
  });

  testWidgets('focus settings save BGM and SE independently', (tester) async {
    final repository = MemoryRepository();
    final controller = GameController(repository)..state = repository.state;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (context) => TextButton(
                    onPressed: () =>
                        showFocusSoundSettings(context, controller),
                    child: const Text('設定'))))));
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(SwitchListTile, 'BGM'));
    await tester.pumpAndSettle();
    expect(repository.state.bgmEnabled, isFalse);
    expect(repository.state.seEnabled, isTrue);
    await tester.tap(find.widgetWithText(SwitchListTile, 'SE（効果音）'));
    await tester.pumpAndSettle();
    expect(repository.state.seEnabled, isFalse);
    expect(repository.state.bgmEnabled, isFalse);
    expect(tester.takeException(), isNull);
    controller.dispose();
  });
  test(
      'old saves default to sound on; copy and JSON retain independent toggles',
      () {
    final old = PlayerState(uid: 'test').toJson()
      ..remove('bgmEnabled')
      ..remove('seEnabled');
    final state = PlayerState.fromJson(old);
    expect(state.bgmEnabled, isTrue);
    expect(state.seEnabled, isTrue);
    final restored = PlayerState.fromJson(
        state.copyWith(bgmEnabled: false).copyWith(coins: 4).toJson());
    expect(restored.bgmEnabled, isFalse);
    expect(restored.seEnabled, isTrue);
  });

  test('three shots sound once each, with no historical burst or resume burst',
      () async {
    final output = RecordingFocusAudio();
    final audio = FocusAudio(output: output);
    void frame(double time, double age) =>
        audio.update(time, boss: false, active: true, poses: [
          FocusSoundPose(
              'hero', 'gunner', 1, true, age, [7 / 24, 10 / 24, 13 / 24])
        ]);
    frame(0, 0);
    frame(.2, .2);
    frame(.3, .3);
    frame(.4, .4);
    frame(.5, .5);
    frame(.6, .6);
    frame(.61, .61);
    expect(output.effects, ['gun', 'gun', 'gun']);
    frame(50, .6);
    expect(output.effects, hasLength(3));
    audio.didChangeAppLifecycleState(AppLifecycleState.paused);
    audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
    frame(50.1, .6);
    expect(output.effects, hasLength(3));
    await audio.close();
    expect(output.disposed, isTrue);
  });

  test('BGM follows boss state; BGM and SE mute independently and stop on exit',
      () async {
    final controller = GameController(MemoryRepository());
    controller.state = PlayerState(uid: 'test');
    final output = RecordingFocusAudio();
    final audio = FocusAudio(controller: controller, output: output);
    void frame(double t, {bool boss = false, bool active = true}) =>
        audio.update(t, boss: boss, active: active, poses: [
          FocusSoundPose('hero', 'mage', (t * 10).floor(), false, .1, [.05])
        ]);
    frame(0);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, 'peaceful');
    frame(.1, boss: true);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, 'boss');
    await controller.setSoundSettings(bgm: false);
    frame(.2, boss: true);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, isNull);
    expect(output.effects, ['fire', 'fire']);
    await controller.setSoundSettings(bgm: true, se: false);
    frame(.3, boss: true);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, 'boss');
    expect(output.effects, hasLength(2));
    expect(output.stops, greaterThan(0));
    audio.didChangeAppLifecycleState(AppLifecycleState.inactive);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, isNull);
    audio.didChangeAppLifecycleState(AppLifecycleState.resumed);
    frame(.4, active: false);
    await Future<void>.delayed(Duration.zero);
    expect(output.tracks.last, isNull);
    await audio.close();
    controller.dispose();
  });

  test('every role has normal and skill SFX', () {
    const roles = [
      'warrior',
      'boxer',
      'samurai',
      'guardian',
      'ninja',
      'assassin',
      'ranger',
      'mage',
      'gunner',
      'spellblade',
      'onmyoji',
      'reaper',
      'angel',
      'devil',
      'dragon_knight',
      'berserker'
    ];
    for (final role in roles) {
      expect(focusEffect(role, false), isNotEmpty);
      expect(focusEffect(role, true), isNotEmpty);
    }
  });
}

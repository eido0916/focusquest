import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';

/// One sample per visible actor. Times come from the original animation events.
class FocusSoundPose {
  const FocusSoundPose(
      this.actor, this.role, this.sequence, this.skill, this.age, this.events);
  final String actor, role;
  final int sequence;
  final bool skill;
  final double age;
  final List<double> events;
}

String focusEffect(String role, bool skill) => switch (role) {
      'warrior' => skill ? 'sword_wave' : 'sword',
      'boxer' => skill ? 'kick' : 'punch',
      'samurai' => 'katana',
      'guardian' => 'heavy',
      'ninja' => skill ? 'dagger' : 'shuriken',
      'assassin' => skill ? 'critical_dagger' : 'dagger',
      'ranger' => 'bow',
      'mage' => skill ? 'ice' : 'fire',
      'gunner' => 'gun',
      'spellblade' => skill ? 'lightning' : 'sword',
      'onmyoji' => skill ? 'spirits' : 'talisman',
      'reaper' => 'scythe',
      'angel' => skill ? 'holy_sword' : 'holy',
      'devil' => skill ? 'curse' : 'dark',
      'dragon_knight' => skill ? 'dragon' : 'heavy',
      'berserker' => skill ? 'earth' : 'heavy',
      _ => 'sword',
    };

/// Include combo strikes as well as the primary release, without duplicating
/// combat bookkeeping events that occur at the same source tick.
List<double> focusSoundTimes(Map<String, dynamic> metadata, String event,
    {double playbackDuration = 0}) {
  final sourceDuration = (metadata['duration_seconds'] as num).toDouble();
  final scale = playbackDuration > 0 ? playbackDuration / sourceDuration : 1.0;
  final ticks = <double>{};
  for (final row in metadata['events'] as List) {
    final name = row['event'] as String;
    if (name == event ||
        (event == 'jab' && ['cross', 'hook'].contains(name)) ||
        (event == 'slash_1' && RegExp(r'^slash_[1-4]$').hasMatch(name))) {
      ticks.add((row['tick'] as num).toDouble() / 24 * scale);
    }
  }
  return ticks.toList()..sort();
}

abstract interface class FocusAudioOutput {
  Future<void> music(String? track);
  Future<void> effect(String name);
  Future<void> silenceEffects();
  Future<void> dispose();
}

class NativeFocusAudioOutput implements FocusAudioOutput {
  AudioPlayer? _music;
  final _players = <AudioPlayer>[];
  final _queues = List.generate(8, (_) => Future<void>.value());
  int _next = 0, _generation = 0;
  bool _closed = false;
  String? _track;
  static const base = 'audio/focus_adventure/';
  @override
  Future<void> music(String? track) async {
    if (_closed) return;
    if (track == null) {
      await _music?.stop();
      _track = null;
    } else if (_track != track) {
      final player = _music ??= AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('$base$track.wav'), volume: .25);
      _track = track;
    }
  }

  @override
  Future<void> effect(String name) {
    if (_closed) return Future.value();
    final index = _next++ % 8;
    while (_players.length <= index) {
      _players.add(AudioPlayer());
    }
    final generation = _generation;
    final task = _queues[index].then((_) async {
      if (_closed || generation != _generation) return;
      final player = _players[index];
      await player.stop();
      if (_closed || generation != _generation) return;
      await player.play(AssetSource('$base$name.wav'),
          volume: .45,
          ctx: AudioContext(
              android: const AudioContextAndroid(
                  audioFocus: AndroidAudioFocus.none)));
    });
    _queues[index] = task.catchError((Object _) {});
    return task;
  }

  @override
  Future<void> silenceEffects() async {
    _generation++;
    await Future.wait(_queues);
    await Future.wait(_players.map((p) => p.stop()));
  }

  @override
  Future<void> dispose() async {
    _closed = true;
    await silenceEffects();
    await Future.wait([
      if (_music != null) _music!.dispose(),
      ..._players.map((p) => p.dispose()),
    ]);
  }
}

class FocusAudio with WidgetsBindingObserver {
  FocusAudio({this.controller, FocusAudioOutput? output})
      : output = output ?? NativeFocusAudioOutput() {
    controller?.addListener(_sync);
    WidgetsBinding.instance.addObserver(this);
  }
  final GameController? controller;
  final FocusAudioOutput output;
  final _previous = <String, FocusSoundPose>{};
  Future<void> _queue = Future.value();
  double? _time;
  bool _boss = false, _active = false, _foreground = true, _closed = false;
  bool _effectsEnabled = true;
  String? _musicKey;
  bool get bgmEnabled => controller?.state?.bgmEnabled ?? true;
  bool get seEnabled => controller?.state?.seEnabled ?? true;
  Future<void> _guard(Future<void> Function() work) async {
    try {
      await work();
    } catch (error) {
      debugPrint('Focus adventure audio: $error');
    }
  }

  void _sync() {
    if (_closed) return;
    final audible = _active && _foreground;
    final track = audible && bgmEnabled ? (_boss ? 'boss' : 'peaceful') : null;
    if (_musicKey != track) {
      _musicKey = track;
      _queue = _queue.then((_) => _guard(() => output.music(_musicKey)));
    }
    final effects = audible && seEnabled;
    if (_effectsEnabled && !effects) {
      unawaited(_guard(output.silenceEffects));
    }
    _effectsEnabled = effects;
  }

  /// Skip historical events when reopening, resuming, or catching up the clock.
  void update(double time,
      {required bool boss,
      required bool active,
      required List<FocusSoundPose> poses}) {
    if (_closed) return;
    _boss = boss;
    _active = active;
    _sync();
    final continuous = _time != null && time >= _time! && time - _time! <= .25;
    for (final pose in poses) {
      final previous = _previous[pose.actor];
      final same =
          previous?.sequence == pose.sequence && previous?.skill == pose.skill;
      final from = same ? previous!.age : -0.000001;
      if (continuous && _effectsEnabled && (same || pose.age <= .25)) {
        for (final event in pose.events) {
          if (from < event && pose.age + 1e-7 >= event) {
            unawaited(_guard(
                () => output.effect(focusEffect(pose.role, pose.skill))));
          }
        }
      }
      _previous[pose.actor] = pose;
    }
    _time = time;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _time = null;
    _sync();
  }

  Future<void> close() async {
    _closed = true;
    controller?.removeListener(_sync);
    WidgetsBinding.instance.removeObserver(this);
    await _queue;
    await _guard(output.dispose);
  }
}

Future<void> showFocusSoundSettings(
        BuildContext context, GameController controller) =>
    showDialog<void>(
        context: context,
        builder: (context) => AnimatedBuilder(
            animation: controller,
            builder: (context, _) => AlertDialog(
                  title: const Text('サウンド設定'),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    SwitchListTile(
                        title: const Text('BGM'),
                        value: controller.state!.bgmEnabled,
                        onChanged: controller.busy
                            ? null
                            : (value) =>
                                _saveSound(context, controller, bgm: value)),
                    SwitchListTile(
                        title: const Text('SE（効果音）'),
                        value: controller.state!.seEnabled,
                        onChanged: controller.busy
                            ? null
                            : (value) =>
                                _saveSound(context, controller, se: value)),
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('閉じる'))
                  ],
                )));

Future<void> _saveSound(BuildContext context, GameController controller,
    {bool? bgm, bool? se}) async {
  try {
    await controller.setSoundSettings(bgm: bgm, se: se);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('サウンド設定を保存できませんでした。')));
    }
  }
}

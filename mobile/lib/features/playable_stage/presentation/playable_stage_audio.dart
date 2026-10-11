import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import '../domain/playable_stage_battle.dart';

abstract interface class StageAudioOutput {
  Future<void> music(String? track, {required bool paused});
  Future<void> effect(BattleSound sound);
  Future<void> dispose();
}

/// Caller-owned silent output is useful for tests and silent previews.
class SilentStageAudioOutput implements StageAudioOutput {
  @override
  Future<void> music(String? track, {required bool paused}) async {}
  @override
  Future<void> effect(BattleSound sound) async {}
  @override
  Future<void> dispose() async {}
}

class NativeStageAudioOutput implements StageAudioOutput {
  static const base = 'audio/playable_stage/';
  AudioPlayer? _bgm;
  String? _track;
  final _effects = <AudioPlayer>[];
  final _queues = List.generate(4, (_) => Future<void>.value());
  int _next = 0;
  bool _disposed = false, _silent = false;

  @override
  Future<void> music(String? track, {required bool paused}) async {
    if (_disposed) return;
    _silent = paused;
    if (paused) {
      await _bgm?.pause();
      await Future.wait(_effects.map((player) => player.stop()));
      return;
    }
    if (track == null) {
      await _bgm?.stop();
      _track = null;
      return;
    }
    final player = _bgm ??= AudioPlayer();
    if (_track != track) {
      await player.setReleaseMode(ReleaseMode.loop);
      await player.play(AssetSource('$base$track.wav'), volume: .26);
      _track = track;
    } else {
      await player.resume();
    }
  }

  @override
  Future<void> effect(BattleSound sound) {
    if (_disposed || _silent) return Future.value();
    while (_effects.length < 4) {
      _effects.add(AudioPlayer());
    }
    final index = _next++ % _effects.length;
    final player = _effects[index];
    final task = _queues[index].then((_) async {
      if (_disposed || _silent) return;
      await player.stop();
      if (_disposed || _silent) return;
      await player.play(AssetSource('$base${sound.name}.wav'),
          volume: .55,
          ctx: AudioContext(
              android: const AudioContextAndroid(
                  audioFocus: AndroidAudioFocus.none)));
    });
    // A failed sound must not poison this channel's subsequent playback.
    _queues[index] = task.catchError((Object _) {});
    return task;
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await Future.wait(_queues);
    await Future.wait([
      if (_bgm != null) _bgm!.dispose(),
      ..._effects.map((player) => player.dispose())
    ]);
  }
}

class PlayableStageAudio extends ChangeNotifier {
  PlayableStageAudio(this.battle, {StageAudioOutput? output})
      : _output = output ?? NativeStageAudioOutput() {
    battle.addListener(_sync);
    _subscription = battle.soundEvents.listen((sound) {
      if (enabled && !battle.paused && !_disposed) {
        unawaited(_guard(() => _output.effect(sound)));
      }
    });
    _sync();
  }
  final PlayableStageBattle battle;
  final StageAudioOutput _output;
  late final StreamSubscription<BattleSound> _subscription;
  bool enabled = true, available = true, _disposed = false;
  String? _key;
  Future<void> _queue = Future.value();

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error) {
      if (!_disposed && available) {
        available = false;
        enabled = false;
        debugPrint('FocusQuest audio unavailable: $error');
        _sync();
        notifyListeners();
      }
    }
  }

  void _sync() {
    if (_disposed) return;
    final track = battle.active ? (battle.isBoss ? 'boss' : 'battle') : null;
    final paused = battle.paused || !enabled;
    final key = '$track:$paused';
    if (_key == key) return;
    _key = key;
    _queue = _queue.then((_) async {
      if (_disposed || _key != key) return;
      await _guard(() => _output.music(track, paused: paused));
    });
  }

  void toggle() {
    if (!available || _disposed) return;
    enabled = !enabled;
    _sync();
    notifyListeners();
  }

  Future<void> close() async {
    if (_disposed) return;
    _disposed = true;
    battle.removeListener(_sync);
    await _subscription.cancel();
    await _queue;
    await _guard(_output.dispose);
    super.dispose();
  }
}

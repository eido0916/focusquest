/// Deterministic, one-shot timeline. IDs refer to the 45 source poses (1-based).
/// Holds use 24Hz ticks, not interpolated images. Safe even if dt skips release.
class ArcherAttackAnimationController {
  ArcherAttackAnimationController({
    required List<int> frameIds,
    required List<double> stepTimes,
    required List<String> phases,
    required this.releaseFrame,
  })  : frameIds = List.unmodifiable(frameIds),
        stepTimes = List.unmodifiable(stepTimes),
        phases = List.unmodifiable(phases) {
    if (frameIds.isEmpty ||
        frameIds.length != stepTimes.length ||
        phases.length != frameIds.length ||
        frameIds.where((id) => id == releaseFrame).length != 1 ||
        stepTimes.any((t) => !t.isFinite || t <= 0)) {
      throw ArgumentError('Invalid archer timeline');
    }
  }

  final List<int> frameIds;
  final List<double> stepTimes;
  final List<String> phases;
  final int releaseFrame;
  bool isPlaying = false;
  int _index = 0;
  double _frameAge = 0;
  bool _released = false;
  int get currentFrame => frameIds[_index];
  String get currentPhase => phases[_index];
  double get duration => stepTimes.fold(0, (sum, t) => sum + t);
  double get releaseTime => stepTimes
      .take(frameIds.indexOf(releaseFrame))
      .fold(0, (sum, t) => sum + t);

  bool play() {
    if (isPlaying) return false;
    _index = 0;
    _frameAge = 0;
    _released = false;
    isPlaying = true;
    return true;
  }

  /// Interruptions never emit a late arrow. The component resumes run itself.
  void cancel() => isPlaying = false;

  /// onAdvance is called before release so the muzzle is at the actual shot
  /// position. onRelease receives the remaining seconds of this update: use
  /// this to catch a newly spawned projectile up to the end of a long update.
  /// Returns time left after the attack, for the destination run/idle ticker.
  double update(
    double dt, {
    required void Function(double seconds, String phase) onAdvance,
    required void Function(double remainingSeconds) onRelease,
    void Function()? onComplete,
  }) {
    if (!dt.isFinite || dt < 0) throw ArgumentError.value(dt, 'dt');
    if (!isPlaying) return dt;
    var remaining = dt;
    while (isPlaying) {
      if (!_released && currentFrame == releaseFrame) {
        _released = true;
        onRelease(remaining);
        if (!isPlaying) return remaining;
      }
      final available = stepTimes[_index] - _frameAge;
      final slice = remaining < available ? remaining : available;
      onAdvance(slice, currentPhase);
      _frameAge += slice;
      remaining -= slice;
      if (_frameAge + 1e-10 < stepTimes[_index]) break;
      _frameAge = 0;
      if (_index + 1 == frameIds.length) {
        isPlaying = false;
        onComplete?.call();
        break;
      }
      _index++;
      // Continue at an exact boundary to emit release on frame entry,
      // including when the remaining dt is zero.
    }
    return remaining;
  }
}

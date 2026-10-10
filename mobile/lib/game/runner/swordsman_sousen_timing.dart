/// Shared runtime timing for Sousen's animation, impact and combat state.
/// Preserve the original opening run/approach, slash and extended afterglow.
class SwordsmanSousenTiming {
  static const stepTimes = <double>[
    .07, .07, .07, .07, .07, // Original opening run.
    .09, .09, .09, .09, .09, // Original approach / deceleration.
    .10, .10, .10, .10, .10,
    .09, .09, .09, .09, .09,
    .055, .055, .055, .12, .12,
    .18, .14, .14, .10, .10, // Existing afterglow stays unchanged.
    .07, .07, .07, .07, .07,
  ];
  static const durationSeconds = 3.165;
  static const damageTimeSeconds = 1.860; // Start of frame 23.
  // Frame 24 is the downward follow-through, after the horizontal slash pose.
  static const groundWaveTimeSeconds = damageTimeSeconds + .055;
}

enum FocusStatus { active, succeeded, cancelled, failed }

enum FocusVerification { timerOnly, usageStats }

class FocusSession {
  const FocusSession(
      {required this.id,
      required this.startedAt,
      required this.durationMinutes,
      this.status = FocusStatus.active,
      this.verification = FocusVerification.timerOnly,
      this.targetPackages = const []});
  final String id;
  final DateTime startedAt;
  final int durationMinutes;
  final FocusStatus status;
  final FocusVerification verification;
  final List<String> targetPackages;
  DateTime get endsAt => startedAt.add(Duration(minutes: durationMinutes));
  Duration remaining(DateTime now) {
    final difference = endsAt.difference(now);
    return difference.isNegative ? Duration.zero : difference;
  }

  FocusSession finish(FocusStatus value) => FocusSession(
      id: id,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      status: value,
      verification: verification,
      targetPackages: targetPackages);
  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': status.name,
        'verification': verification.name,
        'targetPackages': targetPackages
      };
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: FocusStatus.values.byName(json['status'] as String),
      verification:
          FocusVerification.values.byName(json['verification'] as String),
      targetPackages: List<String>.from(json['targetPackages'] as List));
}

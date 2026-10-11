import '../../party/domain/party_member.dart';

enum FocusStatus { active, succeeded, cancelled, failed }

enum FocusVerification { timerOnly, usageStats }

class FocusSession {
  const FocusSession(
      {required this.id,
      required this.startedAt,
      required this.durationMinutes,
      this.status = FocusStatus.active,
      this.verification = FocusVerification.timerOnly,
      this.targetPackages = const [],
      this.partyMembers = const [],
      this.partyClockOffsetMs = 0});
  final List<PartyMember> partyMembers;
  final int partyClockOffsetMs;
  DateTime focusNow(DateTime now) =>
      now.add(Duration(milliseconds: partyClockOffsetMs));
  final String id;
  final DateTime startedAt;
  final int durationMinutes;
  final FocusStatus status;
  final FocusVerification verification;
  final List<String> targetPackages;
  DateTime get endsAt => startedAt.add(Duration(minutes: durationMinutes));
  // Android UsageStats and the native warning service use the device clock.
  FocusSession get deviceClockSession => partyClockOffsetMs == 0
      ? this
      : FocusSession(
          id: id,
          startedAt:
              startedAt.subtract(Duration(milliseconds: partyClockOffsetMs)),
          durationMinutes: durationMinutes,
          status: status,
          verification: verification,
          targetPackages: targetPackages,
          partyMembers: partyMembers);
  Duration remaining(DateTime now) {
    final difference = endsAt.difference(focusNow(now));
    if (difference > Duration(minutes: durationMinutes)) {
      return Duration(minutes: durationMinutes);
    }
    return difference.isNegative ? Duration.zero : difference;
  }

  FocusSession finish(FocusStatus value) => FocusSession(
      id: id,
      startedAt: startedAt,
      durationMinutes: durationMinutes,
      status: value,
      verification: verification,
      targetPackages: targetPackages,
      partyMembers: partyMembers,
      partyClockOffsetMs: partyClockOffsetMs);
  Map<String, dynamic> toJson() => {
        'id': id,
        'startedAt': startedAt.toUtc().toIso8601String(),
        'durationMinutes': durationMinutes,
        'status': status.name,
        'verification': verification.name,
        'targetPackages': targetPackages,
        'partyMembers': partyMembers.map((m) => m.toJson()).toList(),
        'partyClockOffsetMs': partyClockOffsetMs
      };
  factory FocusSession.fromJson(Map<String, dynamic> json) => FocusSession(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      durationMinutes: json['durationMinutes'] as int,
      status: FocusStatus.values.byName(json['status'] as String),
      verification:
          FocusVerification.values.byName(json['verification'] as String),
      targetPackages: List<String>.from(json['targetPackages'] as List),
      partyClockOffsetMs: json['partyClockOffsetMs'] as int? ?? 0,
      partyMembers: (json['partyMembers'] as List? ?? [])
          .map((m) => PartyMember.fromJson(Map<String, dynamic>.from(m as Map)))
          .toList());
}

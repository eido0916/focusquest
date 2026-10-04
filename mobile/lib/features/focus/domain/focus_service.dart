import '../../../core/config/game_balance.dart';
import 'focus_session.dart';

class FocusService {
  FocusSession start(
      {required String id,
      required DateTime now,
      required int minutes,
      bool monitored = false,
      List<String> targetPackages = const []}) {
    if (minutes < 1 || minutes > GameBalance.maximumFocusMinutes) {
      throw ArgumentError('集中時間は1〜180分です。');
    }
    if (monitored && targetPackages.isEmpty) {
      throw ArgumentError('対象アプリを選択してください。');
    }
    return FocusSession(
        id: id,
        startedAt: now,
        durationMinutes: minutes,
        verification: monitored
            ? FocusVerification.usageStats
            : FocusVerification.timerOnly,
        targetPackages: List.unmodifiable(targetPackages));
  }

  FocusStatus evaluate(FocusSession session, DateTime now,
      {bool targetUsed = false, bool usageEvidenceAvailable = false}) {
    if (session.status != FocusStatus.active) return session.status;
    if (now.isBefore(session.startedAt)) return FocusStatus.failed;
    if (session.verification == FocusVerification.usageStats &&
        (targetUsed || !usageEvidenceAvailable)) return FocusStatus.failed;
    return now.isBefore(session.endsAt)
        ? FocusStatus.active
        : FocusStatus.succeeded;
  }
}

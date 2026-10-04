import 'focus_session.dart';

class FocusSummary {
  const FocusSummary(
      {required this.todayMinutes,
      required this.totalMinutes,
      required this.streak,
      required this.longestStreak,
      required this.days});
  final int todayMinutes;
  final int totalMinutes;
  final int streak;
  final int longestStreak;
  final Set<DateTime> days;
}

class StreakService {
  // UTC calendar labels prevent daylight saving changes from changing day gaps.
  DateTime day(DateTime time) {
    final local = time.toLocal();
    return DateTime.utc(local.year, local.month, local.day);
  }

  FocusSummary summarize(Iterable<FocusSession> sessions, DateTime now) {
    final today = day(now);
    final unique = <String, FocusSession>{};
    for (final s in sessions) {
      if (s.status == FocusStatus.succeeded && !s.endsAt.isAfter(now)) {
        unique[s.id] = s;
      }
    }
    final days = unique.values.map((s) => day(s.endsAt)).toSet();
    final sorted = days.toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? previous;
    for (final date in sorted) {
      run = previous != null && date.difference(previous).inDays == 1
          ? run + 1
          : 1;
      if (run > longest) longest = run;
      previous = date;
    }
    var cursor =
        days.contains(today) ? today : today.subtract(const Duration(days: 1));
    var streak = 0;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return FocusSummary(
        todayMinutes: unique.values
            .where((s) => day(s.endsAt) == today)
            .fold(0, (sum, s) => sum + s.durationMinutes),
        totalMinutes:
            unique.values.fold(0, (sum, s) => sum + s.durationMinutes),
        streak: streak,
        longestStreak: longest,
        days: days);
  }
}

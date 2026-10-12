import '../../data/player_state.dart';
import '../focus/domain/streak_service.dart';
import 'certificate_catalog.dart';

class CertificateData {
  const CertificateData(
      {required this.role,
      required this.gender,
      required this.name,
      required this.level,
      required this.focusMinutes,
      required this.defeats,
      required this.days,
      required this.stages,
      required this.number,
      required this.issuedAt});
  final String role, gender, name, number;
  final int level, focusMinutes, defeats, days, stages;
  final DateTime? issuedAt;
  String get title => CertificateCatalog.title(role, level);

  factory CertificateData.fromState(PlayerState state, DateTime now) {
    final hero = state.activeCharacter!;
    final summary = StreakService().summarize(state.sessions.values, now);
    final first = state.firstPlayedAt?.toLocal();
    final today = DateTime.utc(now.year, now.month, now.day);
    final firstDay =
        first == null ? null : DateTime.utc(first.year, first.month, first.day);
    return CertificateData(
        role: hero.characterType,
        gender: hero.appearance,
        name: hero.name,
        level: hero.level,
        focusMinutes: summary.totalMinutes,
        defeats: state.totalDefeats,
        days: firstDay == null
            ? summary.days.length
            : (today.difference(firstDay).inDays + 1).clamp(0, 1000000),
        stages: state.clearedPlayableStages.length,
        number: state.adventurerNumber ?? '未登録',
        issuedAt: first);
  }
}

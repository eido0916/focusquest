import '../../character/domain/stats.dart';

class DiagnosisQuestion {
  const DiagnosisQuestion(this.id, this.text, this.axis,
      {this.reversed = false,
      this.optionA = '',
      this.optionB = '',
      this.weight = 1});
  final String id;
  final String text;
  final int axis;
  final bool reversed;
  final String optionA;
  final String optionB;
  final int weight;
}

class PersonalityType {
  const PersonalityType(
      {required this.typeId,
      required this.name,
      required this.description,
      required this.job,
      required this.stats,
      required this.assetKey,
      required this.traits});
  final String typeId;
  final String name;
  final String description;
  final String job;
  final Stats stats;
  final String assetKey;
  final List<String> traits;
}

class DiagnosisService {
  const DiagnosisService(
      {required this.questions, required this.types, this.axes = 4});
  final List<DiagnosisQuestion> questions;
  final Map<int, PersonalityType> types;
  final int axes;
  PersonalityType evaluate(Map<String, int> answers) {
    final scores = List.filled(axes, 0);
    for (final question in questions) {
      final value = answers[question.id];
      if (value == null || (value != 1 && value != 2)) {
        throw ArgumentError('すべての質問でAまたはBを選んでください。');
      }
      scores[question.axis] += (value == 1 ? 1 : -1) *
          question.weight *
          (question.reversed ? -1 : 1);
    }
    var mask = 0;
    for (var axis = 0; axis < axes; axis++) {
      if (scores[axis] > 0) mask |= 1 << axis;
    }
    final result = types[mask];
    if (result == null) throw StateError('診断タイプ $mask が未設定です。');
    return result;
  }
}

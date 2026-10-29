/// Training points are separate from combat stats. One focused minute earns 10 points.
class FocusTask {
  FocusTask(
      {required String title,
      required Map<String, int> allocation,
      this.allocationSource,
      this.reason,
      this.model,
      this.rubricVersion})
      : title = title.trim(),
        allocation = Map.unmodifiable(allocation) {
    if (this.title.isEmpty || this.title.runes.length > 80) {
      throw ArgumentError('タスク名は1〜80文字で入力してください。');
    }
    if (allocation.keys.any((key) => !parameters.containsKey(key)) ||
        allocation.values.any((value) => value < 0 || value > 10) ||
        allocation.values.fold(0, (a, b) => a + b) != 10) {
      throw ArgumentError('配分の合計を10にしてください。');
    }
  }
  static const parameters = {
    'knowledge': '知識',
    'creativity': '創造力',
    'discipline': '継続力',
    'vitality': '体力',
    'insight': '洞察力',
    'empathy': '共感力',
  };
  final String? allocationSource, reason, model;
  final int? rubricVersion;
  bool get isAiAssessed =>
      ['gemini', 'openai'].contains(allocationSource) &&
      (reason?.trim().isNotEmpty ?? false) &&
      rubricVersion == 1;
  final String title;
  final Map<String, int> allocation;
  Map<String, int> gains(int minutes) => {
        for (final e in allocation.entries)
          if (e.value > 0) e.key: e.value * minutes,
      };
  Map<String, dynamic> toJson() => {
        'title': title,
        'allocation': allocation,
        'allocationSource': allocationSource,
        'reason': reason,
        'model': model,
        'rubricVersion': rubricVersion
      };
  factory FocusTask.fromJson(Map<String, dynamic> json) => FocusTask(
      allocationSource: json['allocationSource'] as String?,
      reason: json['reason'] as String?,
      model: json['model'] as String?,
      rubricVersion: json['rubricVersion'] as int?,
      title: json['title'] as String,
      allocation: Map<String, int>.from(json['allocation'] as Map));
}

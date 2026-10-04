import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../domain/diagnosis_service.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key, required this.onComplete});
  final Future<void> Function(PersonalityType) onComplete;
  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _answers = <String, int>{};
  int _step = -1;
  bool _busy = false;
  bool _tutorial = false;
  String? _error;
  PersonalityType? _result;
  @override
  Widget build(BuildContext context) {
    final question = _step >= 0 && _step < GameCatalog.questions.length
        ? GameCatalog.questions[_step]
        : null;
    return Scaffold(
        appBar: AppBar(title: const Text('冒険のはじまり')),
        body: SafeArea(
          child: ListView(padding: const EdgeInsets.all(24), children: [
            if (_step == -1) ...[
              Text('集中を、あなたの力に。',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              const Text(
                  'スマホを置いて過ごした時間で、仲間が成長します。\n集中 → 報酬 → 育成 → 冒険 → 新しい仲間。\nまずは4つの質問から、最初の職業を見つけましょう。'),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () => setState(() => _step = 0),
                  child: const Text('性格診断をはじめる')),
            ] else if (question != null) ...[
              LinearProgressIndicator(
                  value: (_step + 1) / GameCatalog.questions.length),
              const SizedBox(height: 24),
              Text('質問 ${_step + 1} / ${GameCatalog.questions.length}'),
              const SizedBox(height: 16),
              Text(question.text,
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 24),
              for (var i = 1; i <= 5; i++)
                RadioListTile<int>(
                    value: i,
                    groupValue: _answers[question.id],
                    title: Text([
                      '全く当てはまらない',
                      'あまり当てはまらない',
                      'どちらでもない',
                      'やや当てはまる',
                      'とても当てはまる'
                    ][i - 1]),
                    onChanged: (value) =>
                        setState(() => _answers[question.id] = value!)),
              FilledButton(
                  onPressed: _answers.containsKey(question.id)
                      ? () => setState(() {
                            _step++;
                            if (_step == GameCatalog.questions.length) {
                              _result = const DiagnosisService(
                                      questions: GameCatalog.questions,
                                      types: GameCatalog.types)
                                  .evaluate(_answers);
                            }
                          })
                      : null,
                  child: Text(_step == GameCatalog.questions.length - 1
                      ? '診断結果を見る'
                      : '次へ')),
              if (_step > 0)
                TextButton(
                    onPressed: () => setState(() => _step--),
                    child: const Text('前の質問')),
            ] else if (!_tutorial) ...[
              const Icon(Icons.auto_awesome, size: 80),
              Text(_result!.name,
                  style: Theme.of(context).textTheme.headlineMedium),
              Text(_result!.description),
              const SizedBox(height: 24),
              Text('最初の職業：${_result!.job}'),
              Text('特性：${_result!.traits.join('・')}'),
              const SizedBox(height: 24),
              FilledButton(
                  onPressed: () => setState(() => _tutorial = true),
                  child: const Text('この仲間と進む')),
            ] else ...[
              Text('最初のクエスト',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 24),
              const Text(
                  '1. ホームで集中時間を選ぶ\n\n2. スマホを置いて、自分の時間に集中する\n\n3. 報酬でレベルアップし、冒険や召喚へ\n\nあなたのペースで、物語を進めましょう。'),
              const SizedBox(height: 24),
              if (_error != null) Text(_error!),
              FilledButton(
                  onPressed: _busy
                      ? null
                      : () async {
                          setState(() {
                            _busy = true;
                            _error = null;
                          });
                          try {
                            await widget.onComplete(_result!);
                          } catch (_) {
                            if (mounted) {
                              setState(() =>
                                  _error = '保存できませんでした。接続を確認して再試行してください。');
                            }
                          } finally {
                            if (mounted) setState(() => _busy = false);
                          }
                        },
                  child: Text(_busy ? '保存中…' : '冒険をはじめる')),
            ],
          ]),
        ));
  }
}

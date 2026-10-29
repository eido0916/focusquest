import 'package:flutter/material.dart';
import '../domain/focus_task.dart';
import '../data/task_ai_service.dart';

Future<FocusTask?> chooseFocusTask(BuildContext context,
        {FocusTask? initial,
        int minutes = 30,
        List<FocusTask> recent = const [],
        TaskAiService? ai}) =>
    showDialog<FocusTask>(
        context: context,
        builder: (_) => _TaskDialog(
            initial: initial,
            minutes: minutes,
            recent: recent,
            ai: ai ?? TaskAiService()));

class _TaskDialog extends StatefulWidget {
  const _TaskDialog(
      {this.initial,
      required this.minutes,
      required this.recent,
      required this.ai});
  final FocusTask? initial;
  final int minutes;
  final List<FocusTask> recent;
  final TaskAiService ai;
  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController title;
  FocusTask? result;
  bool assessing = false;
  String? error;
  @override
  void initState() {
    super.initState();
    title = TextEditingController(text: widget.initial?.title);
    result = widget.initial?.isAiAssessed == true ? widget.initial : null;
    title.addListener(_edited);
  }

  void _edited() => setState(() {
        result = null;
        error = null;
      });
  @override
  void dispose() {
    title.removeListener(_edited);
    title.dispose();
    super.dispose();
  }

  Future<void> _assess() async {
    setState(() {
      assessing = true;
      error = null;
      result = null;
    });
    try {
      final task = await widget.ai.assess(title.text);
      if (mounted) setState(() => result = task);
    } on TaskAiException catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) setState(() => error = 'AI判定に失敗しました。再試行してください。');
    } finally {
      if (mounted) setState(() => assessing = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
          title: const Text('取り組むタスクを入力'),
          content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    TextField(
                        controller: title,
                        enabled: !assessing,
                        maxLength: 80,
                        minLines: 1,
                        maxLines: 3,
                        decoration: const InputDecoration(
                            labelText: '取り組むタスク',
                            hintText: '例：英語の長文を読み、要点をまとめる')),
                    if (widget.recent.isNotEmpty)
                      Wrap(spacing: 6, children: [
                        for (final task in widget.recent.take(5))
                          ActionChip(
                              label: SizedBox(
                                  width: 160,
                                  child: Text(task.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis)),
                              onPressed: assessing
                                  ? null
                                  : () => title.text = task.title),
                      ]),
                    const Text('タスクの内容からAIが成長ポイントの配分を決めます。'),
                    const SizedBox(height: 8),
                    const Text('入力したタスクをGoogle Geminiへ送信して判定します。'),
                    const SizedBox(height: 12),
                    if (assessing)
                      const Column(children: [
                        LinearProgressIndicator(),
                        SizedBox(height: 8),
                        Text('AIがタスクの内容を確認しています…')
                      ]),
                    if (result != null) ...[
                      Text('AIの判定理由：${result!.reason}'),
                      const SizedBox(height: 12),
                      for (final e in FocusTask.parameters.entries)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Row(children: [
                              Expanded(child: Text(e.value)),
                              Text(
                                  '+${(result!.allocation[e.key] ?? 0) * widget.minutes}pt'),
                            ])),
                      Text(
                          '${widget.minutes}分の集中成功で合計${widget.minutes * 10}pt'),
                      const Text('途中終了・失敗では加算されません。'),
                    ],
                    if (error != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(error!,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.error))),
                  ]))),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル')),
            if (result == null)
              FilledButton(
                  onPressed: assessing ? null : _assess,
                  child: Text(error == null ? 'AIで配分を決める' : 'AI判定を再試行'))
            else
              FilledButton(
                  onPressed: () => Navigator.pop(context, result),
                  child: const Text('このタスクに設定')),
          ]);
}

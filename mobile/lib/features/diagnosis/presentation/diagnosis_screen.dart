import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../domain/diagnosis_service.dart';
import 'job_portrait.dart';
import 'king_intro_scene.dart';

class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key, required this.onComplete});
  final Future<void> Function(PersonalityType, String, String) onComplete;
  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen> {
  final _answers = <String, int>{};
  final _name = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _scroll = ScrollController();
  int _step = -1;
  String? _appearance;
  bool _busy = false;
  String? _error;
  PersonalityType? _result;
  @override
  void dispose() {
    _name.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _go(int step) {
    setState(() {
      _step = step;
      _error = null;
    });
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  Future<void> _begin() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onComplete(_result!, _name.text.trim(), _appearance!);
    } catch (_) {
      if (mounted) setState(() => _error = '冒険の記録を保存できませんでした。もう一度お試しください。');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_step == -1) return KingIntroScene(onTouchStone: () => _go(0));
    final base = Theme.of(context);
    final theme = base.copyWith(
      scaffoldBackgroundColor: const Color(0xff080c18),
      colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          onPrimary: Colors.black,
          surface: Color(0xff080c18),
          onSurface: Colors.white),
      textTheme: base.textTheme
          .apply(bodyColor: Colors.white, displayColor: Colors.white),
      inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Color(0xff121a30),
          border:
              OutlineInputBorder(borderSide: BorderSide(color: Colors.white))),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.white)),
      radioTheme:
          RadioThemeData(fillColor: WidgetStateProperty.all(Colors.white)),
    );
    final questions = _step == 1 || _step == 2
        ? GameCatalog.questions.sublist((_step - 1) * 5, _step * 5)
        : <DiagnosisQuestion>[];
    final complete = questions.every((q) => _answers.containsKey(q.id));
    return Theme(
        data: theme,
        child: Scaffold(
            body: SafeArea(
                child: Center(
                    child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
              controller: _scroll,
              padding: const EdgeInsets.all(20),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    const Text('冒 険 の は じ ま り',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 14,
                            color: Color(0xffc5cbe0),
                            letterSpacing: 3)),
                    const SizedBox(height: 24),
                    if (_step == 0) ...[
                      const _Window(
                          title: '不思議な声',
                          child: Text('まばゆい光の中から、声が響く。\n\n「そなたの名と、望む姿を教えておくれ。」',
                              style: TextStyle(height: 1.9, fontSize: 17))),
                      const SizedBox(height: 24),
                      _Window(
                          title: '冒険者の登録',
                          child: Form(
                              key: _form,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('あなたの名前'),
                                    const SizedBox(height: 12),
                                    TextFormField(
                                        controller: _name,
                                        key: const Key('adventurer-name'),
                                        maxLength: 16,
                                        textInputAction: TextInputAction.done,
                                        decoration: const InputDecoration(
                                            hintText: '名前を入力してください'),
                                        validator: (value) => value == null ||
                                                value.trim().isEmpty
                                            ? '名前を入力してください。'
                                            : null),
                                    const SizedBox(height: 20),
                                    const Text('見た目の希望'),
                                    const SizedBox(height: 8),
                                    for (final entry
                                        in {'male': '男', 'female': '女'}.entries)
                                      RadioListTile<String>(
                                          key: Key('appearance-${entry.key}'),
                                          contentPadding: EdgeInsets.zero,
                                          value: entry.key,
                                          groupValue: _appearance,
                                          title: Text(entry.value),
                                          onChanged: (value) => setState(
                                              () => _appearance = value)),
                                    if (_error != null)
                                      Text(_error!,
                                          style: const TextStyle(
                                              color: Color(0xffffb4ab))),
                                  ]))),
                      const SizedBox(height: 20),
                      _Command(
                          label: '石の問いに答える',
                          onPressed: () {
                            final valid = _form.currentState!.validate();
                            if (_appearance == null) {
                              setState(() => _error = '見た目を選んでください。');
                            }
                            if (valid && _appearance != null) {
                              FocusScope.of(context).unfocus();
                              _go(1);
                            }
                          }),
                    ] else if (_step == 1 || _step == 2) ...[
                      _Window(
                          title: '魂への問い  $_step / 2',
                          child: Text(
                              '「${_name.text.trim()}よ。そなたに近い答えを選ぶがよい。」\n\nQ${_step == 1 ? '1〜5' : '6〜10'}  ／  全10問',
                              style: const TextStyle(height: 1.8))),
                      const SizedBox(height: 12),
                      Text('${_answers.length} / 10 回答済み',
                          textAlign: TextAlign.right,
                          style: const TextStyle(color: Color(0xffc5cbe0))),
                      for (final q in questions) ...[
                        const SizedBox(height: 22),
                        _Window(
                            title: q.id.toUpperCase(),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(q.text,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          height: 1.6)),
                                  const SizedBox(height: 12),
                                  for (var i = 1; i <= 2; i++)
                                    RadioListTile<int>(
                                        key: Key('${q.id}-$i'),
                                        contentPadding: EdgeInsets.zero,
                                        value: i,
                                        groupValue: _answers[q.id],
                                        title: Text(
                                            '${i == 1 ? 'A' : 'B'}  ${i == 1 ? q.optionA : q.optionB}',
                                            style:
                                                const TextStyle(height: 1.6)),
                                        onChanged: (value) => setState(
                                            () => _answers[q.id] = value!)),
                                ])),
                      ],
                      const SizedBox(height: 24),
                      if (!complete)
                        const Text('5つの問いすべてに答えると、先へ進めます。',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Color(0xffc5cbe0))),
                      const SizedBox(height: 12),
                      _Command(
                          label: _step == 1 ? '次の5問へ' : '診断結果を見る',
                          onPressed: !complete
                              ? null
                              : () {
                                  if (_step == 1) {
                                    _go(2);
                                  } else {
                                    _result = const DiagnosisService(
                                            questions: GameCatalog.questions,
                                            types: GameCatalog.types)
                                        .evaluate(_answers);
                                    _go(3);
                                  }
                                }),
                      TextButton(
                          onPressed: () => _go(_step - 1),
                          child: Text(_step == 1 ? '名前・見た目に戻る' : '前の5問に戻る')),
                    ] else ...[
                      const _Window(
                          title: '魔法石',
                          child: Text('「そなたの魂が示す道は、ここにある。」',
                              style: TextStyle(height: 1.8, fontSize: 17))),
                      const SizedBox(height: 24),
                      _Window(
                          title: '診断結果',
                          child: Column(children: [
                            Text(_name.text.trim(),
                                style: const TextStyle(
                                    fontSize: 16, color: Color(0xffc5cbe0))),
                            JobPortrait(
                                typeId: _result!.typeId,
                                appearance: _appearance!),
                            Text(_result!.job,
                                style: const TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 3)),
                            const SizedBox(height: 16),
                            Text(_result!.name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 18,
                                    color: Color(0xffefcf7d),
                                    height: 1.6)),
                            const SizedBox(height: 24),
                            const Align(
                                alignment: Alignment.centerLeft,
                                child: Text('性格・強み',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold))),
                            const SizedBox(height: 10),
                            Text(_result!.description,
                                style:
                                    const TextStyle(height: 1.9, fontSize: 16)),
                            const SizedBox(height: 14),
                            Text(_result!.traits.join(' ・ '),
                                style:
                                    const TextStyle(color: Color(0xffc5cbe0))),
                          ])),
                      const SizedBox(height: 24),
                      const _Window(
                          title: '旅立ちの手引き',
                          child: Text(
                              '集中する時間が、あなたの冒険になる。\n\nホームで集中時間を選ぶと、冒険が始まります。\n報酬を集めて、成長・装備へ。',
                              style: TextStyle(height: 1.8))),
                      const SizedBox(height: 20),
                      if (_error != null)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(_error!,
                                style:
                                    const TextStyle(color: Color(0xffffb4ab)))),
                      _Command(
                          label: _busy ? '冒険の記録を保存中…' : '冒険に進む',
                          onPressed: _busy ? null : _begin),
                      TextButton(
                          onPressed: _busy ? null : () => _go(2),
                          child: const Text('答えを見直す')),
                    ],
                    const SizedBox(height: 24),
                  ])),
        )))));
  }
}

class _Window extends StatelessWidget {
  const _Window({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      Stack(clipBehavior: Clip.none, children: [
        Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 26, 18, 18),
            decoration: BoxDecoration(
                color: const Color(0xff080c18),
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(4)),
            child: child),
        Positioned(
            top: -10,
            left: 16,
            child: Container(
                color: const Color(0xff080c18),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(title,
                    style: const TextStyle(
                        color: Colors.white, letterSpacing: 1)))),
      ]);
}

class _Command extends StatelessWidget {
  const _Command({required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => OutlinedButton(
        style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            disabledForegroundColor: Colors.white38,
            side: BorderSide(
                color: onPressed == null ? Colors.white30 : Colors.white,
                width: 2),
            minimumSize: const Size(double.infinity, 56),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
        onPressed: onPressed,
        child: Text('▶  $label',
            style: const TextStyle(fontSize: 17, letterSpacing: 1)),
      );
}

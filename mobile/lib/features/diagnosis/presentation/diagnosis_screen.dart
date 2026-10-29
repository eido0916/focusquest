import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../domain/diagnosis_service.dart';
import 'job_reveal_screen.dart';
import 'king_intro_scene.dart';
import 'sanctuary_widgets.dart';

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
  int _questionIndex = 0;
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
    if (_step == 0) return _identity();
    if (_step == 1) return _question();
    return JobRevealScreen(
      result: _result!,
      code: const DiagnosisService(
              questions: GameCatalog.questions, types: GameCatalog.types)
          .codeFor(_result!),
      name: _name.text.trim(),
      appearance: _appearance!,
      scroll: _scroll,
      busy: _busy,
      error: _error,
      onBegin: _begin,
      onReview: () => _go(1),
    );
  }

  Widget _identity() => SanctuaryShell(scroll: _scroll, children: [
        const SanctuaryHeader(),
        const Center(
            child: SanctuaryFrame(
                asset: 'title-plaque',
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                child: Text('STEP  1 / 2',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontFamily: 'SunlitSerif')))),
        const SizedBox(height: 12),
        const Stack(
            fit: StackFit.passthrough,
            clipBehavior: Clip.none,
            children: [
              SanctuaryFrame(
                  padding: EdgeInsets.fromLTRB(24, 30, 24, 24),
                  child: Text('まばゆい光の中から、声が響く。\n「そなたの名と、望む姿を教えておくれ。」',
                      style: TextStyle(
                          fontSize: 16,
                          height: 1.9,
                          fontWeight: FontWeight.w600))),
              Positioned(
                  top: -7,
                  left: 12,
                  child: SanctuaryFrame(
                      asset: 'title-plaque',
                      padding:
                          EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                      child: Text('不思議な声',
                          style:
                              TextStyle(color: Colors.white, fontSize: 13)))),
            ]),
        const SizedBox(height: 16),
        Stack(alignment: Alignment.topCenter, children: [
          Padding(
              padding: const EdgeInsets.only(top: 16),
              child: SanctuaryFrame(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 22),
                  child: Form(
                      key: _form,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const _SanctuaryLabel('あなたの名前'),
                            const SizedBox(height: 8),
                            SanctuaryFrame(
                                blue: true,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 3),
                                child: TextFormField(
                                    controller: _name,
                                    key: const Key('adventurer-name'),
                                    maxLength: 16,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontFamily: 'SunlitSerif'),
                                    buildCounter: (_,
                                            {required currentLength,
                                            required isFocused,
                                            maxLength}) =>
                                        null,
                                    onChanged: (_) => setState(() {}),
                                    decoration: const InputDecoration(
                                        hintText: '名前を入力してください',
                                        hintStyle: TextStyle(
                                            color: Color(0xffa7bde2),
                                            fontSize: 16),
                                        filled: false,
                                        border: InputBorder.none,
                                        enabledBorder: InputBorder.none,
                                        focusedBorder: InputBorder.none,
                                        errorBorder: InputBorder.none,
                                        focusedErrorBorder: InputBorder.none,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 12)),
                                    validator: (value) =>
                                        value == null || value.trim().isEmpty
                                            ? '名前を入力してください。'
                                            : null)),
                            Align(
                                alignment: Alignment.centerRight,
                                child: Text(
                                    '${_name.text.characters.length}/16',
                                    style: const TextStyle(fontSize: 13))),
                            const SizedBox(height: 12),
                            const _SanctuaryLabel('見た目の希望'),
                            const SizedBox(height: 8),
                            Row(children: [
                              Expanded(
                                  child: SanctuaryChoice(
                                      key: const Key('appearance-male'),
                                      label: '男',
                                      compact: true,
                                      selected: _appearance == 'male',
                                      onTap: () => setState(
                                          () => _appearance = 'male'))),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: SanctuaryChoice(
                                      key: const Key('appearance-female'),
                                      label: '女',
                                      compact: true,
                                      purple: true,
                                      selected: _appearance == 'female',
                                      onTap: () => setState(
                                          () => _appearance = 'female'))),
                            ]),
                            if (_error != null)
                              Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(_error!,
                                      style: const TextStyle(
                                          color: Color(0xff9c2837)))),
                          ])))),
          const FractionallySizedBox(
              widthFactor: .67,
              child: SanctuaryFrame(
                  asset: 'title-plaque',
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text('冒険者の登録',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          letterSpacing: 2)))),
        ]),
        const SizedBox(height: 16),
        SanctuaryCommand(
            label: '石の問いに答える',
            onPressed: () {
              final valid = _form.currentState!.validate();
              if (_appearance == null) setState(() => _error = '見た目を選んでください。');
              if (valid && _appearance != null) {
                FocusScope.of(context).unfocus();
                _go(1);
              }
            }),
      ]);

  Widget _question() {
    final q = GameCatalog.questions[_questionIndex];
    return SanctuaryShell(scroll: _scroll, children: [
      const SanctuaryHeader(),
      SanctuaryFrame(
          child: Text(
              'まばゆい光の中から、声が響く。\n「${_name.text.trim()}よ。そなたに近い答えを選ぶがよい。」',
              style: const TextStyle(
                  fontSize: 16, height: 1.9, fontWeight: FontWeight.w600))),
      const SizedBox(height: 12),
      SanctuaryProgress(
          index: _questionIndex, count: GameCatalog.questions.length),
      const SizedBox(height: 16),
      Stack(alignment: Alignment.topCenter, children: [
        Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SanctuaryFrame(
                padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
                child: Center(
                    child: Text(q.text,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18,
                            height: 1.65,
                            fontWeight: FontWeight.w600))))),
        SanctuaryBadge(label: q.id.toUpperCase()),
      ]),
      const SizedBox(height: 12),
      for (var i = 1; i <= 2; i++) ...[
        SanctuaryChoice(
            key: Key('${q.id}-$i'),
            label: (i == 1 ? q.optionA : q.optionB).replaceFirst('、', '、\n'),
            letter: i == 1 ? 'A' : 'B',
            purple: i == 2,
            selected: _answers[q.id] == i,
            onTap: () => setState(() => _answers[q.id] = i)),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      SanctuaryCommand(
          label: _questionIndex == GameCatalog.questions.length - 1
              ? '診断結果を見る'
              : 'この答えで進む',
          onPressed: !_answers.containsKey(q.id)
              ? null
              : () {
                  if (_questionIndex < GameCatalog.questions.length - 1) {
                    setState(() => _questionIndex++);
                    _go(1);
                  } else {
                    _result = const DiagnosisService(
                            questions: GameCatalog.questions,
                            types: GameCatalog.types)
                        .evaluate(_answers);
                    _go(3);
                  }
                }),
      TextButton(
          style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              textStyle:
                  const TextStyle(fontSize: 16, fontFamily: 'SunlitSerif')),
          onPressed: () {
            if (_questionIndex == 0) {
              _go(0);
            } else {
              setState(() => _questionIndex--);
              _go(1);
            }
          },
          child: Text(_questionIndex == 0 ? '名前・見た目に戻る' : '前の問いに戻る')),
    ]);
  }
}

class _SanctuaryLabel extends StatelessWidget {
  const _SanctuaryLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Row(children: [
        Image.asset('$sanctuaryAssets/compass.png',
            width: 24, height: 24, excludeFromSemantics: true),
        const SizedBox(width: 8),
        Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: sanctuaryGold)),
      ]);
}

import 'package:flutter/material.dart';
import '../../../data/game_catalog.dart';
import '../domain/diagnosis_service.dart';
import 'job_portrait.dart';
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
                    ...[
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
                              '集中する時間が、あなたの冒険になる。\n\nホームで集中時間を選ぶと、冒険が始まります。\n集中で経験値を獲得し、冒険者を育てよう。',
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
                          onPressed: _busy ? null : () => _go(1),
                          child: const Text('答えを見直す')),
                    ],
                    const SizedBox(height: 24),
                  ])),
        )))));
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

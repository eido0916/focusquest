import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/game_balance.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../domain/focus_session.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, required this.controller});
  final GameController controller;
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late final Timer _ticker;
  final _custom = TextEditingController();
  int _minutes = 30;
  bool _settling = false;
  bool _automaticFailed = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void dispose() {
    _ticker.cancel();
    _custom.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted) return;
    setState(() {});
    final session = widget.controller.activeFocus;
    if (session != null &&
        session.remaining(widget.controller.clock()) == Duration.zero &&
        !_settling &&
        !_automaticFailed &&
        !widget.controller.busy) {
      _finish();
    }
  }

  Future<void> _finish({bool cancel = false}) async {
    if (_settling) return;
    setState(() {
      _settling = true;
      _error = null;
    });
    try {
      final result = await widget.controller.finishFocus(cancel: cancel);
      if (mounted && result != null) {
        final succeeded = result.status == FocusStatus.succeeded;
        await showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
                    title: Text(succeeded
                        ? '集中クエスト達成！'
                        : cancel
                            ? '集中を中断しました'
                            : '集中クエスト未達成'),
                    content: Text(succeeded
                        ? '${result.durationMinutes}分の冒険の準備ができました。\nEXP +${result.durationMinutes * 10}\nポイント +${result.durationMinutes * 100 ~/ 30}\n冒険進行 +${result.durationMinutes}\n獲得アイテムはキャラクター画面で確認できます。'
                        : cancel
                            ? '報酬はありません。また次の集中で挑戦しましょう。'
                            : '対象アプリの使用、または使用状況を確認できなかったため、報酬はありません。'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'))
                    ]));
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _automaticFailed = true;
          _error = '結果を保存できませんでした。再試行してください。';
        });
      }
    } finally {
      if (mounted) setState(() => _settling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final session = controller.activeFocus;
    final seconds = session?.remaining(controller.clock()).inSeconds ?? 0;
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
          child: QuestBackdrop(
              child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                  children: [
                const SizedBox(height: 100),
                QuestCard(
                    caption: session == null ? '旅の支度' : '集中の時間',
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (session == null) ...[
                            const Text('どのくらい集中しますか？',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            Wrap(spacing: 12, children: [
                              for (final minutes in GameBalance.focusPresets)
                                ChoiceChip(
                                    label: Text('$minutes分'),
                                    selected: _minutes == minutes,
                                    onSelected: (_) => setState(() {
                                          _minutes = minutes;
                                          _custom.clear();
                                        }))
                            ]),
                            const SizedBox(height: 16),
                            TextField(
                                controller: _custom,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                    labelText: 'カスタム（1〜180分）'),
                                onChanged: (value) => setState(
                                    () => _minutes = int.tryParse(value) ?? 0)),
                            const SizedBox(height: 24),
                            Text(controller.state!.monitoring
                                ? '選択したアプリの使用を確認します。'
                                : 'タイマーのみ：他のアプリの使用は確認しません。設定から確認機能を有効にできます。'),
                            const SizedBox(height: 24),
                            FilledButton(
                                onPressed: controller.busy ||
                                        _minutes < 1 ||
                                        _minutes > 180
                                    ? null
                                    : () => runAction(context, () async {
                                          await controller.startFocus(_minutes);
                                          if (mounted) {
                                            setState(() {
                                              _automaticFailed = false;
                                            });
                                          }
                                        }),
                                child: const Text('集中を開始')),
                          ] else ...[
                            const SizedBox(height: 32),
                            const SizedBox(height: 32),
                            Text(
                                '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                                textAlign: TextAlign.center,
                                style:
                                    Theme.of(context).textTheme.displayLarge),
                            const SizedBox(height: 24),
                            LinearProgressIndicator(
                                value: (1 -
                                        seconds /
                                            (session.durationMinutes * 60))
                                    .clamp(0, 1)),
                            const SizedBox(height: 24),
                            const Text(
                                '画面を消して、自分の時間に集中しましょう。終了後にアプリへ戻ると結果を確認できます。'),
                            const SizedBox(height: 24),
                            Text(session.verification ==
                                    FocusVerification.usageStats
                                ? '対象アプリの使用を確認する集中'
                                : 'タイマーのみの集中'),
                            if (_error != null) ...[
                              Text(_error!),
                              FilledButton(
                                  onPressed: _settling ? null : () => _finish(),
                                  child: const Text('結果の保存を再試行'))
                            ],
                            TextButton(
                                onPressed: _settling || controller.busy
                                    ? null
                                    : () async {
                                        final confirmed = await showDialog<
                                                bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                                    title: const Text(
                                                        '集中を中断しますか？'),
                                                    content: const Text(
                                                        '途中終了では報酬を獲得できません。'),
                                                    actions: [
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  false),
                                                          child: const Text(
                                                              '続ける')),
                                                      TextButton(
                                                          onPressed: () =>
                                                              Navigator.pop(
                                                                  context,
                                                                  true),
                                                          child: const Text(
                                                              '中断する'))
                                                    ]));
                                        if (confirmed == true && mounted) {
                                          await _finish(cancel: true);
                                        }
                                      },
                                child: const Text('集中を中断')),
                          ],
                        ])),
              ])),
        ));
  }
}

import '../../../core/widgets/game_ui.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/config/game_balance.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../core/widgets/role_logo.dart';
import '../domain/focus_session.dart';
import '../domain/focus_adventure.dart';
import 'battle_replay_page.dart';
import '../../party/presentation/party_page.dart';
import '../../party/presentation/party_battle_page.dart';
import '../../character/presentation/character_screen.dart';
import '../../settings/settings_screen.dart';
import '../../adventure/presentation/adventure_screen.dart';
import 'focus_selection_scene.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({super.key, required this.controller, this.onNavigate});
  final GameController controller;
  final ValueChanged<int>? onNavigate;
  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late final Timer _ticker;
  final _custom = TextEditingController();
  int _minutes = 30;
  bool _settling = false;
  bool _automaticFailed = false;
  bool _battleOpen = false;
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
        !_battleOpen &&
        !_automaticFailed &&
        (ModalRoute.of(context)?.isCurrent ?? false) &&
        !widget.controller.busy) {
      _finish();
    }
  }

  Future<void> _openBattle() async {
    final session = widget.controller.activeFocus;
    if (session == null || _battleOpen || _settling) return;
    setState(() => _battleOpen = true);
    try {
      await Navigator.of(context).push(MaterialPageRoute<void>(
          builder: (_) => session.partyMembers.isNotEmpty
              ? PartyBattlePage(
                  session: session,
                  clock: widget.controller.clock,
                  party: widget.controller.party)
              : BattleReplayPage(
                  characterName:
                      widget.controller.state?.activeCharacter?.name ?? '冒険者',
                  appearance:
                      widget.controller.state?.activeCharacter?.appearance ??
                          'male',
                  heroLevel:
                      widget.controller.state?.activeCharacter?.level ?? 1,
                  characterType:
                      widget.controller.state?.activeCharacter?.characterType ??
                          'warrior',
                  session: session,
                  clock: widget.controller.clock)));
    } finally {
      if (mounted) {
        setState(() => _battleOpen = false);
        _tick();
      }
    }
  }

  Future<void> _openParty() async {
    final previous = widget.controller.activeFocus?.id;
    await Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PartyPage(controller: widget.controller)));
    if (mounted &&
        widget.controller.activeFocus != null &&
        widget.controller.activeFocus!.id != previous) {
      _automaticFailed = false;
      await _openBattle();
    }
  }

  Future<void> _startFocus() async {
    final controller = widget.controller;
    final permissions = await controller.monitor.guardPermissions();
    if (!mounted) return;
    if (permissions != null && permissions.values.any((allowed) => !allowed)) {
      final usageMissing = permissions['usage'] != true;
      final openSettings = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
                title: const Text('アプリ警告の許可'),
                content: Text(usageMissing
                    ? '集中中に他のアプリを開くと警告します。まずAndroid設定でFocus Questの「使用状況へのアクセス」を許可してください。設定から戻って、もう一度「集中を開始」を押してください。'
                    : '警告を表示するため、Android設定でFocus Questの「他のアプリの上に表示」を許可してください。設定から戻って、もう一度「集中を開始」を押してください。'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('キャンセル')),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('設定を開く')),
                ],
              ));
      if (openSettings == true) {
        if (usageMissing) {
          await controller.monitor.requestAccess();
        } else {
          await controller.monitor.requestOverlay();
        }
      }
      return;
    }
    await controller.startFocus(_minutes);
    if (mounted) {
      setState(() => _automaticFailed = false);
      await _openBattle();
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
                        ? '${result.durationMinutes}分の集中を達成しました。\nEXP +${result.durationMinutes * GameBalance.expPerMinute}\n育てた力で、冒険に挑戦しましょう。'
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
    if (session == null) {
      final character = controller.state!.activeCharacter!;
      return FocusSelectionScene(
        typeId: character.characterType,
        characterName: character.name,
        level: character.level,
        appearance: character.appearance,
        minutes: _minutes,
        stage: FocusAdventure.chapter(
            controller.state!.focusAdventureSeconds.toDouble()),
        partyConnected: controller.party.connected,
        message: controller.partyStartError ?? controller.party.error,
        onMinutes: (minutes) => setState(() {
          _minutes = minutes;
          _custom.clear();
        }),
        onCustom: _chooseCustomTime,
        onParty: controller.busy || _settling ? null : _openParty,
        onStart: controller.busy ||
                controller.party.connected ||
                _minutes < 1 ||
                _minutes > 180
            ? null
            : () => runAction(context, _startFocus),
        onNavigate: (tab) {
          if (widget.onNavigate != null) {
            widget.onNavigate!(tab);
          } else if (tab == 0) {
            Navigator.of(context).maybePop();
          } else {
            final page = switch (tab) {
              1 => CharacterScreen(controller: controller),
              2 => AdventureScreen(controller: controller),
              _ => SettingsScreen(controller: controller),
            };
            Navigator.of(context).push(MaterialPageRoute<void>(
                builder: (_) => Scaffold(body: SafeArea(child: page))));
          }
        },
        onBack: () => Navigator.of(context).maybePop(),
      );
    }
    return Scaffold(
        extendBodyBehindAppBar: true,
        appBar:
            const GameAppBar(backgroundColor: Colors.transparent, elevation: 0),
        body: SafeArea(
            child: QuestBackdrop(
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 64, 20, 24),
                    children: [
              Row(children: [
                RoleLogo(
                    role: controller.state!.activeCharacter!.characterType,
                    size: 44),
                const SizedBox(width: 10),
                Expanded(child: Text(controller.state!.activeCharacter!.name)),
                Text('Lv. ${controller.state!.activeCharacter!.level}'),
              ]),
              const SizedBox(height: 12),
              QuestActionButton(
                  label: controller.party.connected ? 'パーティーを見る' : 'パーティを組む',
                  icon: Icons.groups_rounded,
                  onTap: controller.busy ||
                          _settling ||
                          !controller.party.connected
                      ? null
                      : _openParty),
              if (session.partyMembers.isNotEmpty)
                Text(
                    '${session.partyMembers.length}人で集中中 · 敵も${session.partyMembers.length}体ずつ出現'),
              if (controller.partyStartError != null)
                Text(controller.partyStartError!),
              if (controller.party.error != null) Text(controller.party.error!),
              QuestCard(
                  caption:
                      '第${FocusAdventure.chapter(session.adventureStartSeconds + session.durationMinutes * 60 - seconds.toDouble())}章 · 集中クエスト進行中',
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextButton(
                            onPressed: controller.busy || _settling
                                ? null
                                : _openBattle,
                            child: const Text('戦いの様子を見る')),
                        const Text(
                            '集中25分でボス出現。さらに5分で撃破し、草原から第二章の幽霊船へ進みます。短い集中でも達成した時間を引き継ぎます。'),
                        const SizedBox(height: 32),
                        Text(
                            '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.displayLarge),
                        const SizedBox(height: 24),
                        LinearProgressIndicator(
                            value:
                                (1 - seconds / (session.durationMinutes * 60))
                                    .clamp(0, 1)),
                        const SizedBox(height: 24),
                        const Text(
                            '画面を消して、自分の時間に集中しましょう。終了後にアプリへ戻ると結果を確認できます。'),
                        const SizedBox(height: 24),
                        Text(session.verification ==
                                FocusVerification.usageStats
                            ? '対象アプリの使用を確認する集中'
                            : '他のアプリを開くと警告します。1分の許可は選んだアプリだけに適用され、時間が切れると再び警告します。集中タイマーは進み続けます。'),
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
                                    final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                                title: const Text('集中を中断しますか？'),
                                                content: const Text(
                                                    '途中終了では報酬を獲得できません。'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child: const Text('続ける')),
                                                  TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text('中断する'))
                                                ]));
                                    if (confirmed == true && mounted) {
                                      await _finish(cancel: true);
                                    }
                                  },
                            child: const Text('集中を中断')),
                      ])),
            ]))));
  }

  Future<void> _chooseCustomTime() async {
    _custom.text = '$_minutes';
    final result = await showDialog<int>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final value = int.tryParse(_custom.text);
              final valid = value != null && value >= 1 && value <= 180;
              return AlertDialog(
                title: const Text('カスタム時間'),
                content: TextField(
                    controller: _custom,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        labelText: '1〜180分',
                        errorText: valid ? null : '1〜180の整数を入力してください'),
                    onChanged: (_) => update(() {}),
                    onSubmitted: (_) {
                      if (valid) Navigator.pop(context, value);
                    }),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('キャンセル')),
                  FilledButton(
                      onPressed:
                          valid ? () => Navigator.pop(context, value) : null,
                      child: const Text('決定')),
                ],
              );
            }));
    if (mounted && result != null) setState(() => _minutes = result);
  }
}

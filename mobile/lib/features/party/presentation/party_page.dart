import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/game_controller.dart';
import 'party_lobby_art.dart';
import '../../focus/domain/focus_adventure.dart';

class PartyPage extends StatefulWidget {
  const PartyPage({super.key, required this.controller});
  final GameController controller;
  @override
  State<PartyPage> createState() => _PartyPageState();
}

class _PartyPageState extends State<PartyPage> {
  final _code = TextEditingController();
  String? _error, _initialSessionId;
  bool _working = false, _returning = false;
  int _minutes = 30;
  @override
  void initState() {
    super.initState();
    _minutes = widget.controller.party.minutes;
    _initialSessionId = widget.controller.activeFocus?.id;
    widget.controller.addListener(_changed);
  }

  void _changed() {
    if (!mounted) return;
    setState(() {});
    final focus = widget.controller.activeFocus;
    if (!_returning && focus != null && focus.id != _initialSessionId) {
      _returning = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && (ModalRoute.of(context)?.isCurrent ?? false)) {
          Navigator.pop(context);
        }
      });
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _code.dispose();
    super.dispose();
  }

  Future<void> _act(Future<void> Function() action) async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _copyCode() async {
    final code = widget.controller.party.code;
    if (code == null) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('コードをコピーしました')));
    }
  }

  Future<void> _join() async {
    _code.text = widget.controller.party.code ?? '';
    final submit = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(builder: (context, update) {
              final valid = RegExp(r'^[A-Z2-9]{6}$')
                  .hasMatch(_code.text.trim().toUpperCase());
              return AlertDialog(
                  backgroundColor: const Color(0xff0b2340),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: lobbyGold)),
                  title: const Text('パーティーコード', style: lobbyTitle),
                  content: TextField(
                      key: const Key('party-code-input'),
                      controller: _code,
                      autofocus: true,
                      maxLength: 6,
                      style: lobbyTitle.copyWith(letterSpacing: 5),
                      textCapitalization: TextCapitalization.characters,
                      autocorrect: false,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp('[a-zA-Z2-9]')),
                        TextInputFormatter.withFunction((oldValue, newValue) =>
                            newValue.copyWith(text: newValue.text.toUpperCase()))
                      ],
                      onChanged: (_) => update(() {}),
                      onSubmitted: (_) {
                        if (valid) Navigator.pop(context, true);
                      },
                      decoration: const InputDecoration(
                          hintText: '6文字のコード', helperText: 'リーダーから届いたコードを入力')),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('キャンセル')),
                    TextButton(
                        onPressed:
                            valid ? () => Navigator.pop(context, true) : null,
                        key: const Key('party-join-submit'),
                        child: const Text('参加する')),
                  ]);
            }));
    if (submit == true && mounted) {
      await _act(() => widget.controller.party.connect(
          url: widget.controller.party.serverUrl,
          member: widget.controller.partyIdentity,
          joinCode: _code.text));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;
    final party = controller.party;
    final started = party.session != null;
    final enabled = !_working && !party.connecting && !controller.busy;
    final canConnect = enabled;
    final canCreate = enabled && controller.activeFocus == null;
    final minutes = party.connected ? party.minutes : _minutes;
    return Scaffold(
        backgroundColor: const Color(0xff0b2340),
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/party_lobby_v001/castle_valley.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x000b2340), Color(0x220b2340)]))),
          SafeArea(
              child: Column(children: [
            const SizedBox(height: 18),
            LobbyPanel(
                asset: 'header',
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(children: [
                  IconButton(
                      tooltip: '戻る',
                      onPressed: () => Navigator.maybePop(context),
                      icon: const Icon(Icons.arrow_back,
                          color: lobbyWhite, size: 28)),
                  const Expanded(
                      child: Text('パーティーを組む',
                          textAlign: TextAlign.center, style: lobbyTitle)),
                  const SizedBox(width: 48),
                ])),
            Expanded(child: LayoutBuilder(builder: (context, constraints) {
              final width = constraints.maxWidth.clamp(0.0, 620.0);
              return SingleChildScrollView(
                  key: const Key('party-lobby-list'),
                  padding: EdgeInsets.fromLTRB(
                      (constraints.maxWidth - width) / 2 + 16,
                      24,
                      (constraints.maxWidth - width) / 2 + 16,
                      24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (!party.connected) ...[
                          SizedBox(
                              height: (constraints.maxHeight * .22)
                                  .clamp(36.0, 170.0)),
                          LobbyAction(
                              key: const Key('party-create'),
                              label: 'パーティーを作成',
                              icon: Icons.group_add_outlined,
                              onTap: canCreate
                                  ? () => _act(() async {
                                        await party.connect(
                                            url: party.serverUrl,
                                            member: controller.partyIdentity);
                                        if (_minutes != party.minutes) {
                                          party.setMinutes(_minutes);
                                        }
                                      })
                                  : null),
                          const SizedBox(height: 24),
                          LobbyAction(
                              key: const Key('party-join'),
                              label: 'コードで参加',
                              icon: Icons.login,
                              onTap: canConnect ? _join : null),
                          const SizedBox(height: 20),
                          LobbyPanel(
                              child: Text('最大4人で、同じ時間に集中。\nコードを共有して仲間を招待しましょう。',
                                  textAlign: TextAlign.center,
                                  style: lobbyBody.copyWith(height: 1.8))),
                        ] else ...[
                          LobbyPanel(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                const Text('パーティーコード', style: lobbyBody),
                                const SizedBox(height: 10),
                                Row(children: [
                                  const LobbyCompass(size: 38),
                                  const SizedBox(width: 10),
                                  Expanded(
                                      child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: SelectableText(party.code!,
                                              style: lobbyTitle.copyWith(
                                                  fontSize: 32,
                                                  letterSpacing: 5)))),
                                  IconButton(
                                      tooltip: 'コードをコピー',
                                      onPressed: _copyCode,
                                      icon: const Icon(Icons.copy,
                                          color: lobbyWhite)),
                                ])
                              ])),
                          const SizedBox(height: 20),
                          Row(children: [
                            Text('${party.members.length} / 4人',
                                style: lobbyTitle.copyWith(fontSize: 22)),
                            const SizedBox(width: 16),
                            const Expanded(child: Divider(color: lobbyGold)),
                            const Icon(Icons.auto_awesome,
                                color: lobbyGold, size: 16)
                          ]),
                          const SizedBox(height: 10),
                          LayoutBuilder(builder: (context, size) {
                            final columns = size.maxWidth < 340 ||
                                    MediaQuery.textScalerOf(context).scale(12) >
                                        15
                                ? 2
                                : 4;
                            return Wrap(spacing: 8, runSpacing: 12, children: [
                              for (var i = 0; i < 4; i++)
                                SizedBox(
                                    width: (size.maxWidth - (columns - 1) * 8) /
                                        columns,
                                    child: LobbyMemberCard(
                                        key: Key('party-slot-$i'),
                                        member: i < party.members.length
                                            ? party.members[i]
                                            : null,
                                        selfId: party.selfId,
                                        hostId: party.hostId,
                                        started: started))
                            ]);
                          }),
                          const SizedBox(height: 20),
                          if (!started)
                            LobbyAction(
                                label: '仲間を招待する',
                                icon: Icons.person_add_outlined,
                                onTap: _copyCode),
                        ],
                        const SizedBox(height: 24),
                        LobbyPanel(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Row(children: [
                                const Icon(Icons.hourglass_top,
                                    color: lobbyGold, size: 20),
                                const SizedBox(width: 8),
                                const Expanded(
                                    child: Text('集中時間の設定', style: lobbyBody)),
                                Text('$minutes分',
                                    style: lobbyTitle.copyWith(fontSize: 24))
                              ]),
                              const SizedBox(height: 14),
                              if (party.connected)
                                DropdownButton<int>(
                                    value: party.focusAreaIndex,
                                    items: [
                                      const DropdownMenuItem(
                                          value: -1, child: Text('訓練場')),
                                      for (final area in party.availableAreas)
                                        DropdownMenuItem(
                                            value: area,
                                            child: Text(FocusAdventure.area(0,
                                                areaIndex: area)))
                                    ],
                                    onChanged:
                                        enabled && !started && party.isHost
                                            ? (area) {
                                                if (area != null) {
                                                  party.setArea(area);
                                                }
                                              }
                                            : null),
                              Wrap(spacing: 8, runSpacing: 8, children: [
                                for (final value in [15, 30, 45, 60])
                                  ChoiceChip(
                                      label: Text('$value分'),
                                      selected: value == minutes,
                                      showCheckmark: false,
                                      labelStyle: lobbyBody.copyWith(
                                          fontSize: 14,
                                          color: value == minutes
                                              ? const Color(0xff132b47)
                                              : lobbyWhite),
                                      backgroundColor: const Color(0xff112e50),
                                      selectedColor: lobbyGold,
                                      side: const BorderSide(color: lobbyGold),
                                      onSelected: enabled &&
                                              !started &&
                                              (!party.connected || party.isHost)
                                          ? (_) {
                                              if (value == minutes) return;
                                              if (party.connected) {
                                                party.setMinutes(value);
                                              } else {
                                                setState(
                                                    () => _minutes = value);
                                              }
                                            }
                                          : null)
                              ]),
                              const SizedBox(height: 10),
                              Text(
                                  started
                                      ? 'この時間で集中中です。'
                                      : !party.connected
                                          ? '作成するパーティーの集中時間を選びます。'
                                          : party.isHost
                                              ? '時間を変更すると、全員の準備が解除されます。'
                                              : 'リーダーが集中時間を設定します。',
                                  style: lobbyBody.copyWith(
                                      fontSize: 11,
                                      color: const Color(0xffd1dce8))),
                            ])),
                        if (party.connected) ...[
                          const SizedBox(height: 18),
                          if (!started) ...[
                            LobbyAction(
                                key: const Key('party-ready'),
                                label: party.ready ? '準備を解除' : '準備OK',
                                icon: Icons.check_circle_outline,
                                onTap: enabled
                                    ? () => _act(() =>
                                        controller.prepareParty(!party.ready))
                                    : null),
                            const SizedBox(height: 12),
                            if (party.isHost) ...[
                              LobbyAction(
                                  key: const Key('party-start'),
                                  label: 'みんなで集中を開始',
                                  icon: Icons.play_arrow,
                                  onTap: enabled &&
                                          party.members.length >= 2 &&
                                          party.members.every((m) => m.ready)
                                      ? party.start
                                      : null),
                              const SizedBox(height: 8),
                              const LobbyPanel(
                                  child: Text('2人以上で、全員の準備ができたら開始できます。',
                                      textAlign: TextAlign.center,
                                      style: lobbyBody)),
                            ] else
                              const LobbyPanel(
                                  child: Text('全員の準備ができたら、リーダーが開始します。',
                                      textAlign: TextAlign.center,
                                      style: lobbyBody)),
                          ] else
                            LobbyAction(
                                label: '集中画面へ',
                                icon: Icons.timer_outlined,
                                onTap: controller.activeFocus != null
                                    ? () => Navigator.pop(context)
                                    : null),
                          TextButton(
                              key: const Key('party-leave'),
                              onPressed:
                                  enabled ? () => _act(party.leave) : null,
                              child: Text(
                                  started ? 'パーティーから退出（集中は継続）' : 'パーティーから退出',
                                  style: lobbyBody.copyWith(fontSize: 12))),
                        ],
                        if (controller.activeFocus != null && !party.connected)
                          const LobbyPanel(
                              child: Text('切断したパーティーのコードを入力すると復帰できます。',
                                  style: lobbyBody)),
                        if (_working || party.connecting) ...[
                          const SizedBox(height: 16),
                          const LinearProgressIndicator(color: lobbyGold),
                          const LobbyPanel(
                              child: Text('仲間の待つ場所へ接続しています…',
                                  textAlign: TextAlign.center,
                                  style: lobbyBody)),
                        ],
                        if (_error ?? party.error ?? controller.partyStartError
                            case final String error) ...[
                          const SizedBox(height: 12),
                          LobbyPanel(
                              key: const Key('party-error'),
                              child: Text(error,
                                  style: lobbyBody.copyWith(
                                      color: const Color(0xffffd6a8)))),
                        ],
                      ]));
            })),
          ])),
        ]));
  }
}

import 'package:flutter/material.dart';
import '../../../core/widgets/quest_screen_fit.dart';
import '../data/party_connection.dart';
import '../../focus/domain/focus_adventure.dart';
import 'party_lobby_art.dart';

class PartyLobbyScene extends StatelessWidget {
  const PartyLobbyScene(
      {super.key,
      required this.party,
      required this.enabled,
      required this.onBack,
      required this.onCopy,
      required this.onLeave,
      required this.onDisband,
      required this.onFocus,
      this.error,
      this.working = false});
  final PartyConnection party;
  final bool enabled, working;
  final VoidCallback onBack, onCopy, onLeave, onDisband;
  final VoidCallback? onFocus;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final started = party.session != null;
    final editable = enabled && !started && party.isHost;
    return Scaffold(
        backgroundColor: const Color(0xff0b2340),
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/party_lobby_v001/castle_valley.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              excludeFromSemantics: true),
          SafeArea(
              child: Column(children: [
            LobbyPanel(
                asset: 'header',
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(children: [
                  IconButton(
                      key: const Key('party-back'),
                      tooltip: '戻る',
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back, color: lobbyWhite)),
                  Expanded(
                      child: Text('パーティーを組む',
                          textAlign: TextAlign.center,
                          style: lobbyTitle.copyWith(fontSize: 20))),
                  Text('${party.members.length} / 4人', style: lobbyBody),
                ])),
            Expanded(
                child: LayoutBuilder(
                    builder: (context, box) => QuestScreenFit(
                        key: const Key('party-lobby-list'),
                        padding: EdgeInsets.symmetric(
                            horizontal: box.maxWidth > 620
                                ? (box.maxWidth - 620) / 2 + 12
                                : 12,
                            vertical: 10),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              LobbyPanel(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 6),
                                  child: Row(children: [
                                    Expanded(
                                        child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                          Text('パーティーコード',
                                              style: lobbyBody.copyWith(
                                                  fontSize: 14)),
                                          SelectableText(party.code ?? '',
                                              style: lobbyTitle.copyWith(
                                                  fontSize: 25,
                                                  letterSpacing: 4)),
                                        ])),
                                    TextButton.icon(
                                        onPressed: onCopy,
                                        icon: const Icon(Icons.copy,
                                            color: lobbyGold, size: 18),
                                        label:
                                            const Text('招待', style: lobbyBody)),
                                  ])),
                              const SizedBox(height: 10),
                              Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < 4; i++) ...[
                                      if (i > 0) const SizedBox(width: 6),
                                      Expanded(
                                          child: LobbyMemberCard(
                                              key: Key('party-slot-$i'),
                                              member: i < party.members.length
                                                  ? party.members[i]
                                                  : null,
                                              selfId: party.selfId,
                                              hostId: party.hostId,
                                              started: started,
                                              compact: true)),
                                    ],
                                  ]),
                              const SizedBox(height: 10),
                              LobbyPanel(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Row(children: [
                                          const Icon(Icons.hourglass_top,
                                              color: lobbyGold, size: 18),
                                          const SizedBox(width: 8),
                                          const Expanded(
                                              child: Text('集中時間の設定',
                                                  style: lobbyBody)),
                                          Text('${party.minutes}分',
                                              style: lobbyTitle.copyWith(
                                                  fontSize: 20)),
                                        ]),
                                        DropdownButton<int>(
                                            isExpanded: true,
                                            isDense: true,
                                            value: party.focusAreaIndex,
                                            style: lobbyBody,
                                            dropdownColor:
                                                const Color(0xff0b2340),
                                            items: [
                                              const DropdownMenuItem(
                                                  value: -1,
                                                  child: Text('訓練場')),
                                              for (final area
                                                  in party.availableAreas)
                                                DropdownMenuItem(
                                                    value: area,
                                                    child: Text(
                                                        FocusAdventure.area(0,
                                                            areaIndex: area)))
                                            ],
                                            onChanged: editable
                                                ? (value) {
                                                    if (value != null) {
                                                      party.setArea(value);
                                                    }
                                                  }
                                                : null),
                                        Wrap(
                                            spacing: 6,
                                            runSpacing: 0,
                                            children: [
                                              for (final minutes in [
                                                15,
                                                30,
                                                45,
                                                60
                                              ])
                                                ChoiceChip(
                                                    label: Text('$minutes分'),
                                                    selected: party.minutes ==
                                                        minutes,
                                                    showCheckmark: false,
                                                    labelStyle: lobbyBody.copyWith(
                                                        fontSize: 14,
                                                        color: party.minutes ==
                                                                minutes
                                                            ? const Color(
                                                                0xff132b47)
                                                            : lobbyWhite),
                                                    backgroundColor:
                                                        const Color(0xff112e50),
                                                    selectedColor: lobbyGold,
                                                    side: const BorderSide(
                                                        color: lobbyGold),
                                                    onSelected: editable
                                                        ? (_) {
                                                            if (party.minutes !=
                                                                minutes) {
                                                              party.setMinutes(
                                                                  minutes);
                                                            }
                                                          }
                                                        : null),
                                            ]),
                                        Text(
                                            started
                                                ? 'この時間で集中中です。'
                                                : party.isHost
                                                    ? '変更すると全員の準備が解除されます。'
                                                    : 'リーダーが時間を設定します。',
                                            style: lobbyBody.copyWith(
                                                fontSize: 14)),
                                      ])),
                              const SizedBox(height: 10),
                              if (!started) ...[
                                LobbyAction(
                                    key: const Key('party-ready'),
                                    compact: true,
                                    label: party.ready ? '準備を解除する' : '準備OK',
                                    icon: Icons.check_circle_outline,
                                    onTap: enabled
                                        ? () => party.setReady(!party.ready)
                                        : null),
                                const SizedBox(height: 8),
                                if (party.isHost)
                                  LobbyAction(
                                      key: const Key('party-start'),
                                      compact: true,
                                      label: 'みんなで集中を開始',
                                      icon: Icons.play_arrow,
                                      onTap: enabled &&
                                              party.members.length >= 2 &&
                                              party.members
                                                  .every((m) => m.ready)
                                          ? party.start
                                          : null),
                                const SizedBox(height: 4),
                                LobbyPanel(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    child: Text(
                                        party.isHost
                                            ? '2人以上・全員の準備完了で開始できます。'
                                            : '準備ができたらリーダーが開始します。',
                                        textAlign: TextAlign.center,
                                        style:
                                            lobbyBody.copyWith(fontSize: 14))),
                              ] else
                                LobbyAction(
                                    compact: true,
                                    label: '集中画面へ',
                                    icon: Icons.timer_outlined,
                                    onTap: onFocus),
                              if (working)
                                const LinearProgressIndicator(color: lobbyGold),
                              if (error != null) ...[
                                const SizedBox(height: 6),
                                LobbyPanel(
                                    key: const Key('party-error'),
                                    padding: const EdgeInsets.all(12),
                                    child: Text(error!,
                                        style: lobbyBody.copyWith(
                                            fontSize: 14,
                                            color: const Color(0xffffd6a8)))),
                              ],
                            ])))),
            LobbyPanel(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                child: Row(children: [
                  Expanded(
                      child: TextButton(
                          key: const Key('party-leave'),
                          onPressed: onLeave,
                          child: Text('パーティーから退出',
                              style: lobbyBody.copyWith(fontSize: 14)))),
                  if (party.isHost)
                    Expanded(
                        child: TextButton(
                            key: const Key('party-disband'),
                            onPressed: enabled ? onDisband : null,
                            child: Text('解散する',
                                style: lobbyBody.copyWith(
                                    fontSize: 14, color: lobbyGold)))),
                ])),
          ])),
        ]));
  }
}

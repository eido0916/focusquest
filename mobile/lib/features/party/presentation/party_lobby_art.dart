import 'package:flutter/material.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../domain/party_member.dart';

const lobbyGold = Color(0xffeac982);
const lobbyWhite = Color(0xfffff8e9);
const lobbyTitle = TextStyle(
    fontFamily: 'SunlitSerif',
    color: lobbyWhite,
    fontSize: 23,
    fontWeight: FontWeight.w600,
    letterSpacing: 1.5);
const lobbyBody = TextStyle(
    fontFamily: 'SunlitSerif', color: lobbyWhite, fontSize: 16, height: 1.35);

class LobbyPanel extends StatelessWidget {
  const LobbyPanel(
      {super.key,
      required this.child,
      this.asset = 'panel',
      this.padding = const EdgeInsets.all(18)});
  final Widget child;
  final String asset;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Image.asset('assets/images/party_lobby_v001/$asset.png',
                fit: BoxFit.fill, excludeFromSemantics: true)),
        Padding(padding: padding, child: child),
      ]);
}

class LobbyCompass extends StatelessWidget {
  const LobbyCompass({super.key, this.size = 42});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/party_lobby_v001/compass.png',
          width: size, height: size, excludeFromSemantics: true);
}

class LobbyAction extends StatelessWidget {
  const LobbyAction(
      {super.key,
      required this.label,
      required this.icon,
      this.onTap,
      this.compact = false});
  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) => Opacity(
      opacity: onTap == null ? .82 : 1,
      child: LobbyPanel(
          asset: 'action',
          padding: EdgeInsets.zero,
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(24),
                  child: Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 16 : 22,
                          vertical: compact ? 12 : 22),
                      child: Row(children: [
                        if (!compact) const LobbyCompass(size: 34),
                        if (!compact) const SizedBox(width: 12),
                        SizedBox(width: 26, child: Icon(icon, color: lobbyWhite, size: compact ? 22 : 26)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(label,
                                textAlign: TextAlign.center,
                                style: lobbyTitle.copyWith(
                                    fontSize: compact ? 16 : 20))),
                        const SizedBox(width: 10),
                        const Icon(Icons.chevron_right,
                            color: lobbyWhite, size: 26),
                      ]))))));
}

class LobbyMemberCard extends StatelessWidget {
  const LobbyMemberCard(
      {super.key,
      this.member,
      this.selfId,
      this.hostId,
      this.compact = false,
      required this.started});
  final PartyMember? member;
  final String? selfId, hostId;
  final bool started;
  final bool compact;
  static const statuses = {
    'waiting': '待機中',
    'starting': '開始準備中',
    'focusing': '集中中',
    'succeeded': '達成',
    'failed': '未達成',
    'cancelled': '中断',
    'cannotStart': '開始できませんでした',
    'disconnected': '接続切れ'
  };
  @override
  Widget build(BuildContext context) {
    final actor = member;
    if (compact) {
      return LobbyPanel(
          asset: 'member',
          padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
          child: SizedBox(
              width: double.infinity,
              height: 156,
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (actor == null) ...[
                      const Icon(Icons.add_circle_outline,
                          color: lobbyGold, size: 30),
                      const SizedBox(height: 8),
                      Text('参加待ち', style: lobbyBody.copyWith(fontSize: 14)),
                    ] else ...[
                      FittedBox(
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (actor.id == hostId)
                          const Icon(Icons.workspace_premium,
                              size: 14, color: lobbyGold),
                        Text(actor.id == selfId ? 'あなた' : '仲間',
                            style: lobbyBody.copyWith(
                                fontSize: 14, color: lobbyGold)),
                      ])),
                      Expanded(
                          child: JobPortrait(
                              typeId: actor.characterType,
                              appearance: actor.appearance,
                              lobby: true,
                              height: 66)),
                      Text(actor.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: lobbyBody.copyWith(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      Text('Lv.${actor.level}',
                          style: lobbyBody.copyWith(fontSize: 14)),
                      Text(
                          started
                              ? statuses[actor.status] ?? '待機中'
                              : actor.ready
                                  ? '準備OK'
                                  : '待機中',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: lobbyBody.copyWith(
                              fontSize: 14,
                              color: actor.ready
                                  ? const Color(0xffa9f0c6)
                                  : lobbyGold)),
                    ],
                  ])));
    }
    return LobbyPanel(
        asset: 'member',
        padding: const EdgeInsets.all(5),
        child: actor == null
            ? SizedBox(
                height: 268,
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border:
                                  Border.all(color: lobbyGold.withOpacity(.8))),
                          child: const Icon(Icons.add,
                              color: lobbyGold, size: 34)),
                      const SizedBox(height: 16),
                      Text('仲間の参加を\n待っています',
                          textAlign: TextAlign.center,
                          style: lobbyBody.copyWith(fontSize: 14)),
                    ]))
            : Column(children: [
                SizedBox(
                    height: 22,
                    child: actor.id == hostId
                        ? Image.asset(
                            'assets/images/party_lobby_v001/crown.png',
                            width: 25,
                            excludeFromSemantics: true)
                        : null),
                JobPortrait(
                    typeId: actor.characterType,
                    appearance: actor.appearance,
                    lobby: true,
                    height: 144,
                    alignment: Alignment.bottomCenter),
                const Divider(color: lobbyGold, height: 10),
                Text(actor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: lobbyBody.copyWith(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                Text(
                    actor.id == selfId
                        ? 'あなた'
                        : actor.id == hostId
                            ? 'リーダー'
                            : '仲間',
                    style: lobbyBody.copyWith(fontSize: 14, color: lobbyGold)),
                Text(JobPortrait.roleNames[actor.characterType] ?? '冒険者',
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: lobbyBody.copyWith(fontSize: 14)),
                Text('Lv.${actor.level}',
                    style: lobbyBody.copyWith(fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                    started
                        ? statuses[actor.status] ?? '待機中'
                        : actor.ready
                            ? '準備OK'
                            : '待機中',
                    textAlign: TextAlign.center,
                    style: lobbyBody.copyWith(
                        fontSize: 14,
                        color:
                            actor.ready ? const Color(0xffa9f0c6) : lobbyGold)),
                const SizedBox(height: 7),
              ]));
  }
}

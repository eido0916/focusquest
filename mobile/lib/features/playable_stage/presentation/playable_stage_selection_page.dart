import 'package:flutter/material.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_stage_catalog.dart';
import '../domain/playable_character.dart';
import '../domain/fq_adventure_character.dart';
import 'playable_stage_page.dart';
import 'playable_stage_assets.dart';
import 'playable_stage_audio.dart';

class PlayableStageSelectionPage extends StatefulWidget {
  const PlayableStageSelectionPage(
      {super.key,
      this.assets,
      this.audioOutput,
      this.battleFactory,
      this.character,
      this.onChooseCharacter,
      this.controller,
      this.embedded = false,
      this.onLegacyAdventure});
  final GameController? controller;
  final bool embedded;
  final VoidCallback? onLegacyAdventure;
  final PlayableCharacter? character;
  final Future<PlayableCharacter?> Function(PlayableCharacter)?
      onChooseCharacter;
  final PlayableStageAssets? assets;
  final StageAudioOutput? audioOutput;
  final PlayableStageBattle Function(PlayableStageDefinition)? battleFactory;
  @override
  State<PlayableStageSelectionPage> createState() =>
      _PlayableStageSelectionPageState();
}

class _PlayableStageSelectionPageState
    extends State<PlayableStageSelectionPage> {
  late final Set<int> _cleared = {
    ...?widget.controller?.state?.clearedPlayableStages
  };
  bool _opening = false;
  String? _error;
  int? _pendingClear;
  late PlayableCharacter _character =
      widget.character ?? PlayableCharacters.defaultCharacter;
  bool get _blocked =>
      _opening ||
      _pendingClear != null ||
      widget.controller?.activeFocus != null ||
      widget.controller?.state?.adventureRun != null ||
      widget.controller?.busy == true;

  Future<void> _saveClear(int number) async {
    try {
      await widget.controller?.recordPlayableClear(number);
      if (mounted) {
        setState(() {
          _cleared.add(number);
          _pendingClear = null;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingClear = number;
          _error = 'クリア記録を保存できませんでした。再試行してください。';
        });
      }
    }
  }

  Future<void> _open(PlayableStageDefinition stage) async {
    if (_blocked) return;
    setState(() {
      _opening = true;
      _error = null;
    });
    PlayableStageBattle? battle;
    var began = false;
    try {
      final controller = widget.controller;
      if (controller != null) {
        await controller.beginPlayableAdventure();
        began = true;
        _character = fqAdventureCharacter(controller.state!.activeCharacter!);
      }
      if (!mounted) return;
      battle = widget.battleFactory?.call(stage) ??
          PlayableStageBattle(stage: stage, character: _character);
      final route = MaterialPageRoute<bool>(
          builder: (_) => PlayableStagePage(
              battle: battle,
              assets: widget.assets,
              audioOutput: widget.audioOutput,
              returnToSelection: true));
      await Navigator.of(context).push(route);
      await route.completed;
      if (battle.mode == StageMode.won) {
        await _saveClear(stage.number);
        if (mounted && _pendingClear == null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('STAGE ${stage.number} クリア！ 次の冒険を選ぼう。'),
              duration: const Duration(seconds: 2)));
        }
      }
    } catch (error) {
      if (mounted) setState(() => _error = '冒険を開始できませんでした。$error');
    } finally {
      battle?.dispose();
      if (began) widget.controller?.endPlayableAdventure();
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(children: [
      Positioned.fill(
          child: Image.asset('assets/images/ui/sunlit_kingdom.png',
              fit: BoxFit.cover, alignment: Alignment.topCenter)),
      const Positioned.fill(
          child: DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xc5081832), Color(0xee081829)])))),
      Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1060),
              child: ListView(
                  key: const Key('stage-selection-list'),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                  children: [
                    _heading(),
                    const SizedBox(height: 14),
                    _traveler(),
                    if (widget.controller?.activeFocus != null)
                      _notice('いまは集中の時間。終了後に冒険へ出発できます。'),
                    if (widget.controller?.state?.adventureRun != null)
                      _notice('以前の冒険が進行中です。「以前の冒険の書」で結果を確認してください。'),
                    if (_error != null) ...[
                      _notice(_error!),
                      if (_pendingClear != null)
                        TextButton.icon(
                            onPressed: () => _saveClear(_pendingClear!),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('クリア記録の保存を再試行')),
                    ],
                    const SizedBox(height: 20),
                    for (var area = 0;
                        area < PlayableStageCatalog.areas.length;
                        area++)
                      _area(area),
                    if (widget.onLegacyAdventure != null)
                      TextButton.icon(
                          key: const Key('legacy-adventure'),
                          onPressed: _opening ? null : widget.onLegacyAdventure,
                          icon: const Icon(Icons.history_edu),
                          label: const Text('以前の冒険の書')),
                  ]))),
    ]);
    if (widget.embedded) return content;
    return Scaffold(
        backgroundColor: sunlitInk,
        appBar: AppBar(
            title: const Text('ステージ選択'),
            backgroundColor: sunlitInk,
            foregroundColor: const Color(0xffffeed0)),
        body: SafeArea(child: content));
  }

  Widget _heading() => SunlitFrame(
      scenery: true,
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_awesome, color: sunlitGold, size: 17),
          SizedBox(width: 8),
          Text('FOCUS QUEST',
              style:
                  TextStyle(color: sunlitGold, letterSpacing: 3, fontSize: 11)),
        ]),
        const SizedBox(height: 8),
        const Text('冒険の書',
            style: TextStyle(
                fontFamily: 'SunlitSerif',
                color: Color(0xfffff1cf),
                fontSize: 32)),
        const SizedBox(height: 5),
        const Text('九つの世界を巡る旅',
            style: TextStyle(
                fontFamily: 'SunlitSerif',
                color: Color(0xffd1dfee),
                fontSize: 14)),
        const SizedBox(height: 14),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.map_outlined, color: sunlitGold, size: 17),
          const SizedBox(width: 7),
          Text('全36ステージ   ·   踏破 ${_cleared.length} / 36',
              style: const TextStyle(color: Color(0xffffe5b1), fontSize: 12)),
        ]),
      ]));

  Widget _traveler() {
    final hero = widget.controller?.state?.activeCharacter;
    final name = hero?.name ?? _character.name;
    final role = hero == null
        ? _character.role
        : JobPortrait.roleNames[hero.characterType];
    final battleRole = hero == null ? role : fqAdventureCharacter(hero).role;
    return SunlitFrame(
        light: true,
        compact: true,
        padding: const EdgeInsets.all(15),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            const Icon(Icons.shield_outlined, color: sunlitInk),
            const SizedBox(width: 10),
            Expanded(
                child: Text('$name${hero == null ? '' : '  Lv.${hero.level}'}',
                    style: const TextStyle(
                        color: sunlitInk,
                        fontFamily: 'SunlitSerif',
                        fontSize: 16,
                        fontWeight: FontWeight.bold))),
          ]),
          const SizedBox(height: 7),
          Text('$roleの旅路。行きたい舞台を選んで出発しよう。',
              style: const TextStyle(
                  color: Color(0xff555044), height: 1.6, fontSize: 12)),
          if (battleRole != role)
            Text('戦闘では$battleRoleの原画アニメーションを使用します。',
                style: const TextStyle(color: Color(0xff555044), fontSize: 11)),
          const SizedBox(height: 7),
          const Text('攻撃をタップ。3回命中でスキル解放。各ステージは3つの戦い。',
              style: TextStyle(
                  color: Color(0xff555044), height: 1.6, fontSize: 11)),
          if (widget.onChooseCharacter != null)
            TextButton.icon(
                key: const Key('demo-change-character'),
                onPressed: _opening
                    ? null
                    : () async {
                        final hero =
                            await widget.onChooseCharacter!(_character);
                        if (mounted && hero != null) {
                          setState(() => _character = hero);
                        }
                      },
                icon: const Icon(Icons.person),
                label: Text('${_character.name} · キャラクター変更')),
        ]));
  }

  Widget _notice(String message) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: SunlitFrame(
          compact: true,
          child: Text(message,
              style: const TextStyle(color: Color(0xffffdba0), height: 1.6))));

  Widget _area(int area) {
    final complete =
        _cleared.where((n) => n > area * 4 && n <= area * 4 + 4).length;
    return Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
              padding: const EdgeInsets.only(bottom: 9, left: 3),
              child: Row(children: [
                const Icon(Icons.explore_outlined, color: sunlitGold, size: 19),
                const SizedBox(width: 8),
                Text('第${area + 1}章',
                    style: const TextStyle(
                        color: sunlitGold,
                        fontFamily: 'SunlitSerif',
                        fontSize: 14)),
                const SizedBox(width: 12),
                const Expanded(child: Divider(color: Color(0xff907649))),
                const SizedBox(width: 12),
                Text('$complete / 4',
                    style: const TextStyle(
                        color: Color(0xffd9c595), fontSize: 12)),
              ])),
          CustomPaint(
              foregroundPainter: const SunlitFramePainter(compact: true),
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: SizedBox(
                      height: 160,
                      child: Stack(fit: StackFit.expand, children: [
                        Image.asset(PlayableStageCatalog.backgrounds[area],
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.none),
                        const DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                              Color(0x11041730),
                              Color(0xee04172d)
                            ]))),
                        Positioned(
                            left: 19,
                            right: 19,
                            bottom: 18,
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                        Text(PlayableStageCatalog.areas[area],
                                            style: const TextStyle(
                                                color: Color(0xffffedc8),
                                                fontFamily: 'SunlitSerif',
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 5),
                                        Text(
                                            'STAGE ${area * 4 + 1} — ${area * 4 + 4}',
                                            style: const TextStyle(
                                                color: Color(0xffd0e4f5),
                                                fontSize: 11,
                                                letterSpacing: 1.5)),
                                      ])),
                                  const Icon(Icons.flag_outlined,
                                      color: sunlitGold, size: 25),
                                ])),
                      ])))),
          const SizedBox(height: 10),
          LayoutBuilder(builder: (context, bounds) {
            final columns = bounds.maxWidth >= 650 ? 4 : 2;
            final width = (bounds.maxWidth - (columns - 1) * 10) / columns;
            return Wrap(spacing: 10, runSpacing: 10, children: [
              for (final stage
                  in PlayableStageCatalog.stages.skip(area * 4).take(4))
                SizedBox(width: width, child: _stageCard(stage)),
            ]);
          }),
        ]));
  }

  Widget _stageCard(PlayableStageDefinition stage) {
    final cleared = _cleared.contains(stage.number);
    return Semantics(
        button: true,
        enabled: !_blocked,
        label: '${stage.area} ステージ${stage.number}',
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                key: Key('select-stage-${stage.number}'),
                onTap: _blocked ? null : () => _open(stage),
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                    foregroundPainter: const SunlitFramePainter(compact: true),
                    child: Container(
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: stage.hasBoss
                                    ? const [
                                        Color(0xff382239),
                                        Color(0xff131d36)
                                      ]
                                    : const [
                                        Color(0xff123e64),
                                        Color(0xff091d3d)
                                      ])),
                        padding: const EdgeInsets.all(14),
                        child: Opacity(
                            opacity: _blocked ? .5 : 1,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(children: [
                                    Icon(
                                        stage.hasBoss
                                            ? Icons.castle_outlined
                                            : Icons.diamond_outlined,
                                        color: sunlitGold,
                                        size: 17),
                                    const SizedBox(width: 5),
                                    Expanded(
                                        child: Text('STAGE ${stage.number}',
                                            style: const TextStyle(
                                                color: Color(0xffffe5b2),
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                                fontFamily: 'SunlitSerif')))
                                  ]),
                                  const SizedBox(height: 9),
                                  Text(
                                      stage.hasBoss
                                          ? stage.opponents.last.name
                                          : '3フェーズの戦い',
                                      style: const TextStyle(
                                          color: Color(0xffe2edf5),
                                          fontSize: 12,
                                          height: 1.5,
                                          fontFamily: 'SunlitSerif')),
                                  const SizedBox(height: 9),
                                  Text(
                                      cleared
                                          ? '✓ CLEAR'
                                          : stage.hasBoss
                                              ? 'ボスに挑む  →'
                                              : '出発する  →',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: cleared
                                              ? const Color(0xffb4e8ca)
                                              : const Color(0xffead3a7),
                                          fontFamily: 'SunlitSerif')),
                                ])))))));
  }
}

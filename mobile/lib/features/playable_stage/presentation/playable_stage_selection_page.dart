import '../../../core/widgets/game_ui.dart';
import '../../../core/game_controller.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import '../../diagnosis/presentation/job_portrait.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_stage_catalog.dart';
import '../domain/playable_character.dart';
import '../domain/fq_adventure_character.dart';
import 'playable_stage_page.dart';
import 'playable_stage_assets.dart';
import 'playable_stage_audio.dart';
import 'playable_stage_details_dialog.dart';

class PlayableStageSelectionPage extends StatefulWidget {
  const PlayableStageSelectionPage(
      {super.key,
      this.assets,
      this.audioOutput,
      this.battleFactory,
      this.character,
      this.onChooseCharacter,
      this.controller,
      this.embedded = false});
  final GameController? controller;
  final bool embedded;
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
  final Set<String> _encountered = {};
  Set<String> _pendingEncounters = {};
  String? _error;
  int? _pendingClear;
  (String, int)? _pendingDefeats;
  late PlayableCharacter _character =
      widget.character ?? PlayableCharacters.defaultCharacter;
  bool get _blocked =>
      _opening ||
      _pendingClear != null ||
      _pendingDefeats != null ||
      _pendingEncounters.isNotEmpty ||
      widget.controller?.activeFocus != null ||
      widget.controller?.busy == true;

  @override
  void initState() {
    super.initState();
    widget.controller?.addListener(_controllerChanged);
  }

  @override
  void didUpdateWidget(covariant PlayableStageSelectionPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_controllerChanged);
      widget.controller?.addListener(_controllerChanged);
      _syncClears();
    }
  }

  void _syncClears() {
    final saved = widget.controller?.state?.clearedPlayableStages;
    if (saved != null) {
      _cleared
        ..clear()
        ..addAll(saved);
    }
  }

  void _controllerChanged() {
    if (mounted) setState(_syncClears);
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_controllerChanged);
    super.dispose();
  }

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

  Future<void> _saveDefeats(String id, int count) async {
    try {
      await widget.controller!.recordAdventureDefeats(id, count);
      if (mounted) {
        setState(() {
          _pendingDefeats = null;
          _error = _pendingClear == null ? null : 'クリア記録を保存できませんでした。再試行してください。';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingDefeats = (id, count);
          _error = '討伐記録を保存できませんでした。再試行してください。';
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
    final defeated = <StageEnemy>{};
    final encountered = <String>{};
    final operationId =
        '${DateTime.now().microsecondsSinceEpoch}-${stage.number}';
    void observeDefeats() {
      final current = battle;
      if (current != null) {
        defeated.addAll(current.enemies.where((e) => !e.alive));
        if (current.mode == StageMode.battle ||
            current.mode == StageMode.lost ||
            (current.mode == StageMode.travel && current.modeTime > 1.8)) {
          encountered.addAll(current.enemies.map((e) => e.definition.id));
        }
      }
    }

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
      battle.addListener(observeDefeats);
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
      observeDefeats();
      battle?.removeListener(observeDefeats);
      _encountered.addAll(encountered);
      if (encountered.isNotEmpty) await _saveEncounters(encountered);
      if (defeated.isNotEmpty && widget.controller != null) {
        await _saveDefeats(operationId, defeated.length);
      }
      battle?.dispose();
      if (began) widget.controller?.endPlayableAdventure();
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = Stack(children: [
      Positioned.fill(
          child: Image.asset(gameBackground,
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
                    if (_pendingDefeats != null)
                      TextButton.icon(
                          onPressed: () => _saveDefeats(
                              _pendingDefeats!.$1, _pendingDefeats!.$2),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('討伐記録を再保存')),
                    if (_pendingEncounters.isNotEmpty)
                      TextButton.icon(
                          onPressed: () => _saveEncounters(_pendingEncounters),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('遭遇記録を再保存')),
                    if (_error != null) ...[
                      _notice(_error!),
                      if (_pendingClear != null)
                        TextButton.icon(
                            key: const Key('retry-stage-clear'),
                            onPressed:
                                _opening || widget.controller?.busy == true
                                    ? null
                                    : () => _saveClear(_pendingClear!),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('クリア記録の保存を再試行')),
                    ],
                    const SizedBox(height: 20),
                    for (var area = 0;
                        area < PlayableStageCatalog.areas.length;
                        area++)
                      _area(area),
                  ]))),
    ]);
    if (widget.embedded) return content;
    return Scaffold(
        backgroundColor: sunlitInk,
        appBar: const GameAppBar(
            title: Text('ステージ選択'),
            backgroundColor: sunlitInk,
            foregroundColor: Color(0xffffeed0)),
        body: SafeArea(child: content));
  }

  Widget _heading() => SunlitFrame(
      scenery: true,
      padding: const EdgeInsets.all(22),
      child: Column(children: [
        const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.auto_awesome, color: sunlitGold, size: 17),
          SizedBox(width: 8),
          Flexible(
              child: Text('FOCUS QUEST',
                  style: TextStyle(
                      color: sunlitGold, letterSpacing: 3, fontSize: 11))),
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
          Flexible(
              child: Text('全36ステージ   ·   踏破 ${_cleared.length} / 36',
                  style:
                      const TextStyle(color: Color(0xffffe5b1), fontSize: 12))),
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

  Future<void> _saveEncounters(Set<String> ids) async {
    final pending = {..._pendingEncounters, ...ids};
    try {
      await widget.controller?.recordPlayableEncounters(pending);
      if (mounted) {
        setState(() {
          _pendingEncounters.clear();
          if (_error == '遭遇記録を保存できませんでした。再試行してください。') {
            _error = null;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _pendingEncounters = pending;
          _error = '遭遇記録を保存できませんでした。再試行してください。';
        });
      }
    }
  }

  Future<void> _showDetails(PlayableStageDefinition stage) async {
    final known = {
      ..._encountered,
      ...?widget.controller?.state?.encounteredEnemyIds,
      // Existing clear records prove every wave in that stage was encountered.
      for (final cleared in PlayableStageCatalog.stages
          .where((stage) => _cleared.contains(stage.number)))
        for (var phase = 0; phase < cleared.opponents.length; phase++)
          for (final enemy in cleared.wave(phase)) enemy.id,
    };
    final challenge = await showDialog<bool>(
        context: context,
        builder: (_) => PlayableStageDetailsDialog(
            stage: stage,
            encounteredEnemyIds: known,
            cleared: _cleared.contains(stage.number),
            canChallenge: !_blocked));
    if (mounted && challenge == true) await _open(stage);
  }

  Widget _stageCard(PlayableStageDefinition stage) => Semantics(
      button: true,
      enabled: !_blocked,
      label: '${stage.area} ステージ${stage.number}',
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              key: Key('select-stage-${stage.number}'),
              onTap: _blocked ? null : () => _showDetails(stage),
              borderRadius: BorderRadius.circular(8),
              child: SunlitFrame(
                  compact: true,
                  padding:
                      const EdgeInsets.symmetric(vertical: 22, horizontal: 12),
                  child: Center(
                      child: Text('Stage ${stage.number}',
                          style: TextStyle(
                              color: _blocked
                                  ? Colors.white38
                                  : const Color(0xffffe5b2),
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SunlitSerif')))))));
}

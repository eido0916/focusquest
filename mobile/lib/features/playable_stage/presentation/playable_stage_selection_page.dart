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
import '../domain/stage_progress.dart';
import 'adventure_map_scene.dart';

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
  StageProgress get _progress => StageProgress(_cleared);
  late int _areaIndex = _progress.currentArea;
  late int _selected = _progress.nextStage;
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
          if (_selected == number && number % 4 != 0 && number < 36) {
            _selected = number + 1;
          }
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
    if (_blocked || !_progress.canChallenge(stage.number)) return;
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
    final content = AdventureMapScene(
        progress: _progress,
        area: _areaIndex,
        selected: _selected,
        blocked: _blocked,
        onSelect: (number) {
          if (_blocked) return;
          setState(() => _selected = number);
          if (_progress.canChallenge(number)) {
            _showDetails(PlayableStageCatalog.stages[number - 1]);
          }
        },
        onChallenge: () =>
            _showDetails(PlayableStageCatalog.stages[_selected - 1]),
        onHistory: _history,
        onNext: () => _chooseArea(_areaIndex + 1),
        traveler: widget.onChooseCharacter == null ? null : _traveler(),
        notices: [
          if (widget.controller?.activeFocus != null)
            _notice('いまは集中の時間。終了後に冒険へ出発できます。'),
          if (_pendingDefeats != null)
            TextButton.icon(
                onPressed: () =>
                    _saveDefeats(_pendingDefeats!.$1, _pendingDefeats!.$2),
                icon: const Icon(Icons.save_outlined),
                label: const Text('討伐記録を再保存')),
          if (_pendingEncounters.isNotEmpty)
            TextButton.icon(
                onPressed: () => _saveEncounters(_pendingEncounters),
                icon: const Icon(Icons.save_outlined),
                label: const Text('遭遇記録を再保存')),
          if (_error != null) _notice(_error!),
          if (_pendingClear != null)
            TextButton.icon(
                key: const Key('retry-stage-clear'),
                onPressed: _opening || widget.controller?.busy == true
                    ? null
                    : () => _saveClear(_pendingClear!),
                icon: const Icon(Icons.save_outlined),
                label: const Text('クリア記録の保存を再試行')),
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

  void _chooseArea(int area) {
    if (!_progress.areaVisible(area) && _progress.countInArea(area) == 0) {
      return;
    }
    final candidates = List.generate(4, (i) => area * 4 + i + 1);
    setState(() {
      _areaIndex = area;
      _selected = candidates.contains(_progress.nextStage)
          ? _progress.nextStage
          : candidates.firstWhere(_progress.canChallenge,
              orElse: () => candidates.first);
    });
  }

  Future<void> _history() async {
    final picked = await showModalBottomSheet<int>(
        context: context,
        backgroundColor: const Color(0xff062141),
        isScrollControlled: true,
        builder: (context) => SafeArea(
            child: ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * .75),
                child: SingleChildScrollView(
                    child: Padding(
                        padding: const EdgeInsets.all(20),
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('旅の記録', style: mapText(24)),
                          Text('全36ステージ ・ 踏破 ${_cleared.length} / 36',
                              style: mapText(14)),
                          const SizedBox(height: 16),
                          for (var area = 0; area < 9; area++)
                            if (_progress.areaVisible(area) ||
                                _progress.countInArea(area) > 0)
                              ListTile(
                                  key: Key('history-area-$area'),
                                  leading: MapIcon(_progress.areaComplete(area)
                                      ? 'check'
                                      : 'flag'),
                                  title: Text(
                                      '第${area + 1}章  ${PlayableStageCatalog.areas[area]}',
                                      style: mapText(17)),
                                  subtitle: Text(
                                      '${_progress.countInArea(area)} / 4 CLEAR',
                                      style: mapText(12)),
                                  trailing: const MapIcon('chevron', size: 18),
                                  onTap: () => Navigator.pop(context, area)),
                          if (_cleared.isEmpty)
                            Text('これから始まる、あなたの冒険。', style: mapText(13)),
                        ]))))));
    if (mounted && picked != null) _chooseArea(picked);
  }

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
          const Text('攻撃をタップ。3回攻撃でスキル解放。各ステージは3つの戦い。',
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
            canChallenge: !_blocked && _progress.canChallenge(stage.number)));
    if (mounted && challenge == true) await _open(stage);
  }
}

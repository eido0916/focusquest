import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import 'adventure_ui.dart';
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
  Widget build(BuildContext context) => AdventureUi(
      child: Scaffold(
          appBar: adventureAppBar('ステージ選択'),
          body: AdventureBackdrop(
              child: SafeArea(
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1100),
                          child: ListView(
                              key: const Key('stage-selection-list'),
                              padding: const EdgeInsets.all(16),
                              children: [
                                if (widget.onChooseCharacter != null) ...[
                                  OutlinedButton.icon(
                                      key: const Key('demo-change-character'),
                                      onPressed: _opening
                                          ? null
                                          : () async {
                                              final hero = await widget
                                                      .onChooseCharacter!(
                                                  _character);
                                              if (mounted && hero != null) {
                                                setState(
                                                    () => _character = hero);
                                              }
                                            },
                                      icon: const Icon(Icons.person),
                                      label: Text(
                                          '${_character.name} · キャラクター変更')),
                                  const SizedBox(height: 12),
                                ],
                                SunlitFrame(
                                  light: true,
                                  scenery: true,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Row(children: [
                                        CompassEmblem(size: 36),
                                        SizedBox(width: 12),
                                        Expanded(
                                            child: Text('冒険の書',
                                                style: TextStyle(
                                                    color: sunlitInk,
                                                    fontSize: 26,
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ]),
                                      const SizedBox(height: 12),
                                      const Text('9つの地を巡り、魔王城へ。',
                                          style: TextStyle(
                                              color: sunlitInk, fontSize: 16)),
                                      const SizedBox(height: 6),
                                      const Text('行き先を選んで出発しよう。各地は3フェーズの戦い。',
                                          style: TextStyle(
                                              color: sunlitInk,
                                              fontSize: 11,
                                              height: 1.7)),
                                      const SizedBox(height: 12),
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 6,
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          children: [
                                            const Icon(Icons.auto_awesome,
                                                color: Color(0xff9f793d),
                                                size: 18),
                                            Text(
                                                '踏破 ${_cleared.length} / ${PlayableStageCatalog.stages.length}',
                                                style: const TextStyle(
                                                    color: sunlitInk,
                                                    fontSize: 12)),
                                            const Text('4ステージごとにボス',
                                                style: TextStyle(
                                                    color: sunlitInk,
                                                    fontSize: 10)),
                                          ]),
                                      const SizedBox(height: 8),
                                      LinearProgressIndicator(
                                          value: _cleared.length /
                                              PlayableStageCatalog
                                                  .stages.length,
                                          color: const Color(0xff258bca),
                                          backgroundColor:
                                              const Color(0xffd9c9a7)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 22),
                                for (var area = 0;
                                    area < PlayableStageCatalog.areas.length;
                                    area++)
                                  _area(area),
                              ])))))));

  Widget _area(int area) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        SunlitFrame(
            padding: EdgeInsets.zero,
            child: SizedBox(
                height: 150,
                child: Stack(fit: StackFit.expand, children: [
                  Image.asset(PlayableStageCatalog.backgrounds[area],
                      fit: BoxFit.cover, filterQuality: FilterQuality.none),
                  const DecoratedBox(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                        Colors.transparent,
                        Color(0xee071c3c)
                      ]))),
                  Positioned(
                      top: 16,
                      left: 18,
                      child: Text('第${area + 1}章',
                          style: const TextStyle(
                              color: sunlitGold,
                              fontSize: 12,
                              letterSpacing: 2))),
                  Positioned(
                      left: 18,
                      bottom: 18,
                      child: Text(
                          '${PlayableStageCatalog.areas[area]}  ·  STAGE ${area * 4 + 1}–${area * 4 + 4}',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'SunlitSerif'))),
                ]))),
        const SizedBox(height: 10),
        LayoutBuilder(builder: (context, constraints) {
          final columns = constraints.maxWidth < 620 ? 2 : 4;
          final width = (constraints.maxWidth - (columns - 1) * 10) / columns;
          return Wrap(spacing: 10, runSpacing: 10, children: [
            for (final stage
                in PlayableStageCatalog.stages.skip(area * 4).take(4))
              SizedBox(width: width, child: _stageCard(stage)),
          ]);
        }),
      ]));

  Widget _stageCard(PlayableStageDefinition stage) {
    final cleared = _cleared.contains(stage.number);
    return SunlitFrame(
        light: !stage.hasBoss,
        compact: true,
        padding: EdgeInsets.zero,
        child: OutlinedButton(
            key: Key('select-stage-${stage.number}'),
            onPressed: _opening ? null : () => _open(stage),
            style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.all(14),
                backgroundColor: Colors.transparent,
                foregroundColor:
                    stage.hasBoss ? const Color(0xfffff3d9) : sunlitInk,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('STAGE ${stage.number}',
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'SunlitSerif')),
              const SizedBox(height: 7),
              Text(
                  stage.hasBoss
                      ? 'BOSS · ${stage.opponents.last.name}'
                      : '3フェーズの戦い',
                  style: const TextStyle(
                      fontSize: 11, height: 1.5, fontFamily: 'SunlitSerif')),
              const SizedBox(height: 8),
              Text(cleared ? '✓ CLEAR' : '挑戦する →',
                  style: TextStyle(
                      fontSize: 11,
                      color: cleared
                          ? const Color(0xff36866d)
                          : stage.hasBoss
                              ? sunlitGold
                              : const Color(0xff8b632c),
                      fontFamily: 'SunlitSerif')),
            ])));
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

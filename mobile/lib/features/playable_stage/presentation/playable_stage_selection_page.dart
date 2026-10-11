import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import 'adventure_ui.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_stage_catalog.dart';
import '../domain/playable_character.dart';
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
      this.onChooseCharacter});
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
  final Set<int> _cleared = {};
  bool _opening = false;
  late PlayableCharacter _character =
      widget.character ?? PlayableCharacters.defaultCharacter;

  Future<void> _open(PlayableStageDefinition stage) async {
    if (_opening) return;
    setState(() => _opening = true);
    final battle = widget.battleFactory?.call(stage) ??
        PlayableStageBattle(stage: stage, character: _character);
    final route = MaterialPageRoute<bool>(
        builder: (_) => PlayableStagePage(
            battle: battle,
            assets: widget.assets,
            audioOutput: widget.audioOutput,
            returnToSelection: true));
    await Navigator.of(context).push(route);
    final won = battle.mode == StageMode.won;
    // The route's widgets can still tick during its reverse transition.
    await route.completed;
    battle.dispose();
    if (!mounted) return;
    setState(() {
      _opening = false;
      if (won) _cleared.add(stage.number);
    });
    if (won) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('STAGE ${stage.number} クリア！ 次の冒険を選ぼう。'),
          duration: const Duration(seconds: 2)));
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
}

import 'package:flutter/material.dart';
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
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xff101b24),
      appBar: AppBar(title: const Text('ステージ選択')),
      body: SafeArea(
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
                                          .onChooseCharacter!(_character);
                                      if (mounted && hero != null) {
                                        setState(() => _character = hero);
                                      }
                                    },
                              icon: const Icon(Icons.person),
                              label: Text('${_character.name} · キャラクター変更')),
                          const SizedBox(height: 12),
                        ],
                        Text('${PlayableStageCatalog.stages.length}のステージを巡る冒険',
                            style: const TextStyle(
                                fontSize: 23,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'SunlitSerif')),
                        const SizedBox(height: 8),
                        Text(
                            '好きなステージに挑戦できます。各ステージは3フェーズ。\n'
                            '各エリアの4ステージ目にはボスが待ち受けます。 クリア ${_cleared.length} / ${PlayableStageCatalog.stages.length}',
                            style: const TextStyle(fontSize: 12, height: 1.7)),
                        const SizedBox(height: 20),
                        for (var area = 0;
                            area < PlayableStageCatalog.areas.length;
                            area++)
                          _area(area),
                      ])))));

  Widget _area(int area) => Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
                height: 120,
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
                        Color(0xcc080e17)
                      ]))),
                  Positioned(
                      left: 14,
                      bottom: 12,
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
    return OutlinedButton(
        key: Key('select-stage-${stage.number}'),
        onPressed: _opening ? null : () => _open(stage),
        style: OutlinedButton.styleFrom(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.all(14),
            backgroundColor: stage.hasBoss
                ? const Color(0xff392739)
                : const Color(0xff1b303c),
            foregroundColor: Colors.white,
            side: BorderSide(
                color: cleared
                    ? const Color(0xff8bc99a)
                    : stage.hasBoss
                        ? const Color(0xffce9b66)
                        : const Color(0xff425767)),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      ? const Color(0xffa6e0b3)
                      : const Color(0xffe8ce99),
                  fontFamily: 'SunlitSerif')),
        ]));
  }
}

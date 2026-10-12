import 'package:flutter/material.dart';
import '../../../core/widgets/sunlit_widgets.dart';
import '../presentation/adventure_ui.dart';
import 'dart:math' as math;
import '../domain/playable_character.dart';
import '../presentation/playable_stage_selection_page.dart';

/// Demo-only entry. Production routes never import this screen.
/// Replace the demo home with PlayableStageSelectionPage to remove selection.
class DemoCharacterSelectionPage extends StatefulWidget {
  const DemoCharacterSelectionPage({super.key, this.initial, this.onSelected});
  final PlayableCharacter? initial;
  final ValueChanged<PlayableCharacter>? onSelected;
  @override
  State<DemoCharacterSelectionPage> createState() =>
      _DemoCharacterSelectionPageState();
}

class _DemoCharacterSelectionPageState
    extends State<DemoCharacterSelectionPage> {
  late PlayableCharacter _selected =
      widget.initial ?? PlayableCharacters.defaultCharacter;
  void _confirm() {
    if (widget.onSelected != null) {
      widget.onSelected!(_selected);
      return;
    }
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => PlayableStageSelectionPage(
            character: _selected,
            onChooseCharacter: (current) => Navigator.of(context)
                .push<PlayableCharacter>(MaterialPageRoute(
                    builder: (routeContext) => DemoCharacterSelectionPage(
                        initial: current,
                        onSelected: (hero) =>
                            Navigator.of(routeContext).pop(hero)))))));
  }

  @override
  Widget build(BuildContext context) => AdventureUi(
      child: Scaffold(
          appBar: adventureAppBar('キャラクター選択 · DEMO'),
          body: AdventureBackdrop(
              child: SafeArea(
                  child: Center(
                      child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1000),
                          child: Column(children: [
                            Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: SunlitFrame(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(children: [
                                      _portrait(_selected),
                                      const SizedBox(width: 10),
                                      Expanded(
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                            Text(_selected.name,
                                                key: const Key(
                                                    'selected-character-name'),
                                                style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            const SizedBox(height: 7),
                                            _bar('体力', _selected.health, 250,
                                                const Color(0xff67cc98)),
                                            _bar('攻撃力', _selected.power, 50,
                                                const Color(0xffff777b)),
                                            _bar('素早さ', _selected.speed, 180,
                                                const Color(0xff70b8ff)),
                                            Text(
                                                '通常攻撃 ${_selected.attackSeconds.toStringAsFixed(2)}秒 / 回',
                                                key: const Key(
                                                    'character-action-seconds'),
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                          ])),
                                    ]))),
                            Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final female in [false, true])
                                    Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6),
                                        child: ChoiceChip(
                                            key: Key(
                                                'character-gender-${female ? 'female' : 'male'}'),
                                            label: Text(female ? '女性' : '男性'),
                                            selected:
                                                _selected.female == female,
                                            onSelected: (_) => setState(() {
                                                  final roleIndex =
                                                      PlayableCharacters.all
                                                              .indexOf(
                                                                  _selected) %
                                                          16;
                                                  _selected = PlayableCharacters
                                                          .all[
                                                      roleIndex +
                                                          (female ? 16 : 0)];
                                                }))),
                                ]),
                            Expanded(
                                child: LayoutBuilder(builder: (_, constraints) {
                              final columns = constraints.maxWidth < 450
                                  ? 2
                                  : constraints.maxWidth < 700
                                      ? 3
                                      : 5;
                              return GridView.count(
                                  key: const Key('character-grid'),
                                  crossAxisCount: columns,
                                  mainAxisSpacing: 10,
                                  crossAxisSpacing: 10,
                                  childAspectRatio: 1.8,
                                  padding: const EdgeInsets.all(14),
                                  children: [
                                    for (final hero in PlayableCharacters.all
                                        .where((hero) =>
                                            hero.female == _selected.female))
                                      OutlinedButton(
                                          key: Key('character-${hero.id}'),
                                          style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.all(4),
                                              backgroundColor: hero == _selected
                                                  ? const Color(0xff294963)
                                                  : const Color(0xee071c3c),
                                              side: BorderSide(
                                                  color: hero == _selected
                                                      ? const Color(0xffffd482)
                                                      : const Color(
                                                          0xffae8d55))),
                                          onPressed: () =>
                                              setState(() => _selected = hero),
                                          child: Row(children: [
                                            _portrait(hero),
                                            Expanded(
                                                child: Text(hero.role,
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.white))),
                                          ])),
                                  ]);
                            })),
                            Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 4, 16, 12),
                                child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton.icon(
                                        key: const Key('character-confirm'),
                                        onPressed: _confirm,
                                        style: FilledButton.styleFrom(
                                            backgroundColor: sunlitGold,
                                            foregroundColor: sunlitInk),
                                        icon: const Icon(Icons.arrow_forward),
                                        label: const Text('このキャラクターでステージ選択へ',
                                            style: TextStyle(
                                                fontFamily: 'SunlitSerif'))))),
                          ])))))));

  Widget _portrait(PlayableCharacter hero) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final side = 64 * math.max(1, dpr.floor()) / dpr;
    return Image.asset('assets/images/playable_stage/${hero.id}_attack_000.png',
        width: side, height: side, filterQuality: FilterQuality.none);
  }

  Widget _bar(String label, int value, int max, Color color) => Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(children: [
        SizedBox(
            width: 46,
            child: Text(label, style: const TextStyle(fontSize: 11))),
        Expanded(
            child: Semantics(
                label: '$label $value',
                child: LinearProgressIndicator(
                    key: Key('character-stat-$label'),
                    value: value / max,
                    color: color,
                    backgroundColor: const Color(0xff293442),
                    minHeight: 7))),
        SizedBox(
            width: 32,
            child: Text('$value',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 11))),
      ]));
}

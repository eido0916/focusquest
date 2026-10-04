import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../core/game_controller.dart';
import '../../core/widgets/quest_widgets.dart';
import '../../game/focus_battle_game.dart';

class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key, required this.controller});
  final GameController controller;
  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    return QuestStage(
      hud: QuestCard(
          caption: '森の小道',
          child: Row(children: [
            Expanded(child: Text('STAGE ${state.stage}')),
            Text('冒険進行度 ${state.adventureProgress}'),
          ])),
      figure: state.pendingBattle != null
          ? BattleView(
              key: ValueKey(state.pendingBattle!['id']), controller: controller)
          : AdventurerFigure(
              type: 'hero.${state.activeCharacter!.characterType}', size: 160),
      commands: QuestCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(
            state.pendingBattle != null
                ? '魔物との戦いが始まった！'
                : state.adventureProgress >= 5
                    ? '森の奥から、魔物の気配がする……。'
                    : '旅立つ力を、集中でたくわえよう。\n集中1分で進行度1。冒険には5必要だ。',
            style: const TextStyle(height: 1.7)),
        if (state.pendingBattle == null)
          QuestCommand(
              label: '自動戦闘へ • 進行度5',
              onTap: controller.busy || state.adventureProgress < 5
                  ? null
                  : () => runAction(context, controller.beginBattle)),
        QuestCommand(
            label: '冒険の記録',
            onTap: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                        title: const Text('冒険の記録'),
                        content: SizedBox(
                            width: 380,
                            child: ListView(shrinkWrap: true, children: [
                              if (state.battleHistory.isEmpty)
                                const Text('まだ冒険の記録はない。'),
                              for (final record
                                  in state.battleHistory.reversed.take(30))
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(
                                        'STAGE ${record['stage']} • ${record['victory'] == true ? '勝利' : '敗北'}\nEXP +${record['exp']} / ポイント +${record['coins']}')),
                            ])),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('閉じる'))
                        ]))),
      ])),
    );
  }
}

class BattleView extends StatefulWidget {
  const BattleView({super.key, required this.controller});
  final GameController controller;
  @override
  State<BattleView> createState() => _BattleViewState();
}

class _BattleViewState extends State<BattleView> {
  late final FocusBattleGame _game;
  bool _failed = false;
  bool _saving = false;
  @override
  void initState() {
    super.initState();
    _game = FocusBattleGame(widget.controller.battleEngine(), _save,
        heroAssetKey:
            'hero.${widget.controller.state!.activeCharacter!.characterType}');
  }

  Future<void> _save() async {
    if (!mounted || _saving) return;
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.controller
          .finishBattle(_game.engine, continueAdventure: true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _game.pauseEngine();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(children: [
        Expanded(
            child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: GameWidget(game: _game))),
        if (_failed)
          FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('戦闘結果の保存を再試行')),
      ]);
}

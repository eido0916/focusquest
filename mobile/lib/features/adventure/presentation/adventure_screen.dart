import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/game_controller.dart';
import '../../../core/widgets/quest_widgets.dart';
import '../../../data/game_catalog.dart';
import '../../character/domain/progression_service.dart';
import '../domain/adventure.dart';
import '../../playable_stage/presentation/playable_stage_selection_page.dart';

class AdventureScreen extends StatelessWidget {
  const AdventureScreen({super.key, required this.controller});
  final GameController controller;

  Future<void> _open(BuildContext context, String stageId) =>
      runAction(context, () async {
        if (controller.state!.adventureRun == null) {
          await controller.startAdventure(stageId);
        }
        if (context.mounted) {
          await Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (_) => AdventureBattlePage(controller: controller)));
        }
      });

  @override
  Widget build(BuildContext context) {
    final state = controller.state!;
    final hero = state.activeCharacter!;
    final stats = ProgressionService().stats(hero, GameCatalog.equipment);
    final pending = state.adventureRun;
    return ListView(padding: const EdgeInsets.all(16), children: [
      QuestCard(
          caption: 'プレイアブルステージ · 全16ステージ',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text('剣士で巡る、4つの舞台',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('草原・幽霊船・火山・魔王城。\nタップで攻撃、3回命中でスキル解放。',
                style: TextStyle(height: 1.6)),
            const SizedBox(height: 12),
            QuestCommand(
                label: 'ステージを選ぶ',
                onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const PlayableStageSelectionPage()))),
          ])),
      const QuestCard(
          caption: '第一章　木漏れ日の王国',
          child: Text('冒険の書',
              style: TextStyle(
                  fontSize: 25,
                  fontFamily: 'serif',
                  fontWeight: FontWeight.bold))),
      QuestCard(
          caption: '旅人のつよさ',
          child: Row(children: [
            const PixelHero(size: 88),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text('${hero.name}　Lv.${hero.level}',
                      style: const TextStyle(fontSize: 18)),
                  const SizedBox(height: 8),
                  Text('HP ${stats.hp}　攻撃 ${stats.attack}　守備 ${stats.defense}'),
                  Text(
                      '速度 ${stats.speed}　会心 ${(stats.criticalRate * 100).round()}%'),
                ])),
          ])),
      QuestCard(
          caption: '旅の案内',
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
                '踏破 ${state.clearedStages.length} / ${AdventureCatalog.stages.length}'),
            const SizedBox(height: 8),
            const Text(
                '集中で力を育て、装備を整えて出発しよう。\n戦闘は自動で進みます。挑戦ごとにHPは全回復。\nポイント・装備は初回クリアで獲得できます。',
                style: TextStyle(height: 1.6)),
            if (controller.activeFocus != null)
              const Text('いまは集中の時間。終了後に冒険できます。',
                  style: TextStyle(color: Color(0xffa9e5df))),
            if (pending != null)
              QuestCommand(
                  label: '進行中の冒険へ戻る',
                  onTap: controller.busy
                      ? null
                      : () => _open(context, pending.stageId)),
          ])),
      for (var i = 0; i < AdventureCatalog.stages.length; i++)
        _stage(context, AdventureCatalog.stages[i], i + 1),
      if (state.clearedStages.length == AdventureCatalog.stages.length)
        const QuestCard(
            caption: '第一章 完結', child: Text('森に光が戻った。あなたの集中が、この旅を支えた。')),
    ]);
  }

  Widget _stage(BuildContext context, AdventureStage stage, int number) {
    final state = controller.state!;
    final unlocked = AdventureCatalog.unlocked(stage.id, state.clearedStages);
    final cleared = state.clearedStages.contains(stage.id);
    return QuestCard(
        caption:
            'STAGE $number　${cleared ? '踏破済み' : unlocked ? '挑戦可能' : '未解放'}',
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(
                unlocked
                    ? (number == 5
                        ? Icons.workspace_premium_outlined
                        : Icons.forest_outlined)
                    : Icons.lock_outline,
                color: const Color(0xffa9e5df)),
            const SizedBox(width: 10),
            Expanded(
                child: Text(stage.name,
                    style: const TextStyle(fontSize: 20, fontFamily: 'serif'))),
          ]),
          const SizedBox(height: 10),
          Text(stage.description, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 10),
          Text(
              '推奨 Lv.${stage.level}　敵 ${stage.enemies.length}体${number == 5 ? '（ボスあり）' : ''}'),
          Text(
              cleared
                  ? '初回報酬 受取済み'
                  : '初回報酬 ${stage.coins}ポイント・${GameCatalog.equipment[stage.item]!.item.name}',
              style: const TextStyle(
                  color: Color(0xffa9e5df), fontSize: 12, height: 1.8)),
          const Divider(height: 20),
          QuestCommand(
              label: !unlocked
                  ? '前のステージをクリアして解放'
                  : cleared
                      ? 'もう一度 挑戦する'
                      : '冒険に出発する',
              onTap: !unlocked ||
                      controller.busy ||
                      controller.activeFocus != null ||
                      state.adventureRun != null
                  ? null
                  : () => _open(context, stage.id)),
        ]));
  }
}

class AdventureBattlePage extends StatefulWidget {
  const AdventureBattlePage({super.key, required this.controller});
  final GameController controller;
  @override
  State<AdventureBattlePage> createState() => _AdventureBattlePageState();
}

class _AdventureBattlePageState extends State<AdventureBattlePage>
    with WidgetsBindingObserver {
  late final AdventureRun _run;
  late final AdventureBattle _battle;
  late final Timer _timer;
  int _revealed = 0;
  bool _saving = false;
  String? _error;
  AdventureRecord? _record;
  @override
  void initState() {
    super.initState();
    _run = widget.controller.state!.adventureRun!;
    _battle = AdventureBattle.simulate(_run);
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) => _tick());
    WidgetsBinding.instance.addPostFrameCallback((_) => _tick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _tick();
  }

  void _tick() {
    if (!mounted || _record != null) return;
    final count = _battle.revealed(_run, widget.controller.clock());
    if (count != _revealed) setState(() => _revealed = count);
    if (_revealed == _battle.events.length &&
        !_saving &&
        _error == null &&
        !widget.controller.busy) {
      _finish();
    }
  }

  Future<void> _finish() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final result = await widget.controller.finishAdventure(_run.id);
      if (mounted) setState(() => _record = result);
    } catch (_) {
      if (mounted) setState(() => _error = '結果を保存できませんでした。再試行できます。');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final stage = AdventureCatalog.stage(_run.stageId);
    final event = _revealed == 0 ? null : _battle.events[_revealed - 1];
    final enemy = stage.enemies[event?.enemyIndex ?? 0];
    final heroHp = event?.heroHp ?? _run.stats.hp;
    final enemyHp = event?.enemyHp ?? enemy.stats.hp;
    final record = _record;
    return Scaffold(
        appBar: AppBar(title: Text(stage.name)),
        body: Stack(fit: StackFit.expand, children: [
          Image.asset('assets/images/ui/forest_meadow_battlefield.png',
              fit: BoxFit.cover),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                Color(0x66081722),
                Color(0x11081722),
                Color(0xee081722)
              ]))),
          SafeArea(
              child: ListView(padding: const EdgeInsets.all(16), children: [
            QuestCard(
                caption: '自動戦闘',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_run.heroName}　HP $heroHp / ${_run.stats.hp}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(value: heroHp / _run.stats.hp),
                      const SizedBox(height: 8),
                      Text(
                          '${enemy.boss ? 'BOSS　' : ''}${enemy.name}　HP $enemyHp / ${enemy.stats.hp}'),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: enemyHp / enemy.stats.hp,
                          color: enemy.boss
                              ? const Color(0xffedb67d)
                              : const Color(0xffb5d998)),
                    ])),
            SizedBox(
                height: 220,
                child: LayoutBuilder(
                    builder: (context, constraints) => Stack(children: [
                          Positioned(
                              left: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: heroHp == 0 ? .35 : 1,
                                  child: event?.heroAttacks == true &&
                                          event!.damage > 0
                                      ? PixelSprite(
                                          key: ValueKey('attack-$_revealed'),
                                          asset:
                                              'assets/images/adventure/hero_attack.png',
                                          columns: 4,
                                          frames: 8,
                                          size: constraints.maxWidth * .46,
                                          loop: false)
                                      : PixelHero(
                                          size: constraints.maxWidth * .46))),
                          Positioned(
                              right: 0,
                              bottom: 0,
                              child: AnimatedOpacity(
                                  duration: const Duration(milliseconds: 250),
                                  opacity: enemyHp == 0 ? .25 : 1,
                                  child: PixelSprite(
                                      key: ValueKey(
                                          'enemy-${event?.enemyIndex ?? 0}'),
                                      asset:
                                          'assets/images/enemies/${enemy.asset}_move_sheet.png',
                                      columns: 3,
                                      frames: 6,
                                      size: constraints.maxWidth *
                                          (enemy.boss ? .50 : .42)))),
                          if (event != null && event.damage > 0)
                            Positioned(
                                left: event.heroAttacks ? null : 54,
                                right: event.heroAttacks ? 54 : null,
                                top: 8,
                                child: Text('${event.damage}',
                                    key: ValueKey('damage-$_revealed'),
                                    style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                              color: Colors.black,
                                              blurRadius: 6,
                                              offset: Offset(2, 2))
                                        ]))),
                        ]))),
            QuestCard(
                caption: record == null
                    ? '戦いの記録'
                    : record.won
                        ? '勝利！'
                        : '再び、旅立つために',
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(event?.message ?? '剣を携え、森へ足を踏み入れた。',
                          style: const TextStyle(fontSize: 17, height: 1.7)),
                      if (_revealed > 1) ...[
                        const SizedBox(height: 8),
                        for (final previous in _battle.events.sublist(
                            (_revealed - 3).clamp(0, _revealed - 1),
                            _revealed - 1))
                          Text(previous.message,
                              style: const TextStyle(
                                  color: Colors.white60,
                                  fontSize: 12,
                                  height: 1.5)),
                      ],
                      if (_saving) const Text('冒険の書に 記録しています…'),
                      if (_error != null) ...[
                        Text(_error!),
                        QuestCommand(
                            label: '保存を再試行する', onTap: _saving ? null : _finish)
                      ],
                      if (record != null) ...[
                        const Divider(),
                        Text(
                            record.won
                                ? record.coins > 0
                                    ? '初回クリア報酬\n${record.coins}ポイント・${GameCatalog.equipment[record.item]!.item.name}'
                                    : 'このステージの初回報酬は受取済みです。'
                                : '集中でレベルを上げ、装備を整えて再挑戦しよう。\nポイントや装備は失われません。',
                            style: const TextStyle(height: 1.7)),
                        if (record.won &&
                            stage.id != AdventureCatalog.stages.last.id)
                          const Text('次のステージが 解放された！',
                              style: TextStyle(
                                  color: Color(0xffa9e5df), height: 2)),
                        QuestCommand(
                            label: '冒険の書へ戻る',
                            onTap: () => Navigator.pop(context)),
                      ] else
                        const Text('画面を閉じても冒険は保存されます。',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white60,
                                height: 2)),
                    ])),
          ])),
        ]));
  }
}

class PixelHero extends StatelessWidget {
  const PixelHero({super.key, this.size = 128});
  final double size;
  @override
  Widget build(BuildContext context) =>
      Image.asset('assets/images/adventure/hero_idle.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.none);
}

/// Draw exact 128px cells without smoothing the existing pixel art.
class PixelSprite extends StatefulWidget {
  const PixelSprite(
      {super.key,
      required this.asset,
      required this.columns,
      required this.frames,
      this.size = 128,
      this.loop = true});
  final String asset;
  final int columns, frames;
  final double size;
  final bool loop;
  @override
  State<PixelSprite> createState() => _PixelSpriteState();
}

class _PixelSpriteState extends State<PixelSprite>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animation;
  ui.Image? _image;
  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
        vsync: this, duration: Duration(milliseconds: widget.loop ? 500 : 800));
    if (widget.loop) {
      _animation.repeat();
    } else {
      _animation.forward();
    }
    _load();
  }

  Future<void> _load() async {
    final bytes = await rootBundle.load(widget.asset);
    final codec = await ui.instantiateImageCodec(
        bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes));
    final frame = await codec.getNextFrame();
    codec.dispose();
    if (mounted) {
      setState(() => _image = frame.image);
    } else {
      frame.image.dispose();
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    _image?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => SizedBox(
          width: widget.size,
          height: widget.size,
          child: _image == null
              ? const SizedBox.shrink()
              : CustomPaint(
                  painter: _SpritePainter(
                      _image!,
                      (_animation.value * widget.frames)
                          .floor()
                          .clamp(0, widget.frames - 1),
                      widget.columns))));
}

class _SpritePainter extends CustomPainter {
  const _SpritePainter(this.image, this.frame, this.columns);
  final ui.Image image;
  final int frame, columns;
  @override
  void paint(Canvas canvas, Size size) => canvas.drawImageRect(
      image,
      Rect.fromLTWH(
          (frame % columns) * 128.0, (frame ~/ columns) * 128.0, 128, 128),
      Offset.zero & size,
      Paint()..filterQuality = FilterQuality.none);
  @override
  bool shouldRepaint(_SpritePainter old) =>
      old.image != image || old.frame != frame;
}

import 'adventure_stage_layout.dart';
import '../../../core/widgets/game_ui.dart';
import 'dart:async';
import '../../../core/widgets/sunlit_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/widgets/quest_display.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_stage_catalog.dart';
import 'playable_stage_assets.dart';
import 'playable_stage_painter.dart';
import 'playable_stage_audio.dart';
import 'adventure_battle_hud.dart';

class PlayableStagePage extends StatefulWidget {
  const PlayableStagePage(
      {super.key,
      this.battle,
      this.assets,
      this.stage,
      this.audioOutput,
      this.returnToSelection = false});
  final PlayableStageBattle? battle;
  final PlayableStageAssets? assets;
  final PlayableStageDefinition? stage;
  final bool returnToSelection;
  final StageAudioOutput? audioOutput;
  @override
  State<PlayableStagePage> createState() => _PlayableStagePageState();
}

class _PlayableStagePageState extends State<PlayableStagePage>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        QuestLandscapeState<PlayableStagePage> {
  late final PlayableStageBattle _battle;
  late final Ticker _ticker;
  late final PlayableStageAudio _audio;
  PlayableStageAssets? _assets;
  Duration? _lastTick;
  String? _error;
  Timer? _returnTimer;
  bool _returned = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _battle = widget.battle ?? PlayableStageBattle(stage: widget.stage);
    _audio = PlayableStageAudio(_battle, output: widget.audioOutput);
    _audio.addListener(_audioChanged);
    _battle.addListener(_onBattleChanged);
    _ticker = createTicker((elapsed) {
      final previous = _lastTick;
      _lastTick = elapsed;
      if (previous != null && _assets != null) {
        for (final enemy in _battle.enemies) {
          final motion = _assets!.motions['${enemy.definition.id}_attack']!;
          enemy.attackDuration = motion.duration;
          enemy.hitTick = motion.eventTick(
              'attack_active_or_release',
              motion.eventTick(
                  'enemy_attack_hit',
                  motion.eventTick('boss_attack_hit',
                      motion.eventTick('fire_breath_start', 11))));
          enemy.defeatDuration =
              _assets!.motions['${enemy.definition.id}_defeat']!.duration;
        }
        _battle.update((elapsed - previous).inMicroseconds / 1000000);
      }
    })
      ..start();
    if (widget.assets != null) {
      _setAssets(widget.assets!);
    } else {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final assets = await PlayableStageAssets.load(
          stage: _battle.stage, character: _battle.character);
      if (!mounted) {
        assets.dispose();
        return;
      }
      setState(() => _setAssets(assets));
    } catch (_) {
      if (mounted) setState(() => _error = 'ステージ素材を読み込めませんでした。');
    }
  }

  void _setAssets(PlayableStageAssets assets) {
    _assets = assets;
    final attack = assets.motions['hero_attack']!;
    final skill = assets.motions['hero_skill']!;
    _battle.heroHurtDuration = assets.motions['hero_hurt']?.duration ?? .5;
    _battle.heroDefeatDuration =
        assets.motions['hero_defeat']?.duration ?? 1.25;
    _battle.configureHeroTiming(attack.metadata, skill.metadata);
  }

  void _onBattleChanged() {
    if (!widget.returnToSelection) return;
    if (_battle.mode == StageMode.won) {
      _returnTimer ??=
          Timer(const Duration(milliseconds: 1400), _returnToSelection);
    } else {
      _returnTimer?.cancel();
      _returnTimer = null;
    }
  }

  void _audioChanged() {
    if (mounted) setState(() {});
  }

  void _returnToSelection() {
    if (!mounted || _returned) return;
    _returned = true;
    Navigator.of(context).pop(_battle.mode == StageMode.won);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) _battle.pause();
    _lastTick = null;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _returnTimer?.cancel();
    _battle.removeListener(_onBattleChanged);
    _audio.removeListener(_audioChanged);
    unawaited(_audio.close());
    if (widget.battle == null) _battle.dispose();
    if (widget.assets == null) _assets?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _battle,
      builder: (context, _) => Scaffold(
          backgroundColor: const Color(0xff122b24),
          body: SafeArea(
              child: Stack(fit: StackFit.expand, children: [
            _scene(),
            AdventureBattleHud(
              battle: _battle,
              utilities: _utilities(),
            ),
            if (_assets == null ||
                _battle.mode == StageMode.ready ||
                _battle.paused ||
                _battle.mode == StageMode.won ||
                (_battle.mode == StageMode.lost && _battle.heroDefeatFinished))
              ColoredBox(
                  color: const Color(0x99112b23),
                  child: Center(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.all(18),
                          child: _overlay()))),
            Positioned(
                left: 4,
                top: 4,
                child: BackButton(
                    color: const Color(0xffffecc0),
                    onPressed: () => Navigator.of(context).maybePop())),
          ]))));

  Widget _utilities() => Row(mainAxisSize: MainAxisSize.min, children: [
        _utility(
            'stage-sound',
            !_audio.available
                ? '音声を再生できません'
                : _audio.enabled
                    ? '音を消す'
                    : '音を出す',
            _audio.enabled ? Icons.volume_up : Icons.volume_off,
            _audio.available ? _audio.toggle : null),
        _utility(
            'stage-pause',
            _battle.paused ? '再開' : '一時停止',
            _battle.paused ? Icons.play_arrow : Icons.pause,
            !_battle.active
                ? null
                : () => _battle.paused ? _battle.resume() : _battle.pause()),
        _utility('stage-reset', 'やり直す', Icons.restart_alt,
            _assets == null ? null : _battle.restart),
      ]);

  Widget _utility(
      String key, String tooltip, IconData icon, VoidCallback? onTap) {
    final side = (MediaQuery.sizeOf(context).width * .053).clamp(44.0, 80.0);
    return Padding(
        padding: const EdgeInsets.only(left: 6),
        child: SizedBox(
            width: side,
            height: side,
            child: Stack(fit: StackFit.expand, children: [
              const AdventureFrame('utility_button'),
              IconButton(
                  key: Key(key),
                  tooltip: tooltip,
                  onPressed: onTap,
                  color: const Color(0xffffecc0),
                  icon: Icon(icon, size: side * .54)),
            ])));
  }

  Widget _scene() => LayoutBuilder(builder: (context, constraints) {
        final layout = AdventureStageLayout(constraints.biggest);
        final bottomInset = layout.bottomInset(_battle.stage.groundLine);
        final size =
            PlayableStagePainter.worldSize(constraints.biggest, bottomInset);
        _battle.spriteWorldSide = PlayableStagePainter.baseSpriteSide(
                size, MediaQuery.devicePixelRatioOf(context)) *
            1280 /
            size.width;
        return ClipRect(
            child: Stack(fit: StackFit.expand, children: [
          if (_assets != null) ...[
            CustomPaint(
                key: const Key('stage-canvas'),
                painter: PlayableStagePainter(
                    _battle, _assets!, MediaQuery.devicePixelRatioOf(context),
                    bottomInset: bottomInset)),
            ..._headHealth(
                PlayableStagePainter(
                    _battle, _assets!, MediaQuery.devicePixelRatioOf(context),
                    bottomInset: bottomInset),
                constraints.biggest),
          ],
          if (_battle.message.isNotEmpty && _battle.mode != StageMode.ready)
            Positioned(
              top: layout.messageTop,
              left: 12,
              right: 12,
              child: Center(
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: const Color(0xdd193b29),
                          borderRadius: BorderRadius.circular(5)),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Text(_battle.message,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15, color: Colors.white))))),
            ),
        ]));
      });

  List<Widget> _headHealth(PlayableStagePainter painter, Size size) {
    final occupied = <Rect>[];
    final widgets = <Widget>[];
    void place(Offset head, double width, double height, Widget child) {
      final left = (head.dx - width / 2).clamp(6.0, size.width - width - 6);
      var top = (head.dy - height - 7).clamp(56.0, size.height - height);
      var rect = Rect.fromLTWH(left, top, width, height);
      for (var attempt = 0; attempt < occupied.length + 1; attempt++) {
        final collisions =
            occupied.where((other) => other.inflate(3).overlaps(rect));
        if (collisions.isEmpty) break;
        final next = (collisions.first.top - height - 4).clamp(56.0, top);
        if (next == top) break;
        top = next;
        rect = Rect.fromLTWH(left, top, width, height);
      }
      occupied.add(rect);
      widgets.add(Positioned(
          left: rect.left, top: rect.top, width: rect.width, child: child));
    }

    place(painter.heroHead(size), 112, 28,
        _hp(_battle.character.role, _battle.hp, _battle.character.health));
    if (_battle.mode == StageMode.battle ||
        (_battle.mode == StageMode.travel && _battle.modeTime > 1.8)) {
      for (final enemy in _battle.enemies.where((enemy) => enemy.alive).toList()
        ..sort((a, b) => (b.definition.isBoss ? 1 : 0)
            .compareTo(a.definition.isBoss ? 1 : 0))) {
        place(
            painter.enemyHead(size, enemy),
            enemy.definition.isBoss ? 168 : 96,
            enemy.definition.isBoss ? 48 : 28,
            _enemyHp(enemy));
      }
    }
    return widgets;
  }

  Widget _enemyHp(StageEnemy enemy) => Semantics(
      label: '敵${enemy.index + 1} ${enemy.definition.name}',
      value: enemy.alive ? 'HP ${enemy.hp} / ${enemy.definition.hp}' : '撃破',
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (enemy.definition.isBoss)
              Text(
                  '${enemy.definition.isBoss ? 'BOSS' : enemy.index + 1} · ${enemy.definition.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: !enemy.alive
                          ? Colors.white38
                          : enemy.definition.isBoss
                              ? sunlitGold
                              : Colors.white)),
            Text(enemy.alive ? '${enemy.hp} / ${enemy.definition.hp}' : '撃破',
                key: Key('enemy-hp-value-${enemy.index}'),
                style: const TextStyle(
                    fontFamily: 'SunlitSerif',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                      Shadow(color: Colors.black, offset: Offset(1, 1))
                    ])),
            const SizedBox(height: 2),
            LinearProgressIndicator(
                key: Key('enemy-hp-${enemy.index}'),
                value: (enemy.hp / enemy.definition.hp).clamp(0.0, 1.0),
                minHeight: enemy.definition.isBoss ? 6 : 3,
                backgroundColor: const Color(0xff233b51),
                color: enemy.definition.isBoss
                    ? sunlitGold
                    : const Color(0xffee8877)),
          ]));

  Widget _hp(String name, int hp, int max) => Semantics(
      label: '$name HP',
      value: '$hp / $max',
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$hp / $max',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.black, blurRadius: 4),
                      Shadow(color: Colors.black, offset: Offset(1, 1))
                    ])),
            const SizedBox(height: 3),
            LinearProgressIndicator(
                key: const Key('player-hp'),
                value: (hp / max).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: const Color(0xaa041328),
                color: const Color(0xff6dc5e9)),
          ]));

  Widget _overlay() {
    final won = _battle.mode == StageMode.won,
        lost = _battle.mode == StageMode.lost;
    final title = _error != null
        ? '読み込みエラー'
        : _assets == null
            ? 'ステージを準備中'
            : _battle.paused
                ? 'ひと休み。'
                : won
                    ? 'STAGE ${_battle.stage.number} クリア！'
                    : lost
                        ? 'もう一度、挑もう。'
                        : '${_battle.character.role}で、${_battle.stage.area}へ。';
    return GamePanel(
        child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Color(0xfff5e5b6))),
              const SizedBox(height: 12),
              Text(
                  _error ??
                      (won
                          ? '3フェーズ突破！\n命中 ${_battle.hits}回 · ミス ${_battle.misses}回\nクリティカル ${_battle.criticals}回 · スキル ${_battle.skills}回\n${_battle.clock.ceil()}秒でクリア'
                          : lost
                              ? '${_battle.phase + 1}フェーズ目で力尽きた。\n集中でレベルを上げて再挑戦しよう。\n推奨 Lv.${_battle.stage.recommendedLevel}'
                              : _battle.paused
                                  ? '準備ができたら、冒険を続けよう。'
                                  : '通常攻撃：命中90%\nクリティカル：20%・ダメージ2倍\n通常攻撃3回で外周ゲージが満タンになり、必中スキルが使える。'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, height: 1.8)),
              const SizedBox(height: 16),
              if (_assets == null && _error == null)
                const CircularProgressIndicator()
              else
                FilledButton(
                    key: const Key('stage-start'),
                    style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xffe8cd85),
                        foregroundColor: const Color(0xff233629)),
                    onPressed: _error != null
                        ? _load
                        : _battle.paused
                            ? _battle.resume
                            : won && widget.returnToSelection
                                ? _returnToSelection
                                : _battle.restart,
                    child: Text(_error != null
                        ? '再試行'
                        : _battle.paused
                            ? '冒険を再開'
                            : won && widget.returnToSelection
                                ? 'ステージ選択へ'
                                : won || lost
                                    ? 'もう一度プレイ'
                                    : '冒険をはじめる')),
              if (widget.returnToSelection && lost) ...[
                const SizedBox(height: 8),
                TextButton(
                    onPressed: _returnToSelection,
                    child: const Text('ステージ選択へ')),
              ],
            ])));
  }
}

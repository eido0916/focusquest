import 'dart:async';
import '../../../core/widgets/sunlit_widgets.dart';
import 'adventure_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../domain/playable_stage_battle.dart';
import '../domain/playable_stage_catalog.dart';
import 'playable_stage_assets.dart';
import 'playable_stage_painter.dart';
import 'playable_stage_audio.dart';

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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
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
    if (int.parse(_battle.character.id.split('_')[1]) >= 11) {
      _battle.attackDuration = attack.duration;
      _battle.skillDuration = skill.duration;
    }
    _battle.attackHitFraction =
        attack.eventTick(_battle.character.attackEvent, 12) /
            (24 * attack.duration);
    _battle.skillHitFraction =
        skill.eventTick(_battle.character.skillEvent, 20) /
            (24 * skill.duration);
    _battle.attackReleaseFractions = attack
        .eventTicks(_battle.character.attackEvent)
        .map((tick) => tick / (24 * attack.duration))
        .toList();
    _battle.skillReleaseFractions = skill
        .eventTicks(_battle.character.skillEvent)
        .map((tick) => tick / (24 * skill.duration))
        .toList();
    _battle.actionOffsetPx = (isSkill, progress) {
      final motion = isSkill ? skill : attack;
      return motion.frame(progress * motion.duration).offset.dx;
    };
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
      builder: (context, _) =>
          AdventureUi(child: Scaffold(body: SafeArea(child: _scene()))));

  Widget _toolbar() => IconButtonTheme(
      data: IconButtonThemeData(
          style: IconButton.styleFrom(
        backgroundColor: const Color(0xe6081424),
        foregroundColor: Colors.white,
        disabledBackgroundColor: const Color(0xc6081424),
        disabledForegroundColor: const Color(0xffb7c5d8),
        shape: const CircleBorder(side: BorderSide(color: Color(0x88ffffff))),
      )),
      child: SizedBox(
          height: 44,
          child: Row(children: [
            if (Navigator.of(context).canPop()) const BackButton(),
            Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text('PHASE ${_battle.phase + 1} / 3',
                    style: const TextStyle(fontSize: 12, color: Colors.white))),
            const Spacer(),
            IconButton(
                key: const Key('stage-sound'),
                tooltip: !_audio.available
                    ? '音声を再生できません'
                    : _audio.enabled
                        ? '音を消す'
                        : '音を出す',
                onPressed: _audio.available ? _audio.toggle : null,
                icon:
                    Icon(_audio.enabled ? Icons.volume_up : Icons.volume_off)),
            IconButton(
                key: const Key('stage-pause'),
                tooltip: _battle.paused ? '再開' : '一時停止',
                onPressed: !_battle.active
                    ? null
                    : () => _battle.paused ? _battle.resume() : _battle.pause(),
                icon: Icon(_battle.paused ? Icons.play_arrow : Icons.pause)),
            IconButton(
                key: const Key('stage-reset'),
                tooltip: 'やり直す',
                onPressed: _assets == null ? null : _battle.restart,
                icon: const Icon(Icons.restart_alt)),
          ])));

  Widget _scene() => LayoutBuilder(builder: (context, constraints) {
        final size = PlayableStagePainter.worldSize(constraints.biggest, 112);
        _battle.spriteWorldSide = PlayableStagePainter.baseSpriteSide(
                size, MediaQuery.devicePixelRatioOf(context)) *
            1280 /
            size.width;
        final painter = _assets == null
            ? null
            : PlayableStagePainter(
                _battle, _assets!, MediaQuery.devicePixelRatioOf(context),
                bottomInset: 112);
        return ClipRect(
            child: Stack(fit: StackFit.expand, children: [
          if (painter != null)
            CustomPaint(key: const Key('stage-canvas'), painter: painter),
          if (painter != null) ..._headHealth(painter, constraints.biggest),
          Positioned(right: 12, bottom: 12, child: _controls()),
          if (_assets == null ||
              _battle.mode == StageMode.ready ||
              _battle.paused ||
              _battle.mode == StageMode.won ||
              _battle.mode == StageMode.lost)
            ColoredBox(
                color: const Color(0x99071c3c),
                child: Center(
                    child: SingleChildScrollView(
                        padding: const EdgeInsets.all(18), child: _overlay()))),
          Positioned(top: 8, left: 8, right: 8, child: _toolbar()),
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

    place(painter.heroHead(size), 96, 24,
        _hp(_battle.character.role, _battle.hp, _battle.character.health));
    if (_battle.mode == StageMode.battle ||
        (_battle.mode == StageMode.travel && _battle.modeTime > 1.8)) {
      for (final enemy in _battle.enemies.where((enemy) => enemy.alive).toList()
        ..sort((a, b) => (b.definition.isBoss ? 1 : 0)
            .compareTo(a.definition.isBoss ? 1 : 0))) {
        place(
            painter.enemyHead(size, enemy),
            enemy.definition.isBoss ? 128 : 64,
            enemy.definition.isBoss ? 44 : 24,
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
                      fontSize: enemy.definition.isBoss ? 12 : 11,
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
                    fontSize: 11,
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
                    fontSize: 12,
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
    return ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SunlitFrame(
            padding: const EdgeInsets.all(22),
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
                              ? '${_battle.phase + 1}フェーズ目で力尽きた。\n攻撃とスキルを組み合わせよう。'
                              : _battle.paused
                                  ? '準備ができたら、冒険を続けよう。'
                                  : '通常攻撃：命中90%\nクリティカル：20%・ダメージ2倍\n通常攻撃を3回当てると必中スキルが使える。'),
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
                        foregroundColor: const Color(0xff071c3c)),
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

  Widget _controls() => Row(
          key: const Key('stage-floating-controls'),
          mainAxisSize: MainAxisSize.min,
          children: [
            _command(
                '攻撃',
                Icons.sports_martial_arts,
                const Key('stage-attack'),
                _battle.canAttack ? _battle.attack : null,
                _battle.action != null
                    ? '行動中'
                    : '${_battle.attackDuration.toStringAsFixed(2)}秒 / 回',
                false),
            const SizedBox(width: 12),
            _command(
                'スキル',
                Icons.bolt,
                const Key('stage-skill'),
                _battle.canSkill ? _battle.skill : null,
                _battle.charge == 3
                    ? _battle.character.skillName
                    : '命中 ${_battle.charge} / 3',
                true),
          ]);

  Widget _command(String label, IconData icon, Key key, VoidCallback? onTap,
      String caption, bool skill) {
    final color = skill ? const Color(0xff247ce8) : const Color(0xffe43c46);
    final busy = _battle.action != null;
    final duration = _battle.action == HeroAction.skill
        ? _battle.skillDuration
        : _battle.attackDuration;
    final progress = busy
        ? (_battle.actionTime / duration).clamp(0.0, 1.0)
        : (skill ? _battle.charge / 3 : 1.0);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      SizedBox(
          width: 96,
          height: 96,
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(
                width: 96,
                height: 96,
                child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    color: sunlitGold,
                    backgroundColor: const Color(0xff12213a))),
            Semantics(
                label: '$label、$caption',
                button: true,
                enabled: onTap != null,
                child: FilledButton(
                    key: key,
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                        fixedSize: const Size(84, 84),
                        padding: EdgeInsets.zero,
                        shape: const CircleBorder(
                            side: BorderSide(color: sunlitGold, width: 1.5)),
                        backgroundColor: color,
                        disabledBackgroundColor: skill
                            ? const Color(0xff234f86)
                            : const Color(0xff85343c),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(icon, size: 30),
                      Text(label,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'SunlitSerif')),
                      if (skill)
                        Text(
                            _battle.canSkill
                                ? '発動可能'
                                : busy
                                    ? '行動中'
                                    : '${_battle.charge} / 3',
                            style: const TextStyle(
                                fontFamily: 'SunlitSerif',
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                    ]))),
          ])),
    ]);
  }
}

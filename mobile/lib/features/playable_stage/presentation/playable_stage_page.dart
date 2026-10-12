import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
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
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final PlayableStageBattle _battle;
  late final Ticker _ticker;
  late final PlayableStageAudio _audio;
  PlayableStageAssets? _assets;
  Duration? _lastTick;
  String? _error;
  Timer? _returnTimer;
  bool _returned = false;
  bool _auto = false;
  @override
  void initState() {
    super.initState();
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]));
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
        if (_auto && !_battle.paused) {
          if (_battle.canSkill) {
            _battle.skill();
          } else if (_battle.canAttack) {
            _battle.attack();
          }
        }
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
    unawaited(SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]));
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
              auto: _auto,
              onAuto: () => setState(() => _auto = !_auto),
              utilities: _utilities(),
            ),
            if (_assets == null ||
                _battle.mode == StageMode.ready ||
                _battle.paused ||
                _battle.mode == StageMode.won ||
                _battle.mode == StageMode.lost)
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
        final size = constraints.biggest;
        _battle.spriteWorldSide = PlayableStagePainter.baseSpriteSide(
                size, MediaQuery.devicePixelRatioOf(context)) *
            1280 /
            size.width;
        return ClipRect(
            child: Stack(fit: StackFit.expand, children: [
          if (_assets != null)
            CustomPaint(
                key: const Key('stage-canvas'),
                painter: PlayableStagePainter(
                    _battle, _assets!, MediaQuery.devicePixelRatioOf(context))),
          if (_battle.message.isNotEmpty && _battle.mode != StageMode.ready)
            Positioned(
              top: constraints.maxWidth > constraints.maxHeight ? 125 : 290,
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
                              style: const TextStyle(fontSize: 12))))),
            ),
        ]));
      });

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
    return Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xff19382c),
            border: Border.all(color: const Color(0xffbca773)),
            borderRadius: BorderRadius.circular(12)),
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
                onPressed: _returnToSelection, child: const Text('ステージ選択へ')),
          ],
        ]));
  }
}

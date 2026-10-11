import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../game/runner/female_battle_assets.dart';
import '../../diagnosis/presentation/job_portrait.dart';

/// Uses the same reviewed female poses as the focus battle, without tweening.
class FemaleAdventureHero extends StatefulWidget {
  const FemaleAdventureHero(
      {super.key,
      required this.characterType,
      required this.size,
      this.attacking = false});
  final String characterType;
  final double size;
  final bool attacking;

  @override
  State<FemaleAdventureHero> createState() => _FemaleAdventureHeroState();
}

class _FemaleAdventureHeroState extends State<FemaleAdventureHero>
    with SingleTickerProviderStateMixin {
  static final _assets = <String, Future<FemaleBattleAssets>>{};
  late final AnimationController _animation;
  late Future<FemaleBattleAssets> _loaded;

  Future<FemaleBattleAssets> _load() => _assets.putIfAbsent(
      widget.characterType,
      () => FemaleBattleAssets.load(FlameGame(), widget.characterType));

  @override
  void initState() {
    super.initState();
    _animation = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _loaded = _load();
    _startWhenLoaded();
  }

  void _startWhenLoaded() {
    _loaded.then((_) {
      if (mounted && widget.attacking) _animation.forward(from: 0);
    }, onError: (Object _) {});
  }

  @override
  void didUpdateWidget(FemaleAdventureHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.characterType != widget.characterType) {
      _loaded = _load();
      _startWhenLoaded();
    }
    if (oldWidget.attacking != widget.attacking) {
      if (widget.attacking) {
        _startWhenLoaded();
      } else {
        _animation.reset();
      }
    }
  }

  @override
  void dispose() {
    _animation.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
      label: '女の${JobPortrait.roleNames[widget.characterType]}',
      child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: FutureBuilder<FemaleBattleAssets>(
              future: _loaded,
              builder: (context, snapshot) {
                final assets = snapshot.data;
                if (assets == null) {
                  return JobPortrait(
                      typeId: widget.characterType,
                      appearance: 'female',
                      height: widget.size);
                }
                return AnimatedBuilder(
                    animation: _animation,
                    builder: (_, __) => CustomPaint(
                        painter: _HeroPainter(assets,
                            widget.attacking ? _animation.value : null)));
              })));
}

class _HeroPainter extends CustomPainter {
  const _HeroPainter(this.assets, this.progress);
  final FemaleBattleAssets assets;
  final double? progress;
  @override
  void paint(Canvas canvas, Size size) {
    final sprite = progress == null
        ? assets.run.frames.first.sprite
        : FemaleBattleAssets.poseAt(assets.attack,
            progress! * FemaleBattleAssets.duration(assets.attack));
    final scale = size.height / assets.frameSize.y;
    final width = assets.frameSize.x * scale;
    canvas.drawImageRect(
        sprite.image,
        ui.Rect.fromLTWH(sprite.srcPosition.x, sprite.srcPosition.y,
            sprite.srcSize.x, sprite.srcSize.y),
        ui.Rect.fromLTWH((size.width - width) / 2, 0, width, size.height),
        Paint()..filterQuality = FilterQuality.none);
  }

  @override
  bool shouldRepaint(_HeroPainter old) =>
      old.assets != assets || old.progress != progress;
}

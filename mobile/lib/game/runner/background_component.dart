import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'battle_state_controller.dart';

class BackgroundComponent extends Component {
  BackgroundComponent(this.state);
  final BattleStateController state;

  @override
  void render(Canvas canvas) {
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 960, 540),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x12000000), Color(0x00000000), Color(0x40031425)],
        ).createShader(const Rect.fromLTWH(0, 0, 960, 540)),
    );
  }
}

import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'enemy_component.dart';
import 'damage_text_component.dart';

class EnemySpawner extends Component {
  EnemySpawner(this.state);
  final BattleStateController state;
  final Map<int, EnemyComponent> _visible = {};
  int _attack = 0;
  @override
  void update(double dt) {
    super.update(dt);
    final ids = state.enemies.map((e) => e.id).toSet();
    for (final id in _visible.keys.toList()) {
      if (!ids.contains(id)) _visible.remove(id)!.removeFromParent();
    }
    for (final enemy in state.enemies) {
      if (!_visible.containsKey(enemy.id)) {
        final component = EnemyComponent(enemy);
        _visible[enemy.id] = component;
        add(component);
      }
    }
    if (_attack != state.attackSerial) {
      _attack = state.attackSerial;
      if (state.attackAge < .1) add(DamageTextComponent(330, 128));
    }
  }
}

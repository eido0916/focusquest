import 'package:flame/components.dart';
import 'battle_state_controller.dart';
import 'enemy_component.dart';
import 'damage_text_component.dart';
import 'enemy_motion_assets.dart';

class EnemySpawner extends Component {
  EnemySpawner(this.state, this.assets);
  final BattleStateController state;
  final EnemyMotionAssets assets;
  final Map<int, EnemyComponent> _visible = {};
  final Map<int, int> _seenDamage = {};
  @override
  void update(double dt) {
    super.update(dt);
    final ids = state.enemies.map((e) => e.id).toSet();
    for (final id in _visible.keys.toList()) {
      if (!ids.contains(id)) {
        _visible.remove(id)!.removeFromParent();
        _seenDamage.remove(id);
      }
    }
    for (final enemy in state.enemies) {
      if (!_visible.containsKey(enemy.id)) {
        final component = EnemyComponent(enemy, assets);
        _visible[enemy.id] = component;
        add(component);
      }
      // A single Sousen impact can damage several enemies on the same tick.
      // Track each enemy, not just the last global hit, to show the whole sweep.
      if (enemy.damageSerial > (_seenDamage[enemy.id] ?? 0)) {
        add(DamageTextComponent(enemy.x, enemy.lastDamage));
      }
      _seenDamage[enemy.id] = enemy.damageSerial;
    }
  }
}

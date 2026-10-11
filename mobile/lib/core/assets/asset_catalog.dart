enum ActorPose { idle, attack, damage, death }

/// Null selects a drawn placeholder. Register bundled files in pubspec.yaml.
class AssetCatalog {
  static const Map<String, String?> images = {
    'hero.warrior': null,
    'hero.mage': null,
    'hero.ranger': null,
    'hero.guardian': null,
    'enemy.slime': null,
    'background.forest': 'enchanted_forest.png',
    'currency.coin': null,
    'currency.exp': null,
  };
  static String? image(String key) => images[key];
  static String? animation(String actor, ActorPose pose) =>
      images['$actor.${pose.name}'];
}

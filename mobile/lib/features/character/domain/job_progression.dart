import 'character.dart';

class JobProgression {
  /// All listed requirements must be met. Points are retained after changing jobs.
  static const requirements = <String, Map<String, int>>{
    'warrior': {'discipline': 300, 'vitality': 150},
    'boxer': {'vitality': 300, 'empathy': 150},
    'samurai': {'discipline': 300, 'insight': 150},
    'guardian': {'discipline': 300, 'empathy': 150},
    'ninja': {'insight': 300, 'vitality': 150},
    'assassin': {'insight': 300, 'creativity': 150},
    'ranger': {'insight': 300, 'empathy': 150},
    'mage': {'knowledge': 300, 'creativity': 150},
    'gunner': {'insight': 300, 'knowledge': 150},
    'spellblade': {'knowledge': 300, 'vitality': 150},
    'onmyoji': {'knowledge': 300, 'empathy': 150},
    'reaper': {'insight': 300, 'discipline': 150},
    'angel': {'empathy': 300, 'discipline': 150},
    'devil': {'creativity': 300, 'insight': 150},
    'dragon_knight': {'vitality': 300, 'creativity': 150},
    'berserker': {'vitality': 300, 'discipline': 150},
  };
  static bool canChange(Character hero, String typeId) =>
      requirements.containsKey(typeId) &&
      (hero.characterType == typeId ||
          hero.unlockedJobs.contains(typeId) ||
          requirements[typeId]!
              .entries
              .every((e) => (hero.trainingPoints[e.key] ?? 0) >= e.value));
}

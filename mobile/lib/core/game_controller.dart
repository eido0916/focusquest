import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/game_catalog.dart';
import '../data/player_repository.dart';
import '../data/player_state.dart';
import '../features/character/domain/character.dart';
import '../features/character/domain/progression_service.dart';
import '../features/diagnosis/domain/diagnosis_service.dart';
import '../features/focus/data/usage_monitor.dart';
import '../features/focus/domain/focus_ledger.dart';
import '../features/focus/domain/focus_service.dart';
import '../features/focus/domain/focus_session.dart';
import '../features/focus/domain/reward_service.dart';
import '../features/gacha/domain/gacha_service.dart';
import '../features/adventure/domain/adventure.dart';

class GameController extends ChangeNotifier {
  GameController(this.repository,
      {UsageMonitor? monitor, DateTime Function()? clock, Random? random})
      : monitor = monitor ?? UsageMonitor(),
        clock = clock ?? DateTime.now,
        random = random ?? Random.secure();
  final PlayerRepository repository;
  final UsageMonitor monitor;
  final DateTime Function() clock;
  final Random random;
  PlayerState? state;
  bool busy = false;
  String? startupError;
  static const uid = 'local-player';
  String _id() =>
      '${clock().microsecondsSinceEpoch}-${random.nextInt(1 << 30)}';
  FocusSession? get activeFocus {
    for (final s in state?.sessions.values ?? <FocusSession>[]) {
      if (s.status == FocusStatus.active) return s;
    }
    return null;
  }

  Future<void> load() async {
    startupError = null;
    try {
      state = await repository.load(uid);
    } catch (_) {
      startupError = '保存データを読み込めませんでした。データを保持したまま再試行できます。';
    }
    notifyListeners();
  }

  Future<T> _action<T>(Future<T> Function() operation) async {
    if (busy) throw StateError('保存中です。少し待ってください。');
    busy = true;
    notifyListeners();
    try {
      return await operation();
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> _save(PlayerState Function(PlayerState) change) async {
    state = await repository.transact(uid, change);
  }

  Future<void> onboard(PersonalityType type,
          {String? name, String appearance = 'male'}) =>
      _action(() => _save((s) {
            if (s.onboardingComplete) return s;
            final hero = Character(
                id: 'starter',
                name: name?.trim().isNotEmpty == true ? name!.trim() : type.job,
                appearance: appearance,
                characterType: type.typeId,
                baseStats: type.stats);
            return s.copyWith(
                onboardingComplete: true,
                activeCharacterId: hero.id,
                characters: {hero.id: hero});
          }));
  Future<void> startFocus(int minutes) => _action(() async {
        final s = state!;
        if (s.adventureRun != null) throw StateError('冒険の結果を確認してから集中できます。');
        if (s.monitoring && !await monitor.hasAccess()) {
          throw StateError('使用状況へのアクセスを許可するか、タイマーのみを選んでください。');
        }
        final session = FocusService().start(
            id: _id(),
            now: clock(),
            minutes: minutes,
            monitored: s.monitoring,
            targetPackages: s.targetPackages);
        await _save((s) => FocusLedger().begin(s, session));
      });
  Future<FocusSession?> finishFocus({bool cancel = false}) => _action(() async {
        final session = activeFocus;
        if (session == null) return null;
        final now = clock();
        var result = FocusStatus.cancelled;
        if (!cancel) {
          final evidence = session.verification == FocusVerification.usageStats
              ? await monitor.evidence(session, now)
              : const UsageEvidence(available: false, targetUsed: false);
          result = FocusService().evaluate(session, now,
              usageEvidenceAvailable: evidence.available,
              targetUsed: evidence.targetUsed);
          if (result == FocusStatus.active) return null;
        }
        final finished = session.finish(result);
        final reward = RewardService(random).focus(finished);
        await _save((s) => FocusLedger().settle(s, session.id, result, reward));
        return finished;
      });
  Future<GachaResult> summon(int count) => _action(() async {
        final id = _id();
        final result = GachaService(random: random, pool: GameCatalog.gachaPool)
            .draw(count: count, balance: state!.coins);
        await _save((s) {
          if (s.appliedOperations.contains('gacha:$id')) return s;
          if (s.coins < result.cost) throw StateError('ポイントが足りません。');
          final inventory = {...s.inventory};
          final characters = {...s.characters};
          for (var i = 0; i < result.prizes.length; i++) {
            final prize = result.prizes[i];
            if (prize.kind == GachaPrizeKind.equipment) {
              inventory[prize.id] = (inventory[prize.id] ?? 0) + 1;
            } else {
              final type = GameCatalog.types.values
                  .firstWhere((t) => t.typeId == prize.id);
              final characterId = '$id-$i';
              characters[characterId] = Character(
                  id: characterId,
                  name: prize.name,
                  characterType: type.typeId,
                  baseStats: type.stats,
                  rarity: prize.rarity);
            }
          }
          return s.copyWith(
              coins: s.coins - result.cost,
              inventory: inventory,
              characters: characters,
              gachaHistory: [
                ...s.gachaHistory,
                {
                  'id': id,
                  'at': clock().toIso8601String(),
                  'cost': result.cost,
                  'prizes': result.prizes
                      .map((p) =>
                          {'id': p.id, 'name': p.name, 'rarity': p.rarity})
                      .toList()
                }
              ],
              appliedOperations: {
                ...s.appliedOperations,
                'gacha:$id'
              });
        });
        return result;
      });
  Future<void> equip(String itemId) => _action(() => _save((s) {
        if (s.adventureRun != null) throw StateError('冒険の終了後に装備を変更できます。');
        if (activeFocus != null) {
          throw StateError('集中の完了後に装備を変更できます。');
        }
        final hero = ProgressionService().equip(
            s.activeCharacter!, GameCatalog.equipment[itemId]!, s.inventory);
        // Equipment instances cannot be equipped by two characters simultaneously.
        final characters = {...s.characters};
        for (final other in characters.values.toList()) {
          if (other.id != hero.id &&
              other.equippedItems.values.contains(itemId)) {
            characters[other.id] = other.copyWith(
                equippedItems: {...other.equippedItems}
                  ..removeWhere((_, value) => value == itemId));
          }
        }
        characters[hero.id] = hero;
        return s.copyWith(characters: characters);
      }));
  Future<void> selectCharacter(String id) => _action(() => _save((s) {
        if (s.adventureRun != null) throw StateError('冒険の終了後に仲間を変更できます。');
        if (activeFocus != null) {
          throw StateError('集中中は仲間を変更できません。');
        }
        if (!s.characters.containsKey(id)) throw StateError('仲間が見つかりません。');
        return s.copyWith(activeCharacterId: id);
      }));
  Future<void> configureMonitoring(bool enabled, List<String> packages) =>
      _action(() => _save((s) {
            if (activeFocus != null) throw StateError('集中が終わってから設定してください。');
            if (enabled && packages.isEmpty) {
              throw StateError('対象アプリを選択してください。');
            }
            return s.copyWith(
                monitoring: enabled,
                targetPackages: List.unmodifiable(packages));
          }));

  Future<void> startAdventure(String stageId) => _action(() async {
        final id = _id();
        final seed = random.nextInt(1 << 30);
        final startedAt = clock();
        await _save((s) {
          if (s.adventureRun != null) throw StateError('進行中の冒険があります。');
          if (s.sessions.values.any((f) => f.status == FocusStatus.active)) {
            throw StateError('集中が終わってから冒険に出発しましょう。');
          }
          if (!AdventureCatalog.unlocked(stageId, s.clearedStages)) {
            throw StateError('前のステージをクリアしてください。');
          }
          final hero = s.activeCharacter;
          if (hero == null) throw StateError('キャラクターを決定してください。');
          return s.copyWith(
              adventureRun: AdventureRun(
                  id: id,
                  stageId: stageId,
                  heroName: hero.name,
                  seed: seed,
                  startedAt: startedAt,
                  stats:
                      ProgressionService().stats(hero, GameCatalog.equipment)));
        });
      });

  Future<AdventureRecord> finishAdventure(String runId) => _action(() async {
        AdventureRecord? record;
        final now = clock();
        await _save((s) {
          if (s.lastAdventure?.runId == runId) {
            record = s.lastAdventure;
            return s;
          }
          final run = s.adventureRun;
          if (run == null || run.id != runId) throw StateError('冒険が見つかりません。');
          final battle = AdventureBattle.simulate(run);
          if (battle.revealed(run, now) < battle.events.length) {
            throw StateError('戦闘はまだ進行中です。');
          }
          final stage = AdventureCatalog.stage(run.stageId);
          final firstClear = battle.won && !s.clearedStages.contains(stage.id);
          record = AdventureRecord(
              runId: run.id,
              stageId: stage.id,
              won: battle.won,
              coins: firstClear ? stage.coins : 0,
              item: firstClear ? stage.item : null);
          return s.copyWith(
              clearAdventureRun: true,
              lastAdventure: record,
              clearedStages: {...s.clearedStages, if (battle.won) stage.id},
              coins: s.coins + record!.coins,
              inventory: {
                ...s.inventory,
                if (firstClear) stage.item: (s.inventory[stage.item] ?? 0) + 1
              },
              appliedOperations: {
                ...s.appliedOperations,
                'adventure:${run.id}'
              });
        });
        return record!;
      });
}

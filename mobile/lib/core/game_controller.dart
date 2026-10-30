import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../data/game_catalog.dart';
import '../data/player_repository.dart';
import '../data/player_state.dart';
import '../features/certificate/focus_defeat_counter.dart';
import '../features/certificate/certificate_catalog.dart';
import '../features/character/domain/character.dart';
import '../features/diagnosis/domain/diagnosis_service.dart';
import '../features/focus/data/usage_monitor.dart';
import '../features/focus/domain/focus_ledger.dart';
import '../features/focus/domain/focus_service.dart';
import '../features/focus/domain/focus_session.dart';
import '../features/focus/domain/focus_adventure.dart';
import '../features/focus/domain/reward_service.dart';
import '../features/party/data/party_connection.dart';
import '../features/party/domain/party_member.dart';

class GameController extends ChangeNotifier {
  GameController(this.repository,
      {UsageMonitor? monitor,
      DateTime Function()? clock,
      Random? random,
      PartyConnection? party})
      : monitor = monitor ?? UsageMonitor(),
        clock = clock ?? DateTime.now,
        random = random ?? Random.secure(),
        party = party ?? PartyConnection() {
    this.party.addListener(_partyChanged);
  }
  final PartyConnection party;
  String? _handledPartySession;
  bool _joiningFocus = false;
  String? partyStartError;
  PartyMember get partyIdentity {
    final hero = state!.activeCharacter!;
    return PartyMember(
        id: '',
        name: hero.name,
        characterType: hero.characterType,
        appearance: hero.appearance,
        level: hero.level,
        unlockedAreas: unlockedFocusAreas);
  }

  Future<void> prepareParty(bool ready) async {
    if (ready) {
      if (activeFocus != null || playableAdventureActive || busy) {
        throw StateError('集中・冒険・保存が終わってから準備してください。');
      }
      final permissions = await monitor.guardPermissions();
      if (permissions != null &&
          permissions.values.any((allowed) => !allowed)) {
        throw StateError('アプリ警告に必要な権限を設定してから準備してください。');
      }
    }
    party.setReady(ready);
  }

  void _partyChanged() {
    notifyListeners();
    final session = party.session;
    if (session == null ||
        _joiningFocus ||
        session['id'] == _handledPartySession) return;
    _joiningFocus = true;
    _handledPartySession = session['id'] as String;
    unawaited(_beginPartyFocus(session));
  }

  Future<void> _beginPartyFocus(Map<String, dynamic> remote) async {
    try {
      partyStartError = null;
      final savedSession = state?.sessions[remote['id']];
      if (savedSession != null && savedSession.status != FocusStatus.active) {
        party.report(savedSession.status.name);
        return;
      }
      if (activeFocus?.id == remote['id']) {
        party.report('focusing');
        return;
      }
      if (activeFocus != null) throw StateError('すでに集中中です。');
      await startFocus(remote['minutes'] as int,
          partySessionId: remote['id'] as String,
          startedAt: DateTime.parse(remote['startedAt'] as String),
          focusAreaIndex: remote['focusAreaIndex'] as int? ?? -1,
          members: (remote['members'] as List)
              .map((m) =>
                  PartyMember.fromJson(Map<String, dynamic>.from(m as Map)))
              .toList());
      party.report('focusing');
    } catch (_) {
      partyStartError = 'パーティーの集中を開始できませんでした。保存状態・使用状況の権限を確認してください。';
      party.report('cannotStart');
    } finally {
      _joiningFocus = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    party.removeListener(_partyChanged);
    party.dispose();
    super.dispose();
  }

  final PlayerRepository repository;
  final UsageMonitor monitor;
  final DateTime Function() clock;
  final Random random;
  PlayerState? state;
  int selectedFocusArea = -1;
  List<int> get unlockedFocusAreas =>
      FocusAdventure.unlockedAreas(state?.clearedPlayableStages ?? {});
  void selectFocusArea(int area) {
    if (area != -1 && !unlockedFocusAreas.contains(area)) {
      throw StateError('冒険の4ステージをクリアすると解放されます。');
    }
    selectedFocusArea = area;
    notifyListeners();
  }

  bool busy = false;
  bool playableAdventureActive = false;

  Future<void> beginPlayableAdventure() => _action(() async {
        if (activeFocus != null) throw StateError('集中が終わってから冒険に出発しましょう。');
        if (playableAdventureActive) throw StateError('冒険はすでに始まっています。');
        playableAdventureActive = true;
      });

  void endPlayableAdventure() {
    playableAdventureActive = false;
    notifyListeners();
  }

  Future<void> setSoundSettings({bool? bgm, bool? se}) =>
      _action(() => _save((s) => s.copyWith(bgmEnabled: bgm, seEnabled: se)));

  Future<void> recordPlayableClear(int stage) => _action(() => _save((s) {
        if (stage < 1 || stage > 36) throw ArgumentError.value(stage, 'stage');
        return s.copyWith(
            clearedPlayableStages: {...s.clearedPlayableStages, stage});
      }));
  Future<void> recordPlayableEncounters(Set<String> ids) =>
      _action(() => _save((s) =>
          s.copyWith(encounteredEnemyIds: {...s.encounteredEnemyIds, ...ids})));
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
      if (state!.adventurerNumber == null ||
          (!state!.onboardingComplete && state!.firstPlayedAt == null)) {
        await _save((s) => s.copyWith(
              firstPlayedAt: !s.onboardingComplete ? clock() : null,
              adventurerNumber: s.adventurerNumber ??
                  'AG-${random.nextInt(10000000).toString().padLeft(7, '0')}',
            ));
      }
    } catch (_) {
      startupError = '保存データを読み込めませんでした。データを保持したまま再試行できます。';
    }
    try {
      final session = activeFocus;
      if (session != null && session.remaining(clock()) > Duration.zero) {
        final permissions = await monitor.guardPermissions();
        if (permissions == null ||
            permissions.values.every((allowed) => allowed)) {
          await monitor.startGuard(session.deviceClockSession);
        }
      } else {
        await monitor.stopGuard();
      }
    } catch (_) {
      // A service restart failure must not prevent access to saved progress.
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

  Future<void> recordAdventureDefeats(String operationId, int count) =>
      _action(() => _save((s) {
            if (count < 0) throw ArgumentError.value(count, 'count');
            final operation = 'defeats:$operationId';
            if (s.appliedOperations.contains(operation) || count == 0) return s;
            return s.copyWith(
                totalDefeats: s.totalDefeats + count,
                appliedOperations: {...s.appliedOperations, operation});
          }));

  // Temporary developer tool; remove together with the settings reset section.
  Future<void> resetForDevelopment() => _action(() async {
        await _save((s) => PlayerState(uid: s.uid));
        await monitor.stopGuard();
      });

  // Temporary developer tool; remove with the developer character screen.
  Future<void> setCharacterForDevelopment(String typeId, String appearance) =>
      _action(() => _save((s) {
            if (activeFocus != null || playableAdventureActive) {
              throw StateError('集中・冒険が終わってから変更してください。');
            }
            final type = GameCatalog.types.values
                .where((type) => type.typeId == typeId)
                .firstOrNull;
            if (type == null || !['male', 'female'].contains(appearance)) {
              throw ArgumentError('職業と性別を選択してください。');
            }
            final hero = s.activeCharacter;
            if (hero == null) throw StateError('キャラクターが見つかりません。');
            final changed = Character(
                id: hero.id,
                name: hero.name,
                characterType: type.typeId,
                appearance: appearance,
                baseStats: type.stats,
                rarity: hero.rarity,
                level: hero.level,
                currentExp: hero.currentExp,
                equippedItems: hero.equippedItems);
            return s.copyWith(characters: {...s.characters, hero.id: changed});
          }));

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
                firstPlayedAt: s.firstPlayedAt ?? clock(),
                adventurerNumber: s.adventurerNumber ??
                    'AG-${random.nextInt(10000000).toString().padLeft(7, '0')}',
                activeCharacterId: hero.id,
                characters: {hero.id: hero});
          }));
  Future<void> startFocus(int minutes,
          {String? partySessionId,
          DateTime? startedAt,
          int? focusAreaIndex,
          List<PartyMember> members = const []}) =>
      _action(() async {
        if (playableAdventureActive) {
          throw StateError('冒険の終了後に集中できます。');
        }
        final permissions = await monitor.guardPermissions();
        if (permissions != null &&
            permissions.values.any((allowed) => !allowed)) {
          throw StateError('アプリ警告には使用状況へのアクセスと他のアプリの上に表示の許可が必要です。');
        }
        final selectedArea = focusAreaIndex ?? selectedFocusArea;
        if (selectedArea != -1 && !unlockedFocusAreas.contains(selectedArea)) {
          throw StateError('この集中エリアはまだ解放されていません。');
        }
        final basic = FocusService().start(
            id: partySessionId ?? _id(),
            now: startedAt ?? clock(),
            minutes: minutes);
        final session = FocusSession(
            id: basic.id,
            startedAt: basic.startedAt,
            durationMinutes: basic.durationMinutes,
            adventureStartSeconds: state!.focusAdventureSeconds,
            focusAreaIndex: selectedArea,
            verification: basic.verification,
            targetPackages: basic.targetPackages,
            partyMembers: List.unmodifiable(members),
            partyClockOffsetMs:
                members.isEmpty ? 0 : party.clockOffset.inMilliseconds);
        if (activeFocus != null) throw StateError('集中セッションはすでに開始されています。');
        await monitor.startGuard(session.deviceClockSession);
        try {
          await _save((s) => FocusLedger().begin(s, session));
        } catch (_) {
          await monitor.stopGuard();
          rethrow;
        }
      });
  Future<FocusSession?> finishFocus({bool cancel = false}) => _action(() async {
        final session = activeFocus;
        if (session == null) return null;
        final now = session.focusNow(clock());
        if (!cancel &&
            session.partyMembers.isNotEmpty &&
            now.isBefore(session.startedAt)) {
          return null;
        }
        var result = FocusStatus.cancelled;
        if (!cancel) {
          final evidence = session.verification == FocusVerification.usageStats
              ? await monitor.evidence(session.deviceClockSession, clock())
              : const UsageEvidence(available: false, targetUsed: false);
          result = FocusService().evaluate(session, now,
              usageEvidenceAvailable: evidence.available,
              targetUsed: evidence.targetUsed);
          if (result == FocusStatus.active) return null;
        }
        final battle = await FocusDefeatCounter.result(
            session, state!.activeCharacter!, now);
        final reward = RewardService(random).focus(session.finish(result),
            defeatedEnemies: battle.defeatedCount,
            defeatedBosses: battle.bossDefeatedCount);
        final finished = session.finish(result, earnedExp: reward.exp);
        await _save((s) {
          final settled = FocusLedger().settle(s, session.id, result, reward);
          final operation = 'defeats:focus:${session.id}';
          if (s.appliedOperations.contains(operation)) return settled;
          return settled.copyWith(
              totalDefeats: settled.totalDefeats + battle.defeatedCount,
              appliedOperations: {...settled.appliedOperations, operation});
        });
        await monitor.stopGuard();
        if (session.partyMembers.isNotEmpty) party.report(result.name);
        return finished;
      });
  Future<void> equip(String itemId) => _action(() async {
        throw StateError('装備機能は廃止されました。');
      });
  Future<void> selectTitle(String title) => _action(() => _save((s) {
        final hero = s.activeCharacter!;
        final titles = CertificateCatalog.titles[hero.characterType]!;
        final index = titles.indexOf(title);
        if (index < 0 || hero.level < CertificateCatalog.unlockLevel(index)) {
          throw StateError('この称号はまだ解放されていません。');
        }
        return s.copyWith(characters: {
          ...s.characters,
          hero.id: hero.copyWith(selectedTitle: title)
        });
      }));

  Future<void> selectCharacter(String id) => _action(() => _save((s) {
        if (playableAdventureActive) throw StateError('冒険の終了後に仲間を変更できます。');
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
}

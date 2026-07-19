import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/persistence_constants.dart';
import '../models/booster_inventory_record.dart';
import '../models/daily_reward_state.dart';
import '../models/game_settings.dart';
import '../models/leaderboard_entry.dart';
import '../models/player_progress_record.dart';
import 'booster_inventory_repository.dart';
import 'daily_reward_repository.dart';
import 'kingdom_gate_reward_repository.dart';
import 'leaderboard_repository.dart';
import 'progress_repository.dart';
import 'settings_repository.dart';
import 'story_progress_repository.dart';
import 'tutorial_progress_repository.dart';

/// Hive-backed offline sync store in the data layer.
class HiveSyncStore
    implements
        ProgressLocalDataSource,
        LeaderboardLocalDataSource,
        BoosterInventoryLocalDataSource,
        SettingsLocalDataSource,
        StoryProgressLocalDataSource,
        KingdomGateRewardLocalDataSource,
        DailyRewardLocalDataSource,
        TutorialProgressLocalDataSource {
  /// Creates a Hive sync store with an injectable Hive interface.
  HiveSyncStore({HiveInterface? hive}) : hive = hive ?? Hive;

  /// Hive interface used for local boxes.
  final HiveInterface hive;

  /// Caches one progress [record] locally.
  @override
  Future<void> cacheProgress(PlayerProgressRecord record) async {
    final box = await _openBox(playerProgressBoxName);
    await box.put(record.storageKey, record.toMap());
  }

  /// Fetches cached progress rows for [playerId].
  @override
  Future<List<PlayerProgressRecord>> fetchCachedProgress(
    String playerId,
  ) async {
    final box = await _openBox(playerProgressBoxName);
    return _recordsFromBox(
      box,
    ).where((record) => record.playerId == playerId).toList(growable: false);
  }

  /// Queues one progress [record] for later sync.
  @override
  Future<void> queuePendingProgress(PlayerProgressRecord record) async {
    final box = await _openBox(pendingPlayerProgressBoxName);
    await box.put(record.storageKey, record.toMap());
  }

  /// Fetches all pending progress rows.
  @override
  Future<List<PlayerProgressRecord>> fetchPendingProgress() async {
    final box = await _openBox(pendingPlayerProgressBoxName);
    return _recordsFromBox(box);
  }

  /// Removes synced pending [record] from the local queue.
  @override
  Future<void> markProgressSynced(PlayerProgressRecord record) async {
    final box = await _openBox(pendingPlayerProgressBoxName);
    await box.delete(record.storageKey);
  }

  /// Caches one leaderboard [entry] locally.
  @override
  Future<void> cacheLeaderboardEntry(LeaderboardEntry entry) async {
    final box = await _openBox(leaderboardBoxName);
    await box.put(entry.storageKey, entry.toMap());
  }

  /// Caches multiple leaderboard [entries] locally.
  @override
  Future<void> cacheLeaderboardEntries(List<LeaderboardEntry> entries) async {
    for (final entry in entries) {
      await cacheLeaderboardEntry(entry);
    }
  }

  /// Fetches cached leaderboard entries for [chapter].
  @override
  Future<List<LeaderboardEntry>> fetchCachedLeaderboard({
    required int chapter,
    required int limit,
  }) async {
    final box = await _openBox(leaderboardBoxName);
    final entries =
        _leaderboardEntriesFromBox(
            box,
          ).where((entry) => entry.chapter == chapter).toList()
          ..sort((first, second) => second.score.compareTo(first.score));
    return entries.take(limit).toList(growable: false);
  }

  /// Queues one leaderboard [entry] for later sync.
  @override
  Future<void> queuePendingLeaderboardEntry(LeaderboardEntry entry) async {
    final box = await _openBox(pendingLeaderboardBoxName);
    await box.put(entry.storageKey, entry.toMap());
  }

  /// Fetches all pending leaderboard entries.
  @override
  Future<List<LeaderboardEntry>> fetchPendingLeaderboardEntries() async {
    final box = await _openBox(pendingLeaderboardBoxName);
    return _leaderboardEntriesFromBox(box);
  }

  /// Removes synced pending [entry] from the local queue.
  @override
  Future<void> markLeaderboardEntrySynced(LeaderboardEntry entry) async {
    final box = await _openBox(pendingLeaderboardBoxName);
    await box.delete(entry.storageKey);
  }

  /// Caches one booster inventory [record] locally.
  @override
  Future<void> cacheBoosterInventory(BoosterInventoryRecord record) async {
    final box = await _openBox(boosterInventoryBoxName);
    await box.put(record.storageKey, record.toMap());
  }

  /// Fetches cached booster inventory rows for [playerId].
  @override
  Future<List<BoosterInventoryRecord>> fetchCachedBoosterInventory(
    String playerId,
  ) async {
    final box = await _openBox(boosterInventoryBoxName);
    return _boosterInventoryRecordsFromBox(
      box,
    ).where((record) => record.playerId == playerId).toList(growable: false);
  }

  /// Queues one booster inventory [record] for later sync.
  @override
  Future<void> queuePendingBoosterInventory(
    BoosterInventoryRecord record,
  ) async {
    final box = await _openBox(pendingBoosterInventoryBoxName);
    await box.put(record.storageKey, record.toMap());
  }

  /// Fetches all pending booster inventory rows.
  @override
  Future<List<BoosterInventoryRecord>> fetchPendingBoosterInventory() async {
    final box = await _openBox(pendingBoosterInventoryBoxName);
    return _boosterInventoryRecordsFromBox(box);
  }

  /// Removes synced pending [record] from the local queue.
  @override
  Future<void> markBoosterInventorySynced(BoosterInventoryRecord record) async {
    final box = await _openBox(pendingBoosterInventoryBoxName);
    await box.delete(record.storageKey);
  }

  /// Loads persisted gameplay settings.
  @override
  Future<GameSettings?> loadSettings() async {
    final box = await _openBox(gameSettingsBoxName);
    final value = box.get(gameSettingsStorageKey);
    if (value is! Map) {
      return null;
    }
    return GameSettings.fromMap(Map<String, dynamic>.from(value));
  }

  /// Saves [settings] locally for the next app launch.
  @override
  Future<void> saveSettings(GameSettings settings) async {
    final box = await _openBox(gameSettingsBoxName);
    await box.put(gameSettingsStorageKey, settings.toMap());
  }

  /// Loads seen kingdom story panel keys from local storage.
  @override
  Future<Set<String>> loadSeenStoryPanelKeys() async {
    final box = await _openBox(storyProgressBoxName);
    final value = box.get(seenStoryPanelsStorageKey);
    if (value is! List) {
      return const <String>{};
    }
    return {
      for (final item in value)
        if (item is String) item,
    };
  }

  /// Marks [storyPanelKey] as seen in local storage.
  @override
  Future<void> markStoryPanelSeen(String storyPanelKey) async {
    final box = await _openBox(storyProgressBoxName);
    final nextKeys = await loadSeenStoryPanelKeys();
    await box.put(
      seenStoryPanelsStorageKey,
      [...nextKeys, storyPanelKey]..sort(),
    );
  }

  /// Loads claimed kingdom gate reward keys from local storage.
  @override
  Future<Set<String>> loadClaimedKingdomGateRewardKeys() async {
    final box = await _openBox(kingdomGateRewardBoxName);
    final value = box.get(claimedKingdomGateRewardsStorageKey);
    if (value is! List) {
      return const <String>{};
    }
    return {
      for (final item in value)
        if (item is String) item,
    };
  }

  /// Marks [gateRewardKey] as claimed in local storage.
  @override
  Future<void> markKingdomGateRewardClaimed(String gateRewardKey) async {
    final box = await _openBox(kingdomGateRewardBoxName);
    final nextKeys = await loadClaimedKingdomGateRewardKeys();
    await box.put(
      claimedKingdomGateRewardsStorageKey,
      [...nextKeys, gateRewardKey]..sort(),
    );
  }

  /// Loads the local daily reward state.
  @override
  Future<DailyRewardState?> loadDailyRewardState() async {
    final box = await _openBox(dailyRewardBoxName);
    final value = box.get(dailyRewardStateStorageKey);
    if (value is! Map) {
      return null;
    }
    return DailyRewardState.fromMap(Map<String, dynamic>.from(value));
  }

  /// Saves [state] to local daily reward storage.
  @override
  Future<void> saveDailyRewardState(DailyRewardState state) async {
    final box = await _openBox(dailyRewardBoxName);
    await box.put(dailyRewardStateStorageKey, state.toMap());
  }

  /// Loads seen tutorial prompt keys from local storage.
  @override
  Future<Set<String>> loadSeenTutorialKeys() async {
    final box = await _openBox(tutorialProgressBoxName);
    final value = box.get(seenTutorialsStorageKey);
    if (value is! List) {
      return const <String>{};
    }
    return {
      for (final item in value)
        if (item is String) item,
    };
  }

  /// Marks [tutorialKey] as seen in local tutorial storage.
  @override
  Future<void> markTutorialSeen(String tutorialKey) async {
    final box = await _openBox(tutorialProgressBoxName);
    final nextKeys = await loadSeenTutorialKeys();
    await box.put(seenTutorialsStorageKey, [...nextKeys, tutorialKey]..sort());
  }

  Future<Box<dynamic>> _openBox(String boxName) {
    if (hive.isBoxOpen(boxName)) {
      return Future.value(hive.box<dynamic>(boxName));
    }
    return hive.openBox<dynamic>(boxName);
  }

  List<PlayerProgressRecord> _recordsFromBox(Box<dynamic> box) {
    return [
      for (final value in box.values)
        if (value is Map)
          PlayerProgressRecord.fromMap(Map<String, dynamic>.from(value)),
    ];
  }

  List<LeaderboardEntry> _leaderboardEntriesFromBox(Box<dynamic> box) {
    return [
      for (final value in box.values)
        if (value is Map)
          LeaderboardEntry.fromMap(Map<String, dynamic>.from(value)),
    ];
  }

  List<BoosterInventoryRecord> _boosterInventoryRecordsFromBox(
    Box<dynamic> box,
  ) {
    return [
      for (final value in box.values)
        if (value is Map)
          BoosterInventoryRecord.fromMap(Map<String, dynamic>.from(value)),
    ];
  }
}

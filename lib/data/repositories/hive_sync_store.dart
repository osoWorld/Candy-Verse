import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants/persistence_constants.dart';
import '../models/leaderboard_entry.dart';
import '../models/player_progress_record.dart';
import 'leaderboard_repository.dart';
import 'progress_repository.dart';

/// Hive-backed offline sync store in the data layer.
class HiveSyncStore
    implements ProgressLocalDataSource, LeaderboardLocalDataSource {
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
}

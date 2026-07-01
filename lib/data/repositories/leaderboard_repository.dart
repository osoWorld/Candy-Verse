import '../../core/constants/persistence_constants.dart';
import '../models/leaderboard_entry.dart';

/// Remote leaderboard data source contract for the data layer.
abstract class LeaderboardRemoteDataSource {
  /// Upserts [entry] to the remote leaderboard store.
  Future<void> upsertLeaderboardEntry(LeaderboardEntry entry);

  /// Fetches leaderboard entries for [chapter] from the remote store.
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required int chapter,
    required int limit,
  });
}

/// Local leaderboard data source contract for the data layer.
abstract class LeaderboardLocalDataSource {
  /// Caches one leaderboard [entry] locally.
  Future<void> cacheLeaderboardEntry(LeaderboardEntry entry);

  /// Caches multiple leaderboard [entries] locally.
  Future<void> cacheLeaderboardEntries(List<LeaderboardEntry> entries);

  /// Fetches cached leaderboard entries for [chapter].
  Future<List<LeaderboardEntry>> fetchCachedLeaderboard({
    required int chapter,
    required int limit,
  });

  /// Queues one leaderboard [entry] for later sync.
  Future<void> queuePendingLeaderboardEntry(LeaderboardEntry entry);

  /// Fetches all pending leaderboard entries.
  Future<List<LeaderboardEntry>> fetchPendingLeaderboardEntries();

  /// Removes synced pending [entry] from the local queue.
  Future<void> markLeaderboardEntrySynced(LeaderboardEntry entry);
}

/// Syncs leaderboards through Supabase with Hive fallback in the data layer.
class LeaderboardRepository {
  /// Creates a leaderboard repository with remote and local data sources.
  const LeaderboardRepository({required this.remote, required this.local});

  /// Supabase-backed remote leaderboard source.
  final LeaderboardRemoteDataSource remote;

  /// Hive-backed local leaderboard source.
  final LeaderboardLocalDataSource local;

  /// Submits [entry] online when possible and queues it locally when offline.
  ///
  /// Inputs: leaderboard row. Output: none. Side effects: writes local cache,
  /// attempts Supabase upsert, and queues offline rows when needed.
  Future<void> submitScore(LeaderboardEntry entry) async {
    await local.cacheLeaderboardEntry(entry);
    try {
      await remote.upsertLeaderboardEntry(entry);
      await local.markLeaderboardEntrySynced(entry);
    } catch (_) {
      await local.queuePendingLeaderboardEntry(entry);
    }
  }

  /// Fetches leaderboard entries, falling back to Hive if Supabase fails.
  ///
  /// Inputs: chapter and optional limit. Output: leaderboard rows. Side effects:
  /// refreshes local cache after successful remote reads.
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required int chapter,
    int limit = defaultLeaderboardLimit,
  }) async {
    try {
      final entries = await remote.fetchLeaderboard(
        chapter: chapter,
        limit: limit,
      );
      await local.cacheLeaderboardEntries(entries);
      return entries;
    } catch (_) {
      return local.fetchCachedLeaderboard(chapter: chapter, limit: limit);
    }
  }

  /// Attempts to sync queued offline leaderboard entries.
  ///
  /// Inputs: none. Output: none. Side effects: writes Supabase and removes
  /// successfully synced local pending rows.
  Future<void> syncPendingLeaderboardEntries() async {
    final pendingEntries = await local.fetchPendingLeaderboardEntries();
    for (final entry in pendingEntries) {
      try {
        await remote.upsertLeaderboardEntry(entry);
        await local.cacheLeaderboardEntry(entry);
        await local.markLeaderboardEntrySynced(entry);
      } catch (_) {
        return;
      }
    }
  }
}

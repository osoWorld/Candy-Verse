import '../models/booster_inventory_record.dart';
import '../models/leaderboard_entry.dart';
import '../models/player_progress_record.dart';
import 'booster_inventory_repository.dart';
import 'leaderboard_repository.dart';
import 'progress_repository.dart';

/// Offline remote source that intentionally defers sync until Supabase exists.
class OfflineSyncRemoteDataSource
    implements
        ProgressRemoteDataSource,
        LeaderboardRemoteDataSource,
        BoosterInventoryRemoteDataSource {
  /// Creates a remote source that reports Supabase as unavailable.
  const OfflineSyncRemoteDataSource();

  /// Throws so ProgressRepository uses Hive cache and pending queue.
  ///
  /// Inputs: [playerId]. Output: none because Supabase is unavailable. Side
  /// effects: none.
  @override
  Future<List<PlayerProgressRecord>> fetchProgress(String playerId) {
    throw StateError('Supabase progress sync is not configured.');
  }

  /// Throws so LeaderboardRepository uses Hive cache and pending queue.
  ///
  /// Inputs: leaderboard query. Output: none because Supabase is unavailable.
  /// Side effects: none.
  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required int chapter,
    required int limit,
  }) {
    throw StateError('Supabase leaderboard sync is not configured.');
  }

  /// Throws after local cache writes so progress is queued for later sync.
  ///
  /// Inputs: progress [record]. Output: none. Side effects: none.
  @override
  Future<void> upsertProgress(PlayerProgressRecord record) {
    throw StateError('Supabase progress sync is not configured.');
  }

  /// Throws after local cache writes so scores are queued for later sync.
  ///
  /// Inputs: leaderboard [entry]. Output: none. Side effects: none.
  @override
  Future<void> upsertLeaderboardEntry(LeaderboardEntry entry) {
    throw StateError('Supabase leaderboard sync is not configured.');
  }

  /// Throws so BoosterInventoryRepository uses Hive cache and pending queue.
  ///
  /// Inputs: [playerId]. Output: none because Supabase is unavailable. Side
  /// effects: none.
  @override
  Future<List<BoosterInventoryRecord>> fetchBoosterInventory(String playerId) {
    throw StateError('Supabase booster inventory sync is not configured.');
  }

  /// Throws after local cache writes so inventory is queued for later sync.
  ///
  /// Inputs: booster inventory [record]. Output: none. Side effects: none.
  @override
  Future<void> upsertBoosterInventory(BoosterInventoryRecord record) {
    throw StateError('Supabase booster inventory sync is not configured.');
  }
}

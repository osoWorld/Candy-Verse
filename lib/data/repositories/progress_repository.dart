import '../models/player_progress_record.dart';

/// Remote progress data source contract for the data layer.
abstract class ProgressRemoteDataSource {
  /// Upserts [record] to the remote progress store.
  Future<void> upsertProgress(PlayerProgressRecord record);

  /// Fetches progress rows for [playerId] from the remote progress store.
  Future<List<PlayerProgressRecord>> fetchProgress(String playerId);
}

/// Local progress data source contract for the data layer.
abstract class ProgressLocalDataSource {
  /// Caches one progress [record] locally.
  Future<void> cacheProgress(PlayerProgressRecord record);

  /// Fetches cached progress rows for [playerId].
  Future<List<PlayerProgressRecord>> fetchCachedProgress(String playerId);

  /// Queues one progress [record] for later sync.
  Future<void> queuePendingProgress(PlayerProgressRecord record);

  /// Fetches all pending progress rows.
  Future<List<PlayerProgressRecord>> fetchPendingProgress();

  /// Removes synced pending [record] from the local queue.
  Future<void> markProgressSynced(PlayerProgressRecord record);
}

/// Syncs player progress through Supabase with Hive fallback in the data layer.
class ProgressRepository {
  /// Creates a progress repository with remote and local data sources.
  const ProgressRepository({required this.remote, required this.local});

  /// Supabase-backed remote progress source.
  final ProgressRemoteDataSource remote;

  /// Hive-backed local progress source.
  final ProgressLocalDataSource local;

  /// Saves [record] online when possible and queues it locally when offline.
  ///
  /// Inputs: progress row. Output: none. Side effects: writes local cache,
  /// attempts Supabase upsert, and queues offline rows when needed.
  Future<void> saveProgress(PlayerProgressRecord record) async {
    await local.cacheProgress(record);
    try {
      await remote.upsertProgress(record);
      await local.markProgressSynced(record);
    } catch (_) {
      await local.queuePendingProgress(record);
    }
  }

  /// Loads progress rows for [playerId], falling back to Hive if Supabase fails.
  ///
  /// Inputs: player id. Output: progress rows. Side effects: refreshes local
  /// cache after successful remote reads.
  Future<List<PlayerProgressRecord>> loadProgress(String playerId) async {
    try {
      final records = await remote.fetchProgress(playerId);
      for (final record in records) {
        await local.cacheProgress(record);
      }
      return records;
    } catch (_) {
      return local.fetchCachedProgress(playerId);
    }
  }

  /// Attempts to sync queued offline progress rows.
  ///
  /// Inputs: none. Output: none. Side effects: writes Supabase and removes
  /// successfully synced local pending rows.
  Future<void> syncPendingProgress() async {
    final pendingRecords = await local.fetchPendingProgress();
    for (final record in pendingRecords) {
      try {
        await remote.upsertProgress(record);
        await local.cacheProgress(record);
        await local.markProgressSynced(record);
      } catch (_) {
        return;
      }
    }
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/booster_inventory_record.dart';
import '../models/leaderboard_entry.dart';
import '../models/player_progress_record.dart';
import '../repositories/booster_inventory_repository.dart';
import '../repositories/hive_sync_store.dart';
import '../repositories/leaderboard_repository.dart';
import '../repositories/progress_repository.dart';
import 'supabase_tables.dart';

/// Supabase-backed sync data source in the data layer.
class SupabaseSyncDataSource
    implements
        ProgressRemoteDataSource,
        LeaderboardRemoteDataSource,
        BoosterInventoryRemoteDataSource {
  /// Creates a Supabase sync source from a configured [client].
  const SupabaseSyncDataSource({required this.client});

  /// Supabase client using the public anon key and server-side RLS.
  final SupabaseClient client;

  /// Upserts [record] into player_progress.
  @override
  Future<void> upsertProgress(PlayerProgressRecord record) async {
    await client.from(SupabaseTables.playerProgress).upsert(record.toMap());
  }

  /// Fetches player_progress rows for [playerId].
  @override
  Future<List<PlayerProgressRecord>> fetchProgress(String playerId) async {
    final response = await client
        .from(SupabaseTables.playerProgress)
        .select()
        .eq('player_id', playerId);
    return [
      for (final row in _rowMaps(response)) PlayerProgressRecord.fromMap(row),
    ];
  }

  /// Upserts [entry] into leaderboards.
  @override
  Future<void> upsertLeaderboardEntry(LeaderboardEntry entry) async {
    await client.from(SupabaseTables.leaderboards).upsert(entry.toMap());
  }

  /// Fetches top leaderboard rows by score for [chapter].
  @override
  Future<List<LeaderboardEntry>> fetchLeaderboard({
    required int chapter,
    required int limit,
  }) async {
    final response = await client
        .from(SupabaseTables.leaderboards)
        .select()
        .eq('chapter', chapter)
        .order('score', ascending: false)
        .limit(limit);
    return [
      for (final row in _rowMaps(response)) LeaderboardEntry.fromMap(row),
    ];
  }

  /// Upserts [record] into booster_inventory.
  @override
  Future<void> upsertBoosterInventory(BoosterInventoryRecord record) async {
    await client.from(SupabaseTables.boosterInventory).upsert(record.toMap());
  }

  /// Fetches booster_inventory rows for [playerId].
  @override
  Future<List<BoosterInventoryRecord>> fetchBoosterInventory(
    String playerId,
  ) async {
    final response = await client
        .from(SupabaseTables.boosterInventory)
        .select()
        .eq('player_id', playerId);
    return [
      for (final row in _rowMaps(response)) BoosterInventoryRecord.fromMap(row),
    ];
  }

  List<Map<String, dynamic>> _rowMaps(Object? response) {
    if (response is List) {
      return [
        for (final row in response)
          if (row is Map) Map<String, dynamic>.from(row),
      ];
    }
    return const [];
  }
}

/// Creates the default progress repository from Supabase and Hive.
ProgressRepository createProgressRepository(SupabaseClient client) {
  final syncDataSource = SupabaseSyncDataSource(client: client);
  final localStore = HiveSyncStore();
  return ProgressRepository(remote: syncDataSource, local: localStore);
}

/// Creates the default leaderboard repository from Supabase and Hive.
LeaderboardRepository createLeaderboardRepository(SupabaseClient client) {
  final syncDataSource = SupabaseSyncDataSource(client: client);
  final localStore = HiveSyncStore();
  return LeaderboardRepository(remote: syncDataSource, local: localStore);
}

/// Creates the default booster inventory repository from Supabase and Hive.
BoosterInventoryRepository createBoosterInventoryRepository(
  SupabaseClient client,
) {
  final syncDataSource = SupabaseSyncDataSource(client: client);
  final localStore = HiveSyncStore();
  return BoosterInventoryRepository(remote: syncDataSource, local: localStore);
}

import '../../core/constants/persistence_constants.dart';
import '../../features/boosters/domain/booster_type.dart';
import '../models/booster_inventory_record.dart';

/// Remote booster inventory data source contract for the data layer.
abstract class BoosterInventoryRemoteDataSource {
  /// Upserts [record] to the remote booster inventory store.
  Future<void> upsertBoosterInventory(BoosterInventoryRecord record);

  /// Fetches booster inventory rows for [playerId] from the remote store.
  Future<List<BoosterInventoryRecord>> fetchBoosterInventory(String playerId);
}

/// Local booster inventory data source contract for the data layer.
abstract class BoosterInventoryLocalDataSource {
  /// Caches one booster inventory [record] locally.
  Future<void> cacheBoosterInventory(BoosterInventoryRecord record);

  /// Fetches cached booster inventory rows for [playerId].
  Future<List<BoosterInventoryRecord>> fetchCachedBoosterInventory(
    String playerId,
  );

  /// Queues one booster inventory [record] for later sync.
  Future<void> queuePendingBoosterInventory(BoosterInventoryRecord record);

  /// Fetches all pending booster inventory rows.
  Future<List<BoosterInventoryRecord>> fetchPendingBoosterInventory();

  /// Removes synced pending [record] from the local queue.
  Future<void> markBoosterInventorySynced(BoosterInventoryRecord record);
}

/// Syncs booster inventory through Supabase with Hive fallback in the data layer.
class BoosterInventoryRepository {
  /// Creates a booster inventory repository with remote and local sources.
  const BoosterInventoryRepository({required this.remote, required this.local});

  /// Supabase-backed remote booster inventory source.
  final BoosterInventoryRemoteDataSource remote;

  /// Hive-backed local booster inventory source.
  final BoosterInventoryLocalDataSource local;

  /// Loads inventory for [playerId] with starter counts for missing rows.
  ///
  /// Inputs: player id. Output: booster count map. Side effects: refreshes the
  /// local cache after successful remote reads and after starter bootstrapping.
  Future<Map<BoosterType, int>> loadInventory(String playerId) async {
    try {
      final records = await remote.fetchBoosterInventory(playerId);
      return _cacheAndNormalize(playerId: playerId, records: records);
    } catch (_) {
      final cachedRecords = await local.fetchCachedBoosterInventory(playerId);
      return _cacheAndNormalize(playerId: playerId, records: cachedRecords);
    }
  }

  /// Consumes [boosterTypes] from [playerId] when enough inventory exists.
  ///
  /// Inputs: player id and selected boosters. Output: whether all boosters were
  /// consumed. Side effects: writes local cache and queues remote sync if
  /// Supabase is unavailable.
  Future<bool> consumeBoosters({
    required String playerId,
    required List<BoosterType> boosterTypes,
  }) async {
    if (boosterTypes.isEmpty) {
      return true;
    }
    final inventory = await loadInventory(playerId);
    final requestedCounts = <BoosterType, int>{};
    for (final boosterType in boosterTypes) {
      requestedCounts[boosterType] = (requestedCounts[boosterType] ?? 0) + 1;
    }
    for (final entry in requestedCounts.entries) {
      if ((inventory[entry.key] ?? 0) < entry.value) {
        return false;
      }
    }
    for (final entry in requestedCounts.entries) {
      await setBoosterCount(
        playerId: playerId,
        boosterType: entry.key,
        count: (inventory[entry.key] ?? 0) - entry.value,
      );
    }
    return true;
  }

  /// Adds [quantity] boosters for [playerId].
  ///
  /// Inputs: player id, booster type, and positive quantity. Output: none.
  /// Side effects: writes local cache and queues remote sync if needed.
  Future<void> addBooster({
    required String playerId,
    required BoosterType boosterType,
    int quantity = 1,
  }) async {
    if (quantity <= 0) {
      return;
    }
    final inventory = await loadInventory(playerId);
    await setBoosterCount(
      playerId: playerId,
      boosterType: boosterType,
      count: (inventory[boosterType] ?? 0) + quantity,
    );
  }

  /// Saves an exact [count] for one booster.
  ///
  /// Inputs: player id, booster type, and count. Output: none. Side effects:
  /// writes local cache, attempts Supabase upsert, and queues offline rows.
  Future<void> setBoosterCount({
    required String playerId,
    required BoosterType boosterType,
    required int count,
  }) async {
    final record = BoosterInventoryRecord(
      playerId: playerId,
      boosterType: boosterType,
      count: count < 0 ? 0 : count,
      updatedAt: DateTime.now().toUtc(),
    );
    await local.cacheBoosterInventory(record);
    try {
      await remote.upsertBoosterInventory(record);
      await local.markBoosterInventorySynced(record);
    } catch (_) {
      await local.queuePendingBoosterInventory(record);
    }
  }

  /// Attempts to sync queued offline booster inventory rows.
  ///
  /// Inputs: none. Output: none. Side effects: writes Supabase and removes
  /// successfully synced local pending rows.
  Future<void> syncPendingBoosterInventory() async {
    final pendingRecords = await local.fetchPendingBoosterInventory();
    for (final record in pendingRecords) {
      try {
        await remote.upsertBoosterInventory(record);
        await local.cacheBoosterInventory(record);
        await local.markBoosterInventorySynced(record);
      } catch (_) {
        return;
      }
    }
  }

  Future<Map<BoosterType, int>> _cacheAndNormalize({
    required String playerId,
    required List<BoosterInventoryRecord> records,
  }) async {
    final inventory = starterInventory();
    for (final record in records) {
      if (record.playerId == playerId) {
        inventory[record.boosterType] = record.count;
      }
    }
    for (final entry in inventory.entries) {
      await local.cacheBoosterInventory(
        BoosterInventoryRecord(
          playerId: playerId,
          boosterType: entry.key,
          count: entry.value,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    }
    return inventory;
  }

  /// Returns V1 starter inventory counts.
  ///
  /// Inputs: none. Output: mutable starter count map. Side effects: none.
  static Map<BoosterType, int> starterInventory() {
    return {
      BoosterType.fusionBooster: defaultInitialBoosterInventoryCount,
      BoosterType.architectTile: defaultInitialBoosterInventoryCount,
      BoosterType.echoCandy: defaultInitialBoosterInventoryCount,
      BoosterType.tempoMeter: 0,
    };
  }
}

/// Local kingdom gate reward source contract for the data layer.
abstract class KingdomGateRewardLocalDataSource {
  /// Loads all claimed kingdom gate reward keys.
  ///
  /// Inputs: none. Output: claimed gate reward keys. Side effects: reads local
  /// storage.
  Future<Set<String>> loadClaimedKingdomGateRewardKeys();

  /// Marks [gateRewardKey] as claimed.
  ///
  /// Inputs: gate reward key. Output: none. Side effects: writes local storage.
  Future<void> markKingdomGateRewardClaimed(String gateRewardKey);
}

/// In-memory kingdom gate reward source for tests and fallback bootstrapping.
class MemoryKingdomGateRewardLocalDataSource
    implements KingdomGateRewardLocalDataSource {
  /// Creates an in-memory kingdom gate reward source.
  MemoryKingdomGateRewardLocalDataSource([Set<String>? initialKeys])
    : _claimedKeys = {...?initialKeys};

  final Set<String> _claimedKeys;

  /// Loads in-memory claimed gate reward keys.
  ///
  /// Inputs: none. Output: claimed gate reward keys. Side effects: none.
  @override
  Future<Set<String>> loadClaimedKingdomGateRewardKeys() async {
    return Set<String>.unmodifiable(_claimedKeys);
  }

  /// Marks [gateRewardKey] claimed in memory.
  ///
  /// Inputs: gate reward key. Output: none. Side effects: updates this source.
  @override
  Future<void> markKingdomGateRewardClaimed(String gateRewardKey) async {
    _claimedKeys.add(gateRewardKey);
  }
}

/// Persists checkpoint reward claims for Kingdom Map gates.
class KingdomGateRewardRepository {
  /// Creates a kingdom gate reward repository.
  const KingdomGateRewardRepository({required this.local});

  /// Local gate reward source.
  final KingdomGateRewardLocalDataSource local;

  /// Loads claimed gate reward keys, falling back to empty on storage failure.
  ///
  /// Inputs: none. Output: claimed gate reward keys. Side effects: reads local
  /// storage.
  Future<Set<String>> loadClaimedKingdomGateRewardKeys() async {
    try {
      return await local.loadClaimedKingdomGateRewardKeys();
    } on Object {
      return const <String>{};
    }
  }

  /// Marks [gateRewardKey] claimed when storage is available.
  ///
  /// Inputs: gate reward key. Output: none. Side effects: writes local storage.
  Future<void> markKingdomGateRewardClaimed(String gateRewardKey) async {
    try {
      await local.markKingdomGateRewardClaimed(gateRewardKey);
    } on Object {
      // PRD.md section 7 - reward persistence must not block map interaction.
    }
  }
}

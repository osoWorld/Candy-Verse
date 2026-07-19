import '../models/daily_reward_state.dart';

/// Local daily reward data source contract for the data layer.
abstract class DailyRewardLocalDataSource {
  /// Loads the persisted daily reward state.
  ///
  /// Inputs: none. Output: state or null when not persisted. Side effects:
  /// reads local storage.
  Future<DailyRewardState?> loadDailyRewardState();

  /// Saves [state] to local storage.
  ///
  /// Inputs: daily reward state. Output: none. Side effects: writes local
  /// storage.
  Future<void> saveDailyRewardState(DailyRewardState state);
}

/// In-memory daily reward source for tests and UI bootstrap fallbacks.
class MemoryDailyRewardLocalDataSource implements DailyRewardLocalDataSource {
  DailyRewardState? _state;

  /// Loads the in-memory daily reward state.
  ///
  /// Inputs: none. Output: state or null. Side effects: none.
  @override
  Future<DailyRewardState?> loadDailyRewardState() async {
    return _state;
  }

  /// Saves [state] in memory.
  ///
  /// Inputs: daily reward state. Output: none. Side effects: mutates memory.
  @override
  Future<void> saveDailyRewardState(DailyRewardState state) async {
    _state = state;
  }
}

/// Coordinates daily reward persistence in the data layer.
class DailyRewardRepository {
  /// Creates a repository backed by [local].
  const DailyRewardRepository({required this.local});

  /// Local source used for daily reward persistence.
  final DailyRewardLocalDataSource local;

  /// Loads daily reward state with a safe initial fallback.
  ///
  /// Inputs: none. Output: persisted or initial state. Side effects: reads
  /// local storage.
  Future<DailyRewardState> loadDailyRewardState() async {
    return await local.loadDailyRewardState() ??
        const DailyRewardState.initial();
  }

  /// Saves [state] through the local data source.
  ///
  /// Inputs: daily reward state. Output: none. Side effects: writes local
  /// storage.
  Future<void> saveDailyRewardState(DailyRewardState state) {
    return local.saveDailyRewardState(state);
  }
}

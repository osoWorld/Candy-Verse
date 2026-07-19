/// Local tutorial progress data source contract for the data layer.
abstract class TutorialProgressLocalDataSource {
  /// Loads tutorial prompt keys the player has already seen.
  ///
  /// Inputs: none. Output: seen tutorial keys. Side effects: reads local
  /// storage.
  Future<Set<String>> loadSeenTutorialKeys();

  /// Marks [tutorialKey] as seen.
  ///
  /// Inputs: tutorial key. Output: none. Side effects: writes local storage.
  Future<void> markTutorialSeen(String tutorialKey);
}

/// In-memory tutorial progress source for tests and fallback bootstrapping.
class MemoryTutorialProgressLocalDataSource
    implements TutorialProgressLocalDataSource {
  /// Creates an in-memory tutorial progress source.
  MemoryTutorialProgressLocalDataSource([Set<String>? initialKeys])
    : _seenTutorialKeys = {...?initialKeys};

  final Set<String> _seenTutorialKeys;

  /// Loads seen tutorial keys from memory.
  ///
  /// Inputs: none. Output: seen keys. Side effects: none.
  @override
  Future<Set<String>> loadSeenTutorialKeys() async {
    return Set<String>.of(_seenTutorialKeys);
  }

  /// Marks [tutorialKey] as seen in memory.
  ///
  /// Inputs: tutorial key. Output: none. Side effects: mutates memory.
  @override
  Future<void> markTutorialSeen(String tutorialKey) async {
    _seenTutorialKeys.add(tutorialKey);
  }
}

/// Loads and saves tutorial progress through a local data source.
class TutorialProgressRepository {
  /// Creates a tutorial progress repository backed by [local].
  const TutorialProgressRepository({required this.local});

  /// Local source used for tutorial progress persistence.
  final TutorialProgressLocalDataSource local;

  /// Loads seen tutorial keys with a safe empty fallback.
  ///
  /// Inputs: none. Output: seen tutorial keys. Side effects: reads local
  /// storage.
  Future<Set<String>> loadSeenTutorialKeys() async {
    try {
      return await local.loadSeenTutorialKeys();
    } on Object {
      return const <String>{};
    }
  }

  /// Persists [tutorialKey] as seen when storage is available.
  ///
  /// Inputs: tutorial key. Output: none. Side effects: writes local storage.
  Future<void> markTutorialSeen(String tutorialKey) async {
    try {
      await local.markTutorialSeen(tutorialKey);
    } on Object {
      // PRD.md section 15 - tutorial persistence must not crash offline play.
    }
  }
}

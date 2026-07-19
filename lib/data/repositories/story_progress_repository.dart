/// Local story progress source contract for the data layer.
abstract class StoryProgressLocalDataSource {
  /// Loads all seen kingdom story panel keys.
  ///
  /// Inputs: none. Output: story panel keys. Side effects: reads local storage.
  Future<Set<String>> loadSeenStoryPanelKeys();

  /// Marks [storyPanelKey] as seen.
  ///
  /// Inputs: story panel key. Output: none. Side effects: writes local storage.
  Future<void> markStoryPanelSeen(String storyPanelKey);
}

/// In-memory story progress source for tests and fallback bootstrapping.
class MemoryStoryProgressLocalDataSource
    implements StoryProgressLocalDataSource {
  /// Creates an in-memory story progress source.
  MemoryStoryProgressLocalDataSource([Set<String>? initialKeys])
    : _seenStoryPanelKeys = {...?initialKeys};

  final Set<String> _seenStoryPanelKeys;

  /// Loads all in-memory seen story panel keys.
  ///
  /// Inputs: none. Output: story panel keys. Side effects: none.
  @override
  Future<Set<String>> loadSeenStoryPanelKeys() async {
    return Set<String>.unmodifiable(_seenStoryPanelKeys);
  }

  /// Marks [storyPanelKey] as seen in memory.
  ///
  /// Inputs: story panel key. Output: none. Side effects: updates this source.
  @override
  Future<void> markStoryPanelSeen(String storyPanelKey) async {
    _seenStoryPanelKeys.add(storyPanelKey);
  }
}

/// Persists which kingdom story panels the player has already seen.
class StoryProgressRepository {
  /// Creates a story progress repository.
  const StoryProgressRepository({required this.local});

  /// Local story progress source.
  final StoryProgressLocalDataSource local;

  /// Loads seen story panel keys, returning an empty set on storage failure.
  ///
  /// Inputs: none. Output: story panel keys. Side effects: reads local storage.
  Future<Set<String>> loadSeenStoryPanelKeys() async {
    try {
      return await local.loadSeenStoryPanelKeys();
    } on Object {
      return const <String>{};
    }
  }

  /// Marks [storyPanelKey] seen when storage is available.
  ///
  /// Inputs: story panel key. Output: none. Side effects: writes local storage.
  Future<void> markStoryPanelSeen(String storyPanelKey) async {
    try {
      await local.markStoryPanelSeen(storyPanelKey);
    } on Object {
      // PRD.md section 7 - story panels must not block map interaction.
    }
  }
}

import '../models/game_settings.dart';

/// Local settings data source contract for the data layer.
abstract class SettingsLocalDataSource {
  /// Loads the persisted player settings.
  ///
  /// Inputs: none. Output: settings or null when none are saved. Side effects:
  /// reads local storage.
  Future<GameSettings?> loadSettings();

  /// Saves [settings] to local storage.
  ///
  /// Inputs: settings. Output: none. Side effects: writes local storage.
  Future<void> saveSettings(GameSettings settings);
}

/// In-memory settings source for tests and fallback bootstrapping.
class MemorySettingsLocalDataSource implements SettingsLocalDataSource {
  /// Creates an in-memory settings source.
  MemorySettingsLocalDataSource([GameSettings? initialSettings])
    : _settings = initialSettings;

  GameSettings? _settings;

  /// Loads the in-memory player settings.
  ///
  /// Inputs: none. Output: settings or null. Side effects: none.
  @override
  Future<GameSettings?> loadSettings() async {
    return _settings;
  }

  /// Saves [settings] in memory.
  ///
  /// Inputs: settings. Output: none. Side effects: updates this data source.
  @override
  Future<void> saveSettings(GameSettings settings) async {
    _settings = settings;
  }
}

/// Loads and saves player settings through a local data source.
class SettingsRepository {
  /// Creates a settings repository.
  const SettingsRepository({required this.local});

  /// Local settings source.
  final SettingsLocalDataSource local;

  /// Loads settings, falling back to V1 defaults when storage is unavailable.
  ///
  /// Inputs: none. Output: player settings. Side effects: reads local storage.
  Future<GameSettings> loadSettings() async {
    try {
      return await local.loadSettings() ?? const GameSettings.defaults();
    } on Object {
      return const GameSettings.defaults();
    }
  }

  /// Saves [settings] when storage is available.
  ///
  /// Inputs: settings. Output: none. Side effects: writes local storage.
  Future<void> saveSettings(GameSettings settings) async {
    try {
      await local.saveSettings(settings);
    } on Object {
      // PRD.md section 15 - settings persistence must not crash offline play.
    }
  }
}

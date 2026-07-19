/// Player settings model in the data layer.
class GameSettings {
  /// Creates player settings.
  const GameSettings({
    required this.soundEnabled,
    required this.hapticsEnabled,
    required this.reduceMotionEnabled,
  });

  /// Creates the default V1 settings.
  const GameSettings.defaults()
    : soundEnabled = true,
      hapticsEnabled = true,
      reduceMotionEnabled = false;

  /// Whether sound hooks may play cues.
  final bool soundEnabled;

  /// Whether gameplay may trigger haptic feedback.
  final bool hapticsEnabled;

  /// Whether intense gameplay motion should be softened.
  final bool reduceMotionEnabled;

  /// Creates settings from persisted JSON-like [map].
  ///
  /// Inputs: Hive map payload. Output: parsed [GameSettings]. Side effects:
  /// none.
  factory GameSettings.fromMap(Map<String, dynamic> map) {
    return GameSettings(
      soundEnabled: _boolFromMap(map, 'soundEnabled', defaultValue: true),
      hapticsEnabled: _boolFromMap(map, 'hapticsEnabled', defaultValue: true),
      reduceMotionEnabled: _boolFromMap(
        map,
        'reduceMotionEnabled',
        defaultValue: false,
      ),
    );
  }

  /// Serializes settings for Hive storage.
  ///
  /// Inputs: none. Output: JSON-like map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'soundEnabled': soundEnabled,
      'hapticsEnabled': hapticsEnabled,
      'reduceMotionEnabled': reduceMotionEnabled,
    };
  }

  /// Copies settings with optional field replacements.
  ///
  /// Inputs: optional setting values. Output: copied [GameSettings]. Side
  /// effects: none.
  GameSettings copyWith({
    bool? soundEnabled,
    bool? hapticsEnabled,
    bool? reduceMotionEnabled,
  }) {
    return GameSettings(
      soundEnabled: soundEnabled ?? this.soundEnabled,
      hapticsEnabled: hapticsEnabled ?? this.hapticsEnabled,
      reduceMotionEnabled: reduceMotionEnabled ?? this.reduceMotionEnabled,
    );
  }

  static bool _boolFromMap(
    Map<String, dynamic> map,
    String key, {
    required bool defaultValue,
  }) {
    final value = map[key];
    return value is bool ? value : defaultValue;
  }
}

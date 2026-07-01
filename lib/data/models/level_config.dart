import 'dart:convert';

import '../../features/boosters/domain/booster_type.dart';
import '../../features/grid_logic/domain/entities/goal_type.dart';
import '../../features/grid_logic/domain/entities/reactive_state.dart';

/// Level configuration data model in the data layer.
class LevelConfig {
  /// Creates an immutable LevelConfig.
  LevelConfig({
    required this.levelId,
    required this.rows,
    required this.columns,
    required this.goalType,
    required this.targetValue,
    required this.availableStates,
    required this.preLevelBoosters,
    this.moveLimit,
    this.timeLimitSeconds,
  }) {
    if (levelId.isEmpty) {
      throw LevelConfigParseException('LevelConfig.levelId must not be empty.');
    }
    if (rows <= 0) {
      throw LevelConfigParseException('LevelConfig.rows must be positive.');
    }
    if (columns <= 0) {
      throw LevelConfigParseException('LevelConfig.columns must be positive.');
    }
    if (targetValue <= 0) {
      throw LevelConfigParseException(
        'LevelConfig.targetValue must be positive.',
      );
    }
    if (availableStates.isEmpty) {
      throw LevelConfigParseException(
        'LevelConfig.availableStates must contain at least one ReactiveState.',
      );
    }
  }

  /// Unique level identifier.
  final String levelId;

  /// Grid row count.
  final int rows;

  /// Grid column count.
  final int columns;

  /// Goal type for this level.
  final GoalType goalType;

  /// Target value for the configured goal.
  final int targetValue;

  /// Optional move limit.
  final int? moveLimit;

  /// Optional time limit in seconds.
  final int? timeLimitSeconds;

  /// Reactive States available to this level.
  final List<ReactiveState> availableStates;

  /// Boosters available before this level starts.
  final List<BoosterType> preLevelBoosters;

  /// Parses a LevelConfig from a JSON string.
  ///
  /// Inputs: JSON text. Output: validated LevelConfig. Side effects: none.
  factory LevelConfig.fromJson(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw LevelConfigParseException(
        'LevelConfig JSON root must be an object.',
      );
    }
    return LevelConfig.fromMap(decoded);
  }

  /// Parses a LevelConfig from decoded JSON map data.
  ///
  /// Inputs: decoded JSON map. Output: validated LevelConfig. Side effects:
  /// none.
  factory LevelConfig.fromMap(Map<String, dynamic> map) {
    return LevelConfig(
      levelId: _requiredString(map, 'levelId'),
      rows: _requiredInt(map, 'rows'),
      columns: _requiredInt(map, 'columns'),
      goalType: _parseGoalType(_requiredString(map, 'goalType')),
      targetValue: _requiredInt(map, 'targetValue'),
      moveLimit: _optionalInt(map, 'moveLimit'),
      timeLimitSeconds: _optionalInt(map, 'timeLimitSeconds'),
      availableStates: _requiredStringList(
        map,
        'availableStates',
      ).map(_parseReactiveState).toList(growable: false),
      preLevelBoosters: _requiredStringList(
        map,
        'preLevelBoosters',
      ).map(_parseBoosterType).toList(growable: false),
    );
  }

  /// Converts this LevelConfig to JSON-compatible map data.
  ///
  /// Inputs: none. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'rows': rows,
      'columns': columns,
      'goalType': goalType.name,
      'targetValue': targetValue,
      if (moveLimit != null) 'moveLimit': moveLimit,
      if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
      'availableStates': [for (final state in availableStates) state.name],
      'preLevelBoosters': [
        for (final boosterType in preLevelBoosters) boosterType.name,
      ],
    };
  }

  static String _requiredString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is String) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName is required and must be a string.',
    );
  }

  static int _requiredInt(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value is int) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName is required and must be an integer.',
    );
  }

  static int? _optionalInt(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be an integer when provided.',
    );
  }

  static List<String> _requiredStringList(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value is List && value.every((entry) => entry is String)) {
      return value.cast<String>();
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName is required and must be a list of strings.',
    );
  }

  static GoalType _parseGoalType(String value) {
    for (final goalType in GoalType.values) {
      if (goalType.name == value) {
        return goalType;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.goalType has unsupported value "$value".',
    );
  }

  static ReactiveState _parseReactiveState(String value) {
    for (final reactiveState in ReactiveState.values) {
      if (reactiveState.name == value) {
        return reactiveState;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.availableStates contains unsupported ReactiveState "$value".',
    );
  }

  static BoosterType _parseBoosterType(String value) {
    for (final boosterType in BoosterType.values) {
      if (boosterType.name == value) {
        return boosterType;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.preLevelBoosters contains unsupported BoosterType "$value".',
    );
  }
}

/// Descriptive exception for invalid LevelConfig JSON in the data layer.
class LevelConfigParseException implements Exception {
  /// Creates a parse exception with a human-readable [message].
  const LevelConfigParseException(this.message);

  /// Human-readable parse failure.
  final String message;

  /// Formats the parse failure for diagnostics and tests.
  @override
  String toString() => 'LevelConfigParseException: $message';
}

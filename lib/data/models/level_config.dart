import 'dart:convert';

import '../../core/constants/grid_logic_constants.dart';
import '../../features/boosters/domain/booster_type.dart';
import '../../features/grid_logic/domain/entities/base_candy.dart';
import '../../features/grid_logic/domain/entities/blocker_stack.dart';
import '../../features/grid_logic/domain/entities/blocker_type.dart';
import '../../features/grid_logic/domain/entities/board_mask.dart';
import '../../features/grid_logic/domain/entities/goal_type.dart';
import '../../features/grid_logic/domain/entities/grid_position.dart';
import '../../features/grid_logic/domain/entities/reactive_state.dart';
import '../../features/grid_logic/domain/entities/game_goal.dart';
import '../../features/kingdom_map/domain/level_difficulty.dart';
import 'level_kind.dart';

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
    this.kingdomId,
    this.levelNumber,
    this.difficulty,
    LevelKind? levelKind,
    this.moveLimit,
    this.timeLimitSeconds,
    this.friendScoreSeed,
    this.allowStartingMatches = false,
    Iterable<int>? starThresholds,
    int? spawnSeed,
    Iterable<BaseCandy>? spawnBaseCandies,
    Iterable<ReactiveState>? spawnReactiveStates,
    BoardMask? boardMask,
    Map<GridPosition, BlockerStack> blockers = const {},
  }) : levelKind = levelKind ?? _levelKindForGoalType(goalType),
       starThresholds = List<int>.unmodifiable(
         starThresholds ?? _defaultStarThresholds(targetValue),
       ),
       spawnSeed = spawnSeed ?? _seedFromLevelId(levelId),
       spawnBaseCandies = List<BaseCandy>.unmodifiable(
         spawnBaseCandies ?? BaseCandy.values,
       ),
       spawnReactiveStates = List<ReactiveState>.unmodifiable(
         spawnReactiveStates ?? availableStates,
       ),
       boardMask = boardMask ?? _defaultBoardMaskFor(rows, columns),
       blockers = Map<GridPosition, BlockerStack>.unmodifiable(blockers) {
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
    if (preLevelBoosters.length != 3) {
      throw LevelConfigParseException(
        'LevelConfig.preLevelBoosters must contain exactly 3 BoosterType values.',
      );
    }
    if (this.starThresholds.length != 3) {
      throw LevelConfigParseException(
        'LevelConfig.starThresholds must contain exactly 3 values.',
      );
    }
    if (this.starThresholds[0] <= 0 ||
        this.starThresholds[1] <= this.starThresholds[0] ||
        this.starThresholds[2] <= this.starThresholds[1]) {
      throw LevelConfigParseException(
        'LevelConfig.starThresholds must be increasing positive integers.',
      );
    }
    if (this.spawnBaseCandies.isEmpty) {
      throw LevelConfigParseException(
        'LevelConfig.spawnRules.baseCandies must contain at least one BaseCandy.',
      );
    }
    if (this.spawnReactiveStates.isEmpty) {
      throw LevelConfigParseException(
        'LevelConfig.spawnRules.reactiveStates must contain at least one ReactiveState.',
      );
    }
    if (this.boardMask.rows != rows || this.boardMask.columns != columns) {
      throw LevelConfigParseException(
        'LevelConfig.boardMask dimensions must match rows and columns.',
      );
    }
    for (final entry in this.blockers.entries) {
      if (!this.boardMask.isPlayable(entry.key)) {
        throw LevelConfigParseException(
          'LevelConfig.blockers contains an unplayable blocker position '
          '${entry.key.row},${entry.key.column}.',
        );
      }
      if (entry.value.hitPoints <= 0) {
        throw LevelConfigParseException(
          'LevelConfig.blockers hitPoints must be positive.',
        );
      }
    }
  }

  /// Unique level identifier.
  final String levelId;

  /// Kingdom id containing this level.
  final String? kingdomId;

  /// Global one-based level number.
  final int? levelNumber;

  /// Grid row count.
  final int rows;

  /// Grid column count.
  final int columns;

  /// Goal type for this level.
  final GoalType goalType;

  /// V1 level kind for map/modal/gameplay goal presentation.
  final LevelKind levelKind;

  /// Difficulty label for the level.
  final LevelDifficulty? difficulty;

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

  /// Star score thresholds for 1, 2, and 3 stars.
  final List<int> starThresholds;

  /// Stable seed used for deterministic friend-score fallback.
  final int? friendScoreSeed;

  /// Whether generated starting boards may contain automatic matches.
  final bool allowStartingMatches;

  /// Spawn seed from level JSON.
  final int spawnSeed;

  /// Base Candy identities allowed by this level's spawn rules.
  final List<BaseCandy> spawnBaseCandies;

  /// Reactive State identities allowed by this level's spawn rules.
  final List<ReactiveState> spawnReactiveStates;

  /// Playable cell shape loaded from LevelConfig JSON.
  final BoardMask boardMask;

  /// Damageable blockers loaded from LevelConfig JSON.
  final Map<GridPosition, BlockerStack> blockers;

  /// User-facing goal label derived from JSON goal fields.
  String get goalLabel {
    return switch (levelKind) {
      LevelKind.score => 'Score $targetValue',
      LevelKind.jelly => 'Clear $targetValue jelly tiles',
      LevelKind.ingredientDrop => 'Drop $targetValue ingredients',
      LevelKind.candyOrder =>
        'Collect $targetValue ${_reactiveStateLabel(collectStateTarget)} candies',
      LevelKind.mixed => 'Clear $targetValue blockers and score',
    };
  }

  /// Reactive State targeted by collectState goals.
  ReactiveState get collectStateTarget {
    if (availableStates.contains(ReactiveState.frost)) {
      return ReactiveState.frost;
    }
    return availableStates.firstWhere(
      (reactiveState) => reactiveState != ReactiveState.none,
      orElse: () => ReactiveState.none,
    );
  }

  /// Pure-domain GameGoal represented by this level config.
  GameGoal get gameGoal {
    return GameGoal(
      goalType: goalType,
      targetValue: targetValue,
      targetReactiveState: goalType == GoalType.collectState
          ? collectStateTarget
          : null,
    );
  }

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
    final spawnRules = _optionalMap(map, 'spawnRules');
    final rows = _requiredInt(map, 'rows');
    final columns = _requiredInt(map, 'columns');
    final goalType = _parseGoalType(_requiredString(map, 'goalType'));
    final levelKindName = _optionalString(map, 'levelKind');
    final boardMask = _parseBoardMask(map, rows: rows, columns: columns);
    final availablePreGameBoosters =
        _optionalStringList(map, 'availablePreGameBoosters') ??
        _requiredStringList(map, 'preLevelBoosters');
    return LevelConfig(
      levelId: _requiredString(map, 'levelId'),
      kingdomId: _optionalString(map, 'kingdomId'),
      levelNumber: _optionalInt(map, 'levelNumber'),
      rows: rows,
      columns: columns,
      goalType: goalType,
      levelKind: levelKindName == null
          ? _levelKindForGoalType(goalType)
          : _parseLevelKind(levelKindName),
      difficulty: _optionalString(map, 'difficulty') == null
          ? null
          : _parseLevelDifficulty(_requiredString(map, 'difficulty')),
      targetValue: _requiredInt(map, 'targetValue'),
      moveLimit: _optionalInt(map, 'moveLimit'),
      timeLimitSeconds: _optionalInt(map, 'timeLimitSeconds'),
      friendScoreSeed: _optionalInt(map, 'friendScoreSeed'),
      allowStartingMatches: _optionalBool(map, 'allowStartingMatches') ?? false,
      starThresholds: _optionalIntList(map, 'starThresholds'),
      availableStates: _requiredStringList(
        map,
        'availableStates',
      ).map(_parseReactiveState).toList(growable: false),
      preLevelBoosters: availablePreGameBoosters
          .map(_parseBoosterType)
          .toList(growable: false),
      spawnSeed: spawnRules == null ? null : _requiredInt(spawnRules, 'seed'),
      spawnBaseCandies: spawnRules == null
          ? null
          : _requiredStringList(
              spawnRules,
              'baseCandies',
            ).map(_parseBaseCandy).toList(growable: false),
      spawnReactiveStates: spawnRules == null
          ? null
          : _requiredStringList(
              spawnRules,
              'reactiveStates',
            ).map(_parseReactiveState).toList(growable: false),
      boardMask: boardMask,
      blockers: _parseBlockers(map, boardMask: boardMask),
    );
  }

  /// Converts this LevelConfig to JSON-compatible map data.
  ///
  /// Inputs: none. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toMap() {
    final sortedBlockers = blockers.entries.toList()
      ..sort((first, second) {
        final rowCompare = first.key.row.compareTo(second.key.row);
        if (rowCompare != 0) {
          return rowCompare;
        }
        return first.key.column.compareTo(second.key.column);
      });
    return {
      'levelId': levelId,
      if (kingdomId != null) 'kingdomId': kingdomId,
      if (levelNumber != null) 'levelNumber': levelNumber,
      'rows': rows,
      'columns': columns,
      if (difficulty != null) 'difficulty': difficulty!.name,
      'levelKind': levelKind.name,
      'goalType': goalType.name,
      'targetValue': targetValue,
      if (moveLimit != null) 'moveLimit': moveLimit,
      if (timeLimitSeconds != null) 'timeLimitSeconds': timeLimitSeconds,
      'availableStates': [for (final state in availableStates) state.name],
      'availablePreGameBoosters': [
        for (final boosterType in preLevelBoosters) boosterType.name,
      ],
      'preLevelBoosters': [
        for (final boosterType in preLevelBoosters) boosterType.name,
      ],
      'boardMask': boardMask.isFullRectangle
          ? <String, Object>{}
          : <String, Object>{'playable': boardMask.toPlayablePositionCodes()},
      'spawnRules': {
        'seed': spawnSeed,
        'baseCandies': [
          for (final baseCandy in spawnBaseCandies) baseCandy.name,
        ],
        'reactiveStates': [
          for (final reactiveState in spawnReactiveStates) reactiveState.name,
        ],
      },
      'blockers': [
        for (final entry in sortedBlockers)
          {
            'position': '${entry.key.row},${entry.key.column}',
            'type': entry.value.blockerType.name,
            'hitPoints': entry.value.hitPoints,
          },
      ],
      'starThresholds': starThresholds,
      if (friendScoreSeed != null) 'friendScoreSeed': friendScoreSeed,
      'allowStartingMatches': allowStartingMatches,
    };
  }

  static String? _optionalString(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is String) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be a string when provided.',
    );
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

  static bool? _optionalBool(Map<String, dynamic> map, String fieldName) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is bool) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be a boolean when provided.',
    );
  }

  static Map<String, dynamic>? _optionalMap(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is Map<String, dynamic>) {
      return value;
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be an object when provided.',
    );
  }

  static List<int>? _optionalIntList(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is List && value.every((entry) => entry is int)) {
      return value.cast<int>();
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be a list of integers when provided.',
    );
  }

  static List<String>? _optionalStringList(
    Map<String, dynamic> map,
    String fieldName,
  ) {
    final value = map[fieldName];
    if (value == null) {
      return null;
    }
    if (value is List && value.every((entry) => entry is String)) {
      return value.cast<String>();
    }
    throw LevelConfigParseException(
      'LevelConfig.$fieldName must be a list of strings when provided.',
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

  static BoardMask _parseBoardMask(
    Map<String, dynamic> map, {
    required int rows,
    required int columns,
  }) {
    final boardMaskMap = _optionalMap(map, 'boardMask');
    if (boardMaskMap == null || boardMaskMap.isEmpty) {
      return _defaultBoardMaskFor(rows, columns);
    }

    final playablePositionCodes = _requiredStringList(boardMaskMap, 'playable');
    try {
      return BoardMask(
        rows: rows,
        columns: columns,
        playablePositions: [
          for (final positionCode in playablePositionCodes)
            _parseGridPositionCode(positionCode, 'boardMask.playable'),
        ],
      );
    } on ArgumentError catch (error) {
      throw LevelConfigParseException(
        'LevelConfig.boardMask is invalid: $error',
      );
    }
  }

  static Map<GridPosition, BlockerStack> _parseBlockers(
    Map<String, dynamic> map, {
    required BoardMask boardMask,
  }) {
    final value = map['blockers'];
    if (value == null) {
      return const {};
    }
    if (value is! List) {
      throw LevelConfigParseException(
        'LevelConfig.blockers must be a list when provided.',
      );
    }

    final blockers = <GridPosition, BlockerStack>{};
    for (var index = 0; index < value.length; index += 1) {
      final entry = value[index];
      if (entry is! Map) {
        throw LevelConfigParseException(
          'LevelConfig.blockers[$index] must be an object.',
        );
      }
      final blockerMap = entry.cast<String, dynamic>();
      final blockerType = _parseBlockerType(
        _requiredString(blockerMap, 'type'),
      );
      final position = _parseBlockerPosition(blockerMap, index);
      if (!boardMask.isPlayable(position)) {
        throw LevelConfigParseException(
          'LevelConfig.blockers[$index] position ${position.row},'
          '${position.column} must be playable.',
        );
      }
      if (blockers.containsKey(position)) {
        throw LevelConfigParseException(
          'LevelConfig.blockers[$index] duplicates position '
          '${position.row},${position.column}.',
        );
      }
      final hitPoints =
          _optionalInt(blockerMap, 'hitPoints') ??
          _defaultHitPointsFor(blockerType);
      if (hitPoints <= 0) {
        throw LevelConfigParseException(
          'LevelConfig.blockers[$index].hitPoints must be positive.',
        );
      }
      blockers[position] = BlockerStack(
        blockerType: blockerType,
        hitPoints: hitPoints,
      );
    }
    return Map<GridPosition, BlockerStack>.unmodifiable(blockers);
  }

  static GridPosition _parseBlockerPosition(
    Map<String, dynamic> blockerMap,
    int index,
  ) {
    final positionCode = _optionalString(blockerMap, 'position');
    if (positionCode != null) {
      return _parseGridPositionCode(positionCode, 'blockers[$index].position');
    }
    final row = _requiredInt(blockerMap, 'row');
    final column = _requiredInt(blockerMap, 'column');
    return GridPosition(row: row, column: column);
  }

  static GridPosition _parseGridPositionCode(String value, String fieldName) {
    final parts = value.split(',');
    if (parts.length != 2) {
      throw LevelConfigParseException(
        'LevelConfig.$fieldName value "$value" must be formatted as row,column.',
      );
    }
    final row = int.tryParse(parts[0]);
    final column = int.tryParse(parts[1]);
    if (row == null || column == null) {
      throw LevelConfigParseException(
        'LevelConfig.$fieldName value "$value" must contain integer row and column.',
      );
    }
    return GridPosition(row: row, column: column);
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

  static LevelKind _parseLevelKind(String value) {
    for (final levelKind in LevelKind.values) {
      if (levelKind.name == value) {
        return levelKind;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.levelKind has unsupported value "$value".',
    );
  }

  static LevelDifficulty _parseLevelDifficulty(String value) {
    for (final difficulty in LevelDifficulty.values) {
      if (difficulty.name == value) {
        return difficulty;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.difficulty has unsupported value "$value".',
    );
  }

  static BaseCandy _parseBaseCandy(String value) {
    for (final baseCandy in BaseCandy.values) {
      if (baseCandy.name == value) {
        return baseCandy;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.spawnRules.baseCandies contains unsupported BaseCandy "$value".',
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

  static BlockerType _parseBlockerType(String value) {
    for (final blockerType in BlockerType.values) {
      if (blockerType.name == value) {
        return blockerType;
      }
    }
    throw LevelConfigParseException(
      'LevelConfig.blockers contains unsupported BlockerType "$value".',
    );
  }

  static LevelKind _levelKindForGoalType(GoalType goalType) {
    return switch (goalType) {
      GoalType.score => LevelKind.score,
      GoalType.collectState => LevelKind.candyOrder,
      GoalType.clearObstacle => LevelKind.jelly,
    };
  }

  static List<int> _defaultStarThresholds(int targetValue) {
    return [targetValue, targetValue + targetValue ~/ 2, targetValue * 2];
  }

  static BoardMask _defaultBoardMaskFor(int rows, int columns) {
    if (rows <= 0) {
      throw LevelConfigParseException('LevelConfig.rows must be positive.');
    }
    if (columns <= 0) {
      throw LevelConfigParseException('LevelConfig.columns must be positive.');
    }
    return BoardMask.full(rows: rows, columns: columns);
  }

  static int _defaultHitPointsFor(BlockerType blockerType) {
    return switch (blockerType) {
      BlockerType.chocolate => chocolateBlockerHitPoints,
      BlockerType.ice => iceBlockerHitPoints,
      BlockerType.wafer => waferBlockerHitPoints,
      BlockerType.syrupLock => syrupLockBlockerHitPoints,
      BlockerType.spiceCrate => spiceCrateBlockerHitPoints,
    };
  }

  static String _reactiveStateLabel(ReactiveState reactiveState) {
    return switch (reactiveState) {
      ReactiveState.molten => 'Molten',
      ReactiveState.frost => 'Frost',
      ReactiveState.living => 'Living',
      ReactiveState.syrup => 'Syrup',
      ReactiveState.spice => 'Spice',
      ReactiveState.none => 'Plain',
    };
  }

  static int _seedFromLevelId(String levelId) {
    var seed = 17;
    for (final codeUnit in levelId.codeUnits) {
      seed = (seed * 31 + codeUnit) & 0x7fffffff;
    }
    return seed == 0 ? 1 : seed;
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

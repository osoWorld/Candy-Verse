import '../models/level_config.dart';
import '../models/level_kind.dart';
import '../../core/constants/grid_logic_constants.dart';
import '../../core/constants/level_generation_constants.dart';
import '../../core/constants/level_playtest_constants.dart';
import '../../features/boosters/domain/booster_type.dart';
import '../../features/grid_logic/domain/entities/base_candy.dart';
import '../../features/grid_logic/domain/entities/blocker_stack.dart';
import '../../features/grid_logic/domain/entities/blocker_type.dart';
import '../../features/grid_logic/domain/entities/goal_type.dart';
import '../../features/grid_logic/domain/entities/grid_position.dart';
import '../../features/grid_logic/domain/entities/reactive_state.dart';
import '../../features/kingdom_map/domain/level_difficulty.dart';

/// Deterministically generates the 100 bundled V1 LevelConfig records.
class LevelConfigGenerator {
  /// Creates a stateless LevelConfig generator.
  const LevelConfigGenerator();

  /// Total number of V1 bundled levels.
  static const int totalLevelCount = 100;

  /// Generates all bundled V1 level configs.
  ///
  /// Inputs: none. Output: 100 deterministic LevelConfig objects. Side effects:
  /// none.
  List<LevelConfig> generateAll() {
    return [
      for (
        var levelNumber = 1;
        levelNumber <= totalLevelCount;
        levelNumber += 1
      )
        generateLevel(levelNumber),
    ];
  }

  /// Generates a single bundled LevelConfig for [levelNumber].
  ///
  /// Inputs: one-based level number. Output: LevelConfig. Side effects: none.
  LevelConfig generateLevel(int levelNumber) {
    if (levelNumber < 1 || levelNumber > totalLevelCount) {
      throw RangeError(
        'LevelConfigGenerator levelNumber $levelNumber must be between 1 and '
        '$totalLevelCount.',
      );
    }

    final kingdom = _kingdomForLevel(levelNumber);
    final levelKind = _levelKindFor(levelNumber);
    final boardSize = _boardSizeFor(levelNumber);
    final difficulty = _difficultyForOffset(levelNumber - kingdom.levelStart);
    final moveLimit = _moveLimitFor(levelNumber);
    final targetValue = _targetValueFor(
      levelNumber: levelNumber,
      levelKind: levelKind,
      difficulty: difficulty,
      moveLimit: moveLimit,
      boardSize: boardSize,
    );
    final availableStates = _availableStatesFor(kingdom.kingdomId);
    final blockers = _blockersFor(
      levelNumber: levelNumber,
      boardSize: boardSize,
      levelKind: levelKind,
      kingdomId: kingdom.kingdomId,
      targetValue: targetValue,
    );

    return LevelConfig(
      levelId: levelIdForNumber(levelNumber),
      kingdomId: kingdom.kingdomId,
      levelNumber: levelNumber,
      rows: boardSize,
      columns: boardSize,
      difficulty: difficulty,
      levelKind: levelKind,
      goalType: _goalTypeFor(levelKind),
      targetValue: targetValue,
      moveLimit: moveLimit,
      availableStates: availableStates,
      preLevelBoosters: const [
        BoosterType.fusionBooster,
        BoosterType.architectTile,
        BoosterType.echoCandy,
      ],
      spawnSeed: 1000 + levelNumber,
      spawnBaseCandies: BaseCandy.values,
      spawnReactiveStates: availableStates,
      blockers: blockers,
      starThresholds: _starThresholdsFor(
        levelKind: levelKind,
        targetValue: targetValue,
        levelNumber: levelNumber,
      ),
      friendScoreSeed: 91000 + levelNumber,
      allowStartingMatches: false,
    );
  }

  /// Returns the generated asset id for [levelNumber].
  ///
  /// Inputs: one-based level number. Output: level id without extension. Side
  /// effects: none.
  static String levelIdForNumber(int levelNumber) {
    final kingdom = _kingdomForLevel(levelNumber);
    return '${kingdom.kingdomId}_level$levelNumber';
  }

  /// Converts [levelConfig] into the committed JSON map format.
  ///
  /// Inputs: generated config. Output: JSON-compatible map. Side effects: none.
  Map<String, dynamic> toGeneratedMap(LevelConfig levelConfig) {
    final generatedMap = levelConfig.toMap();
    generatedMap['specialCandyRules'] = _specialCandyRulesFor(
      levelConfig.levelNumber ?? 1,
    );
    return generatedMap;
  }

  static _GeneratedKingdom _kingdomForLevel(int levelNumber) {
    for (final kingdom in _kingdoms) {
      if (levelNumber >= kingdom.levelStart &&
          levelNumber <= kingdom.levelEnd) {
        return kingdom;
      }
    }
    throw RangeError('No generated kingdom contains level $levelNumber.');
  }

  static int _boardSizeFor(int levelNumber) {
    if (levelNumber <= 30) {
      return 7;
    }
    if (levelNumber <= 70) {
      return 8;
    }
    return 9;
  }

  static LevelKind _levelKindFor(int levelNumber) {
    if (levelNumber % 11 == 0) {
      return LevelKind.mixed;
    }
    if (levelNumber % 5 == 0) {
      return LevelKind.jelly;
    }
    if (levelNumber % 4 == 0) {
      return LevelKind.candyOrder;
    }
    if (levelNumber % 3 == 0) {
      return LevelKind.ingredientDrop;
    }
    return LevelKind.score;
  }

  static GoalType _goalTypeFor(LevelKind levelKind) {
    return switch (levelKind) {
      LevelKind.score => GoalType.score,
      LevelKind.jelly => GoalType.clearObstacle,
      LevelKind.ingredientDrop => GoalType.clearObstacle,
      LevelKind.candyOrder => GoalType.collectState,
      LevelKind.mixed => GoalType.clearObstacle,
    };
  }

  static int _targetValueFor({
    required int levelNumber,
    required LevelKind levelKind,
    required LevelDifficulty difficulty,
    required int moveLimit,
    required int boardSize,
  }) {
    return switch (levelKind) {
      LevelKind.score => _scoreTargetFor(
        levelNumber: levelNumber,
        difficulty: difficulty,
        moveLimit: moveLimit,
      ),
      LevelKind.jelly => _objectiveTargetFor(
        levelKind: levelKind,
        difficulty: difficulty,
        moveLimit: moveLimit,
        boardSize: boardSize,
      ),
      LevelKind.ingredientDrop => _objectiveTargetFor(
        levelKind: levelKind,
        difficulty: difficulty,
        moveLimit: moveLimit,
        boardSize: boardSize,
      ),
      LevelKind.candyOrder => generatedCandyOrderTargetCount,
      LevelKind.mixed => _objectiveTargetFor(
        levelKind: levelKind,
        difficulty: difficulty,
        moveLimit: moveLimit,
        boardSize: boardSize,
      ),
    };
  }

  static Map<GridPosition, BlockerStack> _blockersFor({
    required int levelNumber,
    required int boardSize,
    required LevelKind levelKind,
    required String kingdomId,
    required int targetValue,
  }) {
    if (levelKind == LevelKind.ingredientDrop) {
      return _ingredientExitBlockers(
        boardSize: boardSize,
        kingdomId: kingdomId,
        blockerCount: targetValue,
        levelNumber: levelNumber,
      );
    }

    final blockerCount = _blockerCountFor(
      levelNumber: levelNumber,
      levelKind: levelKind,
      targetValue: targetValue,
    );
    if (blockerCount == 0) {
      return const {};
    }

    final candidates =
        [
          for (var row = 1; row < boardSize - 1; row += 1)
            for (var column = 0; column < boardSize; column += 1)
              GridPosition(row: row, column: column),
        ]..sort((first, second) {
          return _blockerRank(
            first,
            levelNumber,
          ).compareTo(_blockerRank(second, levelNumber));
        });

    return {
      for (final position in candidates.take(blockerCount))
        position: BlockerStack(
          blockerType: _blockerTypeFor(kingdomId, levelKind),
          hitPoints: _hitPointsFor(_blockerTypeFor(kingdomId, levelKind)),
        ),
    };
  }

  static Map<GridPosition, BlockerStack> _ingredientExitBlockers({
    required int boardSize,
    required String kingdomId,
    required int blockerCount,
    required int levelNumber,
  }) {
    final leftExitColumn = (boardSize ~/ 2) - 1;
    final rightExitColumn = boardSize ~/ 2;
    final blockerType = _blockerTypeFor(kingdomId, LevelKind.ingredientDrop);
    final blockers = <GridPosition, BlockerStack>{};
    final exitPositions = [
      GridPosition(row: boardSize - 1, column: leftExitColumn),
      GridPosition(row: boardSize - 1, column: rightExitColumn),
    ];
    for (final position in exitPositions) {
      if (blockers.length >= blockerCount) {
        return Map<GridPosition, BlockerStack>.unmodifiable(blockers);
      }
      blockers[position] = BlockerStack(
        blockerType: blockerType,
        hitPoints: _hitPointsFor(blockerType),
      );
    }

    final candidates =
        [
          for (var row = boardSize ~/ 2; row < boardSize - 1; row += 1)
            for (var column = 0; column < boardSize; column += 1)
              GridPosition(row: row, column: column),
        ]..sort((first, second) {
          return _blockerRank(
            first,
            levelNumber,
          ).compareTo(_blockerRank(second, levelNumber));
        });

    for (final position in candidates) {
      if (blockers.length >= blockerCount) {
        break;
      }
      blockers[position] = BlockerStack(
        blockerType: blockerType,
        hitPoints: _hitPointsFor(blockerType),
      );
    }

    return Map<GridPosition, BlockerStack>.unmodifiable(blockers);
  }

  static int _blockerCountFor({
    required int levelNumber,
    required LevelKind levelKind,
    required int targetValue,
  }) {
    return switch (levelKind) {
      LevelKind.score => levelNumber > 20 ? generatedScoreSideBlockerCount : 0,
      LevelKind.jelly => targetValue,
      LevelKind.ingredientDrop => targetValue,
      LevelKind.candyOrder =>
        levelNumber > 24 ? generatedCandyOrderSideBlockerCount : 0,
      LevelKind.mixed => targetValue,
    };
  }

  static int _blockerRank(GridPosition position, int levelNumber) {
    return ((position.row + 1) * generatedBlockerRankRowMultiplier ^
            (position.column + 1) * generatedBlockerRankColumnMultiplier ^
            levelNumber * generatedBlockerRankLevelMultiplier) &
        levelConfigGridSeedMask;
  }

  static BlockerType _blockerTypeFor(String kingdomId, LevelKind levelKind) {
    if (levelKind == LevelKind.ingredientDrop) {
      return BlockerType.wafer;
    }
    return switch (kingdomId) {
      'cocoa_castle' => BlockerType.chocolate,
      'frosted_peaks' => BlockerType.ice,
      'molten_bakery' => BlockerType.spiceCrate,
      'syrup_lagoon' => BlockerType.syrupLock,
      _ => BlockerType.wafer,
    };
  }

  static int _hitPointsFor(BlockerType blockerType) {
    return switch (blockerType) {
      BlockerType.chocolate => chocolateBlockerHitPoints,
      BlockerType.ice => iceBlockerHitPoints,
      BlockerType.wafer => waferBlockerHitPoints,
      BlockerType.syrupLock => syrupLockBlockerHitPoints,
      BlockerType.spiceCrate => spiceCrateBlockerHitPoints,
    };
  }

  static List<int> _starThresholdsFor({
    required LevelKind levelKind,
    required int targetValue,
    required int levelNumber,
  }) {
    if (levelKind == LevelKind.score) {
      return [targetValue, targetValue + targetValue ~/ 2, targetValue * 2];
    }
    final baseScore = 2500 + levelNumber * 175;
    return [baseScore, baseScore + 1500, baseScore + 3500];
  }

  static List<ReactiveState> _availableStatesFor(String kingdomId) {
    return switch (kingdomId) {
      'sugar_meadow' => const [ReactiveState.none, ReactiveState.living],
      'cocoa_castle' => const [
        ReactiveState.none,
        ReactiveState.living,
        ReactiveState.syrup,
      ],
      'frosted_peaks' => const [
        ReactiveState.none,
        ReactiveState.frost,
        ReactiveState.living,
      ],
      'molten_bakery' => const [
        ReactiveState.none,
        ReactiveState.molten,
        ReactiveState.frost,
        ReactiveState.spice,
      ],
      'syrup_lagoon' => const [
        ReactiveState.none,
        ReactiveState.syrup,
        ReactiveState.living,
        ReactiveState.spice,
      ],
      _ => const [ReactiveState.none],
    };
  }

  static LevelDifficulty _difficultyForOffset(int offset) {
    final oneBased = offset + 1;
    if (oneBased == 20) {
      return LevelDifficulty.legendary;
    }
    if (oneBased == 18) {
      return LevelDifficulty.nightmarishlyHard;
    }
    if (oneBased == 15) {
      return LevelDifficulty.superHard;
    }
    if (oneBased == 10 || oneBased == 13) {
      return LevelDifficulty.hard;
    }
    return LevelDifficulty.simple;
  }

  static int _moveLimitFor(int levelNumber) {
    return 18 + levelNumber % 7;
  }

  static int _scoreTargetFor({
    required int levelNumber,
    required LevelDifficulty difficulty,
    required int moveLimit,
  }) {
    final rawTarget =
        generatedScoreBaseTarget +
        levelNumber * generatedScorePerLevelTargetStep;
    final cappedTarget = _roundedDownScoreTarget(
      moveLimit * playtestExpectedScorePerMove * _scorePressureCap(difficulty),
    );
    if (rawTarget < cappedTarget) {
      return rawTarget;
    }
    return cappedTarget;
  }

  static int _roundedDownScoreTarget(double target) {
    final rounded =
        (target ~/ generatedScoreTargetStep) * generatedScoreTargetStep;
    return rounded < generatedScoreTargetStep
        ? generatedScoreTargetStep
        : rounded;
  }

  static double _scorePressureCap(LevelDifficulty difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => generatedHardScorePressureCap,
      LevelDifficulty.superHard => generatedSuperHardScorePressureCap,
      LevelDifficulty.nightmarishlyHard => generatedNightmareScorePressureCap,
      LevelDifficulty.legendary => generatedLegendaryScorePressureCap,
      LevelDifficulty.simple => generatedSimpleScorePressureCap,
    };
  }

  static int _objectiveTargetFor({
    required LevelKind levelKind,
    required LevelDifficulty difficulty,
    required int moveLimit,
    required int boardSize,
  }) {
    final pressureTarget =
        (moveLimit *
                _objectivePressure(
                  levelKind: levelKind,
                  difficulty: difficulty,
                ))
            .ceil();
    final densityTarget =
        (boardSize * boardSize * _blockerDensityCap(difficulty)).floor();
    if (pressureTarget < 1) {
      return 1;
    }
    if (pressureTarget > densityTarget) {
      return densityTarget;
    }
    return pressureTarget;
  }

  static double _objectivePressure({
    required LevelKind levelKind,
    required LevelDifficulty difficulty,
  }) {
    return switch (levelKind) {
      LevelKind.jelly => _jellyPressure(difficulty),
      LevelKind.ingredientDrop => _ingredientPressure(difficulty),
      LevelKind.mixed => _mixedPressure(difficulty),
      LevelKind.score || LevelKind.candyOrder => 0,
    };
  }

  static double _jellyPressure(LevelDifficulty difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => generatedHardJellyPressure,
      LevelDifficulty.superHard => generatedSuperHardJellyPressure,
      LevelDifficulty.nightmarishlyHard => generatedNightmareJellyPressure,
      LevelDifficulty.legendary => generatedLegendaryJellyPressure,
      LevelDifficulty.simple => generatedSimpleJellyPressure,
    };
  }

  static double _ingredientPressure(LevelDifficulty difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => generatedHardIngredientPressure,
      LevelDifficulty.superHard => generatedSuperHardIngredientPressure,
      LevelDifficulty.nightmarishlyHard => generatedNightmareIngredientPressure,
      LevelDifficulty.legendary => generatedLegendaryIngredientPressure,
      LevelDifficulty.simple => generatedSimpleIngredientPressure,
    };
  }

  static double _mixedPressure(LevelDifficulty difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => generatedHardMixedPressure,
      LevelDifficulty.superHard => generatedSuperHardMixedPressure,
      LevelDifficulty.nightmarishlyHard => generatedNightmareMixedPressure,
      LevelDifficulty.legendary => generatedLegendaryMixedPressure,
      LevelDifficulty.simple => generatedSimpleMixedPressure,
    };
  }

  static double _blockerDensityCap(LevelDifficulty difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => generatedHardBlockerDensityCap,
      LevelDifficulty.superHard => generatedSuperHardBlockerDensityCap,
      LevelDifficulty.nightmarishlyHard => generatedNightmareBlockerDensityCap,
      LevelDifficulty.legendary => generatedLegendaryBlockerDensityCap,
      LevelDifficulty.simple => generatedSimpleBlockerDensityCap,
    };
  }

  static Map<String, bool> _specialCandyRulesFor(int levelNumber) {
    return {
      'allowRowClear': true,
      'allowColumnClear': true,
      'allowWrapped': levelNumber >= 12,
      'allowColorOrb': levelNumber >= 18,
      'allowFishCharm': levelNumber >= 35,
      'allowAlchemyBomb': levelNumber >= 60,
    };
  }

  static const _kingdoms = [
    _GeneratedKingdom(kingdomId: 'sugar_meadow', levelStart: 1, levelEnd: 20),
    _GeneratedKingdom(kingdomId: 'cocoa_castle', levelStart: 21, levelEnd: 40),
    _GeneratedKingdom(kingdomId: 'frosted_peaks', levelStart: 41, levelEnd: 60),
    _GeneratedKingdom(kingdomId: 'molten_bakery', levelStart: 61, levelEnd: 80),
    _GeneratedKingdom(kingdomId: 'syrup_lagoon', levelStart: 81, levelEnd: 100),
  ];
}

class _GeneratedKingdom {
  const _GeneratedKingdom({
    required this.kingdomId,
    required this.levelStart,
    required this.levelEnd,
  });

  final String kingdomId;
  final int levelStart;
  final int levelEnd;
}

import '../../core/constants/level_playtest_constants.dart';
import '../../features/grid_logic/domain/match_detector.dart';
import '../../features/grid_logic/domain/valid_move_detector.dart';
import '../../features/kingdom_map/domain/level_difficulty.dart';
import '../models/level_config.dart';
import '../models/level_kind.dart';
import '../models/level_playtest_report.dart';
import 'level_config_starting_grid_factory.dart';

/// Deterministic balance analyzer for generated LevelConfig records.
class LevelPlaytestAnalyzer {
  /// Creates a level playtest analyzer with optional domain dependencies.
  LevelPlaytestAnalyzer({
    MatchDetector? matchDetector,
    ValidMoveDetector? validMoveDetector,
    LevelConfigStartingGridFactory? startingGridFactory,
  }) : matchDetector = matchDetector ?? MatchDetector(),
       validMoveDetector = validMoveDetector ?? ValidMoveDetector(),
       startingGridFactory =
           startingGridFactory ?? const LevelConfigStartingGridFactory();

  /// Match detector used for starting match and valid move checks.
  final MatchDetector matchDetector;

  /// Valid move detector used for adjacent swap availability checks.
  final ValidMoveDetector validMoveDetector;

  /// Starting grid factory shared with gameplay.
  final LevelConfigStartingGridFactory startingGridFactory;

  /// Analyzes every [levelConfig] and returns ordered reports.
  ///
  /// Inputs: level configs. Output: playtest reports. Side effects: none.
  List<LevelPlaytestReport> analyzeAll(Iterable<LevelConfig> levelConfigs) {
    return [for (final levelConfig in levelConfigs) analyze(levelConfig)];
  }

  /// Analyzes one [levelConfig].
  ///
  /// Inputs: level config. Output: playtest report. Side effects: none.
  LevelPlaytestReport analyze(LevelConfig levelConfig) {
    final startingGrid = startingGridFactory.create(levelConfig);
    final startingMatches = matchDetector.detectMatches(startingGrid);
    final validMoveCount = validMoveDetector.countValidMoves(startingGrid);
    final playableCellCount = levelConfig.boardMask.playablePositions.length;
    final blockerCount = levelConfig.blockers.length;
    final blockerDensity = blockerCount / playableCellCount;
    final moveLimit = levelConfig.moveLimit;
    final goalPressure = _goalPressure(levelConfig);
    final flags = _flagsFor(
      levelConfig: levelConfig,
      startingMatchCount: startingMatches.length,
      validMoveCount: validMoveCount,
      blockerDensity: blockerDensity,
      goalPressure: goalPressure,
    );

    return LevelPlaytestReport(
      levelId: levelConfig.levelId,
      levelNumber: levelConfig.levelNumber ?? 0,
      kingdomId: levelConfig.kingdomId ?? 'unknown',
      levelKind: levelConfig.levelKind,
      difficulty: levelConfig.difficulty,
      rows: levelConfig.rows,
      columns: levelConfig.columns,
      playableCellCount: playableCellCount,
      blockerCount: blockerCount,
      blockerDensity: blockerDensity,
      moveLimit: moveLimit,
      targetValue: levelConfig.targetValue,
      goalPressure: goalPressure,
      startingMatchCount: startingMatches.length,
      validMoveCount: validMoveCount,
      flags: flags,
      balanceStatus: _balanceStatusFor(flags),
    );
  }

  List<LevelPlaytestFlag> _flagsFor({
    required LevelConfig levelConfig,
    required int startingMatchCount,
    required int validMoveCount,
    required double blockerDensity,
    required double goalPressure,
  }) {
    final flags = <LevelPlaytestFlag>[];
    if (!levelConfig.allowStartingMatches && startingMatchCount > 0) {
      flags.add(LevelPlaytestFlag.startingMatches);
    }
    if (validMoveCount == 0) {
      flags.add(LevelPlaytestFlag.noValidMoves);
    }
    final moveLimit = levelConfig.moveLimit;
    if (moveLimit == null) {
      flags.add(LevelPlaytestFlag.missingMoveLimit);
    } else if (moveLimit < playtestMinimumMoveLimit) {
      flags.add(LevelPlaytestFlag.lowMoveLimit);
    }
    if (blockerDensity > _maxBlockerDensity(levelConfig.difficulty)) {
      flags.add(LevelPlaytestFlag.highBlockerDensity);
    }
    final pressureRange = _pressureRangeFor(levelConfig);
    final levelNumber = levelConfig.levelNumber ?? 0;
    if (levelNumber > playtestTutorialGraceLevelCount &&
        goalPressure < pressureRange.min) {
      flags.add(LevelPlaytestFlag.lowGoalPressure);
    }
    if (goalPressure > pressureRange.max) {
      flags.add(LevelPlaytestFlag.highGoalPressure);
    }
    return flags;
  }

  LevelBalanceStatus _balanceStatusFor(List<LevelPlaytestFlag> flags) {
    if (flags.contains(LevelPlaytestFlag.startingMatches) ||
        flags.contains(LevelPlaytestFlag.noValidMoves) ||
        flags.contains(LevelPlaytestFlag.missingMoveLimit)) {
      return LevelBalanceStatus.invalid;
    }
    final tooEasy = flags.contains(LevelPlaytestFlag.lowGoalPressure);
    final tooHard =
        flags.contains(LevelPlaytestFlag.highGoalPressure) ||
        flags.contains(LevelPlaytestFlag.highBlockerDensity) ||
        flags.contains(LevelPlaytestFlag.lowMoveLimit);
    if (tooEasy && tooHard) {
      return LevelBalanceStatus.needsReview;
    }
    if (tooEasy) {
      return LevelBalanceStatus.likelyTooEasy;
    }
    if (tooHard) {
      return LevelBalanceStatus.likelyTooHard;
    }
    return LevelBalanceStatus.stable;
  }

  double _goalPressure(LevelConfig levelConfig) {
    final moveLimit = levelConfig.moveLimit;
    if (moveLimit == null || moveLimit <= 0) {
      return double.infinity;
    }
    if (levelConfig.levelKind == LevelKind.score) {
      return levelConfig.targetValue /
          (moveLimit * playtestExpectedScorePerMove);
    }
    return levelConfig.targetValue / moveLimit;
  }

  double _maxBlockerDensity(LevelDifficulty? difficulty) {
    return switch (difficulty) {
      LevelDifficulty.hard => playtestHardBlockerDensityMax,
      LevelDifficulty.superHard => playtestSuperHardBlockerDensityMax,
      LevelDifficulty.nightmarishlyHard => playtestNightmareBlockerDensityMax,
      LevelDifficulty.legendary => playtestLegendaryBlockerDensityMax,
      LevelDifficulty.simple || null => playtestSimpleBlockerDensityMax,
    };
  }

  _PressureRange _pressureRangeFor(LevelConfig levelConfig) {
    if (levelConfig.levelKind == LevelKind.score) {
      return switch (levelConfig.difficulty) {
        LevelDifficulty.hard => const _PressureRange(min: 0.55, max: 1.65),
        LevelDifficulty.superHard => const _PressureRange(min: 0.7, max: 1.9),
        LevelDifficulty.nightmarishlyHard => const _PressureRange(
          min: 0.82,
          max: 2.1,
        ),
        LevelDifficulty.legendary => const _PressureRange(min: 0.95, max: 2.35),
        LevelDifficulty.simple ||
        null => const _PressureRange(min: 0.28, max: 1.45),
      };
    }

    return switch (levelConfig.difficulty) {
      LevelDifficulty.hard => const _PressureRange(min: 0.25, max: 0.95),
      LevelDifficulty.superHard => const _PressureRange(min: 0.35, max: 1.12),
      LevelDifficulty.nightmarishlyHard => const _PressureRange(
        min: 0.45,
        max: 1.28,
      ),
      LevelDifficulty.legendary => const _PressureRange(min: 0.5, max: 1.45),
      LevelDifficulty.simple ||
      null => const _PressureRange(min: 0.08, max: 0.82),
    };
  }
}

class _PressureRange {
  const _PressureRange({required this.min, required this.max});

  final double min;
  final double max;
}

import '../../features/kingdom_map/domain/level_difficulty.dart';
import 'level_kind.dart';

/// Playtest balance status for one generated level report.
enum LevelBalanceStatus {
  /// No structural or tuning warning was found.
  stable,

  /// The level may be too easy for its assigned difficulty.
  likelyTooEasy,

  /// The level may be too hard for its assigned difficulty.
  likelyTooHard,

  /// Mixed non-critical signals require a designer pass.
  needsReview,

  /// Structural problems make the level unsafe to ship.
  invalid,
}

/// Individual playtest warning or failure flags.
enum LevelPlaytestFlag {
  /// Starting board contains automatic matches without explicit permission.
  startingMatches,

  /// Starting board has no valid adjacent swap.
  noValidMoves,

  /// Level is missing a move limit.
  missingMoveLimit,

  /// Move limit is too low for readable V1 play.
  lowMoveLimit,

  /// Blocker density is high for the assigned difficulty.
  highBlockerDensity,

  /// Goal pressure is lower than expected for the assigned difficulty.
  lowGoalPressure,

  /// Goal pressure is higher than expected for the assigned difficulty.
  highGoalPressure,
}

/// Playtest report for one LevelConfig in the data layer.
class LevelPlaytestReport {
  /// Creates an immutable playtest report.
  LevelPlaytestReport({
    required this.levelId,
    required this.levelNumber,
    required this.kingdomId,
    required this.levelKind,
    required this.difficulty,
    required this.rows,
    required this.columns,
    required this.playableCellCount,
    required this.blockerCount,
    required this.blockerDensity,
    required this.moveLimit,
    required this.targetValue,
    required this.goalPressure,
    required this.startingMatchCount,
    required this.validMoveCount,
    required List<LevelPlaytestFlag> flags,
    required this.balanceStatus,
  }) : flags = List<LevelPlaytestFlag>.unmodifiable(flags);

  /// Level id analyzed by this report.
  final String levelId;

  /// Global one-based level number.
  final int levelNumber;

  /// Kingdom id that owns this level.
  final String kingdomId;

  /// V1 level kind for goal interpretation.
  final LevelKind levelKind;

  /// Difficulty label assigned to this level.
  final LevelDifficulty? difficulty;

  /// Board row count.
  final int rows;

  /// Board column count.
  final int columns;

  /// Playable cell count after BoardMask is applied.
  final int playableCellCount;

  /// Number of blockers placed on playable cells.
  final int blockerCount;

  /// Ratio of blockers to playable cells.
  final double blockerDensity;

  /// Move limit used by this level, or null when missing.
  final int? moveLimit;

  /// Goal target value from LevelConfig.
  final int targetValue;

  /// Normalized target pressure for the configured goal and moves.
  final double goalPressure;

  /// Number of automatic matches on the starting board.
  final int startingMatchCount;

  /// Number of valid adjacent swaps on the starting board.
  final int validMoveCount;

  /// Tuning flags raised for this level.
  final List<LevelPlaytestFlag> flags;

  /// Overall playtest balance status.
  final LevelBalanceStatus balanceStatus;

  /// Returns whether this report contains a structural failure.
  ///
  /// Inputs: none. Output: critical failure flag. Side effects: none.
  bool get hasCriticalFailure {
    return flags.contains(LevelPlaytestFlag.startingMatches) ||
        flags.contains(LevelPlaytestFlag.noValidMoves) ||
        flags.contains(LevelPlaytestFlag.missingMoveLimit);
  }

  /// Converts this report to JSON-compatible diagnostics.
  ///
  /// Inputs: none. Output: serializable map. Side effects: none.
  Map<String, dynamic> toMap() {
    return {
      'levelId': levelId,
      'levelNumber': levelNumber,
      'kingdomId': kingdomId,
      'levelKind': levelKind.name,
      'difficulty': difficulty?.name,
      'rows': rows,
      'columns': columns,
      'playableCellCount': playableCellCount,
      'blockerCount': blockerCount,
      'blockerDensity': blockerDensity,
      'moveLimit': moveLimit,
      'targetValue': targetValue,
      'goalPressure': goalPressure,
      'startingMatchCount': startingMatchCount,
      'validMoveCount': validMoveCount,
      'flags': [for (final flag in flags) flag.name],
      'balanceStatus': balanceStatus.name,
    };
  }

  /// Returns a compact one-line report for CLI output.
  ///
  /// Inputs: none. Output: summary line. Side effects: none.
  String get summaryLine {
    final flagSummary = flags.isEmpty
        ? 'none'
        : flags.map(levelPlaytestFlagLabel).join(', ');
    return 'L$levelNumber $levelId ${levelBalanceStatusLabel(balanceStatus)} '
        'moves=${moveLimit ?? '-'} validMoves=$validMoveCount '
        'matches=$startingMatchCount blockers=$blockerCount '
        'density=${blockerDensity.toStringAsFixed(2)} '
        'pressure=${goalPressure.toStringAsFixed(2)} flags=$flagSummary';
  }
}

/// Returns a user-facing label for [status].
///
/// Inputs: balance status. Output: label. Side effects: none.
String levelBalanceStatusLabel(LevelBalanceStatus status) {
  return switch (status) {
    LevelBalanceStatus.stable => 'stable',
    LevelBalanceStatus.likelyTooEasy => 'likely too easy',
    LevelBalanceStatus.likelyTooHard => 'likely too hard',
    LevelBalanceStatus.needsReview => 'needs review',
    LevelBalanceStatus.invalid => 'invalid',
  };
}

/// Returns a user-facing label for [flag].
///
/// Inputs: playtest flag. Output: label. Side effects: none.
String levelPlaytestFlagLabel(LevelPlaytestFlag flag) {
  return switch (flag) {
    LevelPlaytestFlag.startingMatches => 'starting matches',
    LevelPlaytestFlag.noValidMoves => 'no valid moves',
    LevelPlaytestFlag.missingMoveLimit => 'missing move limit',
    LevelPlaytestFlag.lowMoveLimit => 'low move limit',
    LevelPlaytestFlag.highBlockerDensity => 'high blocker density',
    LevelPlaytestFlag.lowGoalPressure => 'low goal pressure',
    LevelPlaytestFlag.highGoalPressure => 'high goal pressure',
  };
}

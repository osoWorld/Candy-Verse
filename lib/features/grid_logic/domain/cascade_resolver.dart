import 'entities/cascade_result.dart';
import 'entities/cascade_step_result.dart';
import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/match_group.dart';
import 'entities/reaction_effect.dart';
import 'entities/tile.dart';
import 'match_detector.dart';
import 'reaction_engine.dart';

/// Resolves match clears and gravity in the pure Dart core logic layer.
class CascadeResolver {
  /// Creates a cascade resolver for match clears, Reaction Effects, and gravity.
  CascadeResolver({required this.matchDetector, ReactionEngine? reactionEngine})
    : reactionEngine = reactionEngine ?? const ReactionEngine();

  /// Match detector used after each Cascade Step to find chain matches.
  final MatchDetector matchDetector;

  /// Reaction Engine used within each Cascade Step before gravity.
  final ReactionEngine reactionEngine;

  /// Resolves all Cascade Step waves in [grid] until no matches remain.
  CascadeResult resolve(GridState grid) {
    var currentGrid = grid;
    final steps = <CascadeStepResult>[];

    while (true) {
      final matches = matchDetector.detectMatches(currentGrid);
      if (matches.isEmpty) {
        break;
      }

      final reactionEffects = reactionEngine.checkAdjacentReactions(
        grid: currentGrid,
        matches: matches,
      );
      final clearedPositions = _collectClearedPositions(
        matches: matches,
        reactionEffects: reactionEffects,
      );
      final gridAfterClear = currentGrid.clearPositions(clearedPositions);
      final gridAfterGravity = applyGravity(gridAfterClear);

      steps.add(
        CascadeStepResult(
          gridBeforeClear: currentGrid,
          gridAfterGravity: gridAfterGravity,
          matches: matches,
          reactionEffects: reactionEffects,
          clearedPositions: clearedPositions,
        ),
      );
      currentGrid = gridAfterGravity;
    }

    return CascadeResult(
      finalGrid: currentGrid,
      steps: List<CascadeStepResult>.unmodifiable(steps),
    );
  }

  /// Returns a new grid with non-empty tiles falling toward larger row indexes.
  GridState applyGravity(GridState grid) {
    final nextCells = [
      for (var row = 0; row < grid.rows; row += 1)
        List<Tile?>.filled(grid.columns, null),
    ];

    for (var column = 0; column < grid.columns; column += 1) {
      var writeRow = grid.rows - 1;
      for (var readRow = grid.rows - 1; readRow >= 0; readRow -= 1) {
        final tile = grid.tileAt(GridPosition(row: readRow, column: column));
        if (tile == null) {
          continue;
        }
        nextCells[writeRow][column] = tile;
        writeRow -= 1;
      }
    }

    return GridState(rows: grid.rows, columns: grid.columns, cells: nextCells);
  }

  Set<GridPosition> _collectClearedPositions({
    required List<MatchGroup> matches,
    required List<ReactionEffect> reactionEffects,
  }) {
    return {
      for (final match in matches) ...match.positions,
      for (final reactionEffect in reactionEffects)
        ...reactionEffect.clearedPositions,
    };
  }
}

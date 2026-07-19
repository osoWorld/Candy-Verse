import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'match_detector.dart';

/// Detects valid adjacent swaps in the pure Dart core logic layer.
class ValidMoveDetector {
  /// Creates a valid move detector backed by [matchDetector].
  ValidMoveDetector({MatchDetector? matchDetector})
    : matchDetector = matchDetector ?? MatchDetector();

  /// Match detector used after tentative swaps.
  final MatchDetector matchDetector;

  /// Returns whether [grid] has at least one valid adjacent swap.
  ///
  /// Inputs: grid state. Output: valid move availability. Side effects: none.
  bool hasValidMove(GridState grid) {
    return countValidMoves(grid) > 0;
  }

  /// Counts valid adjacent swaps in [grid].
  ///
  /// Inputs: grid state. Output: valid adjacent swap count. Side effects: none.
  int countValidMoves(GridState grid) {
    var validMoveCount = 0;
    for (var row = 0; row < grid.rows; row += 1) {
      for (var column = 0; column < grid.columns; column += 1) {
        final first = GridPosition(row: row, column: column);
        final firstTile = grid.tileAt(first);
        if (firstTile == null) {
          continue;
        }
        for (final second in [
          GridPosition(row: row, column: column + 1),
          GridPosition(row: row + 1, column: column),
        ]) {
          if (!grid.contains(second)) {
            continue;
          }
          final secondTile = grid.tileAt(second);
          if (secondTile == null) {
            continue;
          }
          if (firstTile.isSpecial || secondTile.isSpecial) {
            validMoveCount += 1;
            continue;
          }
          final swappedGrid = grid.swapTiles(first, second);
          if (matchDetector.detectMatches(swappedGrid).isNotEmpty) {
            validMoveCount += 1;
          }
        }
      }
    }
    return validMoveCount;
  }
}

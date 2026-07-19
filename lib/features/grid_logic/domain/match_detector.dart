import '../../../core/constants/grid_logic_constants.dart';
import 'entities/base_candy.dart';
import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/match_group.dart';
import 'entities/tile.dart';

/// Finds same-Base Candy matches in the pure Dart core logic layer.
class MatchDetector {
  /// Detects all horizontal and vertical 3+ Base Candy matches in [grid].
  List<MatchGroup> detectMatches(GridState grid) {
    final rawMatches = <MatchGroup>[
      ..._detectHorizontalMatches(grid),
      ..._detectVerticalMatches(grid),
      ..._detectSquareMatches(grid),
    ];
    return _mergeIntersectingMatches(rawMatches);
  }

  List<MatchGroup> _detectHorizontalMatches(GridState grid) {
    final matches = <MatchGroup>[];
    for (var row = 0; row < grid.rows; row += 1) {
      var runStart = 0;
      Tile? previousTile;
      for (var column = 0; column <= grid.columns; column += 1) {
        final currentTile = column < grid.columns
            ? grid.tileAt(GridPosition(row: row, column: column))
            : null;
        if (!_hasSameBaseCandy(previousTile, currentTile)) {
          _addRunMatch(
            matches: matches,
            baseCandy: previousTile?.baseCandy,
            rowStart: row,
            columnStart: runStart,
            rowStep: 0,
            columnStep: 1,
            length: column - runStart,
          );
          runStart = column;
        }
        previousTile = currentTile;
      }
    }
    return matches;
  }

  List<MatchGroup> _detectVerticalMatches(GridState grid) {
    final matches = <MatchGroup>[];
    for (var column = 0; column < grid.columns; column += 1) {
      var runStart = 0;
      Tile? previousTile;
      for (var row = 0; row <= grid.rows; row += 1) {
        final currentTile = row < grid.rows
            ? grid.tileAt(GridPosition(row: row, column: column))
            : null;
        if (!_hasSameBaseCandy(previousTile, currentTile)) {
          _addRunMatch(
            matches: matches,
            baseCandy: previousTile?.baseCandy,
            rowStart: runStart,
            columnStart: column,
            rowStep: 1,
            columnStep: 0,
            length: row - runStart,
          );
          runStart = row;
        }
        previousTile = currentTile;
      }
    }
    return matches;
  }

  List<MatchGroup> _detectSquareMatches(GridState grid) {
    final matches = <MatchGroup>[];
    for (var row = 0; row < grid.rows - 1; row += 1) {
      for (var column = 0; column < grid.columns - 1; column += 1) {
        final topLeft = grid.tileAt(GridPosition(row: row, column: column));
        if (topLeft == null) {
          continue;
        }
        final positions = {
          GridPosition(row: row, column: column),
          GridPosition(row: row, column: column + 1),
          GridPosition(row: row + 1, column: column),
          GridPosition(row: row + 1, column: column + 1),
        };
        if (positions.every(
          (position) => grid.tileAt(position)?.baseCandy == topLeft.baseCandy,
        )) {
          matches.add(
            MatchGroup(baseCandy: topLeft.baseCandy, positions: positions),
          );
        }
      }
    }
    return matches;
  }

  void _addRunMatch({
    required List<MatchGroup> matches,
    required BaseCandy? baseCandy,
    required int rowStart,
    required int columnStart,
    required int rowStep,
    required int columnStep,
    required int length,
  }) {
    if (baseCandy == null || length < minimumMatchLength) {
      return;
    }

    matches.add(
      MatchGroup(
        baseCandy: baseCandy,
        positions: [
          for (var index = 0; index < length; index += 1)
            GridPosition(
              row: rowStart + rowStep * index,
              column: columnStart + columnStep * index,
            ),
        ],
      ),
    );
  }

  List<MatchGroup> _mergeIntersectingMatches(List<MatchGroup> rawMatches) {
    final mergedMatches = List<MatchGroup>.of(rawMatches);
    var didMerge = true;
    while (didMerge) {
      didMerge = false;
      for (var outer = 0; outer < mergedMatches.length; outer += 1) {
        for (var inner = outer + 1; inner < mergedMatches.length; inner += 1) {
          final first = mergedMatches[outer];
          final second = mergedMatches[inner];
          if (first.baseCandy == second.baseCandy && first.intersects(second)) {
            mergedMatches[outer] = first.merge(second);
            mergedMatches.removeAt(inner);
            didMerge = true;
            break;
          }
        }
        if (didMerge) {
          break;
        }
      }
    }
    return mergedMatches;
  }

  bool _hasSameBaseCandy(Tile? first, Tile? second) {
    return first != null &&
        second != null &&
        first.baseCandy == second.baseCandy;
  }
}

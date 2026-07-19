import '../../../core/constants/grid_logic_constants.dart';
import 'entities/base_candy.dart';
import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/match_group.dart';
import 'entities/special_candy_activation.dart';
import 'entities/special_candy_creation.dart';
import 'entities/special_candy_resolution.dart';
import 'entities/special_candy_type.dart';

/// Resolves Special Candy creation and activation in the pure Dart core layer.
class SpecialCandyResolver {
  /// Creates a stateless SpecialCandyResolver.
  const SpecialCandyResolver();

  /// Resolves Special Candy creation and activation for [matches].
  ///
  /// Inputs: current [grid], detected [matches], and optional preferred
  /// creation positions from a player swap. Output: SpecialCandyResolution.
  /// Side effects: none.
  SpecialCandyResolution resolve({
    required GridState grid,
    required List<MatchGroup> matches,
    Iterable<GridPosition> preferredCreationPositions = const [],
  }) {
    final activations = <SpecialCandyActivation>[];
    final creations = <SpecialCandyCreation>[];
    final preferredPositions = List<GridPosition>.unmodifiable(
      preferredCreationPositions,
    );

    for (final match in matches) {
      final matchActivations = _activationsForMatch(grid, match);
      activations.addAll(matchActivations);

      if (matchActivations.isNotEmpty) {
        continue;
      }

      final specialCandyType = specialCandyTypeForMatch(match);
      if (specialCandyType == SpecialCandyType.none) {
        continue;
      }

      final creationPosition = _creationPositionFor(
        match: match,
        preferredPositions: preferredPositions,
      );
      final sourceTile = grid.tileAt(creationPosition);
      if (sourceTile == null) {
        continue;
      }
      creations.add(
        SpecialCandyCreation(
          position: creationPosition,
          specialCandyType: specialCandyType,
          tile: sourceTile.withSpecialCandyType(specialCandyType),
        ),
      );
    }

    return SpecialCandyResolution(
      creations: creations,
      activations: activations,
    );
  }

  /// Returns the Special Candy type created by [match].
  ///
  /// Inputs: detected match group. Output: SpecialCandyType or none. Side
  /// effects: none.
  SpecialCandyType specialCandyTypeForMatch(MatchGroup match) {
    if (_isSquareMatch(match)) {
      return SpecialCandyType.fishCharm;
    }
    if (_isLine(match) && match.length >= 5) {
      return SpecialCandyType.colorOrb;
    }
    if (_isTOrLShape(match)) {
      return SpecialCandyType.wrapped;
    }
    if (_isHorizontalLine(match) && match.length == 4) {
      return SpecialCandyType.rowClear;
    }
    if (_isVerticalLine(match) && match.length == 4) {
      return SpecialCandyType.columnClear;
    }
    return SpecialCandyType.none;
  }

  /// Activates the Special Candy at [origin].
  ///
  /// Inputs: current [grid], special [origin], and optional target Base Candy
  /// for colorOrb activation. Output: activation record. Side effects: none.
  SpecialCandyActivation activate({
    required GridState grid,
    required GridPosition origin,
    BaseCandy? targetBaseCandy,
  }) {
    final tile = grid.tileAt(origin);
    if (tile == null || tile.specialCandyType == SpecialCandyType.none) {
      return SpecialCandyActivation(
        origin: origin,
        specialCandyType: SpecialCandyType.none,
        clearedPositions: const [],
      );
    }

    final clearedPositions = switch (tile.specialCandyType) {
      SpecialCandyType.rowClear => _rowPositions(grid, origin.row),
      SpecialCandyType.columnClear => _columnPositions(grid, origin.column),
      SpecialCandyType.wrapped => _squareAround(
        grid: grid,
        origin: origin,
        radius: wrappedSpecialCandyRadius,
      ),
      SpecialCandyType.colorOrb => _baseCandyPositions(
        grid: grid,
        targetBaseCandy: targetBaseCandy ?? tile.baseCandy,
      )..add(origin),
      SpecialCandyType.fishCharm => {
        origin,
        _fishTarget(grid: grid, origin: origin),
      },
      SpecialCandyType.alchemyBomb => _squareAround(
        grid: grid,
        origin: origin,
        radius: alchemyBombSpecialCandyRadius,
      ),
      SpecialCandyType.none => <GridPosition>{},
    };

    return SpecialCandyActivation(
      origin: origin,
      specialCandyType: tile.specialCandyType,
      clearedPositions: clearedPositions,
    );
  }

  List<SpecialCandyActivation> _activationsForMatch(
    GridState grid,
    MatchGroup match,
  ) {
    final activations = <SpecialCandyActivation>[];
    for (final position in match.positions) {
      final tile = grid.tileAt(position);
      if (tile == null || tile.specialCandyType == SpecialCandyType.none) {
        continue;
      }
      activations.add(
        activate(
          grid: grid,
          origin: position,
          targetBaseCandy: match.baseCandy,
        ),
      );
    }
    return activations;
  }

  GridPosition _creationPositionFor({
    required MatchGroup match,
    required List<GridPosition> preferredPositions,
  }) {
    for (final preferredPosition in preferredPositions) {
      if (match.positions.contains(preferredPosition)) {
        return preferredPosition;
      }
    }
    final sortedPositions = List<GridPosition>.of(match.positions)
      ..sort((first, second) {
        final rowComparison = first.row.compareTo(second.row);
        if (rowComparison != 0) {
          return rowComparison;
        }
        return first.column.compareTo(second.column);
      });
    return sortedPositions[sortedPositions.length ~/ 2];
  }

  bool _isHorizontalLine(MatchGroup match) {
    return {for (final position in match.positions) position.row}.length == 1;
  }

  bool _isVerticalLine(MatchGroup match) {
    return {for (final position in match.positions) position.column}.length ==
        1;
  }

  bool _isLine(MatchGroup match) {
    return _isHorizontalLine(match) || _isVerticalLine(match);
  }

  bool _isSquareMatch(MatchGroup match) {
    if (match.length != fishCharmSquareEdgeLength * fishCharmSquareEdgeLength) {
      return false;
    }
    final rows = {for (final position in match.positions) position.row};
    final columns = {for (final position in match.positions) position.column};
    if (rows.length != fishCharmSquareEdgeLength ||
        columns.length != fishCharmSquareEdgeLength) {
      return false;
    }
    for (final row in rows) {
      for (final column in columns) {
        if (!match.positions.contains(GridPosition(row: row, column: column))) {
          return false;
        }
      }
    }
    return true;
  }

  bool _isTOrLShape(MatchGroup match) {
    if (match.length < 5 || _isLine(match)) {
      return false;
    }
    final rowCounts = <int, int>{};
    final columnCounts = <int, int>{};
    for (final position in match.positions) {
      rowCounts[position.row] = (rowCounts[position.row] ?? 0) + 1;
      columnCounts[position.column] = (columnCounts[position.column] ?? 0) + 1;
    }
    return rowCounts.values.any((count) => count >= minimumMatchLength) &&
        columnCounts.values.any((count) => count >= minimumMatchLength);
  }

  Set<GridPosition> _rowPositions(GridState grid, int row) {
    return {
      for (var column = 0; column < grid.columns; column += 1)
        if (grid.tileAt(GridPosition(row: row, column: column)) != null)
          GridPosition(row: row, column: column),
    };
  }

  Set<GridPosition> _columnPositions(GridState grid, int column) {
    return {
      for (var row = 0; row < grid.rows; row += 1)
        if (grid.tileAt(GridPosition(row: row, column: column)) != null)
          GridPosition(row: row, column: column),
    };
  }

  Set<GridPosition> _squareAround({
    required GridState grid,
    required GridPosition origin,
    required int radius,
  }) {
    return {
      for (var row = origin.row - radius; row <= origin.row + radius; row += 1)
        for (
          var column = origin.column - radius;
          column <= origin.column + radius;
          column += 1
        )
          if (grid.contains(GridPosition(row: row, column: column)) &&
              grid.tileAt(GridPosition(row: row, column: column)) != null)
            GridPosition(row: row, column: column),
    };
  }

  Set<GridPosition> _baseCandyPositions({
    required GridState grid,
    required BaseCandy targetBaseCandy,
  }) {
    return {
      for (var row = 0; row < grid.rows; row += 1)
        for (var column = 0; column < grid.columns; column += 1)
          if (grid.tileAt(GridPosition(row: row, column: column))?.baseCandy ==
              targetBaseCandy)
            GridPosition(row: row, column: column),
    };
  }

  GridPosition _fishTarget({
    required GridState grid,
    required GridPosition origin,
  }) {
    for (var row = grid.rows - 1; row >= 0; row -= 1) {
      for (var column = grid.columns - 1; column >= 0; column -= 1) {
        final candidate = GridPosition(row: row, column: column);
        if (candidate != origin && grid.tileAt(candidate) != null) {
          return candidate;
        }
      }
    }
    return origin;
  }
}

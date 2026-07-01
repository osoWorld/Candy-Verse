import '../../../core/constants/booster_constants.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import 'fusion_booster_activation.dart';
import 'fusion_effect_type.dart';
import 'special_candy_type.dart';

/// Resolves Fusion Booster pairings in the boosters domain layer.
class FusionBooster {
  /// Creates a stateless Fusion Booster resolver.
  const FusionBooster();

  /// Activates a Fusion Booster pairing on [grid] at [origin].
  ///
  /// Inputs: the current [grid], activation [origin], and two different special
  /// candy types. Output: a FusionBoosterActivation describing affected cells.
  /// Side effects: none.
  FusionBoosterActivation activate({
    required GridState grid,
    required GridPosition origin,
    required SpecialCandyType firstSpecialCandyType,
    required SpecialCandyType secondSpecialCandyType,
  }) {
    if (!grid.contains(origin)) {
      throw RangeError(
        'FusionBooster origin row ${origin.row}, column ${origin.column} is '
        'outside ${grid.rows} x ${grid.columns} GridState.',
      );
    }
    if (firstSpecialCandyType == secondSpecialCandyType) {
      throw ArgumentError(
        'Fusion Booster requires two different special candy types.',
      );
    }

    final pairing = _FusionBoosterPairing(
      firstSpecialCandyType,
      secondSpecialCandyType,
    );
    if (pairing.matches(
      SpecialCandyType.rowClear,
      SpecialCandyType.columnClear,
    )) {
      return FusionBoosterActivation(
        effectType: FusionEffectType.crossClear,
        origin: origin,
        firstSpecialCandyType: firstSpecialCandyType,
        secondSpecialCandyType: secondSpecialCandyType,
        affectedPositions: _crossClearPositions(grid, origin),
      );
    }
    if (pairing.matches(
      SpecialCandyType.rowClear,
      SpecialCandyType.areaBurst,
    )) {
      return FusionBoosterActivation(
        effectType: FusionEffectType.rowBurst,
        origin: origin,
        firstSpecialCandyType: firstSpecialCandyType,
        secondSpecialCandyType: secondSpecialCandyType,
        affectedPositions: _rowBurstPositions(grid, origin),
      );
    }

    throw UnsupportedError(
      'Fusion Booster pairing $firstSpecialCandyType + '
      '$secondSpecialCandyType is not implemented in Step 9.',
    );
  }

  Iterable<GridPosition> _crossClearPositions(
    GridState grid,
    GridPosition origin,
  ) sync* {
    for (var column = 0; column < grid.columns; column += 1) {
      yield GridPosition(row: origin.row, column: column);
    }
    for (var row = 0; row < grid.rows; row += 1) {
      yield GridPosition(row: row, column: origin.column);
    }
  }

  Iterable<GridPosition> _rowBurstPositions(
    GridState grid,
    GridPosition origin,
  ) sync* {
    for (var column = 0; column < grid.columns; column += 1) {
      yield GridPosition(row: origin.row, column: column);
    }
    for (
      var row = origin.row - fusionBoosterAreaRadius;
      row <= origin.row + fusionBoosterAreaRadius;
      row += 1
    ) {
      for (
        var column = origin.column - fusionBoosterAreaRadius;
        column <= origin.column + fusionBoosterAreaRadius;
        column += 1
      ) {
        final position = GridPosition(row: row, column: column);
        if (grid.contains(position)) {
          yield position;
        }
      }
    }
  }
}

class _FusionBoosterPairing {
  const _FusionBoosterPairing(this.first, this.second);

  final SpecialCandyType first;
  final SpecialCandyType second;

  bool matches(
    SpecialCandyType expectedFirst,
    SpecialCandyType expectedSecond,
  ) {
    return (first == expectedFirst && second == expectedSecond) ||
        (first == expectedSecond && second == expectedFirst);
  }
}

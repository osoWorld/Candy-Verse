import '../models/level_config.dart';
import '../../features/grid_logic/domain/entities/grid_position.dart';
import '../../features/grid_logic/domain/entities/grid_state.dart';
import '../../features/grid_logic/domain/entities/reactive_state.dart';
import '../../features/grid_logic/domain/entities/spawn_rule.dart';
import '../../features/grid_logic/domain/entities/tile.dart';
import '../../features/grid_logic/domain/match_detector.dart';
import '../../features/grid_logic/domain/refill_resolver.dart';
import '../../features/grid_logic/domain/tile_spawner.dart';
import '../../features/grid_logic/domain/valid_move_detector.dart';

/// Builds deterministic starting grids for LevelConfig records.
class LevelConfigStartingGridFactory {
  /// Creates a stateless starting grid factory.
  const LevelConfigStartingGridFactory();

  /// Creates a deterministic full starting board for [levelConfig].
  ///
  /// Inputs: parsed level config. Output: GridState with no empty playable
  /// cells and at least one valid move when the spawn rules allow it. Side
  /// effects: none.
  GridState create(LevelConfig levelConfig) {
    final refilledGrid = _refillEmptyGrid(levelConfig);
    final validMoveDetector = ValidMoveDetector();
    if (validMoveDetector.hasValidMove(refilledGrid)) {
      return refilledGrid;
    }
    return _withInjectedValidMove(
      grid: refilledGrid,
      levelConfig: levelConfig,
      matchDetector: validMoveDetector.matchDetector,
      validMoveDetector: validMoveDetector,
    );
  }

  GridState _refillEmptyGrid(LevelConfig levelConfig) {
    final emptyGrid = GridState(
      rows: levelConfig.rows,
      columns: levelConfig.columns,
      cells: [
        for (var row = 0; row < levelConfig.rows; row += 1)
          List<Tile?>.filled(levelConfig.columns, null),
      ],
      boardMask: levelConfig.boardMask,
      blockers: levelConfig.blockers,
    );
    final spawnRule = SpawnRule(
      baseCandies: levelConfig.spawnBaseCandies,
      reactiveStates: levelConfig.spawnReactiveStates,
      seed: levelConfig.spawnSeed,
    );
    return RefillResolver(
      tileSpawner: TileSpawner(spawnRule: spawnRule),
    ).refill(grid: emptyGrid).grid;
  }

  GridState _withInjectedValidMove({
    required GridState grid,
    required LevelConfig levelConfig,
    required MatchDetector matchDetector,
    required ValidMoveDetector validMoveDetector,
  }) {
    if (levelConfig.spawnBaseCandies.length < 2) {
      return grid;
    }

    for (var row = 0; row < grid.rows - 1; row += 1) {
      for (var column = 0; column < grid.columns - 2; column += 1) {
        final left = GridPosition(row: row, column: column);
        final middle = GridPosition(row: row, column: column + 1);
        final right = GridPosition(row: row, column: column + 2);
        final belowMiddle = GridPosition(row: row + 1, column: column + 1);
        if (![left, middle, right, belowMiddle].every(grid.isPlayable)) {
          continue;
        }
        for (final matchCandy in levelConfig.spawnBaseCandies) {
          for (final spacerCandy in levelConfig.spawnBaseCandies) {
            if (spacerCandy == matchCandy) {
              continue;
            }
            final candidateGrid = grid
                .setTile(
                  left,
                  _tileFor(
                    levelConfig: levelConfig,
                    position: left,
                    index: 0,
                    baseCandyIndex: levelConfig.spawnBaseCandies.indexOf(
                      matchCandy,
                    ),
                  ),
                )
                .setTile(
                  middle,
                  _tileFor(
                    levelConfig: levelConfig,
                    position: middle,
                    index: 1,
                    baseCandyIndex: levelConfig.spawnBaseCandies.indexOf(
                      spacerCandy,
                    ),
                  ),
                )
                .setTile(
                  right,
                  _tileFor(
                    levelConfig: levelConfig,
                    position: right,
                    index: 2,
                    baseCandyIndex: levelConfig.spawnBaseCandies.indexOf(
                      matchCandy,
                    ),
                  ),
                )
                .setTile(
                  belowMiddle,
                  _tileFor(
                    levelConfig: levelConfig,
                    position: belowMiddle,
                    index: 3,
                    baseCandyIndex: levelConfig.spawnBaseCandies.indexOf(
                      matchCandy,
                    ),
                  ),
                );
            if (matchDetector.detectMatches(candidateGrid).isEmpty &&
                validMoveDetector.hasValidMove(candidateGrid)) {
              return candidateGrid;
            }
          }
        }
      }
    }

    return grid;
  }

  Tile _tileFor({
    required LevelConfig levelConfig,
    required GridPosition position,
    required int index,
    required int baseCandyIndex,
  }) {
    final reactiveStates = levelConfig.spawnReactiveStates;
    final reactiveState = reactiveStates.contains(ReactiveState.none)
        ? ReactiveState.none
        : reactiveStates.first;
    return Tile(
      id: '${levelConfig.levelId}-valid-move-${position.row}-${position.column}-$index',
      baseCandy: levelConfig.spawnBaseCandies[baseCandyIndex],
      reactiveState: reactiveState,
    );
  }
}

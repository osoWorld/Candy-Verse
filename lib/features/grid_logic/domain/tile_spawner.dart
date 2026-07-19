import 'entities/grid_position.dart';
import 'entities/spawn_rule.dart';
import 'entities/tile.dart';

/// Deterministically creates refill tiles in the pure Dart core logic layer.
class TileSpawner {
  /// Creates a TileSpawner using [spawnRule].
  const TileSpawner({required this.spawnRule});

  /// Spawn identities available to this spawner.
  final SpawnRule spawnRule;

  /// Creates one tile for [position] and [spawnIndex].
  ///
  /// Inputs: grid position, global spawn index, and optional candidate offset.
  /// Output: deterministic Tile. Side effects: none.
  Tile spawnTile({
    required GridPosition position,
    required int spawnIndex,
    int candidateOffset = 0,
  }) {
    final mixedValue = _mix(
      spawnRule.seed,
      spawnIndex,
      position.row,
      position.column,
      candidateOffset,
    );
    final baseCandy =
        spawnRule.baseCandies[mixedValue % spawnRule.baseCandies.length];
    final reactiveState =
        spawnRule.reactiveStates[(mixedValue ~/ spawnRule.baseCandies.length) %
            spawnRule.reactiveStates.length];

    return Tile(
      id:
          'spawn-${spawnRule.seed}-$spawnIndex-${position.row}-'
          '${position.column}-$candidateOffset',
      baseCandy: baseCandy,
      reactiveState: reactiveState,
    );
  }

  int _mix(int seed, int spawnIndex, int row, int column, int candidateOffset) {
    var value = seed & 0x7fffffff;
    value = (value * 1103515245 + 12345 + spawnIndex * 374761393) & 0x7fffffff;
    value = (value + row * 668265263 + column * 2246822519) & 0x7fffffff;
    value = (value + candidateOffset * 3266489917) & 0x7fffffff;
    return value;
  }
}

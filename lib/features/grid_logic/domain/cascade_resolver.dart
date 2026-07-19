import 'entities/cascade_result.dart';
import 'entities/cascade_step_result.dart';
import 'entities/grid_position.dart';
import 'entities/grid_state.dart';
import 'entities/match_group.dart';
import 'entities/reaction_effect.dart';
import 'entities/spawn_rule.dart';
import 'entities/special_candy_activation.dart';
import 'entities/special_candy_creation.dart';
import 'entities/special_candy_type.dart';
import 'entities/tile.dart';
import 'match_detector.dart';
import 'refill_resolver.dart';
import 'reaction_engine.dart';
import 'special_candy_resolver.dart';
import 'tile_spawner.dart';

/// Resolves match clears and gravity in the pure Dart core logic layer.
class CascadeResolver {
  /// Creates a cascade resolver for match clears, Reaction Effects, and gravity.
  CascadeResolver({
    required this.matchDetector,
    ReactionEngine? reactionEngine,
    SpecialCandyResolver? specialCandyResolver,
    RefillResolver? refillResolver,
  }) : reactionEngine = reactionEngine ?? const ReactionEngine(),
       specialCandyResolver =
           specialCandyResolver ?? const SpecialCandyResolver(),
       refillResolver =
           refillResolver ??
           RefillResolver(
             tileSpawner: TileSpawner(spawnRule: SpawnRule.defaultRule),
           );

  /// Match detector used after each Cascade Step to find chain matches.
  final MatchDetector matchDetector;

  /// Reaction Engine used within each Cascade Step before gravity.
  final ReactionEngine reactionEngine;

  /// Special Candy resolver used before clear and gravity.
  final SpecialCandyResolver specialCandyResolver;

  /// Refill resolver used after gravity before the next Cascade Step.
  final RefillResolver refillResolver;

  /// Resolves all Cascade Step waves in [grid] until no matches remain.
  CascadeResult resolve(
    GridState grid, {
    Iterable<GridPosition> preferredCreationPositions = const [],
  }) {
    var currentGrid = grid;
    var spawnIndex = 0;
    final steps = <CascadeStepResult>[];
    var cascadeStepIndex = 0;

    while (true) {
      final matches = matchDetector.detectMatches(currentGrid);
      if (matches.isEmpty) {
        break;
      }

      final specialCandyResolution = specialCandyResolver.resolve(
        grid: currentGrid,
        matches: matches,
        preferredCreationPositions: cascadeStepIndex == 0
            ? preferredCreationPositions
            : const [],
      );
      final reactionEffects = reactionEngine.checkAdjacentReactions(
        grid: currentGrid,
        matches: matches,
      );
      final clearedPositions = _collectClearedPositions(
        matches: matches,
        reactionEffects: reactionEffects,
        specialCandyActivations: specialCandyResolution.activations,
        specialCandyCreations: specialCandyResolution.creations,
      );
      final blockerDamageResult = currentGrid.damageBlockers(
        _collectBlockerDamagePositions(
          matches: matches,
          clearedPositions: clearedPositions,
          specialCandyCreations: specialCandyResolution.creations,
        ),
      );
      final gridWithSpecialCreations = _applySpecialCandyCreations(
        grid: blockerDamageResult.grid,
        specialCandyCreations: specialCandyResolution.creations,
        clearedPositions: clearedPositions,
      );
      final gridAfterClear = gridWithSpecialCreations.clearPositions(
        clearedPositions,
      );
      final gridAfterGravity = applyGravity(gridAfterClear);
      final refillResult = refillResolver.refill(
        grid: gridAfterGravity,
        spawnStartIndex: spawnIndex,
      );
      final gridAfterRefill = refillResult.grid;
      spawnIndex = refillResult.nextSpawnIndex;

      steps.add(
        CascadeStepResult(
          gridBeforeClear: currentGrid,
          gridAfterGravity: gridAfterRefill,
          matches: matches,
          reactionEffects: reactionEffects,
          specialCandyCreations: specialCandyResolution.creations,
          specialCandyActivations: specialCandyResolution.activations,
          clearedPositions: clearedPositions,
          clearedBlockers: blockerDamageResult.clearedBlockers,
        ),
      );
      currentGrid = gridAfterRefill;
      cascadeStepIndex += 1;
    }

    return CascadeResult(
      finalGrid: currentGrid,
      steps: List<CascadeStepResult>.unmodifiable(steps),
    );
  }

  /// Resolves a direct Special Candy activation without requiring a match.
  ///
  /// Inputs: current [grid], special [origin], and optional target tile
  /// position for colorOrb. Output: one-step CascadeResult. Side effects: none.
  CascadeResult resolveSpecialActivation({
    required GridState grid,
    required GridPosition origin,
    GridPosition? target,
  }) {
    final originTile = grid.tileAt(origin);
    if (originTile == null ||
        originTile.specialCandyType == SpecialCandyType.none) {
      return CascadeResult(finalGrid: grid, steps: const []);
    }
    final targetTile = target == null ? null : grid.tileAt(target);
    final activation = specialCandyResolver.activate(
      grid: grid,
      origin: origin,
      targetBaseCandy: targetTile?.baseCandy,
    );
    final clearedPositions = activation.clearedPositions;
    if (clearedPositions.isEmpty) {
      return CascadeResult(finalGrid: grid, steps: const []);
    }

    final blockerDamageResult = grid.damageBlockers(clearedPositions);
    final gridAfterClear = blockerDamageResult.grid.clearPositions(
      clearedPositions,
    );
    final gridAfterGravity = applyGravity(gridAfterClear);
    final refillResult = refillResolver.refill(grid: gridAfterGravity);
    final activationStep = CascadeStepResult(
      gridBeforeClear: grid,
      gridAfterGravity: refillResult.grid,
      matches: const [],
      reactionEffects: const [],
      specialCandyActivations: [activation],
      clearedPositions: clearedPositions,
      clearedBlockers: blockerDamageResult.clearedBlockers,
    );
    final cascadeResult = resolve(refillResult.grid);
    return CascadeResult(
      finalGrid: cascadeResult.finalGrid,
      steps: [activationStep, ...cascadeResult.steps],
    );
  }

  /// Returns a new grid with non-empty tiles falling toward larger row indexes.
  GridState applyGravity(GridState grid) {
    final nextCells = [
      for (var row = 0; row < grid.rows; row += 1)
        List<Tile?>.filled(grid.columns, null),
    ];

    for (var column = 0; column < grid.columns; column += 1) {
      final playableRows = [
        for (var row = grid.rows - 1; row >= 0; row -= 1)
          if (grid.isPlayable(GridPosition(row: row, column: column))) row,
      ];
      var writeIndex = 0;
      for (final readRow in playableRows) {
        final tile = grid.tileAt(GridPosition(row: readRow, column: column));
        if (tile == null) {
          continue;
        }
        nextCells[playableRows[writeIndex]][column] = tile;
        writeIndex += 1;
      }
    }

    return GridState(
      rows: grid.rows,
      columns: grid.columns,
      cells: nextCells,
      boardMask: grid.boardMask,
      blockers: grid.blockers,
    );
  }

  Set<GridPosition> _collectClearedPositions({
    required List<MatchGroup> matches,
    required List<ReactionEffect> reactionEffects,
    required List<SpecialCandyActivation> specialCandyActivations,
    required List<SpecialCandyCreation> specialCandyCreations,
  }) {
    final reactionClearedPositions = {
      for (final reactionEffect in reactionEffects)
        ...reactionEffect.clearedPositions,
    };
    final activationClearedPositions = {
      for (final activation in specialCandyActivations)
        ...activation.clearedPositions,
    };
    final createdPositions = {
      for (final specialCandyCreation in specialCandyCreations)
        if (!reactionClearedPositions.contains(specialCandyCreation.position) &&
            !activationClearedPositions.contains(specialCandyCreation.position))
          specialCandyCreation.position,
    };
    return {
      for (final match in matches) ...match.positions,
      ...reactionClearedPositions,
      ...activationClearedPositions,
    }..removeAll(createdPositions);
  }

  Set<GridPosition> _collectBlockerDamagePositions({
    required List<MatchGroup> matches,
    required Set<GridPosition> clearedPositions,
    required List<SpecialCandyCreation> specialCandyCreations,
  }) {
    return {
      ...clearedPositions,
      for (final match in matches) ...match.positions,
      for (final specialCandyCreation in specialCandyCreations)
        specialCandyCreation.position,
    };
  }

  GridState _applySpecialCandyCreations({
    required GridState grid,
    required List<SpecialCandyCreation> specialCandyCreations,
    required Set<GridPosition> clearedPositions,
  }) {
    var nextGrid = grid;
    for (final specialCandyCreation in specialCandyCreations) {
      if (clearedPositions.contains(specialCandyCreation.position)) {
        continue;
      }
      nextGrid = nextGrid.setTile(
        specialCandyCreation.position,
        specialCandyCreation.tile,
      );
    }
    return nextGrid;
  }
}

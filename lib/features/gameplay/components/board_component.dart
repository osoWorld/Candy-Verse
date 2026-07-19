import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../boosters/domain/architect_tile.dart';
import '../../boosters/domain/booster_type.dart';
import '../../boosters/domain/echo_candy.dart';
import '../../boosters/domain/fusion_booster.dart';
import '../../boosters/domain/special_candy_type.dart' as booster_special;
import '../../grid_logic/domain/entities/cascade_result.dart';
import '../../grid_logic/domain/cascade_resolver.dart';
import '../../grid_logic/domain/entities/blocker_stack.dart';
import '../../grid_logic/domain/entities/blocker_type.dart';
import '../../grid_logic/domain/entities/cascade_step_result.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../../grid_logic/domain/entities/reaction_effect.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/entities/special_candy_type.dart'
    as grid_special;
import '../../grid_logic/domain/match_detector.dart';
import '../../grid_logic/domain/swap_resolver.dart';
import '../game/tempered_shatter_sound_hook.dart';
import 'combo_label_component.dart';
import 'particle_effects.dart';
import 'reactive_state_decal_component.dart';
import 'special_candy_effect_component.dart';
import 'tempered_shatter_effect_component.dart';
import 'tile_component.dart';

/// GridState board renderer and gesture bridge in the Flame game layer.
class BoardComponent extends PositionComponent
    with TapCallbacks, DragCallbacks {
  /// Creates a board renderer that reads [gridState].
  BoardComponent({
    required GridState gridState,
    required this.tileSize,
    required this.tileGap,
    SwapResolver? swapResolver,
    CascadeResolver? cascadeResolver,
    FusionBooster? fusionBooster,
    ArchitectTile? architectTile,
    EchoCandy? echoCandy,
    TemperedShatterSoundHook? temperedShatterSoundHook,
    this.onAcceptedSwap,
    this.onCascadeStepClear,
    this.onCascadeStepResolved,
    this.onCascadeSettled,
    this.isInputEnabledProvider,
    this.selectedBoosterProvider,
    this.onBoosterActivated,
    this.reduceMotionProvider,
  }) : _gridState = gridState,
       _swapResolver =
           swapResolver ??
           SwapResolver(
             matchDetector: MatchDetector(),
             cascadeResolver: CascadeResolver(matchDetector: MatchDetector()),
           ),
       _cascadeResolver =
           cascadeResolver ?? CascadeResolver(matchDetector: MatchDetector()),
       _fusionBooster = fusionBooster ?? const FusionBooster(),
       _architectTile = architectTile ?? const ArchitectTile(),
       _echoCandy = echoCandy ?? const EchoCandy(),
       _temperedShatterSoundHook =
           temperedShatterSoundHook ?? TemperedShatterSoundHook(),
       _trayPaint = Paint()..color = CandyAlchemyColors.boardTray,
       _trayBorderPaint = Paint()
         ..color = CandyAlchemyColors.boardTrayBorder
         ..style = PaintingStyle.stroke
         ..strokeWidth = staticTileStrokeWidth * 1.5,
       _cellPaint = Paint()..color = CandyAlchemyColors.boardCell,
       _cellHighlightPaint = Paint()
         ..color = CandyAlchemyColors.boardCellHighlight
         ..style = PaintingStyle.stroke
         ..strokeWidth = 1.2,
       super(
         size: Vector2(
           staticBoardPadding * 2 +
               gridState.columns * tileSize +
               (gridState.columns - 1) * tileGap,
           staticBoardPadding * 2 +
               gridState.rows * tileSize +
               (gridState.rows - 1) * tileGap,
         ),
       );

  /// Grid state read from the pure Dart core logic layer.
  GridState get gridState => _gridState;
  GridState _gridState;

  /// Logical tile size used for rendering.
  final double tileSize;

  /// Logical gap between rendered tiles.
  final double tileGap;

  /// Updates the board component size after responsive layout changes.
  ///
  /// Inputs: none. Output: none. Side effects: updates Flame component size.
  void refreshSizeFromGrid() {
    size = Vector2(
      staticBoardPadding * 2 +
          _gridState.columns * tileSize +
          (_gridState.columns - 1) * tileGap,
      staticBoardPadding * 2 +
          _gridState.rows * tileSize +
          (_gridState.rows - 1) * tileGap,
    );
  }

  /// Callback invoked after the pure logic layer accepts a swap.
  final void Function()? onAcceptedSwap;

  /// Callback invoked before each Cascade Step clear animation.
  final void Function(int cascadeStepIndex)? onCascadeStepClear;

  /// Callback invoked with the full Cascade Step payload for scoring/goals.
  final void Function(int cascadeStepIndex, CascadeStepResult cascadeStep)?
  onCascadeStepResolved;

  /// Callback invoked after the board has finished resolving cascades.
  final void Function()? onCascadeSettled;

  /// Returns whether board gestures should currently be accepted.
  final bool Function()? isInputEnabledProvider;

  /// Returns a selected booster when the next tap should target the board.
  final BoosterType? Function()? selectedBoosterProvider;

  /// Callback invoked after a booster successfully changes the board.
  final bool Function(BoosterType boosterType)? onBoosterActivated;

  /// Returns whether intense gameplay motion should be reduced.
  final bool Function()? reduceMotionProvider;

  final SwapResolver _swapResolver;
  final CascadeResolver _cascadeResolver;
  final FusionBooster _fusionBooster;
  final ArchitectTile _architectTile;
  final EchoCandy _echoCandy;
  final TemperedShatterSoundHook _temperedShatterSoundHook;
  final Paint _trayPaint;
  final Paint _trayBorderPaint;
  final Paint _cellPaint;
  final Paint _cellHighlightPaint;
  final Map<GridPosition, TileComponent> _tileComponents = {};
  final List<ParticleEffects> _particleEffectPool = [];
  final Vector2 _shakeBasePosition = Vector2.zero();
  _BoardInteractionState _interactionState = _BoardInteractionState.idle;
  GridPosition? _selectedPosition;
  GridPosition? _dragStartPosition;
  var _dragDeltaX = 0.0;
  var _dragDeltaY = 0.0;
  var _shakeElapsedSeconds = 0.0;
  var _isShaking = false;
  CascadeStepResult? _lastCascadeStep;

  /// Adds one TileComponent child for each non-empty GridState cell.
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _rebuildTileComponents();
  }

  /// Advances board-level camera shake for Tempered Shatter VFX.
  @override
  void update(double dt) {
    super.update(dt);

    if (!_isShaking) {
      return;
    }
    if (_reduceMotionEnabled) {
      position.setFrom(_shakeBasePosition);
      _isShaking = false;
      return;
    }

    // DESIGN.md §5 — 4px decaying sine-wave camera shake for 150ms.
    _shakeElapsedSeconds += dt;
    final progress =
        (_shakeElapsedSeconds / temperedShatterCameraShakeDurationSeconds)
            .clamp(0.0, 1.0);
    if (progress >= 1) {
      position.setFrom(_shakeBasePosition);
      _isShaking = false;
      return;
    }

    final amplitude = temperedShatterCameraShakePixels * (1 - progress);
    position.setValues(
      _shakeBasePosition.x + math.sin(progress * math.pi * 8) * amplitude,
      _shakeBasePosition.y +
          math.sin(progress * math.pi * 13) * amplitude * 0.5,
    );
  }

  /// Handles tap selection and tap-to-swap between adjacent tiles.
  @override
  void onTapDown(TapDownEvent event) {
    if (!_isInputEnabled() ||
        _interactionState != _BoardInteractionState.idle) {
      return;
    }
    final gridPosition = _gridPositionFromLocal(event.localPosition);
    if (gridPosition == null) {
      _clearSelectedPosition();
      return;
    }

    final selectedBooster = selectedBoosterProvider?.call();
    if (selectedBooster != null) {
      _clearSelectedPosition();
      unawaited(_activateSelectedBooster(selectedBooster, gridPosition));
      return;
    }
    _handleTappedGridPosition(gridPosition);
  }

  /// Captures the drag start position for swipe-to-swap.
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (!_isInputEnabled() ||
        _interactionState != _BoardInteractionState.idle) {
      return;
    }
    if (selectedBoosterProvider?.call() != null) {
      return;
    }
    _dragStartPosition = _gridPositionFromLocal(event.localPosition);
    _dragDeltaX = 0;
    _dragDeltaY = 0;
  }

  /// Converts a drag gesture into one adjacent swap attempt.
  @override
  void onDragUpdate(DragUpdateEvent event) {
    if (_interactionState != _BoardInteractionState.idle ||
        !_isInputEnabled() ||
        _dragStartPosition == null) {
      return;
    }

    _dragDeltaX += event.localDelta.x;
    _dragDeltaY += event.localDelta.y;
    final threshold = tileSize * dragSwapThresholdTileFraction;
    if (_dragDeltaX.abs() < threshold && _dragDeltaY.abs() < threshold) {
      return;
    }

    final startPosition = _dragStartPosition!;
    final targetPosition = _dragTargetFor(startPosition);
    _dragStartPosition = null;
    if (targetPosition != null && _gridState.contains(targetPosition)) {
      _attemptSwap(startPosition, targetPosition);
    }
  }

  /// Clears pending drag state.
  @override
  void onDragEnd(DragEndEvent event) {
    super.onDragEnd(event);
    _dragStartPosition = null;
    _dragDeltaX = 0;
    _dragDeltaY = 0;
  }

  /// Renders the board tray behind tile children.
  @override
  void render(Canvas canvas) {
    final trayRect = Offset.zero & Size(size.x, size.y);
    final trayRRect = RRect.fromRectAndRadius(
      trayRect,
      const Radius.circular(staticBoardCornerRadius),
    );

    // DESIGN.md section 6: playful purple tray with visible candy cells.
    canvas.drawRRect(trayRRect, _trayPaint);
    _drawBoardCells(canvas);
    canvas.drawRRect(trayRRect, _trayBorderPaint);
    super.render(canvas);
    _drawBlockers(canvas);
  }

  void _drawBoardCells(Canvas canvas) {
    for (var row = 0; row < _gridState.rows; row += 1) {
      for (var column = 0; column < _gridState.columns; column += 1) {
        final gridPosition = GridPosition(row: row, column: column);
        if (!_gridState.isPlayable(gridPosition)) {
          continue;
        }
        final cellRect = Rect.fromLTWH(
          staticBoardPadding + column * (tileSize + tileGap),
          staticBoardPadding + row * (tileSize + tileGap),
          tileSize,
          tileSize,
        ).deflate(tileSize * 0.04);
        final cellRRect = RRect.fromRectAndRadius(
          cellRect,
          Radius.circular(tileSize * 0.16),
        );
        canvas
          ..drawRRect(cellRRect, _cellPaint)
          ..drawArc(
            cellRect.deflate(tileSize * 0.12),
            3.9,
            1.1,
            false,
            _cellHighlightPaint,
          );
      }
    }
  }

  void _drawBlockers(Canvas canvas) {
    for (final entry in _gridState.blockers.entries) {
      _drawBlocker(canvas, entry.key, entry.value);
    }
  }

  void _drawBlocker(
    Canvas canvas,
    GridPosition gridPosition,
    BlockerStack blocker,
  ) {
    final rect = _rectForGridPosition(gridPosition).deflate(tileSize * 0.1);
    final fillPaint = Paint()..color = _blockerColorFor(blocker.blockerType);
    final strokePaint = Paint()
      ..color = CandyAlchemyColors.blockerStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.0, tileSize * 0.035);
    final rRect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(tileSize * 0.14),
    );

    // DESIGN.md section 7: blockers overlay the candy with distinct silhouettes.
    switch (blocker.blockerType) {
      case BlockerType.chocolate:
        canvas.drawRRect(rRect, fillPaint);
        _drawChocolateBlockerGrooves(canvas, rect, strokePaint);
      case BlockerType.ice:
        _drawIceBlocker(canvas, rect, fillPaint, strokePaint);
      case BlockerType.wafer:
        canvas.drawRRect(rRect, fillPaint);
        _drawWaferBlockerStripes(canvas, rect, strokePaint);
      case BlockerType.syrupLock:
        canvas.drawRRect(rRect, fillPaint);
        _drawSyrupLock(canvas, rect, strokePaint);
      case BlockerType.spiceCrate:
        canvas.drawRRect(rRect, fillPaint);
        _drawSpiceCrateCross(canvas, rect, strokePaint);
    }
    canvas.drawRRect(rRect, strokePaint);
    _drawBlockerHitPips(canvas, rect, blocker.hitPoints);
  }

  void _drawChocolateBlockerGrooves(
    Canvas canvas,
    Rect rect,
    Paint strokePaint,
  ) {
    canvas
      ..drawLine(
        Offset(rect.left + rect.width * 0.5, rect.top),
        Offset(rect.left + rect.width * 0.5, rect.bottom),
        strokePaint,
      )
      ..drawLine(
        Offset(rect.left, rect.top + rect.height * 0.5),
        Offset(rect.right, rect.top + rect.height * 0.5),
        strokePaint,
      );
  }

  void _drawIceBlocker(
    Canvas canvas,
    Rect rect,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right, rect.center.dy)
      ..lineTo(rect.center.dx, rect.bottom)
      ..lineTo(rect.left, rect.center.dy)
      ..close();
    canvas
      ..drawPath(path, fillPaint)
      ..drawPath(path, strokePaint)
      ..drawLine(rect.topLeft, rect.bottomRight, strokePaint)
      ..drawLine(rect.topRight, rect.bottomLeft, strokePaint);
  }

  void _drawWaferBlockerStripes(Canvas canvas, Rect rect, Paint strokePaint) {
    for (var index = 1; index <= 2; index += 1) {
      final x = rect.left + rect.width * index / 3;
      final y = rect.top + rect.height * index / 3;
      canvas
        ..drawLine(Offset(x, rect.top), Offset(x, rect.bottom), strokePaint)
        ..drawLine(Offset(rect.left, y), Offset(rect.right, y), strokePaint);
    }
  }

  void _drawSyrupLock(Canvas canvas, Rect rect, Paint strokePaint) {
    final shackleRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + rect.height * 0.36),
      width: rect.width * 0.42,
      height: rect.height * 0.42,
    );
    final bodyRect = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + rect.height * 0.62),
      width: rect.width * 0.52,
      height: rect.height * 0.38,
    );
    canvas
      ..drawArc(shackleRect, math.pi, math.pi, false, strokePaint)
      ..drawRRect(
        RRect.fromRectAndRadius(bodyRect, Radius.circular(tileSize * 0.08)),
        strokePaint,
      );
  }

  void _drawSpiceCrateCross(Canvas canvas, Rect rect, Paint strokePaint) {
    canvas
      ..drawLine(rect.topLeft, rect.bottomRight, strokePaint)
      ..drawLine(rect.topRight, rect.bottomLeft, strokePaint)
      ..drawLine(
        Offset(rect.left, rect.top + rect.height * 0.5),
        Offset(rect.right, rect.top + rect.height * 0.5),
        strokePaint,
      );
  }

  void _drawBlockerHitPips(Canvas canvas, Rect rect, int hitPoints) {
    final pipPaint = Paint()..color = CandyAlchemyColors.blockerStroke;
    final radius = math.max(1.2, tileSize * 0.035);
    for (var index = 0; index < hitPoints; index += 1) {
      canvas.drawCircle(
        Offset(
          rect.right - radius * (2.2 + index * 2.4),
          rect.bottom - radius * 2.2,
        ),
        radius,
        pipPaint,
      );
    }
  }

  Color _blockerColorFor(BlockerType blockerType) {
    return switch (blockerType) {
      BlockerType.chocolate => CandyAlchemyColors.chocolateBlocker,
      BlockerType.ice => CandyAlchemyColors.iceBlocker,
      BlockerType.wafer => CandyAlchemyColors.waferBlocker,
      BlockerType.syrupLock => CandyAlchemyColors.syrupLockBlocker,
      BlockerType.spiceCrate => CandyAlchemyColors.spiceCrateBlocker,
    };
  }

  Future<void> _rebuildTileComponents() async {
    removeWhere((component) => component is TileComponent);
    _tileComponents.clear();
    // ARCHITECTURE.md section 3: Flame reads core GridState only.
    for (var row = 0; row < _gridState.rows; row += 1) {
      for (var column = 0; column < _gridState.columns; column += 1) {
        final gridPosition = GridPosition(row: row, column: column);
        final tile = _gridState.tileAt(gridPosition);
        if (tile == null) {
          continue;
        }
        final tileComponent = TileComponent(
          tile: tile,
          gridPosition: gridPosition,
          tileSize: tileSize,
          position: _positionForGridPosition(gridPosition),
        );
        _tileComponents[gridPosition] = tileComponent;
        await add(tileComponent);
      }
    }
  }

  void _handleTappedGridPosition(GridPosition gridPosition) {
    final selectedPosition = _selectedPosition;
    if (selectedPosition == null) {
      _setSelectedPosition(gridPosition);
      return;
    }
    if (selectedPosition == gridPosition) {
      _clearSelectedPosition();
      return;
    }
    if (selectedPosition.isOrthogonallyAdjacentTo(gridPosition)) {
      _attemptSwap(selectedPosition, gridPosition);
      return;
    }
    _setSelectedPosition(gridPosition);
  }

  Future<void> _activateSelectedBooster(
    BoosterType boosterType,
    GridPosition origin,
  ) async {
    if (_interactionState != _BoardInteractionState.idle) {
      return;
    }
    if (!_isInputEnabled()) {
      return;
    }
    if (!_gridState.contains(origin) || _gridState.tileAt(origin) == null) {
      return;
    }

    _interactionState = _BoardInteractionState.clearing;
    final didActivate = switch (boosterType) {
      BoosterType.fusionBooster => await _activateFusionBooster(origin),
      BoosterType.architectTile => await _activateArchitectTile(origin),
      BoosterType.echoCandy => await _activateEchoCandy(),
      BoosterType.tempoMeter => false,
    };
    if (didActivate) {
      onBoosterActivated?.call(boosterType);
    }
    _interactionState = _BoardInteractionState.idle;
  }

  Future<bool> _activateFusionBooster(GridPosition origin) async {
    final activation = _fusionBooster.activate(
      grid: _gridState,
      origin: origin,
      firstSpecialCandyType: booster_special.SpecialCandyType.rowClear,
      secondSpecialCandyType: booster_special.SpecialCandyType.columnClear,
    );
    await _playBoosterClearThenCascade(activation.affectedPositions);
    return true;
  }

  Future<bool> _activateArchitectTile(GridPosition origin) async {
    try {
      final activation = _architectTile.rotateSectionClockwise(
        grid: _gridState,
        center: origin,
      );
      await _playGridTransition(activation.gridAfter);
      _gridState = activation.gridAfter;
      final cascadeResult = _cascadeResolver.resolve(_gridState);
      await _playCascadeResult(cascadeResult);
      _gridState = cascadeResult.finalGrid;
      onCascadeSettled?.call();
      return true;
    } on RangeError {
      return false;
    }
  }

  Future<bool> _activateEchoCandy() async {
    final lastCascadeStep = _lastCascadeStep;
    if (lastCascadeStep == null) {
      return false;
    }
    final replay = _echoCandy.scheduleReplay(lastCascadeStep);
    await Future<void>.delayed(_durationFromSeconds(replay.delaySeconds));
    await _playBoosterClearThenCascade(replay.replayPositions);
    return true;
  }

  Future<void> _attemptSwap(GridPosition first, GridPosition second) async {
    if (_interactionState != _BoardInteractionState.idle) {
      return;
    }
    if (!_isInputEnabled()) {
      return;
    }
    _clearSelectedPosition();

    final firstComponent = _tileComponents[first];
    final secondComponent = _tileComponents[second];
    if (firstComponent == null || secondComponent == null) {
      return;
    }

    _interactionState = _BoardInteractionState.swapping;
    final swapResult = _swapResolver.resolveSwap(
      grid: _gridState,
      first: first,
      second: second,
    );

    if (!swapResult.isAccepted) {
      await _playRejectedSwap(firstComponent, secondComponent, first, second);
      _interactionState = _BoardInteractionState.idle;
      return;
    }

    onAcceptedSwap?.call();
    await _playAcceptedSwap(firstComponent, secondComponent, first, second);
    _commitVisualSwap(firstComponent, secondComponent, first, second);
    _gridState = swapResult.swappedGrid;
    await _playCascadeResult(swapResult.cascadeResult!);
    _gridState = swapResult.cascadeResult!.finalGrid;
    onCascadeSettled?.call();
    _interactionState = _BoardInteractionState.idle;
  }

  Future<void> _playAcceptedSwap(
    TileComponent firstComponent,
    TileComponent secondComponent,
    GridPosition first,
    GridPosition second,
  ) async {
    await Future.wait([
      _moveTileTo(firstComponent, _positionForGridPosition(second)),
      _moveTileTo(secondComponent, _positionForGridPosition(first)),
    ]);
  }

  Future<void> _playRejectedSwap(
    TileComponent firstComponent,
    TileComponent secondComponent,
    GridPosition first,
    GridPosition second,
  ) async {
    await Future.wait([
      _moveTileTo(firstComponent, _positionForGridPosition(second)),
      _moveTileTo(secondComponent, _positionForGridPosition(first)),
    ]);
    await Future.wait([
      _moveTileTo(
        firstComponent,
        _positionForGridPosition(first),
        isRejectedReturn: true,
      ),
      _moveTileTo(
        secondComponent,
        _positionForGridPosition(second),
        isRejectedReturn: true,
      ),
    ]);
  }

  Future<void> _playCascadeResult(CascadeResult cascadeResult) async {
    var cascadeStepIndex = 0;
    for (final cascadeStep in cascadeResult.steps) {
      onCascadeStepClear?.call(cascadeStepIndex);
      onCascadeStepResolved?.call(cascadeStepIndex, cascadeStep);
      _showComboLabel(cascadeStepIndex);
      await _playCascadeStep(cascadeStep);
      _lastCascadeStep = cascadeStep;
      cascadeStepIndex += 1;
    }
  }

  Future<void> _playBoosterClearThenCascade(
    Iterable<GridPosition> positions,
  ) async {
    final clearedPositions = {
      for (final position in positions)
        if (_gridState.contains(position) &&
            _gridState.tileAt(position) != null)
          position,
    };
    if (clearedPositions.isEmpty) {
      return;
    }

    final blockerDamageResult = _gridState.damageBlockers(clearedPositions);
    final gridAfterClear = blockerDamageResult.grid.clearPositions(
      clearedPositions,
    );
    final gridAfterGravity = _cascadeResolver.applyGravity(gridAfterClear);
    final refillResult = _cascadeResolver.refillResolver.refill(
      grid: gridAfterGravity,
    );
    final boosterStep = CascadeStepResult(
      gridBeforeClear: _gridState,
      gridAfterGravity: refillResult.grid,
      matches: const [],
      reactionEffects: const [],
      clearedPositions: clearedPositions,
      clearedBlockers: blockerDamageResult.clearedBlockers,
    );
    onCascadeStepClear?.call(0);
    onCascadeStepResolved?.call(0, boosterStep);
    await _playCascadeStep(boosterStep);
    _lastCascadeStep = boosterStep;
    _gridState = boosterStep.gridAfterGravity;

    final cascadeResult = _cascadeResolver.resolve(_gridState);
    await _playCascadeResult(cascadeResult);
    _gridState = cascadeResult.finalGrid;
    onCascadeSettled?.call();
  }

  Future<void> _playGridTransition(GridState gridAfter) async {
    _interactionState = _BoardInteractionState.falling;
    final destinationByTileId = _positionsByTileId(gridAfter);
    final moves = <Future<void>>[];
    final nextTileComponents = <GridPosition, TileComponent>{};

    for (final entry in _tileComponents.entries) {
      final tileComponent = entry.value;
      final destination = destinationByTileId[tileComponent.tile.id];
      if (destination == null) {
        tileComponent.removeFromParent();
        continue;
      }
      tileComponent.updateGridPosition(destination);
      nextTileComponents[destination] = tileComponent;
      final targetPosition = _positionForGridPosition(destination);
      if (tileComponent.position != targetPosition) {
        moves.add(_moveTileTo(tileComponent, targetPosition));
      }
    }

    _tileComponents
      ..clear()
      ..addAll(nextTileComponents);

    if (moves.isNotEmpty) {
      await Future.wait(moves);
    }
    for (final entry in _tileComponents.entries) {
      entry.value.position = _positionForGridPosition(entry.key);
    }
  }

  Future<void> _playCascadeStep(CascadeStepResult cascadeStep) async {
    await _playClearAnimations(cascadeStep);
    await _playGravityAnimation(cascadeStep);
    _gridState = cascadeStep.gridAfterGravity;
  }

  Future<void> _playClearAnimations(CascadeStepResult cascadeStep) async {
    _interactionState = _BoardInteractionState.clearing;
    final specialCandyAnimation = _playSpecialCandyEffectAnimations(
      cascadeStep,
    );
    final reactionAnimation = _playReactionEffectAnimations(cascadeStep);
    if (reactionAnimation != null) {
      await Future<void>.delayed(
        _durationFromSeconds(
          _motionDuration(temperedShatterRowClearDelaySeconds),
        ),
      );
    }

    final clearAnimations = <Future<void>>[];
    for (final clearedPosition in cascadeStep.clearedPositions) {
      final tileComponent = _tileComponents[clearedPosition];
      if (tileComponent != null) {
        _spawnSugarSparkle(clearedPosition);
        _spawnReactiveStateEffects(cascadeStep, clearedPosition);
        clearAnimations.add(tileComponent.startClearAnimation());
      }
    }
    if (reactionAnimation != null) {
      clearAnimations.add(reactionAnimation);
    }
    if (specialCandyAnimation != null) {
      clearAnimations.add(specialCandyAnimation);
    }
    if (clearAnimations.isNotEmpty) {
      await Future.wait(clearAnimations);
    }
    for (final clearedPosition in cascadeStep.clearedPositions) {
      final tileComponent = _tileComponents.remove(clearedPosition);
      tileComponent?.removeFromParent();
    }
  }

  Future<void> _playGravityAnimation(CascadeStepResult cascadeStep) async {
    _interactionState = _BoardInteractionState.falling;
    final destinationByTileId = _positionsByTileId(
      cascadeStep.gridAfterGravity,
    );
    final moves = <Future<void>>[];
    final nextTileComponents = <GridPosition, TileComponent>{};

    for (final entry in _tileComponents.entries) {
      final tileComponent = entry.value;
      final destination = destinationByTileId[tileComponent.tile.id];
      if (destination == null) {
        tileComponent.removeFromParent();
        continue;
      }
      tileComponent.updateGridPosition(destination);
      nextTileComponents[destination] = tileComponent;
      final targetPosition = _positionForGridPosition(destination);
      if (tileComponent.position != targetPosition) {
        moves.add(
          _fallTileTo(
            tileComponent,
            targetPosition,
            rowDistance: math.max(1, (destination.row - entry.key.row).abs()),
          ),
        );
      }
    }

    _tileComponents
      ..clear()
      ..addAll(nextTileComponents);

    await _addRefilledTileComponents(
      cascadeStep.gridAfterGravity,
      nextTileComponents,
      moves,
    );

    if (moves.isNotEmpty) {
      await Future.wait(moves);
    }
    for (final entry in _tileComponents.entries) {
      entry.value.position = _positionForGridPosition(entry.key);
    }
  }

  Future<void> _addRefilledTileComponents(
    GridState gridState,
    Map<GridPosition, TileComponent> nextTileComponents,
    List<Future<void>> moves,
  ) async {
    final spawnedByColumn = <int, int>{};

    for (var row = 0; row < gridState.rows; row += 1) {
      for (var column = 0; column < gridState.columns; column += 1) {
        final destination = GridPosition(row: row, column: column);
        if (nextTileComponents.containsKey(destination)) {
          continue;
        }
        final tile = gridState.tileAt(destination);
        if (tile == null) {
          continue;
        }

        final spawnDepth = spawnedByColumn[column] ?? 0;
        spawnedByColumn[column] = spawnDepth + 1;
        final targetPosition = _positionForGridPosition(destination);
        final startPosition = Vector2(
          targetPosition.x,
          staticBoardPadding - (spawnDepth + 1) * (tileSize + tileGap),
        );
        final tileComponent = TileComponent(
          tile: tile,
          gridPosition: destination,
          tileSize: tileSize,
          position: startPosition,
        );
        nextTileComponents[destination] = tileComponent;
        _tileComponents[destination] = tileComponent;
        await add(tileComponent);
        moves.add(
          _fallTileTo(
            tileComponent,
            targetPosition,
            rowDistance: destination.row + spawnDepth + 1,
          ),
        );
      }
    }
  }

  Future<void> _moveTileTo(
    TileComponent tileComponent,
    Vector2 targetPosition, {
    bool isRejectedReturn = false,
  }) {
    final duration = isRejectedReturn
        ? rejectedSwapReturnDurationSeconds
        : basicSwapDurationSeconds;
    final effect = MoveEffect.to(
      targetPosition,
      EffectController(
        duration: _motionDuration(duration),
        curve: isRejectedReturn ? Curves.easeInOutCubic : Curves.easeOutCubic,
      ),
    );
    tileComponent.add(effect);
    return effect.completed;
  }

  Future<void> _fallTileTo(
    TileComponent tileComponent,
    Vector2 targetPosition, {
    required int rowDistance,
  }) {
    final fallDuration = _fallDuration(rowDistance);
    final effect = MoveEffect.to(
      targetPosition,
      EffectController(
        duration: _motionDuration(fallDuration),
        curve: Curves.easeOutCubic,
      ),
    );
    tileComponent.add(effect);
    return effect.completed.then((_) {
      if (_reduceMotionEnabled) {
        return null;
      }
      return tileComponent.startLandingBounce();
    });
  }

  Future<void>? _playSpecialCandyEffectAnimations(
    CascadeStepResult cascadeStep,
  ) {
    final animations = <Future<void>>[];
    for (final activation in cascadeStep.specialCandyActivations) {
      if (activation.specialCandyType == grid_special.SpecialCandyType.none ||
          activation.clearedPositions.isEmpty) {
        continue;
      }

      final effect = SpecialCandyEffectComponent(
        activation: activation,
        tileSize: tileSize,
        tileGap: tileGap,
        boardSize: size,
        reduceMotion: _reduceMotionEnabled,
      )..priority = specialCandyEffectPriority;
      add(effect);
      animations.add(effect.completed);
    }

    if (animations.isEmpty) {
      return null;
    }
    return Future.wait(animations);
  }

  Future<void>? _playReactionEffectAnimations(CascadeStepResult cascadeStep) {
    final animations = <Future<void>>[];
    for (final reactionEffect in cascadeStep.reactionEffects) {
      if (reactionEffect is! TemperedShatterReaction) {
        continue;
      }

      _temperedShatterSoundHook.playTemperedShatter();
      if (!_reduceMotionEnabled) {
        _startTemperedShatterCameraShake();
      }
      final effect = TemperedShatterEffectComponent(
        row: reactionEffect.row,
        triggerPositions: reactionEffect.triggerPositions,
        clearedPositions: reactionEffect.clearedPositions,
        tileSize: tileSize,
        tileGap: tileGap,
        size: size,
        reduceMotion: _reduceMotionEnabled,
      )..priority = temperedShatterEffectPriority;
      add(effect);
      animations.add(effect.completed);
    }

    if (animations.isEmpty) {
      return null;
    }
    return Future.wait(animations);
  }

  void _showComboLabel(int cascadeStepIndex) {
    if (_reduceMotionEnabled || cascadeStepIndex < 1) {
      return;
    }
    final labelHeight = math.max(tileSize * 1.35, 48.0);
    final label = ComboLabelComponent(
      cascadeStepIndex: cascadeStepIndex,
      position: Vector2(0, staticBoardPadding + tileSize * 0.35),
      size: Vector2(size.x, labelHeight),
    )..priority = cascadeComboLabelPriority;
    add(label);
  }

  void _startTemperedShatterCameraShake() {
    _shakeBasePosition.setFrom(position);
    _shakeElapsedSeconds = 0;
    _isShaking = true;
  }

  void _spawnReactiveStateEffects(
    CascadeStepResult cascadeStep,
    GridPosition clearedPosition,
  ) {
    final tile = cascadeStep.gridBeforeClear.tileAt(clearedPosition);
    if (tile == null || tile.reactiveState == ReactiveState.none) {
      return;
    }
    if (_reduceMotionEnabled) {
      return;
    }

    final topLeft = _positionForGridPosition(clearedPosition);
    final particleKind = _particleKindFor(tile.reactiveState);
    if (particleKind != null) {
      _spawnParticleEffect(particleKind, topLeft);
    }

    // DESIGN.md section 4: reactive-state decals are visual-only board feedback.
    switch (tile.reactiveState) {
      case ReactiveState.molten:
        _spawnMoltenHeatTrail(cascadeStep, clearedPosition);
      case ReactiveState.frost:
        _spawnFrostNeighborTints(cascadeStep, clearedPosition);
      case ReactiveState.syrup:
        _spawnSyrupColumnSlick(cascadeStep, clearedPosition.column);
      case ReactiveState.living:
      case ReactiveState.spice:
      case ReactiveState.none:
        break;
    }
  }

  void _spawnSugarSparkle(GridPosition clearedPosition) {
    if (_reduceMotionEnabled) {
      return;
    }
    _spawnParticleEffect(
      ParticleEffectKind.sugarSparkle,
      _positionForGridPosition(clearedPosition),
    );
  }

  void _spawnMoltenHeatTrail(
    CascadeStepResult cascadeStep,
    GridPosition clearedPosition,
  ) {
    final below = GridPosition(
      row: clearedPosition.row + 1,
      column: clearedPosition.column,
    );
    if (!cascadeStep.gridBeforeClear.contains(below)) {
      return;
    }
    _spawnDecal(
      kind: ReactiveStateDecalKind.heatTrail,
      position: _positionForGridPosition(below),
      size: Vector2.all(tileSize),
    );
  }

  void _spawnFrostNeighborTints(
    CascadeStepResult cascadeStep,
    GridPosition clearedPosition,
  ) {
    final neighbors = <GridPosition>[
      GridPosition(
        row: clearedPosition.row - 1,
        column: clearedPosition.column,
      ),
      GridPosition(
        row: clearedPosition.row + 1,
        column: clearedPosition.column,
      ),
      GridPosition(
        row: clearedPosition.row,
        column: clearedPosition.column - 1,
      ),
      GridPosition(
        row: clearedPosition.row,
        column: clearedPosition.column + 1,
      ),
    ];
    for (final neighbor in neighbors) {
      if (!cascadeStep.gridBeforeClear.contains(neighbor)) {
        continue;
      }
      _spawnDecal(
        kind: ReactiveStateDecalKind.frostTint,
        position: _positionForGridPosition(neighbor),
        size: Vector2.all(tileSize),
      );
    }
  }

  void _spawnSyrupColumnSlick(CascadeStepResult cascadeStep, int column) {
    final columnHeight =
        cascadeStep.gridBeforeClear.rows * tileSize +
        (cascadeStep.gridBeforeClear.rows - 1) * tileGap;
    _spawnDecal(
      kind: ReactiveStateDecalKind.syrupSlick,
      position: Vector2(
        staticBoardPadding + column * (tileSize + tileGap),
        staticBoardPadding,
      ),
      size: Vector2(tileSize, columnHeight),
    );
  }

  void _spawnDecal({
    required ReactiveStateDecalKind kind,
    required Vector2 position,
    required Vector2 size,
  }) {
    final decal = ReactiveStateDecalComponent(
      kind: kind,
      position: position,
      size: size,
    )..priority = reactiveStateDecalPriority;
    add(decal);
  }

  void _spawnParticleEffect(ParticleEffectKind kind, Vector2 position) {
    final effect = _acquireParticleEffect();
    effect
      ..priority = reactiveStateParticlePriority
      ..play(kind: kind, position: position, tileSize: tileSize);
    add(effect);
  }

  ParticleEffects _acquireParticleEffect() {
    for (final effect in _particleEffectPool) {
      if (!effect.isMounted && !effect.isRemoving) {
        return effect;
      }
    }
    final effect = ParticleEffects();
    _particleEffectPool.add(effect);
    return effect;
  }

  double _fallDuration(int rowDistance) {
    final duration =
        cascadeFallBaseDurationSeconds +
        math.max(0, rowDistance - 1) * cascadeFallPerRowDurationSeconds;
    return math.min(duration, cascadeFallMaxDurationSeconds);
  }

  ParticleEffectKind? _particleKindFor(ReactiveState reactiveState) {
    switch (reactiveState) {
      case ReactiveState.molten:
        return ParticleEffectKind.moltenEmber;
      case ReactiveState.frost:
        return ParticleEffectKind.frostShard;
      case ReactiveState.living:
        return ParticleEffectKind.livingHeart;
      case ReactiveState.syrup:
        return ParticleEffectKind.syrupSplash;
      case ReactiveState.spice:
        return ParticleEffectKind.spiceEmber;
      case ReactiveState.none:
        return null;
    }
  }

  void _commitVisualSwap(
    TileComponent firstComponent,
    TileComponent secondComponent,
    GridPosition first,
    GridPosition second,
  ) {
    firstComponent.updateGridPosition(second);
    secondComponent.updateGridPosition(first);
    _tileComponents[first] = secondComponent;
    _tileComponents[second] = firstComponent;
  }

  void _setSelectedPosition(GridPosition gridPosition) {
    _clearSelectedPosition();
    _selectedPosition = gridPosition;
    _tileComponents[gridPosition]?.setSelected(true);
  }

  void _clearSelectedPosition() {
    final selectedPosition = _selectedPosition;
    if (selectedPosition != null) {
      _tileComponents[selectedPosition]?.setSelected(false);
    }
    _selectedPosition = null;
  }

  GridPosition? _gridPositionFromLocal(Vector2 localPosition) {
    final boardX = localPosition.x - staticBoardPadding;
    final boardY = localPosition.y - staticBoardPadding;
    if (boardX < 0 || boardY < 0) {
      return null;
    }

    final pitch = tileSize + tileGap;
    final column = boardX ~/ pitch;
    final row = boardY ~/ pitch;
    if (row < 0 ||
        row >= _gridState.rows ||
        column < 0 ||
        column >= _gridState.columns) {
      return null;
    }
    if (boardX - column * pitch >= tileSize ||
        boardY - row * pitch >= tileSize) {
      return null;
    }
    final gridPosition = GridPosition(row: row, column: column);
    if (!_gridState.isPlayable(gridPosition)) {
      return null;
    }
    return gridPosition;
  }

  GridPosition? _dragTargetFor(GridPosition startPosition) {
    if (_dragDeltaX.abs() > _dragDeltaY.abs()) {
      return GridPosition(
        row: startPosition.row,
        column: startPosition.column + (_dragDeltaX > 0 ? 1 : -1),
      );
    }
    return GridPosition(
      row: startPosition.row + (_dragDeltaY > 0 ? 1 : -1),
      column: startPosition.column,
    );
  }

  Vector2 _positionForGridPosition(GridPosition gridPosition) {
    return Vector2(
      staticBoardPadding + gridPosition.column * (tileSize + tileGap),
      staticBoardPadding + gridPosition.row * (tileSize + tileGap),
    );
  }

  Rect _rectForGridPosition(GridPosition gridPosition) {
    return Rect.fromLTWH(
      staticBoardPadding + gridPosition.column * (tileSize + tileGap),
      staticBoardPadding + gridPosition.row * (tileSize + tileGap),
      tileSize,
      tileSize,
    );
  }

  Map<String, GridPosition> _positionsByTileId(GridState gridState) {
    final positions = <String, GridPosition>{};
    for (var row = 0; row < gridState.rows; row += 1) {
      for (var column = 0; column < gridState.columns; column += 1) {
        final position = GridPosition(row: row, column: column);
        final tile = gridState.tileAt(position);
        if (tile != null) {
          positions[tile.id] = position;
        }
      }
    }
    return positions;
  }

  Duration _durationFromSeconds(double seconds) {
    return Duration(milliseconds: (seconds * 1000).round());
  }

  double _motionDuration(double seconds) {
    if (!_reduceMotionEnabled) {
      return seconds;
    }
    return math.min(seconds, 0.08);
  }

  bool _isInputEnabled() {
    return isInputEnabledProvider?.call() ?? true;
  }

  bool get _reduceMotionEnabled => reduceMotionProvider?.call() ?? false;
}

enum _BoardInteractionState { idle, swapping, clearing, falling }

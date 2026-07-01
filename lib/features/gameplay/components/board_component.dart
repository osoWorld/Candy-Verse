import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/animation.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../grid_logic/domain/cascade_resolver.dart';
import '../../grid_logic/domain/entities/cascade_step_result.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/grid_state.dart';
import '../../grid_logic/domain/entities/reaction_effect.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/entities/swap_result.dart';
import '../../grid_logic/domain/match_detector.dart';
import '../../grid_logic/domain/swap_resolver.dart';
import '../game/tempered_shatter_sound_hook.dart';
import 'particle_effects.dart';
import 'reactive_state_decal_component.dart';
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
    TemperedShatterSoundHook? temperedShatterSoundHook,
    this.onAcceptedSwap,
    this.onCascadeStepClear,
  }) : _gridState = gridState,
       _swapResolver =
           swapResolver ??
           SwapResolver(
             matchDetector: MatchDetector(),
             cascadeResolver: CascadeResolver(matchDetector: MatchDetector()),
           ),
       _temperedShatterSoundHook =
           temperedShatterSoundHook ?? TemperedShatterSoundHook(),
       _trayPaint = Paint()..color = CandyAlchemyColors.boardTray,
       _trayBorderPaint = Paint()
         ..color = CandyAlchemyColors.boardTrayBorder
         ..style = PaintingStyle.stroke
         ..strokeWidth = staticTileStrokeWidth,
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

  /// Callback invoked after the pure logic layer accepts a swap.
  final void Function()? onAcceptedSwap;

  /// Callback invoked before each Cascade Step clear animation.
  final void Function(int cascadeStepIndex)? onCascadeStepClear;

  final SwapResolver _swapResolver;
  final TemperedShatterSoundHook _temperedShatterSoundHook;
  final Paint _trayPaint;
  final Paint _trayBorderPaint;
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
    if (_interactionState != _BoardInteractionState.idle) {
      return;
    }
    final gridPosition = _gridPositionFromLocal(event.localPosition);
    if (gridPosition == null) {
      _clearSelectedPosition();
      return;
    }
    _handleTappedGridPosition(gridPosition);
  }

  /// Captures the drag start position for swipe-to-swap.
  @override
  void onDragStart(DragStartEvent event) {
    super.onDragStart(event);
    if (_interactionState != _BoardInteractionState.idle) {
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

    // Step 5: gestures and animation live here; game rules stay in domain.
    canvas.drawRRect(trayRRect, _trayPaint);
    canvas.drawRRect(trayRRect, _trayBorderPaint);
    super.render(canvas);
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

  Future<void> _attemptSwap(GridPosition first, GridPosition second) async {
    if (_interactionState != _BoardInteractionState.idle) {
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
    await _playCascadeSteps(swapResult);
    _gridState = swapResult.cascadeResult!.finalGrid;
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

  Future<void> _playCascadeSteps(SwapResult swapResult) async {
    var cascadeStepIndex = 0;
    for (final cascadeStep in swapResult.cascadeResult!.steps) {
      onCascadeStepClear?.call(cascadeStepIndex);
      await _playCascadeStep(cascadeStep);
      cascadeStepIndex += 1;
    }
  }

  Future<void> _playCascadeStep(CascadeStepResult cascadeStep) async {
    await _playClearAnimations(cascadeStep);
    await _playGravityAnimation(cascadeStep);
    _gridState = cascadeStep.gridAfterGravity;
  }

  Future<void> _playClearAnimations(CascadeStepResult cascadeStep) async {
    _interactionState = _BoardInteractionState.clearing;
    final reactionAnimation = _playReactionEffectAnimations(cascadeStep);
    if (reactionAnimation != null) {
      await Future<void>.delayed(
        _durationFromSeconds(temperedShatterRowClearDelaySeconds),
      );
    }

    final clearAnimations = <Future<void>>[];
    for (final clearedPosition in cascadeStep.clearedPositions) {
      final tileComponent = _tileComponents[clearedPosition];
      if (tileComponent != null) {
        _spawnReactiveStateEffects(cascadeStep, clearedPosition);
        clearAnimations.add(tileComponent.startClearAnimation());
      }
    }
    if (reactionAnimation != null) {
      clearAnimations.add(reactionAnimation);
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
        moves.add(_fallTileTo(tileComponent, targetPosition));
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
      EffectController(duration: duration, curve: Curves.easeInOutCubic),
    );
    tileComponent.add(effect);
    return effect.completed;
  }

  Future<void> _fallTileTo(
    TileComponent tileComponent,
    Vector2 targetPosition,
  ) {
    final effect = MoveEffect.to(
      targetPosition,
      EffectController(
        duration: cascadeFallDurationSeconds,
        curve: Curves.easeInOutCubic,
      ),
    );
    tileComponent.add(effect);
    return effect.completed;
  }

  Future<void>? _playReactionEffectAnimations(CascadeStepResult cascadeStep) {
    final animations = <Future<void>>[];
    for (final reactionEffect in cascadeStep.reactionEffects) {
      if (reactionEffect is! TemperedShatterReaction) {
        continue;
      }

      _temperedShatterSoundHook.playTemperedShatter();
      _startTemperedShatterCameraShake();
      final effect = TemperedShatterEffectComponent(
        row: reactionEffect.row,
        triggerPositions: reactionEffect.triggerPositions,
        clearedPositions: reactionEffect.clearedPositions,
        tileSize: tileSize,
        tileGap: tileGap,
        size: size,
      )..priority = temperedShatterEffectPriority;
      add(effect);
      animations.add(effect.completed);
    }

    if (animations.isEmpty) {
      return null;
    }
    return Future.wait(animations);
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
    return GridPosition(row: row, column: column);
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
}

enum _BoardInteractionState { idle, swapping, clearing, falling }

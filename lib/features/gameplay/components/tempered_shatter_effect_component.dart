import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../grid_logic/domain/entities/grid_position.dart';

/// Tempered Shatter reaction renderer in the Flame game layer.
class TemperedShatterEffectComponent extends PositionComponent {
  /// Creates the full-row Tempered Shatter VFX from resolved reaction data.
  TemperedShatterEffectComponent({
    required this.row,
    required Iterable<GridPosition> triggerPositions,
    required Iterable<GridPosition> clearedPositions,
    required this.tileSize,
    required this.tileGap,
    required Vector2 size,
  }) : triggerPositions = List<GridPosition>.unmodifiable(triggerPositions),
       clearedPositions = List<GridPosition>.unmodifiable(clearedPositions),
       _paint = Paint(),
       _shards = List<_TemperedShatterShardSpec>.generate(
         temperedShatterShardPoolSize,
         (index) => _TemperedShatterShardSpec(index: index),
       ),
       super(size: size) {
    _configureShards();
  }

  /// Row cleared by the Tempered Shatter reaction.
  final int row;

  /// Positions that triggered the Tempered Shatter reaction.
  final List<GridPosition> triggerPositions;

  /// Positions cleared by the Tempered Shatter reaction.
  final List<GridPosition> clearedPositions;

  /// Logical tile size used by BoardComponent.
  final double tileSize;

  /// Logical tile gap used by BoardComponent.
  final double tileGap;

  final Paint _paint;
  final List<_TemperedShatterShardSpec> _shards;
  final Completer<void> _completed = Completer<void>();
  var _elapsedSeconds = 0.0;

  /// Completes when the full 550ms Tempered Shatter sequence finishes.
  Future<void> get completed => _completed.future;

  /// Advances the Tempered Shatter sequence and removes it when finished.
  @override
  void update(double dt) {
    super.update(dt);

    // ARCHITECTURE.md §9 — update only elapsed time; shard slots are pooled.
    _elapsedSeconds += dt;
    if (_elapsedSeconds >= temperedShatterTotalDurationSeconds) {
      if (!_completed.isCompleted) {
        _completed.complete();
      }
      removeFromParent();
    }
  }

  /// Renders anticipation flash, crack sweep, and row shatter particles.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // DESIGN.md §5 — 150ms anticipation flash.
    _renderAnticipationFlash(canvas);

    // DESIGN.md §5 — 120ms crack line between trigger locations.
    _renderCrackSweep(canvas);

    // DESIGN.md §5 — 280ms ember-orange and frost-blue glass shatter.
    _renderRowShatter(canvas);
  }

  void _renderAnticipationFlash(Canvas canvas) {
    if (_elapsedSeconds > temperedShatterAnticipationDurationSeconds) {
      return;
    }

    final opacity = _anticipationOpacity();
    _paint
      ..color = CandyAlchemyColors.temperedShatterFlash.withValues(
        alpha: opacity,
      )
      ..style = PaintingStyle.fill;

    for (final position in triggerPositions) {
      final rect = _tileRect(position).deflate(tileSize * 0.08);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, Radius.circular(tileSize * 0.18)),
        _paint,
      );
    }
  }

  void _renderCrackSweep(Canvas canvas) {
    final crackElapsed =
        _elapsedSeconds - temperedShatterAnticipationDurationSeconds;
    if (crackElapsed < 0 ||
        crackElapsed > temperedShatterCrackDurationSeconds ||
        triggerPositions.length < 2) {
      return;
    }

    final progress = (crackElapsed / temperedShatterCrackDurationSeconds).clamp(
      0.0,
      1.0,
    );
    final start = _tileRect(triggerPositions.first).center;
    final end = _tileRect(triggerPositions.last).center;
    final current = Offset.lerp(start, end, progress)!;

    _paint
      ..color = CandyAlchemyColors.temperedShatterCrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(start, current, _paint);
  }

  void _renderRowShatter(Canvas canvas) {
    final shatterElapsed =
        _elapsedSeconds - temperedShatterRowClearDelaySeconds;
    if (shatterElapsed < 0 ||
        shatterElapsed > temperedShatterRowShatterDurationSeconds) {
      return;
    }

    final progress = (shatterElapsed / temperedShatterRowShatterDurationSeconds)
        .clamp(0.0, 1.0);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final rowRect = _rowRect();

    _paint
      ..color = CandyAlchemyColors.temperedShatterFlash.withValues(
        alpha: opacity * 0.22,
      )
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(rowRect, Radius.circular(tileSize * 0.16)),
      _paint,
    );

    for (final shard in _shards) {
      final center = Offset(
        rowRect.left +
            shard.rowFraction * rowRect.width +
            math.cos(shard.angleRadians) * shard.travelDistance * progress,
        rowRect.center.dy +
            math.sin(shard.angleRadians) * shard.travelDistance * progress,
      );
      _paint
        ..color = shard.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      _drawShard(canvas, center, shard.radius * (1 - progress * 0.45));
    }
  }

  double _anticipationOpacity() {
    if (_elapsedSeconds <= temperedShatterFlashInDurationSeconds) {
      final progress = _elapsedSeconds / temperedShatterFlashInDurationSeconds;
      return Curves.easeIn.transform(progress.clamp(0.0, 1.0)) * 0.75;
    }

    final outElapsed = _elapsedSeconds - temperedShatterFlashInDurationSeconds;
    final progress = (outElapsed / temperedShatterFlashOutDurationSeconds)
        .clamp(0.0, 1.0);
    return (1 - progress) * 0.75;
  }

  Rect _tileRect(GridPosition position) {
    return Rect.fromLTWH(
      staticBoardPadding + position.column * (tileSize + tileGap),
      staticBoardPadding + position.row * (tileSize + tileGap),
      tileSize,
      tileSize,
    );
  }

  Rect _rowRect() {
    if (clearedPositions.isEmpty) {
      return Rect.fromLTWH(
        staticBoardPadding,
        staticBoardPadding + row * (tileSize + tileGap),
        tileSize,
        tileSize,
      );
    }

    var minColumn = clearedPositions.first.column;
    var maxColumn = clearedPositions.first.column;
    for (final position in clearedPositions) {
      minColumn = math.min(minColumn, position.column);
      maxColumn = math.max(maxColumn, position.column);
    }

    return Rect.fromLTWH(
      staticBoardPadding + minColumn * (tileSize + tileGap),
      staticBoardPadding + row * (tileSize + tileGap),
      (maxColumn - minColumn + 1) * tileSize +
          (maxColumn - minColumn) * tileGap,
      tileSize,
    );
  }

  void _configureShards() {
    for (final shard in _shards) {
      final normalizedIndex = shard.index / _shards.length;
      shard
        ..rowFraction = normalizedIndex
        ..angleRadians = -math.pi * 0.75 + normalizedIndex * math.pi * 1.5
        ..travelDistance = tileSize * (0.55 + normalizedIndex * 0.5)
        ..radius = tileSize * (0.055 + normalizedIndex * 0.025)
        ..color = shard.index.isEven
            ? CandyAlchemyColors.molten
            : CandyAlchemyColors.frost;
    }
  }

  void _drawShard(Canvas canvas, Offset center, double radius) {
    final path = Path()
      ..moveTo(center.dx, center.dy - radius)
      ..lineTo(center.dx + radius * 0.72, center.dy + radius * 0.8)
      ..lineTo(center.dx - radius * 0.85, center.dy + radius * 0.52)
      ..close();
    canvas.drawPath(path, _paint);
  }
}

class _TemperedShatterShardSpec {
  _TemperedShatterShardSpec({required this.index});

  final int index;
  double rowFraction = 0;
  double angleRadians = 0;
  double travelDistance = 0;
  double radius = 0;
  Color color = CandyAlchemyColors.frost;
}

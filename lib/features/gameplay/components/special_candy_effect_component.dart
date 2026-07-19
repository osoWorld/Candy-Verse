import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/special_candy_activation.dart';
import '../../grid_logic/domain/entities/special_candy_type.dart';

/// Special Candy activation VFX renderer in the Flame game layer.
class SpecialCandyEffectComponent extends PositionComponent {
  /// Creates a self-removing visual effect for one [activation].
  SpecialCandyEffectComponent({
    required this.activation,
    required this.tileSize,
    required this.tileGap,
    required Vector2 boardSize,
    required bool reduceMotion,
  }) : _affectedPositions = _sortedPositions(activation.clearedPositions),
       _fishTarget = _fishTargetFor(activation),
       _durationSeconds = _motionDuration(
         _durationFor(activation.specialCandyType),
         reduceMotion,
       ),
       super(size: boardSize);

  /// Activation data read from the pure Dart core logic layer.
  final SpecialCandyActivation activation;

  /// Logical tile size used by the owning BoardComponent.
  final double tileSize;

  /// Logical tile gap used by the owning BoardComponent.
  final double tileGap;

  final List<GridPosition> _affectedPositions;
  final GridPosition? _fishTarget;
  final double _durationSeconds;
  final Paint _paint = Paint();
  final Paint _strokePaint = Paint()..style = PaintingStyle.stroke;
  final Completer<void> _completed = Completer<void>();
  var _elapsedSeconds = 0.0;

  /// Completes when this effect finishes and removes itself.
  Future<void> get completed => _completed.future;

  /// Advances the self-removing Special Candy effect.
  @override
  void update(double dt) {
    super.update(dt);

    // DESIGN.md section 11 - visual-only special-candy explosion timing.
    _elapsedSeconds += dt;
    if (_elapsedSeconds >= _durationSeconds) {
      if (!_completed.isCompleted) {
        _completed.complete();
      }
      removeFromParent();
    }
  }

  /// Renders the active Special Candy effect for its activation type.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
    _drawAffectedCellFlashes(canvas, progress);
    switch (activation.specialCandyType) {
      case SpecialCandyType.rowClear:
        _drawLineSweep(canvas, progress, isHorizontal: true);
      case SpecialCandyType.columnClear:
        _drawLineSweep(canvas, progress, isHorizontal: false);
      case SpecialCandyType.wrapped:
        _drawWrappedPulse(canvas, progress);
      case SpecialCandyType.colorOrb:
        _drawColorOrbRays(canvas, progress);
      case SpecialCandyType.fishCharm:
        _drawFishTrail(canvas, progress);
      case SpecialCandyType.alchemyBomb:
        _drawAlchemyBombBurst(canvas, progress);
      case SpecialCandyType.none:
        break;
    }
  }

  void _drawLineSweep(
    Canvas canvas,
    double progress, {
    required bool isHorizontal,
  }) {
    final originCenter = _centerFor(activation.origin);
    final sweepProgress = Curves.easeOutCubic.transform(progress);
    final start = isHorizontal
        ? Offset(staticBoardPadding, originCenter.dy)
        : Offset(originCenter.dx, staticBoardPadding);
    final end = isHorizontal
        ? Offset(size.x - staticBoardPadding, originCenter.dy)
        : Offset(originCenter.dx, size.y - staticBoardPadding);
    final sweepEnd = Offset.lerp(start, end, sweepProgress)!;

    // DESIGN.md section 11 - striped specials use readable sweep explosions.
    _strokePaint
      ..color = CandyAlchemyColors.candyGold.withValues(alpha: 0.22)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = tileSize * 0.58;
    canvas.drawLine(start, sweepEnd, _strokePaint);
    _strokePaint
      ..color = CandyAlchemyColors.sugarWhite.withValues(alpha: 0.92)
      ..strokeWidth = tileSize * 0.16;
    canvas.drawLine(start, sweepEnd, _strokePaint);
    _drawSweepSparks(canvas, sweepEnd, isHorizontal: isHorizontal);
  }

  void _drawWrappedPulse(Canvas canvas, double progress) {
    final center = _centerFor(activation.origin);
    final firstPulse = Curves.easeOutBack.transform(
      (progress / 0.62).clamp(0.0, 1.0),
    );
    final secondPulse = progress < 0.34
        ? 0.0
        : Curves.easeOutCubic.transform(((progress - 0.34) / 0.66).clamp(0, 1));

    // PRD.md section 11 - wrapped clears a 3x3 area then pulses again.
    _drawBurstRing(
      canvas,
      center: center,
      radius: tileSize * (0.42 + firstPulse * 1.75),
      alpha: (1 - progress).clamp(0.0, 1.0),
      color: CandyAlchemyColors.popPink,
    );
    if (secondPulse > 0) {
      _drawBurstRing(
        canvas,
        center: center,
        radius: tileSize * (0.62 + secondPulse * 2.2),
        alpha: (1 - secondPulse).clamp(0.0, 1.0),
        color: CandyAlchemyColors.candyGold,
      );
    }
  }

  void _drawColorOrbRays(Canvas canvas, double progress) {
    final originCenter = _centerFor(activation.origin);
    final rayProgress = Curves.easeOutCubic.transform(progress);
    final colors = const [
      CandyAlchemyColors.candyGold,
      CandyAlchemyColors.popPink,
      CandyAlchemyColors.syrupTeal,
      CandyAlchemyColors.frost,
      CandyAlchemyColors.molten,
    ];

    // DESIGN.md section 5 - colorOrb reads as rainbow sugar energy.
    for (var index = 0; index < _affectedPositions.length; index += 1) {
      final target = _affectedPositions[index];
      if (target == activation.origin) {
        continue;
      }
      final targetCenter = _centerFor(target);
      final rayEnd = Offset.lerp(originCenter, targetCenter, rayProgress)!;
      _strokePaint
        ..color = colors[index % colors.length].withValues(
          alpha: (1 - progress * 0.35).clamp(0.0, 1.0),
        )
        ..strokeCap = StrokeCap.round
        ..strokeWidth = math.max(2, tileSize * 0.055);
      canvas.drawLine(originCenter, rayEnd, _strokePaint);
      _paint.color = colors[index % colors.length].withValues(
        alpha: rayProgress,
      );
      canvas.drawCircle(rayEnd, tileSize * 0.09, _paint);
    }
    _drawBurstRing(
      canvas,
      center: originCenter,
      radius: tileSize * (0.35 + progress * 0.85),
      alpha: (1 - progress * 0.45).clamp(0.0, 1.0),
      color: CandyAlchemyColors.sugarWhite,
    );
  }

  void _drawFishTrail(Canvas canvas, double progress) {
    final target = _fishTarget;
    final originCenter = _centerFor(activation.origin);
    if (target == null) {
      _drawFishCharm(canvas, originCenter, 1 - progress * 0.4);
      return;
    }

    final targetCenter = _centerFor(target);
    final travelProgress = Curves.easeInOutCubic.transform(progress);
    final current = Offset.lerp(originCenter, targetCenter, travelProgress)!;
    final control = Offset(
      (originCenter.dx + targetCenter.dx) / 2,
      math.min(originCenter.dy, targetCenter.dy) - tileSize * 0.9,
    );
    final trailPoint = _quadraticPoint(
      start: originCenter,
      control: control,
      end: targetCenter,
      progress: travelProgress,
    );

    // DESIGN.md section 5 - fishCharm uses a readable target trail.
    final path = Path()
      ..moveTo(originCenter.dx, originCenter.dy)
      ..quadraticBezierTo(control.dx, control.dy, trailPoint.dx, trailPoint.dy);
    _strokePaint
      ..color = CandyAlchemyColors.frost.withValues(alpha: 0.58)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = math.max(2, tileSize * 0.06);
    canvas.drawPath(path, _strokePaint);
    _drawFishCharm(canvas, current, 1);
  }

  void _drawAlchemyBombBurst(Canvas canvas, double progress) {
    final center = _centerFor(activation.origin);
    final eased = Curves.easeOutCubic.transform(progress);
    final maxRadius = tileSize * 3.05;

    // PRD.md section 11 - alchemyBomb triggers a large state-colored burst.
    _paint
      ..color = CandyAlchemyColors.molten.withValues(
        alpha: (0.26 * (1 - progress)).clamp(0.0, 1.0),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, maxRadius * eased, _paint);
    _drawBurstRing(
      canvas,
      center: center,
      radius: maxRadius * eased,
      alpha: (1 - progress).clamp(0.0, 1.0),
      color: CandyAlchemyColors.candyGold,
    );
    _drawAlchemySymbol(canvas, center, eased);
  }

  void _drawAffectedCellFlashes(Canvas canvas, double progress) {
    final flashProgress =
        (_elapsedSeconds /
                math.min(
                  specialCandyCellFlashDurationSeconds,
                  _durationSeconds,
                ))
            .clamp(0.0, 1.0);
    final opacity = (1 - flashProgress).clamp(0.0, 1.0);
    if (opacity <= 0) {
      return;
    }
    _paint
      ..color = CandyAlchemyColors.sugarWhite.withValues(alpha: opacity * 0.18)
      ..style = PaintingStyle.fill;
    for (final position in _affectedPositions) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          _cellRectFor(position).deflate(tileSize * 0.06),
          Radius.circular(tileSize * 0.18),
        ),
        _paint,
      );
    }
  }

  void _drawSweepSparks(
    Canvas canvas,
    Offset center, {
    required bool isHorizontal,
  }) {
    _strokePaint
      ..color = CandyAlchemyColors.candyGold
      ..strokeWidth = math.max(2, tileSize * 0.04);
    for (var index = -1; index <= 1; index += 1) {
      final offset = index * tileSize * 0.16;
      final first = isHorizontal
          ? center.translate(-tileSize * 0.18, offset)
          : center.translate(offset, -tileSize * 0.18);
      final second = isHorizontal
          ? center.translate(tileSize * 0.18, offset * 0.35)
          : center.translate(offset * 0.35, tileSize * 0.18);
      canvas.drawLine(first, second, _strokePaint);
    }
  }

  void _drawBurstRing(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required double alpha,
    required Color color,
  }) {
    _strokePaint
      ..color = color.withValues(alpha: alpha.clamp(0.0, 1.0))
      ..strokeWidth = math.max(2, tileSize * 0.055);
    canvas.drawCircle(center, radius, _strokePaint);
  }

  void _drawFishCharm(Canvas canvas, Offset center, double opacity) {
    final radius = tileSize * 0.18;
    final fishPaint = Paint()
      ..color = CandyAlchemyColors.frost.withValues(
        alpha: opacity.clamp(0.0, 1.0),
      );
    final body = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..quadraticBezierTo(
        center.dx,
        center.dy - radius * 0.8,
        center.dx + radius * 1.15,
        center.dy,
      )
      ..quadraticBezierTo(
        center.dx,
        center.dy + radius * 0.8,
        center.dx - radius,
        center.dy,
      )
      ..close();
    final tail = Path()
      ..moveTo(center.dx - radius, center.dy)
      ..lineTo(center.dx - radius * 1.65, center.dy - radius * 0.65)
      ..lineTo(center.dx - radius * 1.65, center.dy + radius * 0.65)
      ..close();
    canvas
      ..drawPath(body, fishPaint)
      ..drawPath(tail, fishPaint);
  }

  void _drawAlchemySymbol(Canvas canvas, Offset center, double progress) {
    final radius = tileSize * (0.32 + progress * 0.62);
    _strokePaint
      ..color = CandyAlchemyColors.sugarWhite.withValues(
        alpha: (1 - progress * 0.2).clamp(0.0, 1.0),
      )
      ..strokeWidth = math.max(2, tileSize * 0.045);
    canvas
      ..drawCircle(center, radius, _strokePaint)
      ..drawLine(
        center.translate(0, -radius * 1.2),
        center.translate(0, radius * 1.2),
        _strokePaint,
      )
      ..drawLine(
        center.translate(-radius, radius * 0.48),
        center.translate(radius, radius * 0.48),
        _strokePaint,
      );
  }

  Offset _centerFor(GridPosition position) {
    return Offset(
      staticBoardPadding +
          position.column * (tileSize + tileGap) +
          tileSize / 2,
      staticBoardPadding + position.row * (tileSize + tileGap) + tileSize / 2,
    );
  }

  Rect _cellRectFor(GridPosition position) {
    return Rect.fromLTWH(
      staticBoardPadding + position.column * (tileSize + tileGap),
      staticBoardPadding + position.row * (tileSize + tileGap),
      tileSize,
      tileSize,
    );
  }

  Offset _quadraticPoint({
    required Offset start,
    required Offset control,
    required Offset end,
    required double progress,
  }) {
    final inverse = 1 - progress;
    return Offset(
      inverse * inverse * start.dx +
          2 * inverse * progress * control.dx +
          progress * progress * end.dx,
      inverse * inverse * start.dy +
          2 * inverse * progress * control.dy +
          progress * progress * end.dy,
    );
  }

  static List<GridPosition> _sortedPositions(Iterable<GridPosition> positions) {
    return List<GridPosition>.of(positions)..sort((first, second) {
      final rowCompare = first.row.compareTo(second.row);
      if (rowCompare != 0) {
        return rowCompare;
      }
      return first.column.compareTo(second.column);
    });
  }

  static GridPosition? _fishTargetFor(SpecialCandyActivation activation) {
    if (activation.specialCandyType != SpecialCandyType.fishCharm) {
      return null;
    }
    for (final position in activation.clearedPositions) {
      if (position != activation.origin) {
        return position;
      }
    }
    return null;
  }

  static double _durationFor(SpecialCandyType specialCandyType) {
    return switch (specialCandyType) {
      SpecialCandyType.rowClear ||
      SpecialCandyType.columnClear => specialCandyLineSweepDurationSeconds,
      SpecialCandyType.wrapped => specialCandyWrappedBurstDurationSeconds,
      SpecialCandyType.colorOrb => specialCandyColorOrbDurationSeconds,
      SpecialCandyType.fishCharm => specialCandyFishCharmDurationSeconds,
      SpecialCandyType.alchemyBomb => specialCandyAlchemyBombDurationSeconds,
      SpecialCandyType.none => matchClearDurationSeconds,
    };
  }

  static double _motionDuration(double seconds, bool reduceMotion) {
    if (!reduceMotion) {
      return seconds;
    }
    return math.min(seconds, 0.08);
  }
}

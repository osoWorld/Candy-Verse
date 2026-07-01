import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';

/// Type of timed reactive-state decal in the Flame game layer.
enum ReactiveStateDecalKind { heatTrail, frostTint, syrupSlick }

/// Timed state-specific board decal renderer in the Flame game layer.
class ReactiveStateDecalComponent extends PositionComponent {
  /// Creates a board decal for heat trails, frost tint, or syrup slicks.
  ReactiveStateDecalComponent({
    required this.kind,
    required Vector2 position,
    required Vector2 size,
  }) : _paint = Paint(),
       _elapsedSeconds = 0,
       _durationSeconds = _durationFor(kind),
       super(position: position, size: size);

  /// Decal type controlling visual treatment and duration.
  final ReactiveStateDecalKind kind;

  final Paint _paint;
  var _elapsedSeconds = 0.0;
  final double _durationSeconds;

  /// Advances this decal until its timed visual has expired.
  @override
  void update(double dt) {
    super.update(dt);

    // ARCHITECTURE.md section 9: opacity tween only; no per-frame object pools needed.
    _elapsedSeconds += dt;
    if (_elapsedSeconds >= _durationSeconds) {
      removeFromParent();
    }
  }

  /// Renders the active decal with fading opacity.
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final progress = (_elapsedSeconds / _durationSeconds).clamp(0.0, 1.0);
    final opacity = (1 - progress).clamp(0.0, 1.0);
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);

    // DESIGN.md section 4: state-specific persistent match decals.
    switch (kind) {
      case ReactiveStateDecalKind.heatTrail:
        _paint
          ..color = CandyAlchemyColors.molten.withValues(alpha: opacity * 0.4)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(size.x * 0.18),
            const Radius.circular(8),
          ),
          _paint,
        );
      case ReactiveStateDecalKind.frostTint:
        _paint
          ..color = CandyAlchemyColors.frost.withValues(alpha: opacity * 0.32)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            rect.deflate(size.x * 0.12),
            const Radius.circular(8),
          ),
          _paint,
        );
      case ReactiveStateDecalKind.syrupSlick:
        _paint
          ..color = CandyAlchemyColors.syrup.withValues(alpha: opacity * 0.22)
          ..style = PaintingStyle.fill;
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(10)),
          _paint,
        );
        _paint
          ..color = CandyAlchemyColors.tileHighlight.withValues(
            alpha: opacity * 0.42,
          )
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawLine(
          Offset(size.x * 0.28, 0),
          Offset(size.x * 0.72, size.y),
          _paint,
        );
    }
  }

  static double _durationFor(ReactiveStateDecalKind kind) {
    switch (kind) {
      case ReactiveStateDecalKind.heatTrail:
        return moltenHeatTrailDurationSeconds;
      case ReactiveStateDecalKind.frostTint:
        return frostTintDurationSeconds;
      case ReactiveStateDecalKind.syrupSlick:
        return syrupSlickDurationSeconds;
    }
  }
}

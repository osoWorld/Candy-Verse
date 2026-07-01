import 'dart:async';
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../grid_logic/domain/entities/base_candy.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/entities/tile.dart';

/// Static candy tile renderer in the Flame game layer.
class TileComponent extends PositionComponent {
  /// Creates a tile renderer for a GridState cell.
  TileComponent({
    required this.tile,
    required this.gridPosition,
    required double tileSize,
    required Vector2 position,
  }) : _basePaint = Paint()..color = _baseCandyColor(tile.baseCandy),
       _accentPaint = Paint()
         ..color = _reactiveStateAccentColor(tile.reactiveState)
         ..style = PaintingStyle.stroke
         ..strokeWidth = staticTileStrokeWidth,
       _highlightPaint = Paint()
         ..color = CandyAlchemyColors.tileHighlight
         ..style = PaintingStyle.stroke
         ..strokeWidth = staticTileHighlightStrokeWidth,
       _shadowPaint = Paint()..color = CandyAlchemyColors.tileShadow,
       _iconBackgroundPaint = Paint()
         ..color = CandyAlchemyColors.iconBackground,
       _iconPaint = Paint()
         ..color = _reactiveStateIconColor(tile.reactiveState)
         ..style = PaintingStyle.stroke
         ..strokeCap = StrokeCap.round
         ..strokeJoin = StrokeJoin.round
         ..strokeWidth = staticTileIconStrokeWidth,
       _selectedPaint = Paint()
         ..color = CandyAlchemyColors.tileHighlight
         ..style = PaintingStyle.stroke
         ..strokeWidth = staticSelectedTileStrokeWidth,
       super(position: position, size: Vector2.all(tileSize));

  /// Tile data read from the pure Dart core logic layer.
  final Tile tile;

  /// Grid position read from the pure Dart core logic layer.
  GridPosition gridPosition;

  final Paint _basePaint;
  final Paint _accentPaint;
  final Paint _highlightPaint;
  final Paint _shadowPaint;
  final Paint _iconBackgroundPaint;
  final Paint _iconPaint;
  final Paint _selectedPaint;
  var _isSelected = false;
  var _isClearing = false;
  var _clearElapsedSeconds = 0.0;
  Completer<void>? _clearCompleter;

  /// Updates the GridPosition represented by this visual tile.
  void updateGridPosition(GridPosition gridPosition) {
    this.gridPosition = gridPosition;
  }

  /// Shows or hides selected tile feedback.
  void setSelected(bool isSelected) {
    _isSelected = isSelected;
  }

  /// Starts the basic match-clear animation and completes when it finishes.
  Future<void> startClearAnimation() {
    if (_isClearing) {
      return _clearCompleter?.future ?? Future.value();
    }
    _isClearing = true;
    _clearElapsedSeconds = 0;
    _clearCompleter = Completer<void>();
    return _clearCompleter!.future;
  }

  /// Advances tile-local clear animation state.
  @override
  void update(double dt) {
    super.update(dt);
    if (!_isClearing) {
      return;
    }

    _clearElapsedSeconds += dt;
    if (_clearElapsedSeconds >= matchClearDurationSeconds) {
      _isClearing = false;
      _clearElapsedSeconds = matchClearDurationSeconds;
      final clearCompleter = _clearCompleter;
      _clearCompleter = null;
      clearCompleter?.complete();
    }
  }

  /// Renders the Base Candy material and Reactive State accessibility icon.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tileRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final renderScale = _currentClearScale();
    if (renderScale != 1) {
      canvas
        ..save()
        ..translate(size.x / 2, size.y / 2)
        ..scale(renderScale, renderScale)
        ..translate(-size.x / 2, -size.y / 2);
    }

    _renderCandy(canvas, tileRect);

    if (renderScale != 1) {
      canvas.restore();
    }

    if (_isSelected && !_isClearing) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          tileRect.deflate(staticSelectedTileStrokeWidth / 2),
          Radius.circular(size.x * 0.18),
        ),
        _selectedPaint,
      );
    }
  }

  void _renderCandy(Canvas canvas, Rect tileRect) {
    final tileCenter = tileRect.center;
    final tileRadius = size.x * 0.42;

    // DESIGN.md section 3: each Base Candy has a distinct silhouette.
    _drawBaseCandyShape(canvas, tileRect, tileCenter, tileRadius);

    // DESIGN.md section 1: glossy crystal confection highlight.
    canvas.drawArc(
      tileRect.deflate(size.x * 0.18),
      3.7,
      1.0,
      false,
      _highlightPaint,
    );

    // DESIGN.md sections 2 and 10: Reactive State accent plus icon overlay.
    if (tile.reactiveState != ReactiveState.none) {
      canvas.drawOval(tileRect.deflate(size.x * 0.08), _accentPaint);
      _drawReactiveStateIcon(canvas, tile.reactiveState);
    }
  }

  double _currentClearScale() {
    if (!_isClearing) {
      return 1;
    }
    final progress = (_clearElapsedSeconds / matchClearDurationSeconds).clamp(
      0.0,
      1.0,
    );
    if (progress < 0.45) {
      return 1 + progress / 0.45 * 0.15;
    }
    return 1.15 * (1 - (progress - 0.45) / 0.55);
  }

  void _drawBaseCandyShape(
    Canvas canvas,
    Rect tileRect,
    Offset tileCenter,
    double tileRadius,
  ) {
    canvas.drawOval(tileRect.shift(const Offset(2, 3)), _shadowPaint);
    switch (tile.baseCandy) {
      case BaseCandy.cocoa:
        _drawCocoa(canvas, tileRect);
      case BaseCandy.citrus:
        _drawCitrus(canvas, tileCenter, tileRadius);
      case BaseCandy.berry:
        _drawBerry(canvas, tileRect, tileCenter, tileRadius);
      case BaseCandy.mint:
        _drawMint(canvas, tileCenter, tileRadius);
      case BaseCandy.cream:
        _drawCream(canvas, tileCenter, tileRadius);
    }
  }

  void _drawCocoa(Canvas canvas, Rect tileRect) {
    final cocoaRect = tileRect.deflate(size.x * 0.12);
    final radius = Radius.circular(size.x * 0.12);
    canvas.drawRRect(RRect.fromRectAndRadius(cocoaRect, radius), _basePaint);
  }

  void _drawCitrus(Canvas canvas, Offset tileCenter, double tileRadius) {
    canvas.drawCircle(tileCenter, tileRadius, _basePaint);
    canvas.drawLine(
      tileCenter,
      Offset(tileCenter.dx, tileCenter.dy - tileRadius * 0.72),
      _highlightPaint,
    );
    canvas.drawLine(
      tileCenter,
      Offset(
        tileCenter.dx + tileRadius * 0.62,
        tileCenter.dy + tileRadius * 0.36,
      ),
      _highlightPaint,
    );
    canvas.drawLine(
      tileCenter,
      Offset(
        tileCenter.dx - tileRadius * 0.62,
        tileCenter.dy + tileRadius * 0.36,
      ),
      _highlightPaint,
    );
  }

  void _drawBerry(
    Canvas canvas,
    Rect tileRect,
    Offset tileCenter,
    double tileRadius,
  ) {
    final path = Path()
      ..moveTo(tileCenter.dx, tileRect.top + size.y * 0.08)
      ..quadraticBezierTo(
        tileRect.right - size.x * 0.08,
        tileCenter.dy,
        tileCenter.dx,
        tileRect.bottom - size.y * 0.08,
      )
      ..quadraticBezierTo(
        tileRect.left + size.x * 0.08,
        tileCenter.dy,
        tileCenter.dx,
        tileRect.top + size.y * 0.08,
      )
      ..close();
    canvas.drawPath(path, _basePaint);
  }

  void _drawMint(Canvas canvas, Offset tileCenter, double tileRadius) {
    final leftLeaf = Path()
      ..moveTo(tileCenter.dx, tileCenter.dy + tileRadius * 0.75)
      ..quadraticBezierTo(
        tileCenter.dx - tileRadius,
        tileCenter.dy,
        tileCenter.dx,
        tileCenter.dy - tileRadius,
      )
      ..quadraticBezierTo(
        tileCenter.dx + tileRadius * 0.15,
        tileCenter.dy,
        tileCenter.dx,
        tileCenter.dy + tileRadius * 0.75,
      )
      ..close();
    final rightLeaf = Path()
      ..moveTo(tileCenter.dx, tileCenter.dy + tileRadius * 0.75)
      ..quadraticBezierTo(
        tileCenter.dx + tileRadius,
        tileCenter.dy,
        tileCenter.dx,
        tileCenter.dy - tileRadius,
      )
      ..quadraticBezierTo(
        tileCenter.dx - tileRadius * 0.15,
        tileCenter.dy,
        tileCenter.dx,
        tileCenter.dy + tileRadius * 0.75,
      )
      ..close();
    canvas.drawPath(leftLeaf, _basePaint);
    canvas.drawPath(rightLeaf, _basePaint);
  }

  void _drawCream(Canvas canvas, Offset tileCenter, double tileRadius) {
    canvas.drawCircle(tileCenter, tileRadius, _basePaint);
    canvas.drawArc(
      Rect.fromCircle(center: tileCenter, radius: tileRadius * 0.72),
      0.2,
      4.8,
      false,
      _accentPaint,
    );
  }

  void _drawReactiveStateIcon(Canvas canvas, ReactiveState reactiveState) {
    final iconRect = Rect.fromLTWH(
      size.x - staticTileIconInset - staticTileIconSize,
      staticTileIconInset,
      staticTileIconSize,
      staticTileIconSize,
    );
    canvas.drawCircle(
      iconRect.center,
      staticTileIconSize * 0.58,
      _iconBackgroundPaint,
    );

    switch (reactiveState) {
      case ReactiveState.molten:
        _drawFlameIcon(canvas, iconRect);
      case ReactiveState.frost:
        _drawSnowflakeIcon(canvas, iconRect);
      case ReactiveState.living:
        _drawHeartIcon(canvas, iconRect);
      case ReactiveState.syrup:
        _drawDropletIcon(canvas, iconRect);
      case ReactiveState.spice:
        _drawPepperIcon(canvas, iconRect);
      case ReactiveState.none:
        break;
    }
  }

  void _drawFlameIcon(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top + 1)
      ..quadraticBezierTo(
        rect.right - 1,
        rect.center.dy,
        rect.center.dx,
        rect.bottom - 1,
      )
      ..quadraticBezierTo(
        rect.left + 1,
        rect.center.dy,
        rect.center.dx,
        rect.top + 1,
      );
    canvas.drawPath(path, _iconPaint);
  }

  void _drawSnowflakeIcon(Canvas canvas, Rect rect) {
    final center = rect.center;
    canvas.drawLine(
      Offset(center.dx, rect.top + 1),
      Offset(center.dx, rect.bottom - 1),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 1, center.dy),
      Offset(rect.right - 1, center.dy),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(rect.left + 3, rect.top + 3),
      Offset(rect.right - 3, rect.bottom - 3),
      _iconPaint,
    );
    canvas.drawLine(
      Offset(rect.right - 3, rect.top + 3),
      Offset(rect.left + 3, rect.bottom - 3),
      _iconPaint,
    );
  }

  void _drawDropletIcon(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.top + 1)
      ..quadraticBezierTo(
        rect.right - 1,
        rect.center.dy,
        rect.center.dx,
        rect.bottom - 1,
      )
      ..quadraticBezierTo(
        rect.left + 1,
        rect.center.dy,
        rect.center.dx,
        rect.top + 1,
      )
      ..close();
    canvas.drawPath(path, _iconPaint);
  }

  void _drawPepperIcon(Canvas canvas, Rect rect) {
    final body = Path()
      ..moveTo(rect.left + 4, rect.top + 5)
      ..quadraticBezierTo(
        rect.right - 1,
        rect.top + 3,
        rect.right - 4,
        rect.bottom - 3,
      )
      ..quadraticBezierTo(
        rect.left + 4,
        rect.bottom - 1,
        rect.left + 4,
        rect.top + 5,
      );
    canvas.drawPath(body, _iconPaint);
    canvas.drawLine(
      Offset(rect.left + 5, rect.top + 4),
      Offset(rect.left + 2, rect.top + 1),
      _iconPaint,
    );
  }

  void _drawHeartIcon(Canvas canvas, Rect rect) {
    final path = Path()
      ..moveTo(rect.center.dx, rect.bottom - 2)
      ..cubicTo(
        rect.left,
        rect.center.dy,
        rect.left + 2,
        rect.top + 1,
        rect.center.dx,
        rect.top + 5,
      )
      ..cubicTo(
        rect.right - 2,
        rect.top + 1,
        rect.right,
        rect.center.dy,
        rect.center.dx,
        rect.bottom - 2,
      );
    canvas.drawPath(path, _iconPaint);
  }

  static Color _baseCandyColor(BaseCandy baseCandy) {
    switch (baseCandy) {
      case BaseCandy.cocoa:
        return CandyAlchemyColors.cocoa;
      case BaseCandy.citrus:
        return CandyAlchemyColors.citrus;
      case BaseCandy.berry:
        return CandyAlchemyColors.berry;
      case BaseCandy.mint:
        return CandyAlchemyColors.mint;
      case BaseCandy.cream:
        return CandyAlchemyColors.cream;
    }
  }

  static Color _reactiveStateAccentColor(ReactiveState reactiveState) {
    switch (reactiveState) {
      case ReactiveState.molten:
        return CandyAlchemyColors.molten;
      case ReactiveState.frost:
        return CandyAlchemyColors.frost;
      case ReactiveState.living:
        return CandyAlchemyColors.living;
      case ReactiveState.syrup:
        return CandyAlchemyColors.syrup;
      case ReactiveState.spice:
        return CandyAlchemyColors.spice;
      case ReactiveState.none:
        return CandyAlchemyColors.tileHighlight;
    }
  }

  static Color _reactiveStateIconColor(ReactiveState reactiveState) {
    if (reactiveState == ReactiveState.living) {
      return CandyAlchemyColors.cream;
    }
    return _reactiveStateAccentColor(reactiveState);
  }
}

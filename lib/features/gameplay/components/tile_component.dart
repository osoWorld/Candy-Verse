import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../grid_logic/domain/entities/base_candy.dart';
import '../../grid_logic/domain/entities/grid_position.dart';
import '../../grid_logic/domain/entities/reactive_state.dart';
import '../../grid_logic/domain/entities/special_candy_type.dart';
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
  final Paint _highlightPaint;
  final Paint _shadowPaint;
  final Paint _iconBackgroundPaint;
  final Paint _iconPaint;
  final Paint _selectedPaint;
  var _isSelected = false;
  var _isClearing = false;
  var _clearElapsedSeconds = 0.0;
  Completer<void>? _clearCompleter;
  var _isLanding = false;
  var _landingElapsedSeconds = 0.0;
  Completer<void>? _landingCompleter;

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

  /// Starts the landing squash animation after a fall or refill.
  Future<void> startLandingBounce() {
    if (_isLanding) {
      return _landingCompleter?.future ?? Future.value();
    }
    _isLanding = true;
    _landingElapsedSeconds = 0;
    _landingCompleter = Completer<void>();
    return _landingCompleter!.future;
  }

  /// Advances tile-local clear animation state.
  @override
  void update(double dt) {
    super.update(dt);
    if (_isClearing) {
      _clearElapsedSeconds += dt;
      if (_clearElapsedSeconds >= matchClearDurationSeconds) {
        _isClearing = false;
        _clearElapsedSeconds = matchClearDurationSeconds;
        final clearCompleter = _clearCompleter;
        _clearCompleter = null;
        clearCompleter?.complete();
      }
    }
    if (_isLanding) {
      _landingElapsedSeconds += dt;
      if (_landingElapsedSeconds >= cascadeLandingBounceDurationSeconds) {
        _isLanding = false;
        _landingElapsedSeconds = cascadeLandingBounceDurationSeconds;
        final landingCompleter = _landingCompleter;
        _landingCompleter = null;
        landingCompleter?.complete();
      }
    }
  }

  /// Renders the Base Candy material and Reactive State accessibility icon.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final tileRect = Rect.fromLTWH(0, 0, size.x, size.y);
    final renderScaleX = _currentRenderScaleX();
    final renderScaleY = _currentRenderScaleY();
    if (renderScaleX != 1 || renderScaleY != 1) {
      canvas
        ..save()
        ..translate(size.x / 2, size.y / 2)
        ..scale(renderScaleX, renderScaleY)
        ..translate(-size.x / 2, -size.y / 2);
    }

    _renderCandy(canvas, tileRect);

    if (renderScaleX != 1 || renderScaleY != 1) {
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

    _drawReactiveStateAura(canvas, tileRect);

    if (tile.specialCandyType == SpecialCandyType.colorOrb) {
      // DESIGN.md section 5: Color Orb uses a dark glossy orb with flecks.
      _drawColorOrb(canvas, tileCenter, tileRadius);
    } else {
      // DESIGN.md section 3: each Base Candy has a distinct silhouette.
      _drawBaseCandyShape(canvas, tileRect, tileCenter, tileRadius);
      if (tile.specialCandyType != SpecialCandyType.none) {
        // DESIGN.md section 5: Special Candy overlays stay readable at 44px.
        _drawSpecialCandyOverlay(canvas, tileRect, tileCenter, tileRadius);
      }
    }

    // DESIGN.md sections 4 and 16: Reactive State icon overlay, not full ring.
    if (tile.reactiveState != ReactiveState.none) {
      _drawReactiveStateDecal(canvas, tileRect);
      _drawReactiveStateIcon(canvas, tile.reactiveState);
    }
  }

  void _drawSpecialCandyOverlay(
    Canvas canvas,
    Rect tileRect,
    Offset tileCenter,
    double tileRadius,
  ) {
    switch (tile.specialCandyType) {
      case SpecialCandyType.rowClear:
        _drawRowClearOverlay(canvas, tileRect);
      case SpecialCandyType.columnClear:
        _drawColumnClearOverlay(canvas, tileRect);
      case SpecialCandyType.wrapped:
        _drawWrappedOverlay(canvas, tileRect);
      case SpecialCandyType.fishCharm:
        _drawFishCharmOverlay(canvas, tileCenter, tileRadius);
      case SpecialCandyType.alchemyBomb:
        _drawAlchemyBombOverlay(canvas, tileCenter, tileRadius);
      case SpecialCandyType.colorOrb:
      case SpecialCandyType.none:
        break;
    }
  }

  void _drawRowClearOverlay(Canvas canvas, Rect tileRect) {
    final stripePaint = Paint()
      ..color = const Color(0xDDFFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.x * 0.11;
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFC83D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.x * 0.035;
    canvas
      ..drawLine(
        Offset(tileRect.left + size.x * 0.18, tileRect.center.dy),
        Offset(tileRect.right - size.x * 0.18, tileRect.center.dy),
        stripePaint,
      )
      ..drawLine(
        Offset(tileRect.left + size.x * 0.18, tileRect.center.dy),
        Offset(
          tileRect.left + size.x * 0.28,
          tileRect.center.dy - size.x * 0.08,
        ),
        sparkPaint,
      )
      ..drawLine(
        Offset(tileRect.right - size.x * 0.18, tileRect.center.dy),
        Offset(
          tileRect.right - size.x * 0.28,
          tileRect.center.dy + size.x * 0.08,
        ),
        sparkPaint,
      );
  }

  void _drawColumnClearOverlay(Canvas canvas, Rect tileRect) {
    final stripePaint = Paint()
      ..color = const Color(0xDDFFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.x * 0.11;
    final sparkPaint = Paint()
      ..color = const Color(0xFFFFC83D)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.x * 0.035;
    canvas
      ..drawLine(
        Offset(tileRect.center.dx, tileRect.top + size.x * 0.18),
        Offset(tileRect.center.dx, tileRect.bottom - size.x * 0.18),
        stripePaint,
      )
      ..drawLine(
        Offset(tileRect.center.dx, tileRect.top + size.x * 0.18),
        Offset(
          tileRect.center.dx + size.x * 0.08,
          tileRect.top + size.x * 0.28,
        ),
        sparkPaint,
      )
      ..drawLine(
        Offset(tileRect.center.dx, tileRect.bottom - size.x * 0.18),
        Offset(
          tileRect.center.dx - size.x * 0.08,
          tileRect.bottom - size.x * 0.28,
        ),
        sparkPaint,
      );
  }

  void _drawWrappedOverlay(Canvas canvas, Rect tileRect) {
    final bandPaint = Paint()
      ..color = const Color(0xDDFFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.x * 0.075;
    final bowPaint = Paint()..color = const Color(0xFFFF5FA2);
    canvas
      ..drawLine(
        Offset(tileRect.left + size.x * 0.16, tileRect.center.dy),
        Offset(tileRect.right - size.x * 0.16, tileRect.center.dy),
        bandPaint,
      )
      ..drawLine(
        Offset(tileRect.center.dx, tileRect.top + size.x * 0.16),
        Offset(tileRect.center.dx, tileRect.bottom - size.x * 0.16),
        bandPaint,
      )
      ..drawCircle(tileRect.center, size.x * 0.08, bowPaint)
      ..drawOval(
        Rect.fromCenter(
          center: tileRect.center.translate(-size.x * 0.1, 0),
          width: size.x * 0.16,
          height: size.x * 0.1,
        ),
        bowPaint,
      )
      ..drawOval(
        Rect.fromCenter(
          center: tileRect.center.translate(size.x * 0.1, 0),
          width: size.x * 0.16,
          height: size.x * 0.1,
        ),
        bowPaint,
      );
  }

  void _drawColorOrb(Canvas canvas, Offset tileCenter, double tileRadius) {
    _drawShapeShadow(
      canvas,
      Rect.fromCircle(center: tileCenter, radius: tileRadius),
    );
    final orbPaint = Paint()
      ..shader = Gradient.radial(
        tileCenter.translate(-tileRadius * 0.25, -tileRadius * 0.25),
        tileRadius,
        const [Color(0xFF44305F), Color(0xFF130B24)],
      );
    canvas.drawCircle(tileCenter, tileRadius * 0.96, orbPaint);
    final fleckColors = const [
      Color(0xFFFFC83D),
      Color(0xFFFF5FA2),
      Color(0xFF35D0C3),
      Color(0xFF86DFFF),
      Color(0xFFFF6B22),
    ];
    for (var index = 0; index < fleckColors.length; index += 1) {
      final angle = -math.pi / 2 + index * math.pi * 0.42;
      final radius = tileRadius * (0.22 + index * 0.11);
      canvas.drawCircle(
        Offset(
          tileCenter.dx + math.cos(angle) * radius,
          tileCenter.dy + math.sin(angle) * radius,
        ),
        size.x * 0.045,
        Paint()..color = fleckColors[index],
      );
    }
    _drawGloss(
      canvas,
      Rect.fromCircle(center: tileCenter, radius: tileRadius * 0.86),
    );
  }

  void _drawFishCharmOverlay(
    Canvas canvas,
    Offset tileCenter,
    double tileRadius,
  ) {
    final fishPaint = Paint()..color = const Color(0xDD86DFFF);
    final fishPath = Path()
      ..moveTo(tileCenter.dx - tileRadius * 0.35, tileCenter.dy)
      ..quadraticBezierTo(
        tileCenter.dx,
        tileCenter.dy - tileRadius * 0.28,
        tileCenter.dx + tileRadius * 0.36,
        tileCenter.dy,
      )
      ..quadraticBezierTo(
        tileCenter.dx,
        tileCenter.dy + tileRadius * 0.28,
        tileCenter.dx - tileRadius * 0.35,
        tileCenter.dy,
      )
      ..close();
    final tailPath = Path()
      ..moveTo(tileCenter.dx - tileRadius * 0.34, tileCenter.dy)
      ..lineTo(
        tileCenter.dx - tileRadius * 0.58,
        tileCenter.dy - tileRadius * 0.18,
      )
      ..lineTo(
        tileCenter.dx - tileRadius * 0.58,
        tileCenter.dy + tileRadius * 0.18,
      )
      ..close();
    canvas
      ..drawPath(fishPath, fishPaint)
      ..drawPath(tailPath, fishPaint)
      ..drawCircle(
        Offset(
          tileCenter.dx + tileRadius * 0.18,
          tileCenter.dy - tileRadius * 0.06,
        ),
        size.x * 0.025,
        Paint()..color = const Color(0xFF2B174A),
      );
  }

  void _drawAlchemyBombOverlay(
    Canvas canvas,
    Offset tileCenter,
    double tileRadius,
  ) {
    final symbolPaint = Paint()
      ..color = _reactiveStateAccentColor(tile.reactiveState)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = size.x * 0.055;
    canvas
      ..drawCircle(tileCenter, tileRadius * 0.42, symbolPaint)
      ..drawLine(
        Offset(tileCenter.dx, tileCenter.dy - tileRadius * 0.62),
        Offset(tileCenter.dx, tileCenter.dy + tileRadius * 0.62),
        symbolPaint,
      )
      ..drawLine(
        Offset(
          tileCenter.dx - tileRadius * 0.55,
          tileCenter.dy + tileRadius * 0.32,
        ),
        Offset(
          tileCenter.dx + tileRadius * 0.55,
          tileCenter.dy + tileRadius * 0.32,
        ),
        symbolPaint,
      );
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

  double _currentRenderScaleX() {
    if (_isClearing) {
      return _currentClearScale();
    }
    if (!_isLanding) {
      return 1;
    }
    final progress =
        (_landingElapsedSeconds / cascadeLandingBounceDurationSeconds).clamp(
          0.0,
          1.0,
        );
    return 1 + math.sin(progress * math.pi) * cascadeLandingSquashFraction / 2;
  }

  double _currentRenderScaleY() {
    if (_isClearing) {
      return _currentClearScale();
    }
    if (!_isLanding) {
      return 1;
    }
    final progress =
        (_landingElapsedSeconds / cascadeLandingBounceDurationSeconds).clamp(
          0.0,
          1.0,
        );
    return 1 - math.sin(progress * math.pi) * cascadeLandingSquashFraction;
  }

  void _drawBaseCandyShape(
    Canvas canvas,
    Rect tileRect,
    Offset tileCenter,
    double tileRadius,
  ) {
    _drawShapeShadow(canvas, tileRect);
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

  void _drawShapeShadow(Canvas canvas, Rect tileRect) {
    final shadowOffset = Offset(size.x * 0.04, size.x * 0.05);
    switch (tile.baseCandy) {
      case BaseCandy.cocoa:
        final rect = tileRect.deflate(size.x * 0.12).shift(shadowOffset);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, Radius.circular(size.x * 0.14)),
          _shadowPaint,
        );
      case BaseCandy.citrus:
      case BaseCandy.cream:
        canvas.drawOval(
          tileRect.deflate(size.x * 0.09).shift(shadowOffset),
          _shadowPaint,
        );
      case BaseCandy.berry:
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            tileRect.deflate(size.x * 0.13).shift(shadowOffset),
            Radius.circular(size.x * 0.34),
          ),
          _shadowPaint,
        );
      case BaseCandy.mint:
        final center = tileRect.center + shadowOffset;
        final radius = size.x * 0.41;
        final path = Path()
          ..moveTo(center.dx, center.dy - radius)
          ..quadraticBezierTo(
            center.dx + radius * 0.88,
            center.dy - radius * 0.12,
            center.dx,
            center.dy + radius,
          )
          ..quadraticBezierTo(
            center.dx - radius * 0.88,
            center.dy - radius * 0.12,
            center.dx,
            center.dy - radius,
          )
          ..close();
        canvas.drawPath(path, _shadowPaint);
    }
  }

  void _drawCocoa(Canvas canvas, Rect tileRect) {
    final cocoaRect = tileRect.deflate(size.x * 0.12);
    final radius = Radius.circular(size.x * 0.14);
    final body = RRect.fromRectAndRadius(cocoaRect, radius);
    canvas.drawRRect(body, _basePaint);
    final bevelPaint = Paint()
      ..color = const Color(0x663A1E12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.06;
    canvas.drawRRect(body.deflate(size.x * 0.06), bevelPaint);
    canvas.drawCircle(
      Offset(cocoaRect.right - size.x * 0.08, cocoaRect.top + size.x * 0.08),
      size.x * 0.1,
      Paint()..color = CandyAlchemyColors.boardCell,
    );
    _drawGloss(canvas, cocoaRect.deflate(size.x * 0.04));
  }

  void _drawCitrus(Canvas canvas, Offset tileCenter, double tileRadius) {
    final path = Path();
    for (var index = 0; index < 8; index += 1) {
      final angle = -math.pi / 2 + index * math.pi / 4;
      final radius = index.isEven ? tileRadius : tileRadius * 0.84;
      final point = Offset(
        tileCenter.dx + math.cos(angle) * radius,
        tileCenter.dy + math.sin(angle) * radius,
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, _basePaint);

    final segmentPaint = Paint()
      ..color = const Color(0x99FFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.045
      ..strokeCap = StrokeCap.round;
    for (final angle in [-math.pi / 2, math.pi / 6, math.pi * 5 / 6]) {
      canvas.drawLine(
        tileCenter,
        Offset(
          tileCenter.dx + math.cos(angle) * tileRadius * 0.62,
          tileCenter.dy + math.sin(angle) * tileRadius * 0.62,
        ),
        segmentPaint,
      );
    }
    _drawGloss(
      canvas,
      Rect.fromCircle(
        center: tileCenter,
        radius: tileRadius,
      ).deflate(size.x * 0.05),
    );
  }

  void _drawBerry(
    Canvas canvas,
    Rect tileRect,
    Offset tileCenter,
    double tileRadius,
  ) {
    final berryRect = Rect.fromCenter(
      center: tileCenter,
      width: tileRadius * 1.35,
      height: tileRadius * 1.9,
    );
    canvas
      ..save()
      ..translate(tileCenter.dx, tileCenter.dy)
      ..rotate(-0.35)
      ..translate(-tileCenter.dx, -tileCenter.dy)
      ..drawRRect(
        RRect.fromRectAndRadius(
          berryRect,
          Radius.circular(berryRect.width * 0.48),
        ),
        _basePaint,
      );
    final lowerPaint = Paint()..color = const Color(0x552B174A);
    canvas.drawArc(
      berryRect.deflate(size.x * 0.04),
      0.2,
      2.4,
      false,
      lowerPaint,
    );
    _drawGloss(canvas, berryRect.deflate(size.x * 0.1));
    canvas.restore();
  }

  void _drawMint(Canvas canvas, Offset tileCenter, double tileRadius) {
    final leaf = Path()
      ..moveTo(tileCenter.dx, tileCenter.dy - tileRadius)
      ..quadraticBezierTo(
        tileCenter.dx + tileRadius * 0.92,
        tileCenter.dy - tileRadius * 0.1,
        tileCenter.dx,
        tileCenter.dy + tileRadius,
      )
      ..quadraticBezierTo(
        tileCenter.dx - tileRadius * 0.92,
        tileCenter.dy - tileRadius * 0.1,
        tileCenter.dx,
        tileCenter.dy - tileRadius,
      )
      ..close();
    canvas.drawPath(leaf, _basePaint);
    final veinPaint = Paint()
      ..color = const Color(0xAAFFF8ED)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.035
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(tileCenter.dx, tileCenter.dy - tileRadius * 0.62),
      Offset(tileCenter.dx, tileCenter.dy + tileRadius * 0.58),
      veinPaint,
    );
    _drawGloss(
      canvas,
      Rect.fromCircle(center: tileCenter, radius: tileRadius * 0.8),
    );
  }

  void _drawCream(Canvas canvas, Offset tileCenter, double tileRadius) {
    canvas.drawOval(
      Rect.fromCircle(center: tileCenter, radius: tileRadius),
      _basePaint,
    );
    final swirlPaint = Paint()
      ..color = const Color(0xFFDCA64A)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.055
      ..strokeCap = StrokeCap.round;
    for (var index = 0; index < 3; index += 1) {
      canvas.drawArc(
        Rect.fromCircle(
          center: tileCenter,
          radius: tileRadius * (0.72 - index * 0.18),
        ),
        0.25 + index * 0.65,
        4.6 - index * 0.8,
        false,
        swirlPaint,
      );
    }
    _drawGloss(
      canvas,
      Rect.fromCircle(center: tileCenter, radius: tileRadius * 0.86),
    );
  }

  void _drawGloss(Canvas canvas, Rect rect) {
    canvas.drawArc(
      rect.deflate(size.x * 0.08),
      3.75,
      0.92,
      false,
      _highlightPaint,
    );
  }

  void _drawReactiveStateAura(Canvas canvas, Rect tileRect) {
    if (tile.reactiveState == ReactiveState.none) {
      return;
    }
    final auraPaint = Paint()
      ..color = _reactiveStateAccentColor(tile.reactiveState).withValues(
        alpha: tile.reactiveState == ReactiveState.living ? 0.16 : 0.2,
      )
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.x * 0.12);
    canvas.drawOval(tileRect.deflate(size.x * 0.16), auraPaint);
  }

  void _drawReactiveStateDecal(Canvas canvas, Rect tileRect) {
    final accentColor = _reactiveStateAccentColor(tile.reactiveState);
    final decalPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.x * 0.035
      ..strokeCap = StrokeCap.round;

    switch (tile.reactiveState) {
      case ReactiveState.molten:
        canvas.drawArc(
          tileRect.deflate(size.x * 0.14),
          -0.2,
          1.35,
          false,
          decalPaint,
        );
      case ReactiveState.frost:
        canvas.drawLine(
          Offset(tileRect.left + size.x * 0.22, tileRect.top + size.x * 0.24),
          Offset(
            tileRect.right - size.x * 0.22,
            tileRect.bottom - size.x * 0.24,
          ),
          decalPaint,
        );
      case ReactiveState.living:
        canvas.drawCircle(
          Offset(
            tileRect.left + size.x * 0.28,
            tileRect.bottom - size.x * 0.24,
          ),
          size.x * 0.045,
          Paint()..color = CandyAlchemyColors.livingHeartParticle,
        );
      case ReactiveState.syrup:
        canvas.drawArc(
          tileRect.deflate(size.x * 0.18),
          1.0,
          1.4,
          false,
          decalPaint,
        );
      case ReactiveState.spice:
        for (final offset in [
          Offset(size.x * 0.28, size.x * 0.28),
          Offset(size.x * 0.44, size.x * 0.2),
          Offset(size.x * 0.6, size.x * 0.32),
        ]) {
          canvas.drawCircle(
            tileRect.topLeft + offset,
            size.x * 0.035,
            Paint()..color = accentColor,
          );
        }
      case ReactiveState.none:
        break;
    }
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

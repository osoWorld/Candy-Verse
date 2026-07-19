import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart';

import '../../../core/constants/gameplay_layout_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';

/// Cascade combo text renderer in the Flame game layer.
class ComboLabelComponent extends PositionComponent {
  /// Creates one self-removing combo label for [cascadeStepIndex].
  ComboLabelComponent({
    required int cascadeStepIndex,
    required Vector2 position,
    required Vector2 size,
  }) : _labelPainter = TextPainter(
         text: TextSpan(
           text: labelForCascadeStep(cascadeStepIndex),
           style: TextStyle(
             color: CandyAlchemyColors.sugarWhite,
             fontSize: math.max(26, size.x * 0.1),
             fontWeight: FontWeight.w900,
             letterSpacing: 0,
           ),
         ),
         textAlign: TextAlign.center,
         textDirection: TextDirection.ltr,
       )..layout(maxWidth: size.x),
       _shadowPainter = TextPainter(
         text: TextSpan(
           text: labelForCascadeStep(cascadeStepIndex),
           style: TextStyle(
             color: CandyAlchemyColors.alchemyInk,
             fontSize: math.max(26, size.x * 0.1),
             fontWeight: FontWeight.w900,
             letterSpacing: 0,
           ),
         ),
         textAlign: TextAlign.center,
         textDirection: TextDirection.ltr,
       )..layout(maxWidth: size.x),
       super(position: position, size: size);

  final TextPainter _labelPainter;
  final TextPainter _shadowPainter;
  final Paint _opacityPaint = Paint();
  final Completer<void> _completed = Completer<void>();
  var _elapsedSeconds = 0.0;

  /// Completes when this combo label has finished and removed itself.
  Future<void> get completed => _completed.future;

  /// Returns the user-facing combo text for [cascadeStepIndex].
  static String labelForCascadeStep(int cascadeStepIndex) {
    final labels = const ['Sweet!', 'Alchemy!', 'Brilliant!', 'Royal Rush!'];
    final labelIndex = math.min(cascadeStepIndex - 1, labels.length - 1);
    return labels[labelIndex < 0 ? 0 : labelIndex];
  }

  /// Advances the self-removing combo label animation.
  @override
  void update(double dt) {
    super.update(dt);

    // DESIGN.md section 11 - combo labels live for 650ms.
    _elapsedSeconds += dt;
    if (_elapsedSeconds >= cascadeComboLabelDurationSeconds) {
      if (!_completed.isCompleted) {
        _completed.complete();
      }
      removeFromParent();
    }
  }

  /// Renders the combo label with the 70% -> 112% -> 100% scale beat.
  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final progress = (_elapsedSeconds / cascadeComboLabelDurationSeconds).clamp(
      0.0,
      1.0,
    );
    final scale = _scaleFor(progress);
    final opacity = progress < 0.78 ? 1.0 : (1 - (progress - 0.78) / 0.22);
    final textOffset = Offset(
      (size.x - _labelPainter.width) / 2,
      (size.y - _labelPainter.height) / 2,
    );
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);

    canvas
      ..saveLayer(
        bounds,
        _opacityPaint
          ..color = Color.fromRGBO(255, 255, 255, opacity.clamp(0.0, 1.0)),
      )
      ..translate(size.x / 2, size.y / 2)
      ..scale(scale, scale)
      ..translate(-size.x / 2, -size.y / 2);

    _drawBackingPill(canvas, textOffset);
    _shadowPainter.paint(
      canvas,
      textOffset.translate(size.x * 0.012, size.x * 0.012),
    );
    _labelPainter.paint(canvas, textOffset);
    canvas.restore();
  }

  double _scaleFor(double progress) {
    if (progress < 0.46) {
      final eased = Curves.easeOutBack.transform(progress / 0.46);
      return _lerp(
        cascadeComboLabelStartScale,
        cascadeComboLabelPeakScale,
        eased,
      );
    }
    final settleProgress = ((progress - 0.46) / 0.54).clamp(0.0, 1.0);
    return _lerp(
      cascadeComboLabelPeakScale,
      cascadeComboLabelEndScale,
      Curves.easeOutCubic.transform(settleProgress),
    );
  }

  double _lerp(double start, double end, double progress) {
    return start + (end - start) * progress.clamp(0.0, 1.0);
  }

  void _drawBackingPill(Canvas canvas, Offset textOffset) {
    final pillRect = Rect.fromCenter(
      center: Offset(size.x / 2, size.y / 2),
      width: math.max(_labelPainter.width + size.x * 0.16, size.x * 0.46),
      height: _labelPainter.height + size.x * 0.07,
    );
    final pillPaint = Paint()
      ..shader = const LinearGradient(
        colors: [CandyAlchemyColors.popPink, CandyAlchemyColors.candyGold],
      ).createShader(pillRect);
    final strokePaint = Paint()
      ..color = CandyAlchemyColors.sugarWhite
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(2, size.x * 0.008);

    canvas
      ..drawRRect(
        RRect.fromRectAndRadius(pillRect, Radius.circular(pillRect.height / 2)),
        pillPaint,
      )
      ..drawRRect(
        RRect.fromRectAndRadius(pillRect, Radius.circular(pillRect.height / 2)),
        strokePaint,
      );
  }
}

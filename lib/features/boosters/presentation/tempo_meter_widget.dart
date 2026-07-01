import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/booster_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';

/// Tempo Meter vial widget in the boosters presentation layer.
class TempoMeterWidget extends StatelessWidget {
  /// Creates a visual Tempo Meter from a normalized [fillRatio].
  const TempoMeterWidget({
    required this.fillRatio,
    required this.isBurstActive,
    super.key,
  });

  /// Filled fraction from 0.0 to 1.0.
  final double fillRatio;

  /// Whether the Tempo Meter burst visual should be active.
  final bool isBurstActive;

  /// Builds the glass vial Tempo Meter UI.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Tempo Meter',
      value: '${(fillRatio.clamp(0.0, 1.0) * 100).round()} percent',
      child: SizedBox(
        width: tempoMeterVialWidth,
        height: tempoMeterVialHeight,
        child: CustomPaint(
          painter: _TempoMeterPainter(
            fillRatio: fillRatio.clamp(0.0, 1.0),
            isBurstActive: isBurstActive,
          ),
        ),
      ),
    );
  }
}

class _TempoMeterPainter extends CustomPainter {
  const _TempoMeterPainter({
    required this.fillRatio,
    required this.isBurstActive,
  });

  final double fillRatio;
  final bool isBurstActive;

  @override
  void paint(Canvas canvas, Size size) {
    final vialRect = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    final vialRadius = Radius.circular(size.width * 0.42);
    final vialRRect = RRect.fromRectAndRadius(vialRect, vialRadius);

    final glassPaint = Paint()
      ..color = CandyAlchemyColors.tileHighlight.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(vialRRect, glassPaint);

    final fillHeight = vialRect.height * fillRatio;
    final fillRect = Rect.fromLTWH(
      vialRect.left,
      vialRect.bottom - fillHeight,
      vialRect.width,
      fillHeight,
    );
    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(fillRect.bottomCenter, fillRect.topCenter, [
        CandyAlchemyColors.frost,
        Color.lerp(
          CandyAlchemyColors.frost,
          CandyAlchemyColors.molten,
          fillRatio,
        )!,
      ]);
    canvas.drawRRect(RRect.fromRectAndRadius(fillRect, vialRadius), fillPaint);

    if (isBurstActive) {
      final burstPaint = Paint()
        ..color = CandyAlchemyColors.molten.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawRRect(vialRRect.deflate(1), burstPaint);
    }

    final outlinePaint = Paint()
      ..color = CandyAlchemyColors.tileHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(vialRRect, outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _TempoMeterPainter oldDelegate) {
    return oldDelegate.fillRatio != fillRatio ||
        oldDelegate.isBurstActive != isBurstActive;
  }
}

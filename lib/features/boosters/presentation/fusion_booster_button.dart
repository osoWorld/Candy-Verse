import 'package:flutter/material.dart';

import '../../../core/constants/booster_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';

/// Fusion Booster button widget in the boosters presentation layer.
class FusionBoosterButton extends StatelessWidget {
  /// Creates a visual Fusion Booster control.
  const FusionBoosterButton({required this.onPressed, super.key});

  /// Called when the player activates the Fusion Booster control.
  final VoidCallback? onPressed;

  /// Builds the half-and-half Fusion Booster tile button.
  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Fusion Booster',
      child: SizedBox.square(
        dimension: fusionBoosterButtonSize,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: onPressed,
          icon: const CustomPaint(
            size: Size.square(fusionBoosterButtonSize),
            painter: _FusionBoosterIconPainter(),
          ),
        ),
      ),
    );
  }
}

class _FusionBoosterIconPainter extends CustomPainter {
  const _FusionBoosterIconPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final clipPath = Path()..addRRect(rrect);
    canvas.save();
    canvas.clipPath(clipPath);

    final leftPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width * 0.55, 0)
      ..lineTo(size.width * 0.45, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(leftPath, Paint()..color = CandyAlchemyColors.frost);

    final rightPath = Path()
      ..moveTo(size.width * 0.55, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width * 0.45, size.height)
      ..close();
    canvas.drawPath(rightPath, Paint()..color = CandyAlchemyColors.molten);

    final seamPaint = Paint()
      ..color = CandyAlchemyColors.temperedShatterCrack
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * 0.55, 4),
      Offset(size.width * 0.45, size.height - 4),
      seamPaint,
    );

    canvas.restore();
    final outlinePaint = Paint()
      ..color = CandyAlchemyColors.tileHighlight
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRRect(rrect.deflate(1), outlinePaint);
  }

  @override
  bool shouldRepaint(covariant _FusionBoosterIconPainter oldDelegate) => false;
}

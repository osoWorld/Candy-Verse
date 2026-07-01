import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/booster_constants.dart';
import '../../gameplay/controllers/gameplay_controller.dart';
import 'fusion_booster_button.dart';
import 'tempo_meter_widget.dart';

/// Step 9 booster UI preview overlay in the boosters presentation layer.
class BoostersPreviewOverlay extends StatelessWidget {
  /// Creates a lightweight booster overlay for the current gameplay preview.
  const BoostersPreviewOverlay({required this.gameplayController, super.key});

  /// Gameplay bridge controller that exposes Tempo Meter state.
  final GameplayController gameplayController;

  /// Builds the visible Tempo Meter and Fusion Booster preview controls.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(boosterPreviewOverlayPadding),
        child: Align(
          alignment: Alignment.centerRight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => TempoMeterWidget(
                  fillRatio: gameplayController.tempoMeterState.value.fillRatio,
                  isBurstActive:
                      gameplayController.tempoMeterState.value.isBurstActive,
                ),
              ),
              const SizedBox(height: boosterPreviewControlGap),
              FusionBoosterButton(onPressed: () {}),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../boosters/presentation/fusion_booster_button.dart';
import '../../boosters/presentation/tempo_meter_widget.dart';
import '../controllers/gameplay_controller.dart';

/// GameplayHUD widget in the Flutter UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md §4 lists gameplay components/game/controllers
/// but Step 11 requires Flutter HUD widgets; presentation is the nearest parent.
class GameplayHUD extends StatelessWidget {
  /// Creates the Gameplay HUD from [gameplayController].
  const GameplayHUD({required this.gameplayController, super.key});

  /// Gameplay bridge controller that exposes live HUD state.
  final GameplayController gameplayController;

  /// Builds the HUD overlay for gameplay.
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(gameplayHudPadding),
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Wrap(
                spacing: uiControlGap,
                runSpacing: uiControlGap,
                alignment: WrapAlignment.center,
                children: [
                  Obx(
                    () => _HudStat(
                      icon: Icons.stars_rounded,
                      label: 'Score',
                      value: gameplayController.score.value.toString(),
                    ),
                  ),
                  Obx(
                    () => _HudStat(
                      icon: Icons.swap_horiz_rounded,
                      label: 'Moves',
                      value: gameplayController.movesRemaining.value.toString(),
                    ),
                  ),
                  Obx(
                    () => _HudStat(
                      icon: Icons.flag_rounded,
                      label: 'Goal',
                      value: gameplayController.goalLabel.value,
                    ),
                  ),
                ],
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Obx(
                    () => TempoMeterWidget(
                      fillRatio:
                          gameplayController.tempoMeterState.value.fillRatio,
                      isBurstActive: gameplayController
                          .tempoMeterState
                          .value
                          .isBurstActive,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  FusionBoosterButton(
                    onPressed: () => gameplayController.addScore(100),
                  ),
                  const SizedBox(height: uiControlGap),
                  IconButton.filledTonal(
                    onPressed: () => Get.toNamed(AppRoutes.winOverlay),
                    icon: const Icon(Icons.emoji_events_rounded),
                    tooltip: 'Win Overlay',
                  ),
                  const SizedBox(height: uiControlGap),
                  IconButton.filledTonal(
                    onPressed: () => Get.toNamed(AppRoutes.loseOverlay),
                    icon: const Icon(Icons.heart_broken_rounded),
                    tooltip: 'Lose Overlay',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gameplayHudStatWidth,
      height: gameplayHudStatHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.iconBackground,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.boardTrayBorder),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            children: [
              Icon(icon, color: CandyAlchemyColors.frost, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CandyAlchemyColors.tileHighlight,
                      ),
                    ),
                    Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: CandyAlchemyColors.cream,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

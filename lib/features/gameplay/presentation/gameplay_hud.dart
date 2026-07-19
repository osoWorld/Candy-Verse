import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../boosters/domain/booster_type.dart';
import '../../boosters/presentation/tempo_meter_widget.dart';
import '../../settings/controllers/settings_controller.dart';
import '../controllers/gameplay_controller.dart';

/// GameplayHUD widget in the Flutter UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md section 4 lists gameplay
/// components/game/controllers but Step 11 requires Flutter HUD widgets;
/// presentation is the nearest parent.
class GameplayHUD extends StatelessWidget {
  /// Creates the Gameplay HUD from [gameplayController].
  const GameplayHUD({
    required this.gameplayController,
    this.onRestartLevel,
    super.key,
  });

  /// Gameplay bridge controller that exposes live HUD state.
  final GameplayController gameplayController;

  /// Callback invoked when the pause overlay asks to restart the level.
  final VoidCallback? onRestartLevel;

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
              child: _TopHudBar(
                gameplayController: gameplayController,
                onRestartLevel: onRestartLevel,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: _BoosterTray(gameplayController: gameplayController),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top gameplay status bar in the Flutter UI layer.
class _TopHudBar extends StatelessWidget {
  const _TopHudBar({required this.gameplayController, this.onRestartLevel});

  final GameplayController gameplayController;
  final VoidCallback? onRestartLevel;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: gameplayHudTopBarMinHeight),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.iconBackground,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.boardTrayBorder),
          boxShadow: const [
            BoxShadow(
              color: CandyAlchemyColors.tileShadow,
              blurRadius: uiControlGap,
              offset: Offset(0, uiPanelCornerRadius),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(uiControlGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Obx(
                    () => _LevelBadge(
                      levelNumber: gameplayController.currentLevelNumber.value,
                    ),
                  ),
                  const SizedBox(width: uiControlGap),
                  Expanded(
                    child: Obx(
                      () => _HudPill(
                        icon: Icons.stars_rounded,
                        label: 'Score',
                        value: gameplayController.score.value.toString(),
                      ),
                    ),
                  ),
                  const SizedBox(width: uiControlGap),
                  Obx(
                    () => _MovesPill(
                      movesRemaining: gameplayController.movesRemaining.value,
                    ),
                  ),
                  const SizedBox(width: uiControlGap),
                  _HudIconButton(
                    icon: Icons.pause_rounded,
                    tooltip: 'Pause',
                    onPressed: _showPauseDialog,
                  ),
                ],
              ),
              const SizedBox(height: uiControlGap),
              Row(
                children: [
                  Expanded(
                    child: Obx(
                      () => _GoalPill(
                        goalLabel: gameplayController.goalLabel.value,
                      ),
                    ),
                  ),
                  const SizedBox(width: uiControlGap),
                  Expanded(
                    child: Obx(
                      () => _StarProgress(
                        score: gameplayController.score.value,
                        goalLabel: gameplayController.goalLabel.value,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showPauseDialog() async {
    gameplayController.pauseGameplay();
    await Get.dialog<void>(
      _PauseDialog(
        gameplayController: gameplayController,
        onRestartLevel: onRestartLevel,
      ),
      barrierDismissible: false,
    );
    if (gameplayController.isPaused.value) {
      gameplayController.resumeGameplay();
    }
  }
}

/// Level number badge in the gameplay HUD layer.
class _LevelBadge extends StatelessWidget {
  const _LevelBadge({required this.levelNumber});

  final int levelNumber;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: gameplayHudPillHeight,
      width: gameplayHudBoosterButtonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.citrus,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.cream, width: 2),
        ),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              levelNumber.toString(),
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: CandyAlchemyColors.gameplayBackground,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact stat pill in the gameplay HUD layer.
class _HudPill extends StatelessWidget {
  const _HudPill({
    required this.icon,
    required this.label,
    required this.value,
    this.accentColor = CandyAlchemyColors.frost,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: gameplayHudPillHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.boardTray,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: accentColor),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: uiControlGap),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 20),
              const SizedBox(width: uiPanelCornerRadius),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: CandyAlchemyColors.tileHighlight,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: CandyAlchemyColors.cream,
                        fontWeight: FontWeight.w900,
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

/// Moves counter pill in the gameplay HUD layer.
class _MovesPill extends StatelessWidget {
  const _MovesPill({required this.movesRemaining});

  final int movesRemaining;

  @override
  Widget build(BuildContext context) {
    final isLow = movesRemaining <= 5;
    return SizedBox(
      width: gameplayHudStatWidth,
      child: _HudPill(
        icon: Icons.swap_horiz_rounded,
        label: 'Moves',
        value: movesRemaining.toString(),
        accentColor: isLow
            ? CandyAlchemyColors.molten
            : CandyAlchemyColors.frost,
      ),
    );
  }
}

/// Current level goal pill in the gameplay HUD layer.
class _GoalPill extends StatelessWidget {
  const _GoalPill({required this.goalLabel});

  final String goalLabel;

  @override
  Widget build(BuildContext context) {
    return _HudPill(icon: Icons.flag_rounded, label: 'Goal', value: goalLabel);
  }
}

/// Star meter in the gameplay HUD layer.
class _StarProgress extends StatelessWidget {
  const _StarProgress({required this.score, required this.goalLabel});

  final int score;
  final String goalLabel;

  @override
  Widget build(BuildContext context) {
    final targetScore = math.max(_targetScoreFromGoal(goalLabel), 1);
    final fill = (score / targetScore).clamp(0.0, 1.0);
    final earnedStars = math.min(3, (fill * 3).ceil());

    return SizedBox(
      height: gameplayHudPillHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.boardTray,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.boardCellHighlight),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: uiControlGap),
          child: Row(
            children: [
              for (var index = 0; index < 3; index += 1)
                Icon(
                  Icons.star_rounded,
                  color: index < earnedStars
                      ? CandyAlchemyColors.citrus
                      : CandyAlchemyColors.boardCellHighlight,
                  size: 18,
                ),
              const SizedBox(width: uiPanelCornerRadius),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(uiPanelCornerRadius),
                  child: LinearProgressIndicator(
                    value: fill,
                    minHeight: gameplayHudStarProgressHeight,
                    backgroundColor: CandyAlchemyColors.gameplayBackground,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      CandyAlchemyColors.citrus,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  int _targetScoreFromGoal(String goalLabel) {
    final match = RegExp(r'\d+').firstMatch(goalLabel);
    if (match == null) {
      return 1;
    }
    return int.tryParse(match.group(0) ?? '') ?? 1;
  }
}

/// Square icon button used by gameplay HUD controls.
class _HudIconButton extends StatelessWidget {
  const _HudIconButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: gameplayHudIconButtonSize,
      child: IconButton(
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        style: IconButton.styleFrom(
          backgroundColor: CandyAlchemyColors.boardTray,
          foregroundColor: CandyAlchemyColors.cream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(uiPanelCornerRadius),
            side: const BorderSide(
              color: CandyAlchemyColors.boardCellHighlight,
            ),
          ),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
      ),
    );
  }
}

/// Bottom booster tray in the gameplay HUD layer.
class _BoosterTray extends StatelessWidget {
  const _BoosterTray({required this.gameplayController});

  final GameplayController gameplayController;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: gameplayHudBoosterTrayHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.iconBackground,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.boardTrayBorder),
          boxShadow: const [
            BoxShadow(
              color: CandyAlchemyColors.tileShadow,
              blurRadius: uiControlGap,
              offset: Offset(0, uiPanelCornerRadius),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: uiControlGap,
            vertical: uiPanelCornerRadius,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => _TempoTrayItem(
                  fillRatio: gameplayController.tempoMeterState.value.fillRatio,
                  isBurstActive:
                      gameplayController.tempoMeterState.value.isBurstActive,
                ),
              ),
              const SizedBox(width: uiControlGap),
              for (final boosterType in gameplayController.trayBoosterTypes)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: uiControlGap),
                    _BoosterTraySlot(
                      boosterType: boosterType,
                      gameplayController: gameplayController,
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Reactive booster inventory slot in the gameplay HUD layer.
class _BoosterTraySlot extends StatelessWidget {
  const _BoosterTraySlot({
    required this.boosterType,
    required this.gameplayController,
  });

  final BoosterType boosterType;
  final GameplayController gameplayController;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => _BoosterTrayButton(
        icon: _boosterIcon(boosterType),
        label: _boosterLabel(boosterType),
        count: gameplayController.boosterCount(boosterType),
        isSelected: gameplayController.isBoosterSelected(boosterType),
        colors: _boosterColors(boosterType),
        onPressed: () => gameplayController.selectBooster(boosterType),
      ),
    );
  }
}

/// Tempo meter tray item in the gameplay HUD layer.
class _TempoTrayItem extends StatelessWidget {
  const _TempoTrayItem({required this.fillRatio, required this.isBurstActive});

  final double fillRatio;
  final bool isBurstActive;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: gameplayHudBoosterButtonSize,
      height: gameplayHudBoosterButtonSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: CandyAlchemyColors.boardTray,
          borderRadius: BorderRadius.circular(uiPanelCornerRadius),
          border: Border.all(color: CandyAlchemyColors.boardCellHighlight),
        ),
        child: Center(
          child: Transform.scale(
            scale: 0.42,
            child: TempoMeterWidget(
              fillRatio: fillRatio,
              isBurstActive: isBurstActive,
            ),
          ),
        ),
      ),
    );
  }
}

/// Booster button used inside the gameplay booster tray.
class _BoosterTrayButton extends StatelessWidget {
  const _BoosterTrayButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.isSelected,
    required this.colors,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool isSelected;
  final List<Color> colors;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && count > 0;

    return Tooltip(
      message: label,
      child: Opacity(
        opacity: isEnabled ? 1 : 0.54,
        child: SizedBox.square(
          dimension: gameplayHudBoosterButtonSize,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: colors,
                    ),
                    borderRadius: BorderRadius.circular(uiPanelCornerRadius),
                    border: Border.all(
                      color: isSelected
                          ? CandyAlchemyColors.citrus
                          : CandyAlchemyColors.cream,
                      width: isSelected ? 3 : 2,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: CandyAlchemyColors.tileShadow,
                        blurRadius: uiPanelCornerRadius,
                        offset: Offset(0, uiPanelCornerRadius / 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    onPressed: isEnabled ? onPressed : null,
                    icon: Icon(
                      icon,
                      color: CandyAlchemyColors.gameplayBackground,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: -uiPanelCornerRadius / 2,
                right: -uiPanelCornerRadius / 2,
                child: _BoosterCountBadge(count: count),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _boosterIcon(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => Icons.auto_awesome_rounded,
    BoosterType.tempoMeter => Icons.bolt_rounded,
    BoosterType.architectTile => Icons.architecture_rounded,
    BoosterType.echoCandy => Icons.graphic_eq_rounded,
  };
}

String _boosterLabel(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => 'Fusion',
    BoosterType.tempoMeter => 'Tempo',
    BoosterType.architectTile => 'Architect',
    BoosterType.echoCandy => 'Echo',
  };
}

List<Color> _boosterColors(BoosterType boosterType) {
  return switch (boosterType) {
    BoosterType.fusionBooster => const [
      CandyAlchemyColors.frost,
      CandyAlchemyColors.molten,
    ],
    BoosterType.tempoMeter => const [
      CandyAlchemyColors.citrus,
      CandyAlchemyColors.molten,
    ],
    BoosterType.architectTile => const [
      CandyAlchemyColors.mint,
      CandyAlchemyColors.citrus,
    ],
    BoosterType.echoCandy => const [
      CandyAlchemyColors.berry,
      CandyAlchemyColors.frost,
    ],
  };
}

/// Booster inventory badge in the gameplay HUD layer.
class _BoosterCountBadge extends StatelessWidget {
  const _BoosterCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: gameplayHudBoosterBadgeSize,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: count > 0
              ? CandyAlchemyColors.molten
              : CandyAlchemyColors.boardTray,
          shape: BoxShape.circle,
          border: Border.all(color: CandyAlchemyColors.cream),
        ),
        child: Center(
          child: Text(
            count.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: CandyAlchemyColors.cream,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

/// Pause dialog in the gameplay presentation layer.
class _PauseDialog extends StatelessWidget {
  const _PauseDialog({required this.gameplayController, this.onRestartLevel});

  final GameplayController gameplayController;
  final VoidCallback? onRestartLevel;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CandyAlchemyColors.iconBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiPanelCornerRadius),
        side: const BorderSide(color: CandyAlchemyColors.boardTrayBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(uiSectionGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.pause_circle_filled_rounded,
                color: CandyAlchemyColors.citrus,
                size: gameplayHudBoosterButtonSize,
              ),
              const SizedBox(height: uiControlGap),
              Text(
                'Paused',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CandyAlchemyColors.cream,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: uiSectionGap),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: uiControlGap,
                runSpacing: uiControlGap,
                children: [
                  FilledButton.icon(
                    onPressed: _resume,
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Resume'),
                  ),
                  OutlinedButton.icon(
                    onPressed: onRestartLevel == null ? null : _restart,
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Restart'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _openSettings,
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Settings'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _returnToMap,
                    icon: const Icon(Icons.map_rounded),
                    label: const Text('Map'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resume() {
    gameplayController.resumeGameplay();
    Get.back<void>();
  }

  void _restart() {
    gameplayController.resumeGameplay();
    Get.back<void>();
    onRestartLevel?.call();
  }

  void _returnToMap() {
    gameplayController.resumeGameplay();
    Get.back<void>();
    Get.offNamed(AppRoutes.kingdomMap);
  }

  void _openSettings() {
    Get.dialog<void>(const _SettingsDialog());
  }
}

/// Settings dialog launched from the gameplay pause overlay.
class _SettingsDialog extends StatelessWidget {
  const _SettingsDialog();

  @override
  Widget build(BuildContext context) {
    final settingsController = Get.find<SettingsController>();
    return Dialog(
      backgroundColor: CandyAlchemyColors.iconBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(uiPanelCornerRadius),
        side: const BorderSide(color: CandyAlchemyColors.boardTrayBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(uiSectionGap),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.tune_rounded,
                color: CandyAlchemyColors.frost,
                size: gameplayHudBoosterButtonSize,
              ),
              const SizedBox(height: uiControlGap),
              Text(
                'Settings',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: CandyAlchemyColors.cream,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: uiControlGap),
              Obx(() {
                final settings = settingsController.settings.value;
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _SettingsSwitch(
                      icon: Icons.volume_up_rounded,
                      title: 'Sound',
                      value: settings.soundEnabled,
                      onChanged: (value) =>
                          unawaited(settingsController.setSoundEnabled(value)),
                    ),
                    _SettingsSwitch(
                      icon: Icons.vibration_rounded,
                      title: 'Haptics',
                      value: settings.hapticsEnabled,
                      onChanged: (value) => unawaited(
                        settingsController.setHapticsEnabled(value),
                      ),
                    ),
                    _SettingsSwitch(
                      icon: Icons.motion_photos_off_rounded,
                      title: 'Reduce Motion',
                      value: settings.reduceMotionEnabled,
                      onChanged: (value) => unawaited(
                        settingsController.setReduceMotionEnabled(value),
                      ),
                    ),
                  ],
                );
              }),
              const SizedBox(height: uiSectionGap),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => Get.back<void>(),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle row used by the gameplay settings dialog.
class _SettingsSwitch extends StatelessWidget {
  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: CandyAlchemyColors.citrus),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: CandyAlchemyColors.cream,
          fontWeight: FontWeight.w800,
        ),
      ),
      activeThumbColor: CandyAlchemyColors.mint,
      value: value,
      onChanged: onChanged,
    );
  }
}

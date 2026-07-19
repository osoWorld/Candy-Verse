import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../kingdom_map/controllers/kingdom_map_controller.dart';
import '../controllers/gameplay_controller.dart';
import '../controllers/gameplay_outcome.dart';
import '../controllers/gameplay_session.dart';

/// LoseOverlay screen in the Flutter UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md §4 lists gameplay components/game/controllers
/// but Step 11 requires Flutter overlay widgets; presentation is the nearest parent.
class LoseOverlay extends StatefulWidget {
  /// Creates the lose overlay route.
  const LoseOverlay({super.key});

  /// Creates state for the lose overlay route.
  @override
  State<LoseOverlay> createState() => _LoseOverlayState();
}

class _LoseOverlayState extends State<LoseOverlay>
    with TickerProviderStateMixin {
  late final GameplayController _gameplayController;
  late final GameplayOutcome _outcome;
  late final AnimationController _dimController;
  late final AnimationController _promptController;

  @override
  void initState() {
    super.initState();
    _gameplayController = Get.find<GameplayController>();
    _outcome = _outcomeFromArguments(Get.arguments);
    _dimController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: gameplayToLoseOverlayTransitionMilliseconds,
      ),
    );
    _promptController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: loseOverlayPromptFadeMilliseconds),
    );
    unawaited(_runLoseOverlaySequence());
  }

  @override
  void dispose() {
    _promptController.dispose();
    _dimController.dispose();
    super.dispose();
  }

  /// Builds the level-failed overlay.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.gameplayBackground,
      body: Stack(
        children: [
          Positioned.fill(
            child: FadeTransition(
              opacity: _dimController,
              child: ColoredBox(
                color: Colors.black.withValues(alpha: loseOverlayDimOpacity),
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _promptController,
              child: Padding(
                padding: const EdgeInsets.all(uiScreenPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(),
                    Icon(
                      Icons.hourglass_empty_rounded,
                      color: CandyAlchemyColors.frost,
                      size: 72,
                    ),
                    const SizedBox(height: uiSectionGap),
                    Text(
                      'Try Again',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: CandyAlchemyColors.cream,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: uiControlGap),
                    Text(
                      _outcome.goalRemainingLabel,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: CandyAlchemyColors.cream,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: uiControlGap),
                    Text(
                      'Score ${_outcome.score}',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: CandyAlchemyColors.tileHighlight,
                      ),
                    ),
                    const SizedBox(height: uiSectionGap),
                    FilledButton.icon(
                      onPressed: () => Get.offNamed(
                        AppRoutes.gameplay,
                        arguments: _sessionArgumentForLevel(
                          _outcome.levelNumber,
                        ),
                      ),
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('Retry'),
                    ),
                    const SizedBox(height: uiControlGap),
                    OutlinedButton.icon(
                      onPressed: () => Get.offNamed(AppRoutes.kingdomMap),
                      icon: const Icon(Icons.map_rounded),
                      label: const Text('Map'),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _runLoseOverlaySequence() async {
    await _dimController.forward();
    if (!mounted) {
      return;
    }
    await _promptController.forward();
  }

  Object _sessionArgumentForLevel(int levelNumber) {
    if (Get.isRegistered<KingdomMapController>()) {
      try {
        return GameplaySession.fromLevel(
          level: Get.find<KingdomMapController>().levelByNumber(levelNumber),
          selectedPreGameBoosters: const [],
        );
      } on RangeError {
        return levelNumber;
      }
    }
    return levelNumber;
  }

  GameplayOutcome _outcomeFromArguments(Object? arguments) {
    if (arguments is GameplayOutcome) {
      return arguments;
    }
    final controllerOutcome = _gameplayController.gameplayOutcome.value;
    if (controllerOutcome != null) {
      return controllerOutcome;
    }
    return GameplayOutcome(
      didWin: false,
      levelId: _gameplayController.levelId.value,
      levelNumber: _gameplayController.currentLevelNumber.value,
      kingdomName: _gameplayController.kingdomName.value,
      goalLabel: _gameplayController.goalLabel.value,
      goalRemainingLabel: _gameplayController.goalLabel.value,
      score: _gameplayController.score.value,
      bestScore: _gameplayController.score.value,
      stars: 0,
      bestStars: 0,
      movesRemaining: _gameplayController.movesRemaining.value,
      rewardLabel: '',
      rewardBoosterType: null,
      saveStatusLabel: '',
    );
  }
}

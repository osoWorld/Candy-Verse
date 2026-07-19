import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../../data/generators/level_config_generator.dart';
import '../../boosters/domain/booster_type.dart';
import '../../kingdom_map/controllers/kingdom_map_controller.dart';
import '../controllers/gameplay_controller.dart';
import '../controllers/gameplay_outcome.dart';
import '../controllers/gameplay_session.dart';

/// WinOverlay screen in the Flutter UI layer.
///
/// PLACEMENT_NOTE: ARCHITECTURE.md §4 lists gameplay components/game/controllers
/// but Step 11 requires Flutter overlay widgets; presentation is the nearest parent.
class WinOverlay extends StatefulWidget {
  /// Creates the win overlay route.
  const WinOverlay({super.key});

  /// Creates state for the win overlay route.
  @override
  State<WinOverlay> createState() => _WinOverlayState();
}

class _WinOverlayState extends State<WinOverlay> with TickerProviderStateMixin {
  late final GameplayController _gameplayController;
  late final GameplayOutcome _outcome;
  late final AnimationController _slideController;
  late final AnimationController _starFillController;
  late final AnimationController _rewardController;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _rewardScaleAnimation;

  @override
  void initState() {
    super.initState();
    _gameplayController = Get.find<GameplayController>();
    _outcome = _outcomeFromArguments(Get.arguments);
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: gameplayToWinOverlayTransitionMilliseconds,
      ),
    );
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _slideController, curve: Curves.easeOutBack),
        );
    _starFillController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: _earnedStarCount * winOverlayStarFillPerStarMilliseconds,
      ),
    );
    _rewardController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: winOverlayRewardRevealMilliseconds,
      ),
    );
    _rewardScaleAnimation = Tween<double>(begin: 0.72, end: 1).animate(
      CurvedAnimation(parent: _rewardController, curve: Curves.easeOutBack),
    );

    _gameplayController.playLevelCompleteFeedback();
    unawaited(_startCelebrationAfterBoardFreeze());
  }

  @override
  void dispose() {
    _slideController.dispose();
    _starFillController.dispose();
    _rewardController.dispose();
    super.dispose();
  }

  /// Builds the level-complete overlay.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.gameplayBackground,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.08,
              colors: [
                Color(0xFF4B2B67),
                CandyAlchemyColors.gameplayBackground,
              ],
            ),
          ),
          child: SlideTransition(
            position: _slideAnimation,
            child: Padding(
              padding: const EdgeInsets.all(uiScreenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Spacer(),
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _starFillController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: const Size(150, 96),
                            painter: _WinBurstPainter(
                              progress: _starFillController.value,
                            ),
                          );
                        },
                      ),
                      Icon(
                        Icons.emoji_events_rounded,
                        color: CandyAlchemyColors.candyGold,
                        size: 76,
                      ),
                    ],
                  ),
                  const SizedBox(height: uiSectionGap),
                  Text(
                    'Recipe Complete',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: CandyAlchemyColors.cream,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  Text(
                    'Level ${_outcome.levelNumber} - ${_outcome.kingdomName}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CandyAlchemyColors.frost,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < 3; index += 1)
                        _AnimatedWinStar(
                          index: index,
                          earnedStars: _outcome.stars,
                          controller: _starFillController,
                        ),
                    ],
                  ),
                  const SizedBox(height: uiControlGap),
                  Text(
                    'Score ${_outcome.score}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CandyAlchemyColors.cream,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  Text(
                    'Best ${_outcome.bestScore}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: CandyAlchemyColors.frost,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  _RewardReveal(
                    rewardLabel: _outcome.rewardLabel,
                    controller: _rewardController,
                    scaleAnimation: _rewardScaleAnimation,
                  ),
                  const SizedBox(height: uiControlGap),
                  Text(
                    '${_outcome.movesRemaining} moves left',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: CandyAlchemyColors.tileHighlight,
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  Text(
                    _outcome.saveStatusLabel,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: CandyAlchemyColors.tileHighlight,
                    ),
                  ),
                  const SizedBox(height: uiSectionGap),
                  FilledButton.icon(
                    onPressed: _goToNextLevel,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: Text(
                      _outcome.levelNumber >=
                              LevelConfigGenerator.totalLevelCount
                          ? 'Map'
                          : 'Next',
                    ),
                  ),
                  const SizedBox(height: uiControlGap),
                  OutlinedButton.icon(
                    onPressed: () => Get.offNamed(
                      AppRoutes.gameplay,
                      arguments: _sessionArgumentForLevel(_outcome.levelNumber),
                    ),
                    icon: const Icon(Icons.replay_rounded),
                    label: const Text('Replay'),
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
      ),
    );
  }

  int get _earnedStarCount => _outcome.stars.clamp(1, 3);

  Future<void> _startCelebrationAfterBoardFreeze() async {
    await Future<void>.delayed(
      const Duration(milliseconds: gameplayFinalStateFreezeMilliseconds),
    );
    if (!mounted) {
      return;
    }
    await _slideController.forward();
    if (!mounted) {
      return;
    }
    await _starFillController.forward();
    if (!mounted) {
      return;
    }
    await _rewardController.forward();
  }

  Future<void> _goToNextLevel() async {
    await Future<void>.delayed(
      const Duration(milliseconds: levelCompleteLiquidMorphMilliseconds),
    );
    if (!mounted) {
      return;
    }
    if (_outcome.levelNumber >= LevelConfigGenerator.totalLevelCount) {
      Get.offNamed(AppRoutes.kingdomMap);
      return;
    }
    Get.offNamed(
      AppRoutes.gameplay,
      arguments: _sessionArgumentForLevel(_outcome.levelNumber + 1),
    );
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
      didWin: true,
      levelId: _gameplayController.levelId.value,
      levelNumber: _gameplayController.currentLevelNumber.value,
      kingdomName: _gameplayController.kingdomName.value,
      goalLabel: _gameplayController.goalLabel.value,
      goalRemainingLabel: 'Goal complete',
      score: _gameplayController.score.value,
      bestScore: _gameplayController.score.value,
      stars: 1,
      bestStars: 1,
      movesRemaining: _gameplayController.movesRemaining.value,
      rewardLabel: '+1 Fusion Booster',
      rewardBoosterType: BoosterType.fusionBooster,
      saveStatusLabel: 'Saved offline - syncs when Supabase is configured',
    );
  }
}

class _AnimatedWinStar extends StatelessWidget {
  const _AnimatedWinStar({
    required this.index,
    required this.earnedStars,
    required this.controller,
  });

  final int index;
  final int earnedStars;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    if (index >= earnedStars) {
      return const Icon(
        Icons.star_rounded,
        color: CandyAlchemyColors.boardCellHighlight,
        size: 40,
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final fillProgress = ((controller.value * earnedStars) - index).clamp(
          0.0,
          1.0,
        );
        final eased = Curves.easeOutBack.transform(fillProgress);
        return Transform.scale(
          scale: 0.72 + eased * 0.38,
          child: Opacity(
            opacity: fillProgress.clamp(0.0, 1.0),
            child: const Icon(
              Icons.star_rounded,
              color: CandyAlchemyColors.candyGold,
              size: 40,
            ),
          ),
        );
      },
    );
  }
}

class _RewardReveal extends StatelessWidget {
  const _RewardReveal({
    required this.rewardLabel,
    required this.controller,
    required this.scaleAnimation,
  });

  final String rewardLabel;
  final AnimationController controller;
  final Animation<double> scaleAnimation;

  @override
  Widget build(BuildContext context) {
    if (rewardLabel.isEmpty) {
      return const SizedBox(height: 24);
    }
    return FadeTransition(
      opacity: controller,
      child: ScaleTransition(
        scale: scaleAnimation,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: CandyAlchemyColors.candyGold.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(uiPanelCornerRadius),
            border: Border.all(
              color: CandyAlchemyColors.candyGold.withValues(alpha: 0.72),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: uiControlGap,
              vertical: uiControlGap / 2,
            ),
            child: Text(
              rewardLabel,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: CandyAlchemyColors.candyGold,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinBurstPainter extends CustomPainter {
  const _WinBurstPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = CandyAlchemyColors.candyGold.withValues(
        alpha: (1 - progress).clamp(0.0, 1.0) * 0.75,
      )
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3;
    for (var index = 0; index < 10; index += 1) {
      final angle = index * 0.6283185307;
      final inner = 26 + progress * 14;
      final outer = 38 + progress * 34;
      canvas.drawLine(
        center.translate(math.cos(angle) * inner, math.sin(angle) * inner),
        center.translate(math.cos(angle) * outer, math.sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WinBurstPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

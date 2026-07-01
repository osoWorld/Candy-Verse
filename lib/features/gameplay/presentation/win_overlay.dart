import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../../level_map/controllers/level_map_controller.dart';
import '../controllers/gameplay_controller.dart';

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

class _WinOverlayState extends State<WinOverlay>
    with SingleTickerProviderStateMixin {
  late final GameplayController _gameplayController;
  late final LevelMapController? _levelMapController;
  late final AnimationController _slideController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _gameplayController = Get.find<GameplayController>();
    _levelMapController = Get.isRegistered<LevelMapController>()
        ? Get.find<LevelMapController>()
        : null;
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

    _gameplayController.playLevelCompleteFeedback();
    unawaited(_startSlideAfterBoardFreeze());
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  /// Builds the level-complete overlay.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SlideTransition(
          position: _slideAnimation,
          child: Padding(
            padding: const EdgeInsets.all(uiScreenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Icon(
                  Icons.emoji_events_rounded,
                  color: CandyAlchemyColors.citrus,
                  size: 72,
                ),
                const SizedBox(height: uiSectionGap),
                Text(
                  'Recipe Complete',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: CandyAlchemyColors.cream,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: uiControlGap),
                Obx(
                  () => Text(
                    'Score ${_gameplayController.score.value}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: CandyAlchemyColors.frost,
                    ),
                  ),
                ),
                const SizedBox(height: uiSectionGap),
                FilledButton.icon(
                  onPressed: _goToNextLevel,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Next'),
                ),
                const SizedBox(height: uiControlGap),
                OutlinedButton.icon(
                  onPressed: () => Get.offNamed(
                    AppRoutes.gameplay,
                    arguments: _gameplayController.currentLevelNumber.value,
                  ),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Replay'),
                ),
                const SizedBox(height: uiControlGap),
                OutlinedButton.icon(
                  onPressed: () => Get.offNamed(AppRoutes.levelMap),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Map'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _startSlideAfterBoardFreeze() async {
    await Future<void>.delayed(
      const Duration(milliseconds: gameplayFinalStateFreezeMilliseconds),
    );
    if (!mounted) {
      return;
    }
    await _slideController.forward();
  }

  Future<void> _goToNextLevel() async {
    final currentLevel = _gameplayController.currentLevelNumber.value;
    _levelMapController?.completeLevel(currentLevel);
    await Future<void>.delayed(
      const Duration(milliseconds: levelCompleteLiquidMorphMilliseconds),
    );
    if (!mounted) {
      return;
    }
    Get.offNamed(AppRoutes.gameplay, arguments: currentLevel + 1);
  }
}

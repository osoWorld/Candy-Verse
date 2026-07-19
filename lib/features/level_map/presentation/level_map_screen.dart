import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/navigation_constants.dart';
import '../../../core/constants/ui_constants.dart';
import '../../../core/theme/candy_alchemy_colors.dart';
import '../controllers/level_map_controller.dart';

/// Level Map screen in the Flutter UI layer.
class LevelMapScreen extends GetView<LevelMapController> {
  /// Creates the Candy Alchemy Level Map screen.
  const LevelMapScreen({super.key});

  /// Builds the fallback Alchemy Kingdoms level map route.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CandyAlchemyColors.cream,
      appBar: AppBar(
        backgroundColor: CandyAlchemyColors.cream,
        foregroundColor: CandyAlchemyColors.cocoa,
        title: const Text('Alchemy Kingdoms'),
        leading: IconButton(
          onPressed: Get.back,
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(uiScreenPadding),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: uiSectionGap,
              crossAxisSpacing: uiSectionGap,
            ),
            itemCount: controller.levelNumbers.length,
            itemBuilder: (context, index) {
              final levelNumber = controller.levelNumbers[index];
              return Obx(
                () => _LevelNode(
                  levelNumber: levelNumber,
                  isUnlocked: controller.isLevelUnlocked(levelNumber),
                  onPressed: controller.isLevelUnlocked(levelNumber)
                      ? () => Get.toNamed(
                          AppRoutes.gameplay,
                          arguments: levelNumber,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LevelNode extends StatelessWidget {
  const _LevelNode({
    required this.levelNumber,
    required this.isUnlocked,
    required this.onPressed,
  });

  final int levelNumber;
  final bool isUnlocked;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox.square(
        dimension: levelMapNodeSize,
        child: IconButton.filled(
          onPressed: onPressed,
          style: IconButton.styleFrom(
            backgroundColor: isUnlocked
                ? CandyAlchemyColors.mint
                : CandyAlchemyColors.boardTrayBorder,
            foregroundColor: isUnlocked
                ? CandyAlchemyColors.cream
                : CandyAlchemyColors.cocoa,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(uiPanelCornerRadius),
            ),
          ),
          icon: Icon(
            isUnlocked
                ? Icons.local_dining_rounded
                : Icons.lock_outline_rounded,
          ),
          tooltip: 'Level $levelNumber',
        ),
      ),
    );
  }
}

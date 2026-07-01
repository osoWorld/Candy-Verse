import 'package:get/get.dart';

import '../../../core/constants/ui_constants.dart';

/// Level map state controller in the GetX UI layer.
class LevelMapController extends GetxController {
  /// Current highest unlocked level number.
  final RxInt highestUnlockedLevel = 1.obs;

  /// Level numbers shown in the current preview chapter.
  List<int> get levelNumbers => [
    for (var level = 1; level <= previewLevelCount; level += 1) level,
  ];

  /// Returns whether [levelNumber] is unlocked.
  ///
  /// Inputs: one-based level number. Output: unlocked state. Side effects:
  /// none.
  bool isLevelUnlocked(int levelNumber) {
    return levelNumber <= highestUnlockedLevel.value;
  }

  /// Marks [levelNumber] as completed and unlocks the next level.
  ///
  /// Inputs: one-based level number. Output: none. Side effects: updates
  /// [highestUnlockedLevel].
  void completeLevel(int levelNumber) {
    if (levelNumber >= highestUnlockedLevel.value) {
      highestUnlockedLevel.value = levelNumber + 1;
    }
  }
}

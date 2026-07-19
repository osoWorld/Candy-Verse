import 'package:get/get.dart';

import '../../../core/utils/candy_alchemy_feedback.dart';
import '../../../data/repositories/level_repository.dart';
import '../../../data/repositories/settings_repository.dart';
import '../../../data/repositories/tutorial_progress_repository.dart';
import '../../onboarding/controllers/tutorial_controller.dart';
import '../../settings/controllers/settings_controller.dart';
import 'gameplay_controller.dart';

/// GetX binding for the Gameplay feature.
class GameplayBinding extends Bindings {
  /// Injects gameplay dependencies for gameplay routes.
  @override
  void dependencies() {
    if (!Get.isRegistered<LevelRepository>()) {
      Get.put(LevelRepository(), permanent: true);
    }
    if (!Get.isRegistered<SettingsRepository>()) {
      Get.put(
        SettingsRepository(local: MemorySettingsLocalDataSource()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TutorialProgressRepository>()) {
      Get.put(
        TutorialProgressRepository(
          local: MemoryTutorialProgressLocalDataSource(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<SettingsController>()) {
      Get.put(
        SettingsController(settingsRepository: Get.find<SettingsRepository>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<TutorialController>()) {
      Get.put(
        TutorialController(
          tutorialProgressRepository: Get.find<TutorialProgressRepository>(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<GameplayController>()) {
      final settingsController = Get.find<SettingsController>();
      Get.put(
        GameplayController(
          feedback: PlatformCandyAlchemyFeedback(
            soundEnabledProvider: () => settingsController.soundEnabled,
            hapticsEnabledProvider: () => settingsController.hapticsEnabled,
          ),
        ),
        permanent: true,
      );
    }
  }
}

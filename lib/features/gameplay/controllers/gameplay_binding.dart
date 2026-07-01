import 'package:get/get.dart';

import 'gameplay_controller.dart';

/// GetX binding for the Gameplay feature.
class GameplayBinding extends Bindings {
  /// Injects GameplayController for gameplay routes.
  @override
  void dependencies() {
    if (!Get.isRegistered<GameplayController>()) {
      Get.put(GameplayController(), permanent: true);
    }
  }
}

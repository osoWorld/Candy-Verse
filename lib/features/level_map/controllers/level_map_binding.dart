import 'package:get/get.dart';

import 'level_map_controller.dart';

/// GetX binding for the Level Map feature.
class LevelMapBinding extends Bindings {
  /// Injects LevelMapController for Level Map routes.
  @override
  void dependencies() {
    if (!Get.isRegistered<LevelMapController>()) {
      Get.put(LevelMapController());
    }
  }
}

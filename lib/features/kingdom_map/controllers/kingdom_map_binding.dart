import 'package:get/get.dart';

import '../../../data/repositories/booster_inventory_repository.dart';
import '../../../data/repositories/kingdom_gate_reward_repository.dart';
import '../../../data/repositories/kingdom_repository.dart';
import '../../../data/repositories/story_progress_repository.dart';
import 'kingdom_map_controller.dart';

/// GetX binding for the Kingdom Map feature.
class KingdomMapBinding extends Bindings {
  /// Injects KingdomMapController for Kingdom Map routes.
  @override
  void dependencies() {
    if (!Get.isRegistered<KingdomRepository>()) {
      Get.put(KingdomRepository(), permanent: true);
    }
    if (!Get.isRegistered<StoryProgressRepository>()) {
      Get.put(
        StoryProgressRepository(local: MemoryStoryProgressLocalDataSource()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<KingdomGateRewardRepository>()) {
      Get.put(
        KingdomGateRewardRepository(
          local: MemoryKingdomGateRewardLocalDataSource(),
        ),
        permanent: true,
      );
    }
    if (!Get.isRegistered<KingdomMapController>()) {
      Get.put(
        KingdomMapController(
          kingdomRepository: Get.find<KingdomRepository>(),
          storyProgressRepository: Get.find<StoryProgressRepository>(),
          kingdomGateRewardRepository: Get.find<KingdomGateRewardRepository>(),
          boosterInventoryRepository:
              Get.isRegistered<BoosterInventoryRepository>()
              ? Get.find<BoosterInventoryRepository>()
              : null,
        ),
        permanent: true,
      );
    }
  }
}

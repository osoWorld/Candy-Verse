import 'package:get/get.dart';

import '../../../core/constants/kingdom_constants.dart';
import '../../../core/constants/persistence_constants.dart';
import '../../../core/constants/profile_constants.dart';
import '../../../data/models/daily_reward_state.dart';
import '../../../data/models/player_progress_record.dart';
import '../../../data/repositories/booster_inventory_repository.dart';
import '../../../data/repositories/daily_reward_repository.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../boosters/domain/booster_type.dart';
import '../../kingdom_map/controllers/kingdom_map_controller.dart';
import '../domain/daily_reward_definition.dart';

// PLACEMENT_NOTE: ARCHITECTURE.md does not yet list profile folders; the player
// profile shell is isolated here so menu/map UI can depend on one controller.

/// Player profile and daily reward controller in the GetX UI layer.
class PlayerProfileController extends GetxController {
  /// Creates a profile controller backed by reward, inventory, and progress.
  PlayerProfileController({
    required this.dailyRewardRepository,
    this.boosterInventoryRepository,
    this.progressRepository,
    DateTime Function()? nowProvider,
  }) : nowProvider = nowProvider ?? DateTime.now;

  /// Repository used to persist daily reward claim state.
  final DailyRewardRepository dailyRewardRepository;

  /// Optional repository used to show and grant booster inventory.
  final BoosterInventoryRepository? boosterInventoryRepository;

  /// Optional repository used to summarize saved level progress.
  final ProgressRepository? progressRepository;

  /// Clock source used for daily reward date keys.
  final DateTime Function() nowProvider;

  /// Player display name shown in the profile shell.
  final RxString playerName = defaultPlayerProfileName.obs;

  /// Highest unlocked level shown in the progress summary.
  final RxInt unlockedLevel = profileInitialUnlockedLevel.obs;

  /// Total earned stars across completed levels.
  final RxInt totalStars = 0.obs;

  /// Furthest kingdom reached by the player.
  final RxString bestKingdomName = profileKingdomNamesByIndex.first.obs;

  /// Booster counts shown in the inventory summary.
  final RxMap<BoosterType, int> boosterCounts = <BoosterType, int>{}.obs;

  /// Current daily reward claim state.
  final Rx<DailyRewardState> dailyRewardState =
      const DailyRewardState.initial().obs;

  /// Whether profile data is currently loading.
  final RxBool isLoadingProfile = false.obs;

  /// Whether the daily reward claim is currently being saved.
  final RxBool isClaimingDailyReward = false.obs;

  /// Most recently claimed reward for short-lived UI feedback.
  final Rxn<DailyRewardDefinition> lastClaimedReward =
      Rxn<DailyRewardDefinition>();

  /// Seven-day V1 daily reward track.
  ///
  /// DESIGN_DEFAULT: reward quantities are offline V1 defaults until live
  /// economy tuning is specified.
  static const List<DailyRewardDefinition> dailyRewardTrack = [
    DailyRewardDefinition(
      day: 1,
      boosterType: BoosterType.fusionBooster,
      quantity: 1,
    ),
    DailyRewardDefinition(
      day: 2,
      boosterType: BoosterType.echoCandy,
      quantity: 1,
    ),
    DailyRewardDefinition(
      day: 3,
      boosterType: BoosterType.architectTile,
      quantity: 1,
    ),
    DailyRewardDefinition(
      day: 4,
      boosterType: BoosterType.fusionBooster,
      quantity: 1,
    ),
    DailyRewardDefinition(
      day: 5,
      boosterType: BoosterType.echoCandy,
      quantity: 2,
    ),
    DailyRewardDefinition(
      day: 6,
      boosterType: BoosterType.architectTile,
      quantity: 2,
    ),
    DailyRewardDefinition(
      day: 7,
      boosterType: BoosterType.fusionBooster,
      quantity: 3,
    ),
  ];

  /// Loads profile summary, booster inventory, and daily reward state.
  ///
  /// Inputs: none. Output: completion future. Side effects: reads repositories
  /// and updates GetX observables.
  Future<void> loadProfile() async {
    isLoadingProfile.value = true;
    try {
      dailyRewardState.value = await dailyRewardRepository
          .loadDailyRewardState();
      await _loadProgressSummary();
      await _loadBoosterInventory();
    } finally {
      isLoadingProfile.value = false;
    }
  }

  /// Returns whether today's reward can be claimed.
  ///
  /// Inputs: none. Output: claim availability. Side effects: none.
  bool get canClaimDailyReward {
    return !dailyRewardState.value.hasClaimedOn(_dateKeyFor(nowProvider()));
  }

  /// Returns the next reward in the daily streak cycle.
  ///
  /// Inputs: none. Output: reward definition. Side effects: none.
  DailyRewardDefinition get nextDailyReward {
    return dailyRewardForDay(_nextStreakDay());
  }

  /// Returns the current streak day to highlight in the reward track.
  ///
  /// Inputs: none. Output: one-based streak day. Side effects: none.
  int get visibleStreakDay {
    if (canClaimDailyReward) {
      return _nextStreakDay();
    }
    return dailyRewardState.value.streakDay
        .clamp(1, dailyRewardCycleLength)
        .toInt();
  }

  /// Returns the reward definition for [day].
  ///
  /// Inputs: one-based day. Output: matching cycle reward. Side effects: none.
  static DailyRewardDefinition dailyRewardForDay(int day) {
    final normalizedIndex = (day - 1) % dailyRewardTrack.length;
    return dailyRewardTrack[normalizedIndex];
  }

  /// Returns the visible count for [boosterType].
  ///
  /// Inputs: booster type. Output: owned count. Side effects: none.
  int boosterCount(BoosterType boosterType) {
    return boosterCounts[boosterType] ?? 0;
  }

  /// Claims today's daily reward when available.
  ///
  /// Inputs: none. Output: claimed reward or null if already claimed. Side
  /// effects: updates booster inventory and persists daily reward state.
  Future<DailyRewardDefinition?> claimDailyReward() async {
    if (!canClaimDailyReward || isClaimingDailyReward.value) {
      return null;
    }

    isClaimingDailyReward.value = true;
    try {
      final streakDay = _nextStreakDay();
      final reward = dailyRewardForDay(streakDay);
      await _grantReward(reward);
      final nextState = DailyRewardState(
        lastClaimDateKey: _dateKeyFor(nowProvider()),
        streakDay: streakDay,
      );
      await dailyRewardRepository.saveDailyRewardState(nextState);
      dailyRewardState.value = nextState;
      lastClaimedReward.value = reward;
      return reward;
    } finally {
      isClaimingDailyReward.value = false;
    }
  }

  Future<void> _loadBoosterInventory() async {
    final repository =
        boosterInventoryRepository ?? _registeredBoosterInventoryRepository();
    if (repository == null) {
      boosterCounts.assignAll(BoosterInventoryRepository.starterInventory());
      return;
    }
    boosterCounts.assignAll(
      await repository.loadInventory(defaultLocalPlayerId),
    );
  }

  Future<void> _loadProgressSummary() async {
    final mapController = _registeredKingdomMapController();
    if (mapController != null) {
      _applyMapProgress(mapController);
      return;
    }

    final repository = progressRepository ?? _registeredProgressRepository();
    if (repository == null) {
      _applyFallbackProgress();
      return;
    }

    final records = await repository.loadProgress(defaultLocalPlayerId);
    _applyProgressRecords(records);
  }

  Future<void> _grantReward(DailyRewardDefinition reward) async {
    final repository =
        boosterInventoryRepository ?? _registeredBoosterInventoryRepository();
    if (repository == null) {
      boosterCounts[reward.boosterType] =
          boosterCount(reward.boosterType) + reward.quantity;
      return;
    }

    await repository.addBooster(
      playerId: defaultLocalPlayerId,
      boosterType: reward.boosterType,
      quantity: reward.quantity,
    );
    boosterCounts.assignAll(
      await repository.loadInventory(defaultLocalPlayerId),
    );
  }

  void _applyMapProgress(KingdomMapController mapController) {
    unlockedLevel.value = mapController.highestUnlockedLevel.value;
    totalStars.value = mapController.completedLevelStars.values.fold<int>(
      0,
      (sum, stars) => sum + stars,
    );
    bestKingdomName.value = _kingdomNameForLevel(unlockedLevel.value);
  }

  void _applyProgressRecords(List<PlayerProgressRecord> records) {
    if (records.isEmpty) {
      _applyFallbackProgress();
      return;
    }

    var nextUnlockedLevel = profileInitialUnlockedLevel;
    var nextTotalStars = 0;
    for (final record in records) {
      final levelNumber = _levelNumberForId(record.levelId);
      if (levelNumber == null) {
        continue;
      }
      nextTotalStars += record.stars.clamp(0, 3).toInt();
      if (levelNumber + 1 > nextUnlockedLevel) {
        nextUnlockedLevel = levelNumber + 1;
      }
    }

    unlockedLevel.value = nextUnlockedLevel
        .clamp(
          profileInitialUnlockedLevel,
          v1KingdomCount * v1LevelsPerKingdom + 1,
        )
        .toInt();
    totalStars.value = nextTotalStars;
    bestKingdomName.value = _kingdomNameForLevel(unlockedLevel.value);
  }

  void _applyFallbackProgress() {
    unlockedLevel.value = profileInitialUnlockedLevel;
    totalStars.value = 0;
    bestKingdomName.value = profileKingdomNamesByIndex.first;
  }

  int _nextStreakDay() {
    final state = dailyRewardState.value;
    final todayKey = _dateKeyFor(nowProvider());
    if (state.lastClaimDateKey == todayKey) {
      return state.streakDay.clamp(1, dailyRewardCycleLength).toInt();
    }
    final yesterdayKey = _dateKeyFor(
      nowProvider().subtract(const Duration(days: 1)),
    );
    if (state.lastClaimDateKey == yesterdayKey) {
      return state.streakDay % dailyRewardCycleLength + 1;
    }
    return 1;
  }

  String _dateKeyFor(DateTime dateTime) {
    final local = dateTime.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  String _kingdomNameForLevel(int levelNumber) {
    final clampedLevel = levelNumber
        .clamp(profileInitialUnlockedLevel, v1KingdomCount * v1LevelsPerKingdom)
        .toInt();
    final index = ((clampedLevel - 1) ~/ v1LevelsPerKingdom)
        .clamp(0, profileKingdomNamesByIndex.length - 1)
        .toInt();
    return profileKingdomNamesByIndex[index];
  }

  int? _levelNumberForId(String levelId) {
    final markerIndex = levelId.lastIndexOf('_level');
    if (markerIndex == -1) {
      return null;
    }
    return int.tryParse(levelId.substring(markerIndex + 6));
  }

  BoosterInventoryRepository? _registeredBoosterInventoryRepository() {
    if (!Get.isRegistered<BoosterInventoryRepository>()) {
      return null;
    }
    return Get.find<BoosterInventoryRepository>();
  }

  ProgressRepository? _registeredProgressRepository() {
    if (!Get.isRegistered<ProgressRepository>()) {
      return null;
    }
    return Get.find<ProgressRepository>();
  }

  KingdomMapController? _registeredKingdomMapController() {
    if (!Get.isRegistered<KingdomMapController>()) {
      return null;
    }
    return Get.find<KingdomMapController>();
  }
}
